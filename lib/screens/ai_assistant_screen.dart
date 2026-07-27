import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_snapshot.dart';
import '../providers/trip_provider.dart';
import '../widgets/ai_assistant_card.dart';

class AiAssistantScreen extends StatefulWidget {
  final String? initialPrompt;

  const AiAssistantScreen({super.key, this.initialPrompt});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage(this.text, this.isUser);
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.add(const _ChatMessage(
      "Hi! I'm your AI travel assistant. Ask me about today's plans, "
      "nearby restaurants, activity ideas, or your expenses.",
      false,
    ));
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.initialPrompt!));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    final dashboard = context.read<TripProvider>().current;
    setState(() {
      _messages.add(_ChatMessage(text, true));
      _messages.add(_ChatMessage(_mockReply(text, dashboard), false));
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Local, offline mock reply — this screen has no real AI backend wired up.
  String _mockReply(String prompt, TripDashboard dashboard) {
    final lower = prompt.toLowerCase();
    final weather = dashboard.weather;
    if (lower.contains('today') || lower.contains('activit')) {
      if (weather != null) {
        return 'Based on today\'s forecast (${weather.tempCelsius}°, ${weather.condition.label.toLowerCase()}), '
            '${weather.aiTip} You could also check the Map for nearby spots around '
            '${dashboard.displayStop.location}.';
      }
      return 'I\'d suggest exploring around ${dashboard.displayStop.location} — check the Map tab for nearby spots.';
    }
    if (lower.contains('restaurant') || lower.contains('food') || lower.contains('eat')) {
      return 'Looking for food near ${dashboard.displayStop.location}? Try the Map tab and filter for restaurants — '
          'I\'d recommend something local and family-friendly for the kids.';
    }
    if (lower.contains('route') || lower.contains('optimize')) {
      return 'For the most efficient day around ${dashboard.displayStop.location}, group nearby stops together '
          'and save travel time for the afternoon when the family needs a slower pace.';
    }
    if (lower.contains('expense') || lower.contains('budget') || lower.contains('money') || lower.contains('cost')) {
      return 'So far you\'ve spent \$${dashboard.totalExpenses.toStringAsFixed(0)} on this trip, '
          '\$${dashboard.todayExpenses.toStringAsFixed(0)} of that today. Check the Expenses card on Home for the full breakdown.';
    }
    return 'Great question! Once connected to a live AI service I\'ll be able to give a detailed answer — '
        'for now, try asking about today\'s activities, restaurants, your route, or expenses.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Travel Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
            ),
          ),
          if (_messages.length <= 1)
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: aiSuggestedPrompts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ActionChip(
                  label: Text(aiSuggestedPrompts[index]),
                  onPressed: () => _send(aiSuggestedPrompts[index]),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask a question…',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _send(_controller.text),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
