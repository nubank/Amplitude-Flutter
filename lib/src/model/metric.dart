part of 'analytics_model.dart';

enum MetricType {
  counter,
  gauge,
  histogram,
  summary;

  static MetricType? fromString(String value) => switch (value) {
        'counter' => counter,
        'gauge' => gauge,
        'histogram' => histogram,
        'summary' => summary,
        _ => null,
      };

  String toJson() => name;
}

class Metric extends AnalyticsModel {
  const Metric(this.name,
      {this.type = MetricType.counter, Map<String, String>? labels})
      : _labels = labels;

  factory Metric.fromJson(Map<String, dynamic> json) => Metric(
        json['name'] as String,
        type:
            MetricType.fromString(json['type'] as String) ?? MetricType.counter,
        labels:
            (json['labels'] as Map<String, dynamic>?)?.cast<String, String>(),
      );

  const Metric.counter(String name, {Map<String, String>? labels})
      : this(name, type: MetricType.counter, labels: labels);

  const Metric.gauge(String name, {Map<String, String>? labels})
      : this(name, type: MetricType.gauge, labels: labels);

  const Metric.histogram(String name, {Map<String, String>? labels})
      : this(name, type: MetricType.histogram, labels: labels);

  const Metric.summary(String name, {Map<String, String>? labels})
      : this(name, type: MetricType.summary, labels: labels);

  @override
  final String name;

  final MetricType type;

  final Map<String, String>? _labels;

  @override
  Map<String, dynamic>? get labels => _labels;

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
