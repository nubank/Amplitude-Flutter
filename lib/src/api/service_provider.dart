import 'package:amplitude_flutter/amplitude_flutter.dart';

/// {@template ServiceProvider}
/// ServiceProvider is a class that provides the necessary services for the
/// Amplitude SDK to function, including Client, DeviceInfo, Session, and
/// optional local storage.
/// {@endtemplate}
class ServiceProvider {
  ServiceProvider({
    required String apiKey,
    required int timeout,
    required bool getCarrierInfo,
    Client? client,
    this.store,
  })  : client = client ?? Client(apiKey),
        deviceInfo = DeviceInfo(getCarrierInfo),
        session = Session(timeout);

  /// Client for interacting with the Amplitude HTTP API.
  final Client client;

  /// Local storage datasource for persisting events.
  /// This is an optional parameter.
  /// the implementations are [ObjectStore] and [SqliteStore].
  final StorageDatasource<EventEntity>? store;

  /// Session management for tracking user sessions.
  final Session session;

  /// Device information helper for retrieving device details.
  final DeviceInfo deviceInfo;

  /// Creates a copy of the current ServiceProvider with optional new values.
  ServiceProvider copyWith({
    Client? client,
    StorageDatasource<EventEntity>? store,
    Session? session,
    DeviceInfo? deviceInfo,
  }) {
    return ServiceProvider(
      apiKey: client?.apiKey ?? this.client.apiKey,
      timeout: session?.timeout ?? this.session.timeout,
      getCarrierInfo:
          deviceInfo?.getCarrierInfo ?? this.deviceInfo.getCarrierInfo,
      client: client ?? this.client,
      store: store ?? this.store,
    );
  }
}
