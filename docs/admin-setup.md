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
"This account is not authorised". There is intentionally no self-registration:
a password or allow-list compiled into the APK is recoverable by anyone who
downloads it, so authorisation is always resolved server-side.

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
