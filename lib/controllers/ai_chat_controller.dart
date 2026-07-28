import 'package:flutter/material.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_quick_action.dart';
import '../services/ai_repository.dart';

/// Drives the AI Assistant chat: holds the conversation, sends messages
/// through [AIRepository], and streams the assistant's reply in as it's
/// "typed". The screen just renders whatever this exposes.
class AIChatController extends ChangeNotifier {
  final AIRepository repository;
  final List<AIChatMessage> _messages = [];
  bool _isSending = false;
  bool _disposed = false;

  AIChatController({required this.repository, required String initialGreeting}) {
    _messages.add(
      AIChatMessage(
        id: _newId(),
        role: AIChatRole.assistant,
        text: initialGreeting,
        timestamp: DateTime.now(),
      ),
    );
  }

  List<AIChatMessage> get messages => List.unmodifiable(_messages);

  bool get isSending => _isSending;

  bool get hasUserMessages => _messages.any((m) => m.isUser);

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _messages.add(AIChatMessage(id: _newId(), role: AIChatRole.user, text: trimmed, timestamp: DateTime.now()));
    _isSending = true;
    _notify();

    try {
      final history = List<AIChatMessage>.unmodifiable(_messages);
      await for (final snapshot in repository.sendMessageStreaming(history: history, userMessage: trimmed)) {
        final index = _messages.indexWhere((m) => m.id == snapshot.id);
        if (index == -1) {
          _messages.add(snapshot);
        } else {
          _messages[index] = snapshot;
        }
        _notify();
      }
    } catch (_) {
      _messages.add(
        AIChatMessage(
          id: _newId(),
          role: AIChatRole.assistant,
          text: "Sorry, I couldn't process that. Please try again.",
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isSending = false;
      _notify();
    }
  }

  Future<void> sendQuickAction(AIQuickAction action) => sendMessage(action.prompt);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _newId() => 'msg-${DateTime.now().microsecondsSinceEpoch}-${_messages.length}';

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
