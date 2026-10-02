// Firestore security-rules regression tests.
//
// These run against the Firebase Firestore emulator and assert the *access
// matrix* the app depends on. They exist because of a real incident: an admin
// provisioned only through the `admins/{uid}` roster document (no `role`
// custom claim) was denied every order/ticket read and every catalogue write.
//
// The cause was `request.auth.token.role` — indexing a *missing* key off the
// token throws in the rules engine ("Property role is undefined on object"),
// aborting the whole boolean before the roster fallback ran. `isStaff()` now
// reads the claim through `token.get('role', null)` and only defers to the
// roster doc when the token carries no `role` claim at all.
//
// Run with:  npm test   (from this directory)
// Requires Java (the emulator) — the CI job installs a JRE.

const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');

const RULES_PATH = path.resolve(__dirname, '..', 'firestore.rules');

const results = [];

async function expectAllowed(label, ctx, op) {
  try {
    await op(ctx.firestore());
    results.push([label, true]);
  } catch (e) {
    results.push([label, false]);
    console.error(`  ✖ expected ALLOW but was DENIED: ${label} (${e.code})`);
  }
}

async function expectDenied(label, ctx, op) {
  try {
    await op(ctx.firestore());
    results.push([label, false]);
    console.error(`  ✖ expected DENY but was ALLOWED: ${label}`);
  } catch (e) {
    results.push([label, true]);
  }
}

async function main() {
  const rules = fs.readFileSync(RULES_PATH, 'utf8');
  const env = await initializeTestEnvironment({
    projectId: 'victoria-fabrics',
    firestore: { rules, host: '127.0.0.1', port: 8080 },
  });

  // Seed a roster for a claim-less admin and a read-only viewer, plus one
  // order so list reads have a document to return.
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.collection('admins').doc('roster-admin').set({ role: 'admin' });
    await db.collection('admins').doc('viewer-user').set({ role: 'viewer' });
    await db.collection('orders').doc('order1').set({
      userId: 'customer-1',
      status: 'pending',
      totalAmount: 1000,
      createdAt: new Date(),
    });
  });

  const rosterAdmin = env.authenticatedContext('roster-admin');
  const claimAdmin = env.authenticatedContext('claim-admin', { role: 'admin' });
  const viewer = env.authenticatedContext('viewer-user');
  const anon = env.unauthenticatedContext();

  // ── Regression: a roster-provisioned admin with NO custom claim ──────────
  // This is the exact scenario that was broken. It is the documented free-tier
  // provisioning path in docs/admin-setup.md.
  await expectAllowed('roster admin (no claim) lists orders', rosterAdmin,
    (db) => db.collection('orders').limit(5).get());
  await expectAllowed('roster admin (no claim) lists tickets', rosterAdmin,
    (db) => db.collection('tickets').limit(5).get());
  await expectAllowed('roster admin (no claim) writes a category', rosterAdmin,
    (db) => db.collection('categories').doc('c1').set({ name: 'Ankara' }));
  await expectAllowed('roster admin (no claim) reads own admins doc',
    rosterAdmin, (db) => db.collection('admins').doc('roster-admin').get());

  // ── The custom-claim path still works ────────────────────────────────────
  await expectAllowed('claim admin lists orders', claimAdmin,
    (db) => db.collection('orders').limit(5).get());
  await expectAllowed('claim admin writes a category', claimAdmin,
    (db) => db.collection('categories').doc('c2').set({ name: 'Lace' }));

  // ── A `viewer` roster entry is not staff ─────────────────────────────────
  await expectDenied('viewer cannot list orders', viewer,
    (db) => db.collection('orders').limit(5).get());
  await expectDenied('viewer cannot write a category', viewer,
    (db) => db.collection('categories').doc('c3').set({ name: 'Silk' }));

  // ── Anonymous baseline ───────────────────────────────────────────────────
  await expectDenied('anonymous cannot list orders', anon,
    (db) => db.collection('orders').limit(5).get());
  await expectAllowed('anonymous can read the catalogue', anon,
    (db) => db.collection('products').limit(5).get());

  await env.cleanup();

  const failed = results.filter(([, ok]) => !ok).length;
  console.log(`\n${results.length - failed}/${results.length} rules checks passed`);
  if (failed > 0) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
