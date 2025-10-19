import 'client.dart';
import 'device_info.dart';
import 'session.dart';
import 'store.dart';

class ServiceProvider {
  ServiceProvider({
    required String apiKey,
    required int timeout,
    required bool getCarrierInfo,
    bool enableUuid = true,
    Store? store,
  })  : client = Client(apiKey),
        deviceInfo = DeviceInfo(getCarrierInfo),
        session = Session(timeout),
        store = store ?? Store(enableUuid: enableUuid);

  final Client client;
  final Store store;
  final Session session;
  final DeviceInfo deviceInfo;
}
