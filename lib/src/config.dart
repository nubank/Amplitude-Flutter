class Config {
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
