import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:equatable/equatable.dart';

part 'event.dart';
part 'metric.dart';
part 'log.dart';

sealed class AnalyticsModel extends Equatable {
  const AnalyticsModel();

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) => switch (json) {
        {'_type': 'event'} => Event.fromJson(json),
        {'_type': 'metric'} => Metric.fromJson(json),
        {'_type': 'log'} => Log.fromJson(json),
        _ => Event.fromJson(json),
      };

  String get name;

  Map<String, dynamic>? get labels;

  Map<String, dynamic> toMap();

  AnalyticsModel withProperties(Map<String, dynamic> properties);

  AnalyticsModel copyWith();
}

extension AnalyticsModelList on List<AnalyticsModel> {
  List<Map<String, dynamic>> toMapList() => [
        for (final item in this) item.toMap(),
      ];
}

extension AnalyticsModelPattern on AnalyticsModel {
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
