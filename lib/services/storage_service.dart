import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

import '../core/logging/app_logger.dart';

/// Product-image upload with a free-tier fallback.
///
/// Firebase Storage now requires a billing account, so on a project without
/// one every upload fails with a configuration error. Rather than block the
/// admin from adding products, the image is downscaled, JPEG-compressed and
/// stored as a `data:` URI inside the product document — Firestore's free
/// quota is far larger than Storage's, and a product doc is well under the
/// 1 MiB limit at this size.
///
/// URLs returned by either path render through [ProductImage].
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final _storage = FirebaseStorage.instance;

  /// Longest edge of an inline image. Kept small because the encoded string
  /// has to fit in a Firestore document alongside the rest of the product.
  static const int _inlineMaxEdge = 800;
  static const int _inlineQuality = 62;

  /// Uploads a product image and returns a URL the app can render.
  ///
  /// Prefers Firebase Storage; falls back to an inline data URI when Storage
  /// is not provisioned (billing not enabled, bucket missing, no permission).
  Future<String> uploadProductImage(File file, String productId) async {
    try {
      return await _uploadToStorage(file, productId);
    } catch (e) {
      AppLogger.warning(
        'Firebase Storage unavailable, storing image inline',
        tag: 'storage',
        context: {'error': e.toString()},
      );
      return encodeInline(file);
    }
  }

  Future<String> _uploadToStorage(File file, String productId) async {
    final ext = file.path.contains('.')
        ? file.path.split('.').last.toLowerCase()
        : 'jpg';
    final filename = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('products/$productId/$filename');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/$ext'),
    );
    return task.ref.getDownloadURL();
  }

  /// Downscales and compresses [file] into a `data:image/jpeg;base64,...` URI.
  ///
  /// Pure computation with no network or platform channel, so it works on a
  /// project with no billing account and is straightforward to unit test.
  static String encodeInline(
    File file, {
    int maxEdge = _inlineMaxEdge,
    int quality = _inlineQuality,
  }) {
    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('That file is not a readable image.');
    }

    final longest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final resized = longest > maxEdge
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? maxEdge : null,
            height: decoded.height > decoded.width ? maxEdge : null,
            interpolation: img.Interpolation.average,
          )
        : decoded;

    final jpeg = img.encodeJpg(resized, quality: quality);
    return 'data:image/jpeg;base64,${base64Encode(jpeg)}';
  }

  /// Deletes a file at the given URL (best-effort).
  ///
  /// Inline data URIs are part of the product document, so there is nothing
  /// to delete here.
  Future<void> deleteByUrl(String url) async {
    if (url.startsWith('data:')) return;
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore — the file may already be gone
    }
  }
}
