// Cloud Storage security-rules regression tests.
//
// Product imagery is world-readable and staff-writable. Staff status comes from
// the `role` custom claim only (Storage rules cannot read Firestore), so a
// token *without* a claim must be a clean denial — not an evaluation error from
// indexing a missing key, which is the class of bug fixed in firestore.rules.
//
// Run with:  npm test   (from this directory)

const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');

const RULES_PATH = path.resolve(__dirname, '..', 'storage.rules');

const IMAGE = { contentType: 'image/jpeg' };
const PDF = { contentType: 'application/pdf' };
const SMALL = Buffer.from('x'.repeat(1024));

const results = [];

async function expectAllowed(label, op) {
  try {
    await op();
    results.push([label, true]);
  } catch (e) {
    results.push([label, false]);
    console.error(`  ✖ expected ALLOW but was DENIED: ${label} (${e.message})`);
  }
}

async function expectDenied(label, op) {
  try {
    await op();
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
    storage: { rules, host: '127.0.0.1', port: 9199 },
  });

  const staff = env.authenticatedContext('staff-user', { role: 'staff' });
  const claimless = env.authenticatedContext('roster-admin'); // no role claim
  const anon = env.unauthenticatedContext();

  const path0 = 'products/p1/photo.jpg';

  // A claim-less token must be denied *cleanly* (no evaluation error).
  await expectDenied('claim-less user cannot upload', () =>
    claimless.storage().ref(path0).put(SMALL, IMAGE));
  await expectDenied('anonymous cannot upload', () =>
    anon.storage().ref(path0).put(SMALL, IMAGE));
  await expectDenied('staff cannot upload a non-image', () =>
    staff.storage().ref(path0).put(SMALL, PDF));

  await expectAllowed('staff can upload an image', () =>
    staff.storage().ref(path0).put(SMALL, IMAGE));
  await expectAllowed('anyone can read product imagery', () =>
    anon.storage().ref(path0).getDownloadURL());

  await env.cleanup();

  const failed = results.filter(([, ok]) => !ok).length;
  console.log(`\n${results.length - failed}/${results.length} storage checks passed`);
  if (failed > 0) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
