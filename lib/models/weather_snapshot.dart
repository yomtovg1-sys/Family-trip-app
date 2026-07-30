import 'package:flutter/material.dart';

enum WeatherCondition { sunny, partlyCloudy, cloudy, rainy, stormy, snowy }

extension WeatherConditionX on WeatherCondition {
  IconData get icon {
    switch (this) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny_rounded;
      case WeatherCondition.partlyCloudy:
        return Icons.wb_cloudy_rounded;
      case WeatherCondition.cloudy:
        return Icons.cloud_rounded;
      case WeatherCondition.rainy:
        return Icons.grain_rounded;
      case WeatherCondition.stormy:
        return Icons.thunderstorm_rounded;
      case WeatherCondition.snowy:
        return Icons.ac_unit_rounded;
    }
  }

  String get label {
    switch (this) {
      case WeatherCondition.sunny:
        return 'Sunny';
      case WeatherCondition.partlyCloudy:
        return 'Partly Cloudy';
      case WeatherCondition.cloudy:
        return 'Cloudy';
      case WeatherCondition.rainy:
        return 'Rainy';
      case WeatherCondition.stormy:
        return 'Stormy';
      case WeatherCondition.snowy:
        return 'Snowy';
    }
  }
}

class WeatherSnapshot {
  final int tempCelsius;
  final WeatherCondition condition;
  final int rainChancePercent;
  final String aiTip;

  const WeatherSnapshot({
    required this.tempCelsius,
    required this.condition,
    required this.rainChancePercent,
    required this.aiTip,
  });

  Map<String, dynamic> toJson() => {
        'tempCelsius': tempCelsius,
        'condition': condition.name,
        'rainChancePercent': rainChancePercent,
        'aiTip': aiTip,
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    return WeatherSnapshot(
      tempCelsius: json['tempCelsius'] as int,
      condition: WeatherCondition.values.byName(json['condition'] as String),
      rainChancePercent: json['rainChancePercent'] as int,
      aiTip: json['aiTip'] as String,
    );
  }
}
