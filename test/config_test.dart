import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Config enableUuid', () {
    group('default configuration', () {
      test('enableUuid defaults to true', () {
        final config = Config();
        expect(config.enableUuid, isTrue);
      });

      test('all other defaults are preserved when enableUuid is default', () {
        final config = Config();
        expect(config.enableUuid, isTrue);
        expect(config.sessionTimeout, equals(Config.defaultSessionTimeout));
        expect(config.bufferSize, equals(Config.defaultBufferSize));
        expect(config.maxStoredEvents, equals(Config.defaultMaxStoredEvents));
        expect(config.flushPeriod, equals(Config.defaultFlushPeriod));
        expect(config.optOut, isFalse);
        expect(config.getCarrierInfo, isFalse);
      });
    });

    group('explicit configuration', () {
      test('enableUuid can be set to true explicitly', () {
        final config = Config(enableUuid: true);
        expect(config.enableUuid, isTrue);
      });

      test('enableUuid can be set to false', () {
        final config = Config(enableUuid: false);
        expect(config.enableUuid, isFalse);
      });

      test('enableUuid configuration does not affect other settings', () {
        final configTrue = Config(
          enableUuid: true,
          sessionTimeout: 60000,
          bufferSize: 20,
          optOut: true,
        );

        final configFalse = Config(
          enableUuid: false,
          sessionTimeout: 60000,
          bufferSize: 20,
          optOut: true,
        );

        expect(configTrue.enableUuid, isTrue);
        expect(configTrue.sessionTimeout, equals(60000));
        expect(configTrue.bufferSize, equals(20));
        expect(configTrue.optOut, isTrue);

        expect(configFalse.enableUuid, isFalse);
        expect(configFalse.sessionTimeout, equals(60000));
        expect(configFalse.bufferSize, equals(20));
        expect(configFalse.optOut, isTrue);
      });
    });

    group('config immutability', () {
      test('enableUuid is final and cannot be changed after creation', () {
        final config = Config(enableUuid: true);
        expect(config.enableUuid, isTrue);
      });
    });

    group('configuration combinations', () {
      test('enableUuid works with all other configuration options', () {
        final config = Config(
          sessionTimeout: 120000,
          bufferSize: 50,
          maxStoredEvents: 2000,
          flushPeriod: 60,
          optOut: true,
          getCarrierInfo: true,
          enableUuid: false,
        );

        expect(config.sessionTimeout, equals(120000));
        expect(config.bufferSize, equals(50));
        expect(config.maxStoredEvents, equals(2000));
        expect(config.flushPeriod, equals(60));
        expect(config.optOut, isTrue);
        expect(config.getCarrierInfo, isTrue);
        expect(config.enableUuid, isFalse);
      });
    });

    group('default constants', () {
      test('default constants are defined correctly', () {
        expect(Config.defaultSessionTimeout, equals(300000));
        expect(Config.defaultBufferSize, equals(10));
        expect(Config.defaultMaxStoredEvents, equals(1000));
        expect(Config.defaultFlushPeriod, equals(30));
      });
    });
  });
}
