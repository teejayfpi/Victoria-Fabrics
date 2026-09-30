import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Translates infrastructure exceptions (Firebase, platform channels, sockets)
/// into the app's typed [AppException] hierarchy so callers never depend on
/// third-party error types.
class ErrorMapper {
  ErrorMapper._();

  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    if (error is FirebaseAuthException) {
      return AuthException(
        message: authMessage(error.code),
        code: error.code,
        originalError: error,
      );
    }

    if (error is FirebaseException) {
      return _mapFirebase(error, stackTrace);
    }

    if (error is TimeoutException) {
      return NetworkException(
        message: 'The request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: error,
      );
    }

    if (error is SocketException) {
      return NetworkException(originalError: error);
    }

    if (error is PlatformException) {
      return AppException(
        message: 'Something went wrong. Please try again.',
        code: error.code,
        originalError: error,
      );
    }

    return AppException(
      message: 'Something went wrong. Please try again.',
      code: 'UNKNOWN',
      originalError: error,
    );
  }

  static Failure toFailure(Object error, [StackTrace? stackTrace]) {
    final appError = map(error, stackTrace);
    switch (appError) {
      case NetworkException():
        return NetworkFailure(message: appError.message, code: appError.code);
      case AuthException():
        return AuthFailure(message: appError.message, code: appError.code);
      case ValidationException(:final fieldErrors):
        return ValidationFailure(
          message: appError.message,
          code: appError.code,
          fieldErrors: fieldErrors,
        );
      case ServerException():
        return ServerFailure(message: appError.message, code: appError.code);
      default:
        return ServerFailure(message: appError.message, code: appError.code);
    }
  }

  static AppException _mapFirebase(
    FirebaseException error,
    StackTrace? stackTrace,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return AuthException(
          message: 'You do not have permission to perform this action.',
          code: error.code,
          originalError: error,
        );
      case 'unavailable':
      case 'deadline-exceeded':
        return NetworkException(
          message: 'Could not reach the server. Check your connection.',
          code: error.code,
          originalError: error,
        );
      case 'not-found':
        return ServerException(
          message: 'The requested record no longer exists.',
          code: error.code,
          originalError: error,
        );
      case 'failed-precondition':
      case 'aborted':
        return ServerException(
          message: 'The data changed while you were working. Please retry.',
          code: error.code,
          originalError: error,
        );
      default:
        return ServerException(
          message: 'A server error occurred. Please try again.',
          code: error.code,
          originalError: error,
        );
    }
  }

  static String authMessage(String code) {
    switch (code) {
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'account-exists-with-different-credential':
        return 'This email is registered with another sign-in method.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }
}

bool isNetworkError(Object error) =>
    error is SocketException || error is NetworkException;
