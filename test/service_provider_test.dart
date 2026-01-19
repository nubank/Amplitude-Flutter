import 'package:amplitude_flutter/src/service_provider.dart';
import 'package:amplitude_flutter/src/store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_store.dart';

void main() {
  group('ServiceProvider', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    group('initialization', () {
      test('initializes all components correctly', () {
        final provider = ServiceProvider(
          apiKey: 'test-api-key',
          timeout: 30000,
          getCarrierInfo: false,
        );

        expect(provider.client, isNotNull);
        expect(provider.deviceInfo, isNotNull);
        expect(provider.session, isNotNull);
        expect(provider.store, isNotNull);
      });

      test('initializes with carrier info enabled', () {
        final provider = ServiceProvider(
          apiKey: 'test-api-key',
          timeout: 30000,
          getCarrierInfo: true,
        );

        expect(provider.client, isNotNull);
        expect(provider.deviceInfo, isNotNull);
        expect(provider.session, isNotNull);
        expect(provider.store, isNotNull);
      });

      test('uses provided Store instance when given', () {
        final mockStore = MockStore();

        final provider = ServiceProvider(
          apiKey: 'test-api-key',
          timeout: 30000,
          getCarrierInfo: false,
          store: mockStore,
        );

        expect(provider.store, equals(mockStore));
        expect(provider.client, isNotNull);
        expect(provider.deviceInfo, isNotNull);
        expect(provider.session, isNotNull);
      });

      test('creates default Store when none provided', () {
        final provider = ServiceProvider(
          apiKey: 'test-api-key',
          timeout: 30000,
          getCarrierInfo: false,
        );

        expect(provider.store, isNotNull);
        expect(provider.store, isA<Store>());
      });
    });

    group('component configuration', () {
      test('configures client with correct API key', () {
        final provider = ServiceProvider(
          apiKey: 'test-api-key-123',
          timeout: 30000,
          getCarrierInfo: false,
        );

        expect(provider.client, isNotNull);
        // Note: We can't directly test the API key since it's private in Client
        // but we can verify the client was created
      });

      test('configures session with correct timeout', () {
        final provider = ServiceProvider(
          apiKey: 'test-api-key',
          timeout: 60000,
          getCarrierInfo: false,
        );

        expect(provider.session, isNotNull);
        // Note: We can't directly test the timeout since it's private in Session
        // but we can verify the session was created
      });

      test('configures device info with carrier info setting', () {
        final providerWithCarrier = ServiceProvider(
          apiKey: 'test-api-key',
          timeout: 30000,
          getCarrierInfo: true,
        );

        final providerWithoutCarrier = ServiceProvider(
          apiKey: 'test-api-key-2',
          timeout: 30000,
          getCarrierInfo: false,
        );

        expect(providerWithCarrier.deviceInfo, isNotNull);
        expect(providerWithoutCarrier.deviceInfo, isNotNull);
        // Note: We can't directly test the getCarrierInfo setting since it's private
        // but we can verify both device info instances were created
      });
    });

    group('multiple instances', () {
      test('creates independent instances', () {
        final provider1 = ServiceProvider(
          apiKey: 'test-api-key-1',
          timeout: 30000,
          getCarrierInfo: false,
        );

        final provider2 = ServiceProvider(
          apiKey: 'test-api-key-2',
          timeout: 60000,
          getCarrierInfo: true,
        );

        // Client and Session are singletons, so instances will be the same
        expect(provider1.client, equals(provider2.client));
        expect(provider1.session, equals(provider2.session));
        // DeviceInfo should be different instances
        expect(provider1.deviceInfo, isNot(equals(provider2.deviceInfo)));
        // Store instances might be the same due to singleton pattern with default dbFile
      });

      test('respects different store instances', () {
        final store1 = MockStore();
        final store2 = MockStore();

        final provider1 = ServiceProvider(
          apiKey: 'test-api-key-1',
          timeout: 30000,
          getCarrierInfo: false,
          store: store1,
        );

        final provider2 = ServiceProvider(
          apiKey: 'test-api-key-2',
          timeout: 30000,
          getCarrierInfo: false,
          store: store2,
        );

        expect(provider1.store, equals(store1));
        expect(provider2.store, equals(store2));
        expect(provider1.store, isNot(equals(provider2.store)));
      });
    });
  });
}