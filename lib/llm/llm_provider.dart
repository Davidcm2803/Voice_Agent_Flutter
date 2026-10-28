enum ChatRole { system, user, assistant, tool }

class ChatMessage {
  const ChatMessage(this.role, this.content);

  const ChatMessage.system(String content) : this(ChatRole.system, content);
  const ChatMessage.user(String content) : this(ChatRole.user, content);
  const ChatMessage.assistant(String content) : this(ChatRole.assistant, content);

  final ChatRole role;
  final String content;
}

class LlmOptions {
  const LlmOptions({
    this.temperature = 1.0,
    this.topK = 64,
    this.topP = 0.95,
    this.maxTokens = 512,
  });

  final double temperature;
  final int topK;
  final double topP;
  final int maxTokens;
}

/// Interfaz común: LiteRT local, Ollama, APIs compatibles con OpenAI...
abstract interface class LlmProvider {
  String get id;
  String get displayName;

  Future<void> load();
  Future<void> dispose();

  /// Devuelve la respuesta en trozos (streaming).
  Stream<String> generate(
    List<ChatMessage> messages, {
    LlmOptions options = const LlmOptions(),
  });
}