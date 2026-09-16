import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('splash asset is bundled and loads', () async {
    final data = await rootBundle.load('assets/images/splash.jpg');
    expect(data.lengthInBytes, greaterThan(1000));
    // JPEG magic bytes
    expect(data.getUint8(0), 0xFF);
    expect(data.getUint8(1), 0xD8);
  });
}