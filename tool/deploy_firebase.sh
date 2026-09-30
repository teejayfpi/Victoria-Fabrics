#!/usr/bin/env bash
#
# Deploys the Victoria Fabrics backend to Firebase.
#
# Requires either:
#   * GOOGLE_APPLICATION_CREDENTIALS pointing at a service-account key, or
#   * an authenticated `firebase login`.
#
# The deploying principal needs Firebase Admin, Service Usage Admin,
# Cloud Build Editor, Artifact Registry Admin, Cloud Run Admin and
# Service Account User on the project.
set -euo pipefail

PROJECT="${FIREBASE_PROJECT:-victoria-fabrics}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "▶ Deploying to ${PROJECT}"

command -v firebase >/dev/null || {
  echo "✖ firebase-tools not found. Install: npm i -g firebase-tools" >&2
  exit 1
}

cd "${ROOT}"

echo "▶ Building Cloud Functions"
npm --prefix functions ci
npm --prefix functions run lint

echo "▶ Deploying Firestore rules, indexes, Storage rules and Functions"
firebase deploy \
  --project "${PROJECT}" \
  --only functions,firestore:rules,firestore:indexes,storage \
  --non-interactive

echo "✔ Deploy complete"
