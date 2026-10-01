import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('splash logo asset is bundled and loads', () async {
    final data = await rootBundle.load('assets/images/splash_logo.png');
    expect(data.lengthInBytes, greaterThan(1000));
    // PNG magic bytes
    expect(data.getUint8(0), 0x89);
    expect(data.getUint8(1), 0x50);
    expect(data.getUint8(2), 0x4E);
    expect(data.getUint8(3), 0x47);
  });
}
