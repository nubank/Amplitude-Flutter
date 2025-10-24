/// {@template date_time_extensions}
/// Extension methods for DateTime class.
/// {@endtemplate}
extension DateTimeExtensions on DateTime {
  /// Converts DateTime to milliseconds since epoch
  int toMs() {
    return millisecondsSinceEpoch;
  }
}
