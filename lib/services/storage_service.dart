import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final _storage = FirebaseStorage.instance;

  /// Uploads a product image to Firebase Storage and returns its download URL.
  Future<String> uploadProductImage(File file, String productId) async {
    final ext = file.path.contains('.')
        ? file.path.split('.').last.toLowerCase()
        : 'jpg';
    final filename = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('products/$productId/$filename');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/$ext'),
    );
    return await task.ref.getDownloadURL();
  }

  /// Deletes a file at the given storage URL (best-effort).
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore — the file may already be gone
    }
  }
}
