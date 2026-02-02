import 'package:equatable/equatable.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class DailyForecast extends Equatable {
  final String day;
  final double temp;
  final String condition;
  final double yieldPotential;

  const DailyForecast({
    required this.day,
    required this.temp,
    required this.condition,
    required this.yieldPotential,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      day: json['day']?.toString() ?? '',
      temp: _parseDouble(json['temp']),
      condition: json['condition']?.toString() ?? '',
      yieldPotential: _parseDouble(json['yield_potential']),
    );
  }

  @override
  List<Object?> get props => [day, temp, condition, yieldPotential];
}

class InsightCard extends Equatable {
  final String label;
  final String value;
  final String status;
  final String iconType;

  const InsightCard({
    required this.label,
    required this.value,
    required this.status,
    required this.iconType,
  });

  factory InsightCard.fromJson(Map<String, dynamic> json) {
    return InsightCard(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      iconType: json['icon_type']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [label, value, status, iconType];
}

class YieldPrediction extends Equatable {
  final String id;
  final double expectedYield; // in quintals/acre
  final double confidence; // 0.0 to 100.0
  final List<String> primaryFactors;
  final List<String> recommendations;
  final List<DailyForecast> dailyForecast;
  final List<InsightCard> contextualInsights;
  final DateTime predictionDate;
  final Map<String, dynamic> rawAiResponse;

  const YieldPrediction({
    required this.id,
    required this.expectedYield,
    required this.confidence,
    required this.primaryFactors,
    required this.recommendations,
    required this.dailyForecast,
    required this.contextualInsights,
    required this.predictionDate,
    required this.rawAiResponse,
  });

  factory YieldPrediction.fromJson(String id, Map<String, dynamic> json) {
    return YieldPrediction(
      id: id,
      expectedYield: _parseDouble(json['expected_yield']),
      confidence: _parseDouble(json['confidence']),
      primaryFactors: (json['factors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      recommendations: (json['recommendations'] as List?)?.map((e) => e.toString()).toList() ?? [],
      dailyForecast: (json['daily_forecast'] as List? ?? [])
          .map((item) => DailyForecast.fromJson(item as Map<String, dynamic>? ?? {}))
          .toList(),
      contextualInsights: (json['contextual_insights'] as List? ?? [])
          .map((item) => InsightCard.fromJson(item as Map<String, dynamic>? ?? {}))
          .toList(),
      predictionDate: DateTime.now(),
      rawAiResponse: json,
    );
  }

  @override
  List<Object?> get props => [id, expectedYield, confidence, primaryFactors, recommendations, dailyForecast, contextualInsights, predictionDate];
}
