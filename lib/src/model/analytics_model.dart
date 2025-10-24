import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:equatable/equatable.dart';

part 'event.dart';
part 'metric.dart';
part 'log.dart';

/// {@template AnalyticsModel}
/// Base class for analytics models such as Event, Metric, and Log.
/// Provides common functionality and enforces implementation of required methods.
/// {@endtemplate}
sealed class AnalyticsModel extends Equatable {
  /// {@macro AnalyticsModel}
  const AnalyticsModel();

  /// Creates an AnalyticsModel from a JSON map.
  factory AnalyticsModel.fromJson(Map<String, dynamic> json) => switch (json) {
        {'_type': 'event'} => Event.fromJson(json),
        {'_type': 'metric'} => Metric.fromJson(json),
        {'_type': 'log'} => Log.fromJson(json),
        _ => Event.fromJson(json),
      };

  /// The name of the analytics model.
  String get name;

  /// The labels associated with the analytics model.
  Map<String, dynamic>? get labels;

  /// Converts the analytics model to a map.
  Map<String, dynamic> toMap();

  /// Adds properties to the analytics model and returns a new instance.
  AnalyticsModel withProperties(Map<String, dynamic> properties);

  /// Creates a copy of the analytics model.
  AnalyticsModel copyWith();
}

/// {@template AnalyticsModelList}
/// Extension methods for List<AnalyticsModel>.
/// {@endtemplate}
extension AnalyticsModelList on List<AnalyticsModel> {
  /// Converts the list of AnalyticsModel to a list of maps.
  List<Map<String, dynamic>> toMapList() => [
        for (final item in this) item.toMap(),
      ];
}

/// {@template AnalyticsModelPattern}
/// Pattern matching extension for AnalyticsModel.
/// {@endtemplate}
extension AnalyticsModelPattern on AnalyticsModel {
  /// Pattern matching for AnalyticsModel.
  /// Executes the corresponding function based on the runtime type.
  /// Returns the result of the executed function.
  /// [event] is executed if the model is an Event.
  /// [metric] is executed if the model is a Metric.
  /// [log] is executed if the model is a Log.
  T when<T>({
    required T Function(Event) event,
    required T Function(Metric) metric,
    required T Function(Log) log,
  }) =>
      switch (this) {
        final Event e => event(e),
        final Metric m => metric(m),
        final Log l => log(l),
      };

  /// Nullable pattern matching for AnalyticsModel.
  /// Executes the corresponding function based on the runtime type if provided.
  /// Returns the result of the executed function or null if no function is provided.
  /// [event] is executed if the model is an Event.
  /// [metric] is executed if the model is a Metric.
  /// [log] is executed if the model is a Log.
  T? whenOrNull<T>({
    T Function(Event)? event,
    T Function(Metric)? metric,
    T Function(Log)? log,
  }) =>
      switch (this) {
        final Event e when event != null => event(e),
        final Metric m when metric != null => metric(m),
        final Log l when log != null => log(l),
        _ => null,
      };
}
