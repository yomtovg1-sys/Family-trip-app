import '../models/ai_chat_message.dart';
import 'ai_context_service.dart';
import 'ai_provider.dart';
import 'prompt_builder.dart';

/// The single place the UI talks to for AI replies. Composes
/// [AIContextService] (automatic trip context), [PromptBuilder] (turns that
/// context into a prompt), and an [AIProvider] (generates the actual
/// reply) — so `AIChatController` never has to know how any of that works.
/// Swapping providers (e.g. to a real OpenAI integration) means
/// constructing this with a different [AIProvider]; nothing else in the
/// app changes.
class AIRepository {
  final AIContextService contextService;
  final PromptBuilder promptBuilder;
  final AIProvider provider;

  const AIRepository({
    required this.contextService,
    required this.promptBuilder,
    required this.provider,
  });

  AIProviderRequest _buildRequest(List<AIChatMessage> history, String userMessage) {
    final context = contextService.buildContext();
    final systemPrompt = promptBuilder.buildSystemPrompt(context);
    return AIProviderRequest(
      context: context,
      systemPrompt: systemPrompt,
      history: history,
      userMessage: userMessage,
    );
  }

  /// Streams progressively-complete snapshots of the same assistant
  /// message: growing `text` with `isStreaming: true`, then one final
  /// snapshot with `isStreaming: false` carrying any suggested action.
  ///
  /// For a provider that can't stream, this yields exactly one snapshot.
  /// For a streaming-capable provider, the definitive text/action come from
  /// [AIProvider.generateReply] while [AIProvider.streamReply] drives the
  /// progressive reveal — both derive from the same deterministic input, so
  /// they agree for [LocalTripAssistantProvider]. A real remote provider
  /// would typically attach structured data (like a suggested action) via
  /// a trailing event of its own streaming protocol instead.
  Stream<AIChatMessage> sendMessageStreaming({
    required List<AIChatMessage> history,
    required String userMessage,
  }) async* {
    final request = _buildRequest(history, userMessage);
    final id = _newMessageId();

    if (!provider.capabilities.supportsStreaming) {
      final reply = await provider.generateReply(request);
      yield AIChatMessage(
        id: id,
        role: AIChatRole.assistant,
        text: reply.text,
        timestamp: DateTime.now(),
        suggestedAction: reply.suggestedAction,
        suggestedActionLabel: reply.suggestedActionLabel,
      );
      return;
    }

    final metadataFuture = provider.generateReply(request);
    final buffer = StringBuffer();
    await for (final chunk in provider.streamReply(request)) {
      buffer.write(chunk);
      yield AIChatMessage(
        id: id,
        role: AIChatRole.assistant,
        text: buffer.toString(),
        timestamp: DateTime.now(),
        isStreaming: true,
      );
    }
    final metadata = await metadataFuture;
    yield AIChatMessage(
      id: id,
      role: AIChatRole.assistant,
      text: buffer.toString(),
      timestamp: DateTime.now(),
      suggestedAction: metadata.suggestedAction,
      suggestedActionLabel: metadata.suggestedActionLabel,
    );
  }

  String _newMessageId() => 'msg-${DateTime.now().microsecondsSinceEpoch}';
}
