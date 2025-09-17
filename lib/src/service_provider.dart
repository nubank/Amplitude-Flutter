import 'client.dart';
import 'device_info.dart';
import 'session.dart';
import 'store.dart';

class ServiceProvider {
  ServiceProvider(
      {required String apiKey,
      required int timeout,
      required bool getCarrierInfo,
      bool enableUuid = true,
      this.store}) {
    client = Client(apiKey);
    deviceInfo = DeviceInfo(getCarrierInfo);
    session = Session(timeout);
    store ??= Store(enableUuid: enableUuid);
  }

  Client? client;
  Store? store;
  Session? session;
  DeviceInfo? deviceInfo;
}
