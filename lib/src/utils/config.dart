/// {@template Config}
/// Configuration class for the Amplitude SDK.
/// {@endtemplate}
final class Config {
  /// {@macro Config}
  /// Creates a new Config instance with the given parameters.
  /// All parameters have default values.
  /// [enableUuid] defaults to true.
  /// Other parameters include session timeout, buffer size,
  /// maximum stored events, flush period, opt-out status
  /// and carrier info retrieval.
  Config({
    this.sessionTimeout = defaultSessionTimeout,
    this.bufferSize = defaultBufferSize,
    this.maxStoredEvents = defaultMaxStoredEvents,
    this.flushPeriod = defaultFlushPeriod,
    this.optOut = false,
    this.getCarrierInfo = false,
    this.enableUuid = true,
  });

  final int sessionTimeout;
  final int bufferSize;
  final int maxStoredEvents;
  final int flushPeriod;
  final bool optOut;
  final bool getCarrierInfo;
  final bool enableUuid;

  static const defaultSessionTimeout = 300_000; // 5 minutes in milliseconds
  static const defaultBufferSize = 10;
  static const defaultMaxStoredEvents = 1_000;
  static const defaultFlushPeriod = 30;
}
