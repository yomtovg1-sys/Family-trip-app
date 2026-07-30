import 'package:flutter/material.dart';

enum AlertSeverity { info, warning, urgent }

extension AlertSeverityX on AlertSeverity {
  Color get color {
    switch (this) {
      case AlertSeverity.info:
        return const Color(0xFF4FC3F7);
      case AlertSeverity.warning:
        return const Color(0xFFFFB74D);
      case AlertSeverity.urgent:
        return const Color(0xFFEF5350);
    }
  }
}

class TravelAlert {
  final String id;
  final IconData icon;
  final String message;
  final AlertSeverity severity;

  const TravelAlert({
    required this.id,
    required this.icon,
    required this.message,
    this.severity = AlertSeverity.info,
  });
}
