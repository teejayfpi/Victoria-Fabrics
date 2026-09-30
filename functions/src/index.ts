import { setGlobalOptions } from "firebase-functions/v2";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

setGlobalOptions({ region: "us-central1", maxInstances: 10 });

// ─── Shared constants ───────────────────────────────────────────────────────

const PRODUCTS = "products";
const ORDERS = "orders";
const ADMINS = "admins";

const VALID_UNITS = ["Yard", "Meter", "Piece"] as const;
type Unit = (typeof VALID_UNITS)[number];

const MAX_LINE_ITEMS = 50;
const MAX_QUANTITY = 1000;
const TOTAL_TOLERANCE = 0.01;

// ─── Validation helpers ─────────────────────────────────────────────────────

class ValidationError extends Error {}

function requireString(
  value: unknown,
  field: string,
  { min = 1, max = 500 }: { min?: number; max?: number } = {},
): string {
  if (typeof value !== "string") {
    throw new ValidationError(`${field} must be a string`);
  }
  const trimmed = value.trim();
  if (trimmed.length < min || trimmed.length > max) {
    throw new ValidationError(
      `${field} must be between ${min} and ${max} characters`,
    );
  }
  return trimmed;
}

function optionalString(
  value: unknown,
  field: string,
  max = 500,
): string | null {
  if (value === undefined || value === null || value === "") return null;
  return requireString(value, field, { max });
}

function requireUnit(value: unknown): Unit {
  if (typeof value !== "string" || !VALID_UNITS.includes(value as Unit)) {
    throw new ValidationError(
      `selectedUnit must be one of ${VALID_UNITS.join(", ")}`,
    );
  }
  return value as Unit;
}

function requireQuantity(value: unknown): number {
  if (
    typeof value !== "number" ||
    !Number.isInteger(value) ||
    value < 1 ||
    value > MAX_QUANTITY
  ) {
    throw new ValidationError(
      `quantity must be an integer between 1 and ${MAX_QUANTITY}`,
    );
  }
  return value;
}

interface LineInput {
  productId: string;
  quantity: number;
  selectedUnit: Unit;
}

function parseItems(raw: unknown): LineInput[] {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new ValidationError("items must be a non-empty array");
  }
  if (raw.length > MAX_LINE_ITEMS) {
    throw new ValidationError(`at most ${MAX_LINE_ITEMS} line items allowed`);
  }
  return raw.map((entry) => {
    if (typeof entry !== "object" || entry === null) {
      throw new ValidationError("each item must be an object");
    }
    const item = entry as Record<string, unknown>;
    return {
      productId: requireString(item.productId, "productId", { max: 128 }),
      quantity: requireQuantity(item.quantity),
      selectedUnit: requireUnit(item.selectedUnit),
    };
  });
}

function priceFor(
  product: FirebaseFirestore.DocumentData,
  unit: Unit,
): number {
  const field =
    unit === "Yard"
      ? "pricePerYard"
      : unit === "Meter"
        ? "pricePerMeter"
        : "pricePerPiece";
  const value = product[field];
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

// ─── placeOrder ─────────────────────────────────────────────────────────────

/**
 * Authoritative order placement.
 *
 * Everything that determines money or stock is derived here, server-side:
 * prices are read from the product documents, the total is recomputed, stock
 * is decremented, and the order is written with a pinned `pending` status.
 * The client only supplies intent (which product, how many, which unit).
 */
export const placeOrder = onCall(async (request: CallableRequest) => {
  const data = (request.data ?? {}) as Record<string, unknown>;

  try {
    const items = parseItems(data.items);
    const deliveryType = data.deliveryType;
    if (deliveryType !== "delivery" && deliveryType !== "pickup") {
      throw new ValidationError("deliveryType must be 'delivery' or 'pickup'");
    }

    const deliveryAddress =
      deliveryType === "delivery"
        ? requireString(data.deliveryAddress, "deliveryAddress", { max: 500 })
        : null;
    const pickupLocation = optionalString(data.pickupLocation, "pickupLocation");
    const customerName = requireString(data.customerName, "customerName", {
      max: 120,
    });
    const customerPhone = requireString(data.customerPhone, "customerPhone", {
      min: 7,
      max: 20,
    });
    const expectedTotal =
      typeof data.expectedTotal === "number" ? data.expectedTotal : null;

    const userId = request.auth?.uid ?? null;
    const orderRef = db.collection(ORDERS).doc();

    const total = await db.runTransaction(async (txn) => {
      const refs = items.map((i) => db.collection(PRODUCTS).doc(i.productId));
      const snaps: FirebaseFirestore.DocumentSnapshot[] = [];
      for (const ref of refs) {
        snaps.push(await txn.get(ref));
      }

      let serverTotal = 0;
      const lineItems: Array<Record<string, unknown>> = [];

      items.forEach((item, index) => {
        const snap = snaps[index];
        if (!snap.exists) {
          throw new ValidationError(
            `Product ${item.productId} is no longer available`,
          );
        }
        const product = snap.data() as FirebaseFirestore.DocumentData;
        if (product.inStock === false) {
          throw new ValidationError(`${product.name ?? "Item"} is out of stock`);
        }

        const unitPrice = priceFor(product, item.selectedUnit);
        if (unitPrice <= 0) {
          throw new ValidationError(
            `${product.name ?? "Item"} has no price for ${item.selectedUnit}`,
          );
        }

        const stockCount =
          typeof product.stockCount === "number" ? product.stockCount : null;
        if (stockCount !== null && item.quantity > stockCount) {
          throw new ValidationError(
            `Only ${stockCount} ${item.selectedUnit}(s) of ${
              product.name ?? "item"
            } left`,
          );
        }

        const lineTotal = unitPrice * item.quantity;
        serverTotal += lineTotal;

        lineItems.push({
          productId: item.productId,
          productName: product.name ?? "",
          imageUrl:
            Array.isArray(product.imageUrls) && product.imageUrls.length > 0
              ? product.imageUrls[0]
              : "",
          quantity: item.quantity,
          selectedUnit: item.selectedUnit,
          unitPrice,
          totalPrice: lineTotal,
        });

        if (stockCount !== null) {
          const next = stockCount - item.quantity;
          txn.update(refs[index], { stockCount: next, inStock: next > 0 });
        }
      });

      if (expectedTotal !== null && Math.abs(serverTotal - expectedTotal) > TOTAL_TOLERANCE) {
        logger.warn("Order total mismatch rejected", {
          expected: expectedTotal,
          server: serverTotal,
        });
        throw new ValidationError("Order total changed. Please review your cart.");
      }

      txn.set(orderRef, {
        id: orderRef.id.substring(0, 8).toUpperCase(),
        userId,
        items: lineItems,
        totalAmount: serverTotal,
        deliveryType,
        deliveryAddress,
        pickupLocation,
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        customerName,
        customerPhone,
      });

      return serverTotal;
    });

    logger.info("Order placed", { orderId: orderRef.id, userId, total });
    return {
      orderId: orderRef.id,
      displayId: orderRef.id.substring(0, 8).toUpperCase(),
      totalAmount: total,
    };
  } catch (error) {
    if (error instanceof ValidationError) {
      throw new HttpsError("invalid-argument", error.message);
    }
    logger.error("placeOrder failed", error);
    throw new HttpsError(
      "internal",
      "We could not place your order. Please try again.",
    );
  }
});

// ─── Admin claim management ─────────────────────────────────────────────────

/**
 * Confirms the caller holds the super-admin role, either through the `role`
 * custom claim or the `admins/{uid}` roster document.
 */
async function assertSuperAdmin(uid: string | undefined): Promise<void> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const user = await admin.auth().getUser(uid);
  const claimRole = user.customClaims?.role;
  if (claimRole === "superAdmin") return;

  const doc = await db.collection(ADMINS).doc(uid).get();
  if (doc.exists && doc.data()?.role === "superAdmin") return;

  throw new HttpsError(
    "permission-denied",
    "Only a super admin may manage administrator roles.",
  );
}

const ASSIGNABLE_ROLES = ["viewer", "staff", "admin", "superAdmin"] as const;
type AssignableRole = (typeof ASSIGNABLE_ROLES)[number];

/**
 * Grants or updates an administrator role. Sets the `role` custom claim (the
 * authoritative source the security rules read) and mirrors it into the
 * `admins/{uid}` document for the admin roster.
 */
export const setAdminRole = onCall(async (request: CallableRequest) => {
  await assertSuperAdmin(request.auth?.uid);

  const data = (request.data ?? {}) as Record<string, unknown>;
  const targetUid = requireString(data.uid, "uid", { max: 128 });
  const role = data.role;
  if (typeof role !== "string" || !ASSIGNABLE_ROLES.includes(role as AssignableRole)) {
    throw new HttpsError(
      "invalid-argument",
      `role must be one of ${ASSIGNABLE_ROLES.join(", ")}`,
    );
  }

  await admin.auth().setCustomUserClaims(targetUid, { role });
  await db.collection(ADMINS).doc(targetUid).set(
    {
      role,
      email: (await admin.auth().getUser(targetUid)).email ?? "",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: request.auth?.uid ?? null,
    },
    { merge: true },
  );

  logger.info("Admin role set", { targetUid, role, by: request.auth?.uid });
  return { uid: targetUid, role };
});

/** Revokes an administrator role (custom claim + roster document). */
export const removeAdminRole = onCall(async (request: CallableRequest) => {
  await assertSuperAdmin(request.auth?.uid);

  const data = (request.data ?? {}) as Record<string, unknown>;
  const targetUid = requireString(data.uid, "uid", { max: 128 });

  await admin.auth().setCustomUserClaims(targetUid, { role: null });
  await db.collection(ADMINS).doc(targetUid).delete();

  logger.info("Admin role removed", { targetUid, by: request.auth?.uid });
  return { uid: targetUid, role: null };
});
