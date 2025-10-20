import 'client.dart';
import 'device_info.dart';
import 'session.dart';
import 'store.dart';

class ServiceProvider {
  ServiceProvider({
    required String apiKey,
    required int timeout,
    required bool getCarrierInfo,
    Client? client,
    bool enableUuid = true,
    Store? store,
  })  : client = client ?? Client(apiKey),
        deviceInfo = DeviceInfo(getCarrierInfo),
        session = Session(timeout),
        store = store ?? Store(enableUuid: enableUuid);

  final Client client;
  final Store store;
  final Session session;
  final DeviceInfo deviceInfo;

  ServiceProvider copyWith({
    Client? client,
    Store? store,
    Session? session,
    DeviceInfo? deviceInfo,
  }) {
    return ServiceProvider(
      apiKey: client?.apiKey ?? this.client.apiKey,
      timeout: session?.timeout ?? this.session.timeout,
      getCarrierInfo:
          deviceInfo?.getCarrierInfo ?? this.deviceInfo.getCarrierInfo,
      client: client ?? this.client,
      enableUuid: store?.enableUuid ?? this.store.enableUuid,
      store: store ?? this.store,
    );
  }
}
