part of 'analytics_model.dart';

/// {@template Log}
/// Class representing a log entry.
/// {@endtemplate}
class Log extends AnalyticsModel {
  /// {@macro Log}
  /// [message] is the log message.
  /// [data] are the optional data associated with the log.
  const Log(this.message, {Map<String, dynamic>? data}) : _data = data;

  /// Creates a Log from a JSON map.
  factory Log.fromJson(Map<String, dynamic> json) => Log(
        json['message'] as String,
        data: json['data'] as Map<String, dynamic>?,
      );

  /// The log message.
  final String message;

  final Map<String, dynamic>? _data;

  @override
  String get name => message;

  @override
  Map<String, dynamic>? get labels => _data;

  Map<String, dynamic>? get data => _data;

  @override
  Map<String, dynamic> toMap() => {
        '_type': 'log',
        'message': message,
        if (_data != null) 'data': _data,
      };

  @override
  Log withProperties(Map<String, dynamic> properties) => Log(
        message,
        data: {...?_data, ...properties},
      );

  @override
  Log copyWith({String? message, Map<String, dynamic>? data}) => Log(
        message ?? this.message,
        data: data ?? _data,
      );

  @override
  List<Object?> get props => [message, _data];
}
