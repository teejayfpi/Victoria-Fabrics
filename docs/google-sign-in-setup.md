# Google sign-in setup

Both apps sign users in with Google. The flow needs configuration in the
Firebase project (`victoria-fabrics`) that code alone cannot provide. When it is
missing the app shows one of two messages, each mapping to a distinct cause:

| Message shown | Thrown as | Real cause |
|---|---|---|
| "Google sign-in is disabled in Firebase. Please contact support." | `FirebaseAuthException: operation-not-allowed` | The **Google** provider is not enabled in Firebase Authentication. |
| "Google sign-in setup is incomplete. Please contact support." | `PlatformException: sign_in_failed` / code `10` (`DEVELOPER_ERROR`) | No **Android OAuth client** matches this build's package name + signing-certificate SHA-1. |

These are console/credential problems, not app bugs. `google-services.json`
already declares the web client
(`1010144166475-6ke40f39m9f4tim92q46gu8p75igqeci`) and the Android client
(`1010144166475-2e1ketnivtoe9223amceoah4pvgae60i`) for package
`com.fabrichaven.fabric_haven`, but the project still needs the provider enabled
and the SHA-1s registered.

## 1. Enable the provider

Firebase Console → **Authentication → Sign-in method → Google → Enable → Save**.

## 2. Register the signing certificates

Firebase Console → **Project settings → General → Your apps →**
`com.fabrichaven.fabric_haven` **→ Add fingerprint**.

Google sign-in is only allowed for a `(package name, SHA-1)` pair that is
registered. Because the customer and admin flavors are signed differently, each
signing key needs its own entry.

### Debug builds

```bash
# Linux/macOS
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android
```

Copy the `SHA1:` value into the fingerprint list.

### Release builds

The release key is supplied by CI from repository secrets
(`ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`).
Print its fingerprint and register it too:

```bash
keytool -list -v -keystore upload-keystore.jks -alias upload
```

If `ANDROID_KEYSTORE_BASE64` is not set, CI falls back to debug signing — in
that case the debug SHA-1 is the only one required.

### Play App Signing

If the app is distributed through Google Play, Play re-signs it. Register the
**App signing key certificate** SHA-1 (Play Console → Release → Setup → App
signing) as well, otherwise sign-in fails only for Play-installed builds.

## 3. Refresh the config

After adding fingerprints, download the updated `google-services.json` and
replace all three committed copies so they stay in sync:

- `android/app/google-services.json`
- `android/app/src/customer/google-services.json`
- `android/app/src/admin/google-services.json`

The admin flavor (`com.fabrichaven.fabric_haven_admin`) currently has no
Google sign-in UI, so only the customer package strictly needs a matching
client — but the file should still list the admin package.

## 4. Verify

Rebuild and install, then check the device log (`adb logcat | grep -i auth`).
A successful tap no longer logs `Google sign-in platform error`; a failure now
records the raw provider `code` and `message` so the remaining mismatch is
identifiable.

## Owner-only step

These changes require access to the Firebase project and the CI signing
secrets. They cannot be made from source control alone.
