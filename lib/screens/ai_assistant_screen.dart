import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/ai_chat_controller.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_quick_action.dart';
import '../models/trip.dart';
import '../providers/memories_provider.dart';
import '../providers/packing_provider.dart';
import '../providers/places_provider.dart';
import '../providers/reservations_provider.dart';
import '../providers/trip_provider.dart';
import '../services/ai_context_service.dart';
import '../services/ai_repository.dart';
import '../services/local_trip_assistant_provider.dart';
import '../services/prompt_builder.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import 'album_preview_screen.dart';

/// A personal AI travel assistant that already knows the current trip: its
/// places, reservations, wallet, expenses, packing list, and memories. The
/// user never has to explain any of that — every reply is grounded in
/// AIContextService's live snapshot of the trip.
class AIAssistantScreen extends StatefulWidget {
  final String? initialPrompt;

  const AIAssistantScreen({super.key, this.initialPrompt});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  late final AIChatController _chatController;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final trip = context.read<TripProvider>().current.trip;

    // The repository is built once, here, from the interfaces — this is
    // the one place that would change to swap in a real LLM: pass a
    // different AIProvider instead of LocalTripAssistantProvider.
    final repository = AIRepository(
      contextService: ProviderAIContextService(
        tripProvider: context.read<TripProvider>(),
        placesProvider: context.read<PlacesProvider>(),
        reservationsProvider: context.read<ReservationsProvider>(),
        packingProvider: context.read<PackingProvider>(),
        memoriesProvider: context.read<MemoriesProvider>(),
      ),
      promptBuilder: const PromptBuilder(),
      provider: const LocalTripAssistantProvider(),
    );

    _chatController = AIChatController(repository: repository, initialGreeting: _greetingFor(trip))
      ..addListener(_onChatChanged);

    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _chatController.sendMessage(widget.initialPrompt!));
    }
  }

  String _greetingFor(Trip trip) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12 ? 'Good morning' : (hour < 18 ? 'Good afternoon' : 'Good evening');
    return "$timeGreeting! I'm your AI travel assistant for ${trip.name}. Ask me anything about your "
        'places, reservations, expenses, or travel documents — I already know the trip.';
  }

  void _onChatChanged() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _chatController.removeListener(_onChatChanged);
    _chatController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleAction(AIQuickLinkTarget target) {
    switch (target) {
      case AIQuickLinkTarget.mapPlaces:
        Navigator.of(context).pushNamed(AppSection.placesRoute);
      case AIQuickLinkTarget.expenses:
        Navigator.of(context).pushNamed(AppSection.expensesRoute);
      case AIQuickLinkTarget.travelWallet:
        Navigator.of(context).pushNamed(AppSection.travelWalletRoute);
      case AIQuickLinkTarget.reservations:
        Navigator.of(context).pushNamed(AppSection.reservationsRoute);
      case AIQuickLinkTarget.packing:
        Navigator.of(context).pushNamed(AppSection.packingRoute);
      case AIQuickLinkTarget.memories:
        Navigator.of(context).pushNamed(AppSection.photosRoute);
      case AIQuickLinkTarget.albumPreview:
        final tripId = context.read<TripProvider>().current.trip.id;
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlbumPreviewScreen(tripId: tripId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().current.trip;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      drawer: const AppDrawer(currentRoute: AppSection.aiAssistantRoute),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                _GreetingHeader(),
                const SizedBox(height: 16),
                _CurrentTripCard(trip: trip),
                const SizedBox(height: 22),
                Text('Quick suggestions', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                _SuggestionChips(onTap: _chatController.sendMessage),
                const SizedBox(height: 22),
                Text('Quick Actions', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                _QuickActionGrid(onTap: _chatController.sendQuickAction),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                for (final message in _chatController.messages)
                  _MessageBubble(message: message, onAction: _handleAction),
                if (_chatController.isSending && (_chatController.messages.isEmpty || _chatController.messages.last.text.isEmpty))
                  const _TypingIndicator(),
              ],
            ),
          ),
          _ChatInputBar(
            controller: _inputController,
            onSend: () {
              final text = _inputController.text;
              _inputController.clear();
              _chatController.sendMessage(text);
            },
          ),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 18 ? 'Good afternoon' : 'Good evening');

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9C6BFF)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text('✨', style: TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting! 👋', style: theme.textTheme.titleLarge),
              Text(
                'Your personal travel assistant',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrentTripCard extends StatelessWidget {
  final Trip trip;

  const _CurrentTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d');
    String statusLabel;
    if (trip.hasEnded) {
      statusLabel = 'Completed';
    } else if (trip.hasStarted) {
      statusLabel = 'In progress';
    } else {
      final days = trip.timeUntilStart.inDays + 1;
      statusLabel = 'In $days day${days == 1 ? '' : 's'}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Text(trip.heroEmoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${trip.flagEmoji} ${trip.destination} · ${dateFormat.format(trip.startDate)}–'
                  '${dateFormat.format(trip.endDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _SuggestionChips({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final suggestion in aiHomeSuggestions)
          Material(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onTap(suggestion),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Text(suggestion, style: theme.textTheme.labelMedium),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  final ValueChanged<AIQuickAction> onTap;

  const _QuickActionGrid({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        for (final action in AIQuickAction.values)
          Material(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onTap(action),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Text(action.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        action.label,
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AIChatMessage message;
  final ValueChanged<AIQuickLinkTarget> onAction;

  const _MessageBubble({required this.message, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
      decoration: BoxDecoration(
        color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message.isStreaming ? '${message.text}▍' : message.text,
        style: TextStyle(color: isUser ? Colors.white : theme.colorScheme.onSurface, height: 1.35),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 13, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('Assistant', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                ],
              ),
            ),
          Align(alignment: isUser ? Alignment.centerRight : Alignment.centerLeft, child: bubble),
          if (!message.isStreaming && message.suggestedAction != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: OutlinedButton.icon(
                onPressed: () => onAction(message.suggestedAction!),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(message.suggestedActionLabel ?? 'Open'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(
          width: 20,
          height: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              3,
              (_) => CircleAvatar(radius: 3, backgroundColor: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Ask about your trip…',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: onSend, icon: const Icon(Icons.send_rounded)),
          ],
        ),
      ),
    );
  }
}
