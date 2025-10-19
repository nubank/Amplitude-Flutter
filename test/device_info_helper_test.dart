import 'package:amplitude_flutter/src/device_info_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('amplitude_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('getDeviceCarrierName', () {
    test('returns carrier name when successful', () async {
      const expectedCarrierName = 'Verizon';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'carrierName') {
          return expectedCarrierName;
        }
        return null;
      });

      final result = await getDeviceCarrierName;

      expect(result, equals(expectedCarrierName));
    });

    test('returns null when carrier name is not available', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'carrierName') {
          return null;
        }
        return null;
      });

      final result = await getDeviceCarrierName;

      expect(result, isNull);
    });

    test('returns empty string when PlatformException occurs', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'carrierName') {
          throw PlatformException(
            code: 'ERROR',
            message: 'Failed to get carrier name',
          );
        }
        return null;
      });

      final result = await getDeviceCarrierName;

      expect(result, equals(''));
    });
  });

  group('preferredDeviceLanguages', () {
    test('returns list of languages', () async {
      const expectedLanguages = ['en-US', 'es-ES', 'fr-FR'];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'preferredLanguages') {
          return expectedLanguages;
        }
        return null;
      });

      final result = await preferredDeviceLanguages;

      expect(result, equals(expectedLanguages));
    });

    test('returns null when no languages available', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'preferredLanguages') {
          return null;
        }
        return null;
      });

      final result = await preferredDeviceLanguages;

      expect(result, isNull);
    });

    test('returns empty list when provided', () async {
      const expectedLanguages = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'preferredLanguages') {
          return expectedLanguages;
        }
        return null;
      });

      final result = await preferredDeviceLanguages;

      expect(result, equals(expectedLanguages));
    });
  });

  group('currentDeviceLocale', () {
    test('returns current locale when successful', () async {
      const expectedLocale = 'en-US';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'currentLocale') {
          return expectedLocale;
        }
        return null;
      });

      final result = await currentDeviceLocale;

      expect(result, equals(expectedLocale));
    });

    test('returns null when locale is not available', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'currentLocale') {
          return null;
        }
        return null;
      });

      final result = await currentDeviceLocale;

      expect(result, isNull);
    });

    test('handles Android locale format (en_US)', () async {
      const expectedLocale = 'en_US';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'currentLocale') {
          return expectedLocale;
        }
        return null;
      });

      final result = await currentDeviceLocale;

      expect(result, equals(expectedLocale));
    });
  });

  group('deviceAdvertisingId', () {
    test('returns advertising ID when successful', () async {
      const expectedAdId = '12345-67890-ABCDE-FGHIJ';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'advertisingId') {
          return expectedAdId;
        }
        return null;
      });

      final result = await deviceAdvertisingId;

      expect(result, equals(expectedAdId));
    });

    test('returns null when advertising ID is not available', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'advertisingId') {
          return null;
        }
        return null;
      });

      final result = await deviceAdvertisingId;

      expect(result, isNull);
    });
  });

  group('deviceModelInfo', () {
    test('returns device model when successful', () async {
      const expectedModel = 'iPhone 14 Pro';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'deviceModel') {
          return expectedModel;
        }
        return null;
      });

      final result = await deviceModelInfo;

      expect(result, equals(expectedModel));
    });

    test('returns null when device model is not available', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'deviceModel') {
          return null;
        }
        return null;
      });

      final result = await deviceModelInfo;

      expect(result, isNull);
    });
  });

  group('multiple method calls', () {
    test('can handle multiple different method calls', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'carrierName':
            return 'T-Mobile';
          case 'currentLocale':
            return 'en-GB';
          case 'deviceModel':
            return 'iPhone 15';
          default:
            return null;
        }
      });

      final carrierName = await getDeviceCarrierName;
      final locale = await currentDeviceLocale;
      final model = await deviceModelInfo;

      expect(carrierName, equals('T-Mobile'));
      expect(locale, equals('en-GB'));
      expect(model, equals('iPhone 15'));
    });
  });
}
