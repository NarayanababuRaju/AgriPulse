import 'package:equatable/equatable.dart';

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
      day: json['day'] ?? '',
      temp: (json['temp'] ?? 0.0).toDouble(),
      condition: json['condition'] ?? '',
      yieldPotential: (json['yield_potential'] ?? 0.0).toDouble(),
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
      label: json['label'] ?? '',
      value: json['value'] ?? '',
      status: json['status'] ?? '',
      iconType: json['icon_type'] ?? '',
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
      expectedYield: (json['expected_yield'] ?? 0.0).toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      primaryFactors: List<String>.from(json['factors'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      dailyForecast: (json['daily_forecast'] as List? ?? [])
          .map((item) => DailyForecast.fromJson(item))
          .toList(),
      contextualInsights: (json['contextual_insights'] as List? ?? [])
          .map((item) => InsightCard.fromJson(item))
          .toList(),
      predictionDate: DateTime.now(),
      rawAiResponse: json,
    );
  }

  @override
  List<Object?> get props => [id, expectedYield, confidence, primaryFactors, recommendations, dailyForecast, contextualInsights, predictionDate];
}
