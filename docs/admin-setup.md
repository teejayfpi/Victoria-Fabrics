# Admin access

How to sign in to the admin app, and how to grant the first administrator.

## How admin sign-in works

The admin app (`lib/main_admin.dart`, flavor `admin`, application ID
`com.fabrichaven.fabric_haven_admin`) authenticates with **Firebase Auth
email + password** — Google sign-in is customer-only.

After authentication, `AdminAuthNotifier._loadAdminProfile` authorises the
account against, in order:

1. a `role` **custom claim** on the ID token, else
2. an **`admins/{uid}`** Firestore document, else
3. the `_bootstrapAdmins` email allow-list — **empty on purpose**.

If none of these match, the account is signed back out and the portal reports
"This account is not authorised", including the exact UID to provision. There is
intentionally no self-registration: a password or allow-list compiled into the
APK is recoverable by anyone who downloads it, so authorisation is always
resolved server-side.

### Known configuration issue: admin Android app registration

`android/app/src/admin/google-services.json` currently reuses the **customer**
`mobilesdk_app_id` (`1:1010144166475:android:27384e1b5bc8721b02c3ce`) while
declaring the admin package name. The Android `google-services` plugin matches on
package name, so the build and sign-in still work, but Firebase Analytics and App
Check attribute admin traffic to the customer app. Register a separate Android
app in the Firebase Console for `com.fabrichaven.fabric_haven_admin`, download its
`google-services.json`, and drop it in at
`android/app/src/admin/google-services.json`. `test/admin/providers/admin_auth_config_test.dart`
guards the package/project invariants around this.

### Roles

| Role | Can sign in | Can manage products / orders / tickets |
| --- | --- | --- |
| `viewer` | yes | no |
| `staff` | yes | yes |
| `admin` | yes | yes |
| `superAdmin` | yes | yes |

The router guard (`isAdminLoggedInProvider`) requires `canManage`, i.e. `staff`
or above. A `viewer` authenticates successfully but is bounced back to the
login screen, so grant `staff` or higher to anyone who needs the portal.

## Deploying the security rules

The rules are the source of truth for who can read orders/tickets and manage the
catalogue, so they must be deployed alongside the app:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

`firestore-rules-tests/` holds emulator-backed regression tests for the access
matrix (`cd firestore-rules-tests && npm install && npm test`; needs a JRE).
They run in CI as the **Firestore Rules** job.

> If the admin portal reports "Could not load dashboard data — you do not have
> permission to perform this action" for an account you *have* provisioned, the
> deployed rules are stale. Re-deploy them with the command above.

## Creating the first administrator (free, Spark plan)

The console writes with the Admin SDK, so the deny-by-default rules do not
block it, and no Cloud Function or billing account is needed.

1. **Firebase Console → Authentication → Users → Add user.** Enter an email and
   a password. Copy the generated **UID**.
2. **Firestore → Start collection `admins` → Document ID = that UID.** Add a
   field `role` (string) = `admin`. Optionally add `email` and `name` (they are
   only used as display fallbacks).
3. Launch the admin app and sign in with that email and password.

The client only ever *reads* its own `admins/{uid}` document (rules allow
`request.auth.uid == uid`); all writes are server-side, so this document cannot
be forged or escalated from the app.

## Promoting an existing account

Find the account's UID (Authentication user list, or its `users/{uid}`
document) and create the same `admins/{uid}` document with the desired `role`.
This works for Google-signed-in customer accounts too.

## Managing roles with the Cloud Functions

`setAdminRole` and `removeAdminRole` (see `functions/src/index.ts`) set both the
custom claim and the roster document atomically. They require the caller to be a
`superAdmin`, so the **first** super admin still has to be seeded by hand as
above (with `role` = `superAdmin`). These functions need the Blaze plan.

## Security notes

- `_bootstrapAdmins` in `admin_auth_provider.dart` is deliberately empty. Keep
  it that way; grant access through the `admins/{uid}` document instead.
- To revoke access, delete the `admins/{uid}` document (and clear any custom
  claim with `removeAdminRole` if one was set).
