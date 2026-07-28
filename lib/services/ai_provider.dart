import '../models/ai_chat_message.dart';
import '../models/trip_context_model.dart';

/// What a given [AIProvider] implementation can do — lets the UI adapt
/// (e.g. only show a mic button when [supportsVoice] is true) without
/// knowing which concrete provider is wired up.
class AIProviderCapabilities {
  final bool supportsStreaming;
  final bool supportsVoice;
  final bool supportsImages;
  final bool requiresNetwork;

  const AIProviderCapabilities({
    this.supportsStreaming = false,
    this.supportsVoice = false,
    this.supportsImages = false,
    this.requiresNetwork = false,
  });
}

/// Everything a provider needs to produce a reply. [context] is the live
/// [TripContextModel]; [systemPrompt] is that same context already
/// flattened by [PromptBuilder] for providers that only accept a text
/// prompt (a real chat-completions API). A local, data-grounded provider
/// can read [context] directly instead, for more reliable answers.
class AIProviderRequest {
  final TripContextModel context;
  final String systemPrompt;
  final List<AIChatMessage> history;
  final String userMessage;

  const AIProviderRequest({
    required this.context,
    required this.systemPrompt,
    required this.history,
    required this.userMessage,
  });
}

class AIProviderReply {
  final String text;
  final AIQuickLinkTarget? suggestedAction;
  final String? suggestedActionLabel;

  const AIProviderReply({required this.text, this.suggestedAction, this.suggestedActionLabel});
}

/// The provider-agnostic seam for generating a reply. Nothing else in the
/// app — [AIRepository], `AIChatController`, `AIAssistantScreen` — knows or
/// cares which concrete implementation is wired up. Swap
/// [LocalTripAssistantProvider] for an OpenAI/Anthropic/etc. implementation
/// by changing a single constructor call in [AIRepository].
abstract class AIProvider {
  String get id;
  String get displayName;
  AIProviderCapabilities get capabilities;

  Future<AIProviderReply> generateReply(AIProviderRequest request);

  /// Streams the reply incrementally. A provider that can't truly stream
  /// may implement this by emitting the full [generateReply] result as one
  /// chunk.
  Stream<String> streamReply(AIProviderRequest request);
}

/// A placeholder for a future real LLM integration (OpenAI, Anthropic, or
/// any other vendor). Not wired up anywhere — it deliberately throws, so
/// enabling a real provider is a visible, intentional swap rather than a
/// silent no-op. Its only purpose is to prove [AIRepository] depends on the
/// [AIProvider] interface, never a concrete vendor.
class UnavailableRemoteAIProvider implements AIProvider {
  const UnavailableRemoteAIProvider();

  @override
  String get id => 'remote-unavailable';

  @override
  String get displayName => 'Remote AI (not configured)';

  @override
  AIProviderCapabilities get capabilities => const AIProviderCapabilities(
        supportsStreaming: true,
        requiresNetwork: true,
      );

  @override
  Future<AIProviderReply> generateReply(AIProviderRequest request) {
    throw UnimplementedError(
      'No remote AI provider is configured yet. Implement AIProvider (e.g. '
      'an OpenAIProvider) and pass it to AIRepository to enable it.',
    );
  }

  @override
  Stream<String> streamReply(AIProviderRequest request) {
    throw UnimplementedError(
      'No remote AI provider is configured yet. Implement AIProvider (e.g. '
      'an OpenAIProvider) and pass it to AIRepository to enable it.',
    );
  }
}
