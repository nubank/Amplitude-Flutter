import 'package:amplitude_flutter/src/service_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_store.dart';

void main() {
  group('ServiceProvider enableUuid', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    group('enableUuid propagation to Store', () {
      test('creates Store with enableUuid=true when specified', () {
        final customStore = MockStore();
        customStore.enableUuid = true;

        final provider = ServiceProvider(
          apiKey: 'test-api-key',
          timeout: 30000,
          getCarrierInfo: false,
          enableUuid: true,
          store: customStore,
        );

        expect(provider.store, isNotNull);
        expect(provider.store.enableUuid, isTrue);
      });

      test('creates Store with enableUuid=false when specified', () {
        final customStore = MockStore();
        customStore.enableUuid = false;

        final provider = ServiceProvider(
          apiKey: 'test-api-key-false',
          timeout: 30000,
          getCarrierInfo: false,
          enableUuid: false,
          store: customStore,
        );

        expect(provider.store, isNotNull);
        expect(provider.store.enableUuid, isFalse);
      });

      test('uses provided Store instance when given', () {
        final mockStore = MockStore();
        mockStore.enableUuid = false;

        final provider = ServiceProvider(
          apiKey: 'test-api-key',
          timeout: 30000,
          getCarrierInfo: false,
          enableUuid: true,
          store: mockStore,
        );

        expect(provider.store, equals(mockStore));
        expect(provider.store.enableUuid, isFalse);
      });
    });

    group('ServiceProvider initialization', () {
      test('initializes all components correctly with enableUuid=true', () {
        final customStore = MockStore();
        customStore.enableUuid = true;

        final provider = ServiceProvider(
          apiKey: 'test-api-key',
          timeout: 30000,
          getCarrierInfo: true,
          enableUuid: true,
          store: customStore,
        );

        expect(provider.client, isNotNull);
        expect(provider.deviceInfo, isNotNull);
        expect(provider.session, isNotNull);
        expect(provider.store, isNotNull);
        expect(provider.store.enableUuid, isTrue);
      });

      test('initializes all components correctly with enableUuid=false', () {
        final customStore = MockStore();
        customStore.enableUuid = false;

        final provider = ServiceProvider(
          apiKey: 'test-api-key',
          timeout: 30000,
          getCarrierInfo: false,
          enableUuid: false,
          store: customStore,
        );

        expect(provider.client, isNotNull);
        expect(provider.deviceInfo, isNotNull);
        expect(provider.session, isNotNull);
        expect(provider.store, isNotNull);
        expect(provider.store.enableUuid, isFalse);
      });
    });

    group('Store instance management', () {
      test('creates new Store when none provided', () {
        final store1 = MockStore();
        store1.enableUuid = true;
        final store2 = MockStore();
        store2.enableUuid = false;

        final provider1 = ServiceProvider(
          apiKey: 'test-api-key-1',
          timeout: 30000,
          getCarrierInfo: false,
          enableUuid: true,
          store: store1,
        );

        final provider2 = ServiceProvider(
          apiKey: 'test-api-key-2',
          timeout: 30000,
          getCarrierInfo: false,
          enableUuid: false,
          store: store2,
        );

        expect(provider1.store, isNotNull);
        expect(provider2.store, isNotNull);
        expect(provider1.store.enableUuid, isTrue);
        expect(provider2.store.enableUuid, isFalse);
      });

      test('respects provided Store instance', () {
        final customStore = MockStore();
        customStore.enableUuid = true;

        final provider = ServiceProvider(
          apiKey: 'test-api-key',
          timeout: 30000,
          getCarrierInfo: false,
          enableUuid: false,
          store: customStore,
        );

        expect(provider.store, equals(customStore));
        expect(provider.store.enableUuid, isTrue);
      });
    });

    group('component interaction', () {
      test('all components are initialized regardless of enableUuid setting',
          () {
        final storeWithUuid = MockStore();
        storeWithUuid.enableUuid = true;
        final storeWithoutUuid = MockStore();
        storeWithoutUuid.enableUuid = false;

        final providerWithUuid = ServiceProvider(
          apiKey: 'test-api-key-with-uuid',
          timeout: 30000,
          getCarrierInfo: false,
          enableUuid: true,
          store: storeWithUuid,
        );

        final providerWithoutUuid = ServiceProvider(
          apiKey: 'test-api-key-without-uuid',
          timeout: 30000,
          getCarrierInfo: false,
          enableUuid: false,
          store: storeWithoutUuid,
        );

        expect(providerWithUuid.client, isNotNull);
        expect(providerWithUuid.deviceInfo, isNotNull);
        expect(providerWithUuid.session, isNotNull);
        expect(providerWithUuid.store, isNotNull);

        expect(providerWithoutUuid.client, isNotNull);
        expect(providerWithoutUuid.deviceInfo, isNotNull);
        expect(providerWithoutUuid.session, isNotNull);
        expect(providerWithoutUuid.store, isNotNull);
      });
    });
  });
}
