import 'package:flutter/material.dart';

/// The five large quick-action buttons on the AI Assistant home area.
enum AIQuickAction { planTrip, findRestaurants, analyzeExpenses, findDocuments, createAlbum }

extension AIQuickActionX on AIQuickAction {
  IconData get icon {
    switch (this) {
      case AIQuickAction.planTrip:
        return Icons.map_rounded;
      case AIQuickAction.findRestaurants:
        return Icons.restaurant_rounded;
      case AIQuickAction.analyzeExpenses:
        return Icons.payments_rounded;
      case AIQuickAction.findDocuments:
        return Icons.description_rounded;
      case AIQuickAction.createAlbum:
        return Icons.menu_book_rounded;
    }
  }

  String get label {
    switch (this) {
      case AIQuickAction.planTrip:
        return 'Plan My Trip';
      case AIQuickAction.findRestaurants:
        return 'Find Restaurants';
      case AIQuickAction.analyzeExpenses:
        return 'Analyze Expenses';
      case AIQuickAction.findDocuments:
        return 'Find Documents';
      case AIQuickAction.createAlbum:
        return 'Create Album';
    }
  }

  /// The chat prompt sent when this action is tapped.
  String get prompt {
    switch (this) {
      case AIQuickAction.planTrip:
        return 'Plan my trip';
      case AIQuickAction.findRestaurants:
        return 'Find restaurants near my saved places';
      case AIQuickAction.analyzeExpenses:
        return 'Analyze my expenses';
      case AIQuickAction.findDocuments:
        return 'Find my travel documents';
      case AIQuickAction.createAlbum:
        return 'Help me create my travel album';
    }
  }
}

/// The example prompts shown as quick-suggestion cards on the AI Assistant
/// home area (and mirrored, compactly, on Home's teaser card).
const List<String> aiHomeSuggestions = [
  'Plan my trip',
  'What should I do today?',
  'Find restaurants near my saved places',
  'Summarize my expenses',
  'Create my travel album',
];
