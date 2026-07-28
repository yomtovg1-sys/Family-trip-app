enum AIChatRole { user, assistant }

/// Where a "suggested action" chip under an assistant message should take
/// the user. Kept as a plain enum — not a callback — so chat messages stay
/// simple, serializable data; the Navigator call happens in the UI layer
/// that renders the message.
enum AIQuickLinkTarget { mapPlaces, expenses, travelWallet, reservations, albumPreview, packing, memories }

/// One turn in the AI Assistant conversation.
class AIChatMessage {
  final String id;
  final AIChatRole role;
  final String text;
  final DateTime timestamp;
  final bool isStreaming;
  final AIQuickLinkTarget? suggestedAction;
  final String? suggestedActionLabel;

  const AIChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.isStreaming = false,
    this.suggestedAction,
    this.suggestedActionLabel,
  });

  bool get isUser => role == AIChatRole.user;

  AIChatMessage copyWith({String? text, bool? isStreaming}) {
    return AIChatMessage(
      id: id,
      role: role,
      timestamp: timestamp,
      text: text ?? this.text,
      isStreaming: isStreaming ?? this.isStreaming,
      suggestedAction: suggestedAction,
      suggestedActionLabel: suggestedActionLabel,
    );
  }
}
