import 'package:amplitude_flutter/src/client.dart';
import 'package:amplitude_flutter/src/device_info.dart';
import 'package:amplitude_flutter/src/service_provider.dart';
import 'package:amplitude_flutter/src/session.dart';
import 'package:amplitude_flutter/src/store.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_client.dart';
import 'mock_store.dart';

class MockDeviceInfo extends Mock implements DeviceInfo {}

class MockSession extends Mock implements Session {}

class MockServiceProvider implements ServiceProvider {
  MockServiceProvider({Client? client, Store? store})
      : client = client ?? MockClient(),
        store = store ?? MockStore(),
        session = MockSession(),
        deviceInfo = MockDeviceInfo();

  @override
  final Client client;
  @override
  final Store store;
  @override
  final Session session;
  @override
  final DeviceInfo deviceInfo;
}
