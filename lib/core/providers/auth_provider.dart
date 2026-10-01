import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../error/exceptions.dart';

const _googleWebClientId =
    '1010144166475-6ke40f39m9f4tim92q46gu8p75igqeci.apps.googleusercontent.com';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(serverClientId: _googleWebClientId);
});

/// Stream of the current auth state (null = signed out)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Convenience: current signed-in user or null
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthController(this._auth, this._googleSignIn)
      : super(const AsyncValue.data(null));

  /// Signs in with Google. Firebase automatically creates a new user record
  /// the first time a Google account is used.
  ///
  /// Returns false when the user closes the Google account picker.
  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow
        state = const AsyncValue.data(null);
        return false;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw const AuthException(
          message:
              'Google sign-in is not configured for this app. Please contact support.',
          code: 'missing-google-id-token',
        );
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      state = const AsyncValue.data(null);
      return _auth.currentUser != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
    state = const AsyncValue.data(null);
  }

  /// Creates an account and, when Firebase is configured to require it, sends
  /// the verification email. Returns true when a session was established.
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        state = const AsyncValue.data(null);
        return false;
      }
      if (displayName != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }
      await user.sendEmailVerification();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = const AsyncValue.data(null);
      return _auth.currentUser != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }
}

String authErrorMessage(Object error) {
  if (error is AuthException) return error.message;

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'operation-not-allowed':
        return 'Google sign-in is disabled in Firebase. Please contact support.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'invalid-credential':
        return 'Google could not verify this account. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'account-exists-with-different-credential':
        return 'This email is already registered with another sign-in method.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Try signing in.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'invalid-email':
        return 'That email address does not look valid.';
      case 'user-not-found':
        return 'No account found for that email. Try creating one.';
      case 'wrong-password':
        return 'Incorrect password. Try again or reset it.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }

  if (error is PlatformException) {
    switch (error.code) {
      case 'sign_in_failed':
      case '10':
        return 'Google sign-in setup is incomplete. Please contact support.';
      case 'network_error':
        return 'No internet connection. Check your network and try again.';
      case 'sign_in_canceled':
        return 'Sign-in was cancelled.';
    }
  }

  return 'Google sign-in failed. Please try again.';
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
  );
});
