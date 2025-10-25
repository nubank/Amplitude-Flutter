part of 'analytics_model.dart';

/// {@template MetricType}
/// Enum representing different types of metrics.
/// {@endtemplate}
enum MetricType {
  /// Counter metric type.
  counter,

  /// Gauge metric type.
  gauge,

  /// Histogram metric type.
  histogram,

  /// Summary metric type.
  summary;

  /// Creates a MetricType from a string.
  /// Returns null if the string does not match any MetricType.
  static MetricType? fromString(String value) => switch (value) {
        'counter' => counter,
        'gauge' => gauge,
        'histogram' => histogram,
        'summary' => summary,
        _ => null,
      };

  String toJson() => name;
}

/// {@template Metric}
/// Class representing a metric for analytics.
/// {@endtemplate}
class Metric extends AnalyticsModel {
  /// {@macro Metric}
  /// [name] is the name of the metric.
  /// [type] is the type of the metric.
  /// [labels] are the optional labels associated with the metric.
  const Metric(this.name,
      {this.type = MetricType.counter, Map<String, String>? labels})
      : _labels = labels;

  /// Creates a Metric from a JSON map.
  factory Metric.fromJson(Map<String, dynamic> json) => Metric(
        json['name'] as String,
        type:
            MetricType.fromString(json['type'] as String) ?? MetricType.counter,
        labels:
            (json['labels'] as Map<String, dynamic>?)?.cast<String, String>(),
      );

  /// Creates a counter Metric.
  const Metric.counter(String name, {Map<String, String>? labels})
      : this(name, type: MetricType.counter, labels: labels);

  /// Creates a gauge Metric.
  const Metric.gauge(String name, {Map<String, String>? labels})
      : this(name, type: MetricType.gauge, labels: labels);

  /// Creates a histogram Metric.
  const Metric.histogram(String name, {Map<String, String>? labels})
      : this(name, type: MetricType.histogram, labels: labels);

  /// Creates a summary Metric.
  const Metric.summary(String name, {Map<String, String>? labels})
      : this(name, type: MetricType.summary, labels: labels);

  @override
  final String name;

  /// The type of the metric.
  final MetricType type;

  final Map<String, String>? _labels;

  @override
  Map<String, dynamic>? get labels => _labels;

  Map<String, String>? get properties => _labels;

  @override
  Map<String, dynamic> toMap() => {
        '_type': 'metric',
        'name': name,
        'type': type.name,
        if (_labels != null) 'labels': _labels,
      };

  @override
  Metric withProperties(Map<String, dynamic> properties) {
    if (properties.isEmpty) {
      return this;
    }
    final newLabels = properties.map((k, v) => MapEntry(k, v.toString()));
    return Metric(name, type: type, labels: {...?_labels, ...newLabels});
  }

  @override
  Metric copyWith(
          {String? name, MetricType? type, Map<String, String>? labels}) =>
      Metric(
        name ?? this.name,
        type: type ?? this.type,
        labels: labels ?? _labels,
      );

  @override
  List<Object?> get props => [name, type, _labels];
}
