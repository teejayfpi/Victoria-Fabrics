import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:fabric_haven/services/storage_service.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('vf_storage_test');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  File writePng(String name, int width, int height) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(10, 104, 71));
    final file = File('${tmp.path}/$name');
    file.writeAsBytesSync(img.encodePng(image));
    return file;
  }

  group('StorageService.encodeInline', () {
    test('produces a JPEG data URI', () {
      final uri = StorageService.encodeInline(writePng('a.png', 100, 100));

      expect(uri, startsWith('data:image/jpeg;base64,'));
      final decoded = base64Decode(uri.substring(uri.indexOf(',') + 1));
      expect(decoded.length, greaterThan(0));
      // JPEG magic bytes
      expect(decoded[0], 0xFF);
      expect(decoded[1], 0xD8);
    });

    test('downscales an oversized image to the max edge', () {
      final uri = StorageService.encodeInline(writePng('big.png', 3000, 1500));

      final bytes = base64Decode(uri.substring(uri.indexOf(',') + 1));
      final decoded = img.decodeImage(bytes)!;
      expect(decoded.width, 800);
      expect(decoded.height, 400);
    });

    test('leaves a small image at its original size', () {
      final uri = StorageService.encodeInline(writePng('small.png', 200, 200));

      final bytes = base64Decode(uri.substring(uri.indexOf(',') + 1));
      final decoded = img.decodeImage(bytes)!;
      expect(decoded.width, 200);
      expect(decoded.height, 200);
    });

    test('rejects a file that is not an image', () {
      final file = File('${tmp.path}/not-an-image.txt')
        ..writeAsStringSync('definitely not a picture');

      expect(
        () => StorageService.encodeInline(file),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
