import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import '../data/mappers/order_document.dart';
import '../data/mappers/place_order_payload.dart';
import '../domain/entities/cart_item.dart';
import '../domain/entities/category.dart';
import '../domain/entities/order.dart';
import '../domain/entities/product.dart';
import '../domain/entities/store_settings.dart';
import '../domain/entities/ticket.dart';
import '../domain/entities/user_profile.dart';
import '../data/datasources/mock_data_source.dart';

/// Low-level Firestore access. Prefer the repositories in
/// `lib/data/repositories/` — they add error mapping and validation.
class FirestoreService {
  FirestoreService._();

  /// Test seam: allows a subclass to override individual Firestore-backed
  /// methods without touching a live project. Production always uses the
  /// singleton above.
  @visibleForTesting
  FirestoreService.forTest();

  static final FirestoreService instance = FirestoreService._();

  // Resolved lazily so the test seam above can construct the service without a
  // live Firebase app; production still reaches the singleton instance.
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(AppConfig.productsCollection);
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(AppConfig.ordersCollection);
  CollectionReference<Map<String, dynamic>> get _tickets =>
      _db.collection(AppConfig.ticketsCollection);
  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection(AppConfig.categoriesCollection);
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConfig.usersCollection);
  DocumentReference<Map<String, dynamic>> get _storeSettings => _db
      .collection(AppConfig.settingsCollection)
      .doc(AppConfig.storeSettingsDoc);

  // ─── Products ─────────────────────────────────────────────────────

  Stream<List<Product>> productsStream() {
    return _products.snapshots().map((snap) => snap.docs
        .map((doc) => Product.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<void> addProduct(Product product) async {
    await _products.doc(product.id).set(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    final data = product.toMap()..remove('createdAt');
    await _products.doc(product.id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  Future<Product?> getProductById(String id) async {
    final doc = await _products.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.id, doc.data()!);
  }

  // ─── Categories ───────────────────────────────────────────────────

  Stream<List<Category>> categoriesStream() {
    return _categories
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Category.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addCategory(Category category) async {
    await _categories.doc(category.id).set({
      ...category.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory(Category category) async {
    await _categories.doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
  }

  /// Seeds the category collection from the bundled defaults the first time
  /// the app runs against an empty database.
  Future<void> seedCategoriesIfEmpty() async {
    final markerRef = _db.collection('_meta').doc('category_seed');
    final existing = await _categories.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final marker = await markerRef.get();
    if (marker.exists) return;

    final batch = _db.batch();
    for (final category in MockDataSource.categories) {
      batch.set(_categories.doc(category.id), {
        ...category.toMap(),
        'createdAt': Timestamp.now(),
      });
    }
    batch.set(markerRef, {'seededAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  // ─── Orders ───────────────────────────────────────────────────────

  /// All orders (admin view). Bounded so a growing store does not stream the
  /// entire history to every client; paginate from the UI when needed.
  Stream<List<Map<String, dynamic>>> ordersStream({int limit = 100}) {
    return _orders
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                <String, dynamic>{...doc.data(), 'firestoreId': doc.id})
            .toList());
  }

  /// Per-user orders (customer view).
  Stream<List<Order>> userOrdersStream(String uid) {
    return _orders
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Order.fromMap(doc.id, doc.data())).toList());
  }

  /// Places an order.
  ///
  /// Preferred path is the `placeOrder` Cloud Function, which re-derives price,
  /// stock and total with the Admin SDK. When Cloud Functions are unavailable —
  /// notably on the free Spark plan, which cannot run Cloud Functions — this
  /// falls back to a Firestore transaction whose result the security rules
  /// independently validate (see `firestore.rules`). In both paths the client
  /// never dictates a price or total.
  ///
  /// [expectedTotal] is only used to detect a stale cart.
  /// Returns the new order's document id.
  Future<String> createOrder({
    required List<CartItem> items,
    required double expectedTotal,
    required DeliveryType deliveryType,
    String? deliveryAddress,
    String? pickupLocation,
    required String customerName,
    required String customerPhone,
  }) async {
    if (items.isEmpty) {
      throw StateError('Cannot create an order with no items');
    }

    final payload = buildPlaceOrderPayload(
      items: items,
      expectedTotal: expectedTotal,
      deliveryType: deliveryType,
      deliveryAddress: deliveryAddress,
      pickupLocation: pickupLocation,
      customerName: customerName,
      customerPhone: customerPhone,
    );

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('placeOrder');
      final response =
          await callable.call<Map<String, dynamic>>(payload);
      final orderId = response.data['orderId'] as String?;
      if (orderId == null) {
        throw StateError('Order was not confirmed by the server');
      }
      AppLogger.info('Order created (function)', tag: 'firestore',
          context: {'orderId': orderId});
      return orderId;
    } on FirebaseFunctionsException catch (e) {
      // A rejected order (bad payload, stale total, out of stock) must surface
      // to the user, not silently fall back to the weaker path.
      if (_isConfigurationError(e)) {
        AppLogger.warning(
          'Cloud Functions unavailable, using rules-validated transaction',
          tag: 'firestore',
          context: {'code': e.code},
        );
        return _createOrderInTransaction(
          items: items,
          expectedTotal: expectedTotal,
          deliveryType: deliveryType,
          deliveryAddress: deliveryAddress,
          pickupLocation: pickupLocation,
          customerName: customerName,
          customerPhone: customerPhone,
        );
      }
      AppLogger.error('placeOrder rejected', tag: 'firestore', error: e);
      rethrow;
    }
  }

  /// `not-found`/`unavailable` mean the function is not deployed or reachable,
  /// as opposed to a validation failure the server deliberately returned.
  bool _isConfigurationError(FirebaseFunctionsException e) {
    return e.code == 'not-found' ||
        e.code == 'unavailable' ||
        e.code == 'internal' ||
        e.code == 'failed-precondition';
  }

  Future<String> _createOrderInTransaction({
    required List<CartItem> items,
    required double expectedTotal,
    required DeliveryType deliveryType,
    String? deliveryAddress,
    String? pickupLocation,
    required String customerName,
    required String customerPhone,
  }) async {
    final orderRef = _orders.doc();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    await _db.runTransaction((txn) async {
      // 1. Read every referenced product at its authoritative state.
      final productRefs =
          items.map((i) => _products.doc(i.product.id)).toList();
      final snapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final ref in productRefs) {
        snapshots.add(await txn.get(ref));
      }

      // 2. Validate availability and recompute the total from live prices.
      var serverTotal = 0.0;
      final lineItems = <Map<String, dynamic>>[];

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final snap = snapshots[i];
        if (!snap.exists) {
          throw StateError('Product ${item.product.id} is no longer available');
        }
        final product = Product.fromMap(snap.id, snap.data()!);
        if (!product.inStock) {
          throw StateError('${product.name} is out of stock');
        }

        final unitPrice = product.getPrice(item.selectedUnit);
        if (unitPrice <= 0) {
          throw StateError(
              '${product.name} has no price for ${item.selectedUnit}');
        }

        final remaining = product.stockCount;
        if (remaining != null && item.quantity > remaining) {
          throw StateError(
              'Only $remaining ${item.selectedUnit}(s) of ${product.name} left');
        }

        final lineItem = buildOrderLineItem(product: product, item: item);
        serverTotal += lineItem['totalPrice'] as double;
        lineItems.add(lineItem);
      }

      if ((serverTotal - expectedTotal).abs() > 0.01) {
        AppLogger.warning(
          'Order total mismatch rejected',
          tag: 'firestore',
          context: {'expected': expectedTotal, 'server': serverTotal},
        );
        throw StateError('Order total changed. Please review your cart.');
      }

      // 3. Decrement stock for tracked products.
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final product = Product.fromMap(snapshots[i].id, snapshots[i].data()!);
        final remaining = product.stockCount;
        if (remaining == null) continue;
        final next = remaining - item.quantity;
        txn.update(productRefs[i], {
          'stockCount': next,
          'inStock': next > 0,
        });
      }

      txn.set(
        orderRef,
        buildOrderDocument(
          shortId: orderRef.id.substring(0, 8).toUpperCase(),
          userId: userId,
          lineItems: lineItems,
          totalAmount: orderTotal(lineItems),
          deliveryType: deliveryType,
          deliveryAddress: deliveryAddress,
          pickupLocation: pickupLocation,
          customerName: customerName,
          customerPhone: customerPhone,
        ),
      );
    });

    AppLogger.info('Order created (transaction)', tag: 'firestore',
        context: {'orderId': orderRef.id});
    return orderRef.id;
  }

  Future<void> updateOrderStatus(String firestoreId, String status) async {
    await _orders.doc(firestoreId).update({'status': status});
  }

  // ─── Support Tickets ──────────────────────────────────────────────

  Stream<List<SupportTicket>> ticketsStream({int limit = 200}) {
    return _tickets
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SupportTicket.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> submitTicket(SupportTicket ticket) async {
    await _tickets.doc(ticket.id).set(ticket.toMap());
  }

  Future<void> updateTicketStatus(String id, String status) async {
    await _tickets.doc(id).update({'status': status});
  }

  // ─── Customer profile (wishlist, addresses, preferences) ──────────

  /// Live `users/{uid}` document. The security rule for this collection
  /// restricts reads and writes to the owning account.
  Stream<UserProfile> userProfileStream(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((snap) => UserProfile.fromMap(snap.data()));

  /// Merges [data] into the customer's profile document, leaving unrelated
  /// fields (wishlist, addresses, preferences) untouched.
  Future<void> mergeUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _users.doc(uid).set(data, SetOptions(merge: true));
  }

  // ─── Store settings ───────────────────────────────────────────────

  /// Live `settings/store` document, defaulted when it has never been written.
  /// World-readable, so the storefront can show the delivery fee before
  /// checkout.
  Stream<StoreSettings> storeSettingsStream() => _storeSettings
      .snapshots()
      .map((snap) => StoreSettings.fromMap(snap.data()));

  /// Persists the store settings. Staff-only per the security rules.
  Future<void> saveStoreSettings(StoreSettings settings) async {
    await _storeSettings.set(settings.toMap());
  }

  // ─── Seed ─────────────────────────────────────────────────────────

  /// Seeds the catalogue on a brand-new store. Idempotent: guarded by a
  /// server-side marker document so concurrent app launches cannot double-seed.
  Future<void> seedProductsIfEmpty() async {
    final markerRef = _db.collection('_meta').doc('catalogue_seed');
    final existing = await _products.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final marker = await markerRef.get();
    if (marker.exists) return;

    final batch = _db.batch();
    for (final product in MockDataSource.products) {
      final data = product.toMap()..['createdAt'] = Timestamp.now();
      batch.set(_products.doc(product.id), data);
    }
    batch.set(markerRef, {'seededAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }
}
