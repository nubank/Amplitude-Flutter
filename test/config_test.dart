import 'package:amplitude_flutter/src/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Config', () {
    group('default configuration', () {
      test('uses default values when no parameters provided', () {
        final config = Config();
        expect(config.sessionTimeout, equals(Config.defaultSessionTimeout));
        expect(config.bufferSize, equals(Config.defaultBufferSize));
        expect(config.maxStoredEvents, equals(Config.defaultMaxStoredEvents));
        expect(config.flushPeriod, equals(Config.defaultFlushPeriod));
        expect(config.optOut, isFalse);
        expect(config.getCarrierInfo, isFalse);
      });
    });

    group('explicit configuration', () {
      test('accepts custom values for all parameters', () {
        final config = Config(
          sessionTimeout: 120000,
          bufferSize: 50,
          maxStoredEvents: 2000,
          flushPeriod: 60,
          optOut: true,
          getCarrierInfo: true,
        );

        expect(config.sessionTimeout, equals(120000));
        expect(config.bufferSize, equals(50));
        expect(config.maxStoredEvents, equals(2000));
        expect(config.flushPeriod, equals(60));
        expect(config.optOut, isTrue);
        expect(config.getCarrierInfo, isTrue);
      });

      test('allows partial configuration with defaults for others', () {
        final config = Config(
          sessionTimeout: 60000,
          optOut: true,
        );

        expect(config.sessionTimeout, equals(60000));
        expect(config.optOut, isTrue);
        // Others should use defaults
        expect(config.bufferSize, equals(Config.defaultBufferSize));
        expect(config.maxStoredEvents, equals(Config.defaultMaxStoredEvents));
        expect(config.flushPeriod, equals(Config.defaultFlushPeriod));
        expect(config.getCarrierInfo, isFalse);
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