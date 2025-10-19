import 'package:amplitude_flutter/src/device_info_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('amplitude_flutter');

  setUp(() {
    // Reset the channel before each test
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('getDeviceCarrierName', () {
    test('returns carrier name when successful', () async {
      // Arrange
      const expectedCarrierName = 'Verizon';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'carrierName') {
          return expectedCarrierName;
        }
        return null;
      });

      // Act
      final result = await getDeviceCarrierName;

      // Assert
      expect(result, equals(expectedCarrierName));
    });

    test('returns null when carrier name is not available', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'carrierName') {
          return null;
        }
        return null;
      });

      // Act
      final result = await getDeviceCarrierName;

      // Assert
      expect(result, isNull);
    });

    test('returns empty string when PlatformException occurs', () async {
      // Arrange
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

      // Act
      final result = await getDeviceCarrierName;

      // Assert
      expect(result, equals(''));
    });
  });

  group('preferredDeviceLanguages', () {
    test('returns list of languages', () async {
      // Arrange
      const expectedLanguages = ['en-US', 'es-ES', 'fr-FR'];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'preferredLanguages') {
          return expectedLanguages;
        }
        return null;
      });

      // Act
      final result = await preferredDeviceLanguages;

      // Assert
      expect(result, equals(expectedLanguages));
    });

    test('returns null when no languages available', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'preferredLanguages') {
          return null;
        }
        return null;
      });

      // Act
      final result = await preferredDeviceLanguages;

      // Assert
      expect(result, isNull);
    });

    test('returns empty list when provided', () async {
      // Arrange
      const expectedLanguages = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'preferredLanguages') {
          return expectedLanguages;
        }
        return null;
      });

      // Act
      final result = await preferredDeviceLanguages;

      // Assert
      expect(result, equals(expectedLanguages));
    });
  });

  group('currentDeviceLocale', () {
    test('returns current locale when successful', () async {
      // Arrange
      const expectedLocale = 'en-US';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'currentLocale') {
          return expectedLocale;
        }
        return null;
      });

      // Act
      final result = await currentDeviceLocale;

      // Assert
      expect(result, equals(expectedLocale));
    });

    test('returns null when locale is not available', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'currentLocale') {
          return null;
        }
        return null;
      });

      // Act
      final result = await currentDeviceLocale;

      // Assert
      expect(result, isNull);
    });

    test('handles Android locale format (en_US)', () async {
      // Arrange
      const expectedLocale = 'en_US';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'currentLocale') {
          return expectedLocale;
        }
        return null;
      });

      // Act
      final result = await currentDeviceLocale;

      // Assert
      expect(result, equals(expectedLocale));
    });
  });

  group('deviceAdvertisingId', () {
    test('returns advertising ID when successful', () async {
      // Arrange
      const expectedAdId = '12345-67890-ABCDE-FGHIJ';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'advertisingId') {
          return expectedAdId;
        }
        return null;
      });

      // Act
      final result = await deviceAdvertisingId;

      // Assert
      expect(result, equals(expectedAdId));
    });

    test('returns null when advertising ID is not available', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'advertisingId') {
          return null;
        }
        return null;
      });

      // Act
      final result = await deviceAdvertisingId;

      // Assert
      expect(result, isNull);
    });
  });

  group('deviceModelInfo', () {
    test('returns device model when successful', () async {
      // Arrange
      const expectedModel = 'iPhone 14 Pro';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'deviceModel') {
          return expectedModel;
        }
        return null;
      });

      // Act
      final result = await deviceModelInfo;

      // Assert
      expect(result, equals(expectedModel));
    });

    test('returns null when device model is not available', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'deviceModel') {
          return null;
        }
        return null;
      });

      // Act
      final result = await deviceModelInfo;

      // Assert
      expect(result, isNull);
    });
  });

  group('multiple method calls', () {
    test('can handle multiple different method calls', () async {
      // Arrange
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

      // Act
      final carrierName = await getDeviceCarrierName;
      final locale = await currentDeviceLocale;
      final model = await deviceModelInfo;

      // Assert
      expect(carrierName, equals('T-Mobile'));
      expect(locale, equals('en-GB'));
      expect(model, equals('iPhone 15'));
    });
  });
}
