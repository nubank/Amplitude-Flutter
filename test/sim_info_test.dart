import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('amplitude_flutter');

  // Register the mock handler.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'carrierName':
          return 'AT&T';
        case 'deviceModel':
          return 'iPhone10,6';
        default:
          return null;
      }
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('amplitude_flutter channel is setup with carrierName method', () async {
    final String name = await getDeviceCarrierName ?? 'unknown';
    expect(name, equals('AT&T'));
  });
}
