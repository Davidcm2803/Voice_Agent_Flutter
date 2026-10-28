import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/core/axel_persona.dart';
import 'package:voice_agent_flutter/core/config.dart';
import 'package:voice_agent_flutter/core/persona_modules.dart';
import 'package:voice_agent_flutter/llm/llm_provider.dart';
import 'package:voice_agent_flutter/llm/providers/litert_provider.dart';
import 'package:voice_agent_flutter/notebook/data/entry_store.dart';
import 'package:voice_agent_flutter/notebook/data/notebook_rag.dart';
import 'package:voice_agent_flutter/ui/notebook/notebook_screen.dart';
import 'package:voice_agent_flutter/ui/settings/settings_screen.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';
import 'package:voice_agent_flutter/ui/widgets/comic_panel.dart';
import 'package:voice_agent_flutter/ui/widgets/empty_state.dart';
import 'package:voice_agent_flutter/ui/widgets/halftone_background.dart';
import 'package:voice_agent_flutter/ui/widgets/model_loader.dart';
import 'package:voice_agent_flutter/voice/stt.dart';
import 'package:voice_agent_flutter/voice/tts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final LiteRtProvider _llm = LiteRtProvider();
  final SttService _stt = SttService();
  final TtsService _tts = TtsService();
  final List<ChatMessage> _messages = [];
  final TextEditingController _input = TextEditingController();
  final StringBuffer _speechBuf = StringBuffer();

  bool _busy = false;
  bool _loadingModel = true;
  bool _listening = false;
  bool _voiceSent = false;
  String? _loadError;
  Future<void>? _loadFuture;

  @override
  void initState() {
    super.initState();
    assert(() {
      debugPrint('Persona ~ ${AxelPersona.estimatedTokens} tokens');
      return true;
    }());
    // El modelo se carga al abrir la app, no al mandar el primer mensaje.
    _loadFuture = _preload();
  }

  @override
  void dispose() {
    _input.dispose();
    _stt.cancel();
    _tts.dispose();
    _llm.dispose();
    super.dispose();
  }

  Future<void> _preload() async {
    try {
      await _llm.load();
    } catch (e) {
      _loadError = e is StateError ? e.message : '$e';
    }
    if (!mounted) return;
    setState(() => _loadingModel = false);
    if (_loadError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Axel listo (${_llm.backendUsed})')),
      );
    }
  }

  void _retry() {
    setState(() {
      _loadError = null;
      _loadingModel = true;
      _loadFuture = _preload();
    });
  }

  void _setLast(String text) {
    if (!mounted) return;
    setState(() {
      _messages[_messages.length - 1] = ChatMessage.assistant(text);
    });
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------- Voz de salida: habla frase por frase mientras llega el texto

  void _feedSpeech(String chunk) {
    _speechBuf.write(chunk);
    var s = _speechBuf.toString();
    final end = RegExp(r'([.!?]+|\n)\s');
    Match? m;
    while ((m = end.firstMatch(s)) != null) {
      _tts.speak(s.substring(0, m!.end));
      s = s.substring(m.end);
    }
    _speechBuf
      ..clear()
      ..write(s);
  }

  void _flushSpeech() {
    final rest = _speechBuf.toString();
    _speechBuf.clear();
    if (rest.trim().isNotEmpty) _tts.speak(rest);
  }

  void _toggleSpeaker() {
    setState(() => _tts.enabled = !_tts.enabled);
    if (!_tts.enabled) _tts.stop();
  }

  // ---------- Voz de entrada

  Future<void> _toggleMic() async {
    if (_busy) return;
    await _tts.stop();

    if (_listening) {
      await _stt.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final ok = await _stt.init(
      onError: (e) {
        if (!mounted) return;
        setState(() => _listening = false);
        if (e != 'error_no_match' && e != 'error_speech_timeout') {
          _snack('Micrófono: $e');
        }
      },
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          setState(() => _listening = false);
        }
      },
    );
    if (!ok) {
      _snack('No pude activar el micrófono. Revisá el permiso y que el '
          'reconocimiento de voz de Google esté instalado.');
      return;
    }

    _voiceSent = false;
    setState(() => _listening = true);
    await _stt.listen(onResult: (text, isFinal) {
      if (!mounted) return;
      _input.text = text;
      _input.selection = TextSelection.collapsed(offset: text.length);
      if (isFinal && !_voiceSent && text.trim().isNotEmpty) {
        _voiceSent = true;
        setState(() => _listening = false);
        _send();
      }
    });
  }

  // ---------- Envío

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    await _tts.stop();
    _speechBuf.clear();

    setState(() {
      _messages.add(ChatMessage.user(text));
      _messages.add(const ChatMessage.assistant(''));
      _busy = true;
    });

    final module = PersonaModules.forMessage(text);
    RagResult? rag;
    try {
      final store = await EntryStore.open();
      rag = NotebookRag.retrieve(await store.loadAll(), text);
    } catch (_) {
      // Si el cuaderno falla, el chat sigue funcionando sin fuentes.
    }
    final parts = <String>[
      if (module != null) '[Contexto para Axel: $module]',
      if (rag != null) rag.context,
      text,
    ];
    final outgoing = parts.join('\n');
    final history = [
      ..._messages.sublist(0, _messages.length - 2),
      ChatMessage.user(outgoing),
    ];
    final buffer = StringBuffer();

    try {
      if (_loadError != null && !_loadingModel) _retry();
      if (_loadingModel) {
        _setLast('Cargando a Gemma... en cuanto termine te respondo.');
      }
      await _loadFuture;
      final err = _loadError;
      if (err != null) throw StateError(err);
      _setLast('');

      await for (final chunk in _llm.generate([
        const ChatMessage.system(AxelPersona.prompt),
        ...history,
      ])) {
        buffer.write(chunk);
        _setLast(buffer.toString());
        _feedSpeech(chunk);
      }
      _flushSpeech();
      final used = rag;
      if (used != null && buffer.isNotEmpty) {
        // Se agrega después de la voz: las fuentes se ven pero no se leen.
        buffer.write(
            '\n\nFuentes: ${used.sources.map((e) => e.title).join(' · ')}');
        _setLast(buffer.toString());
      }
    } catch (e) {
      final msg = e is StateError ? e.message : '$e';
      _setLast(
          buffer.isEmpty ? 'Error: $msg' : '${buffer.toString()}\n\n[$msg]');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _newChat() async {
    await _tts.stop();
    _speechBuf.clear();
    await _llm.resetConversation();
    if (!mounted) return;
    setState(() => _messages.clear());
  }

  Widget _emptyArea() {
    if (_loadingModel) return const ModelLoader();
    if (_loadError != null) {
      return _LoadError(message: _loadError!, onRetry: _retry);
    }
    return const EmptyState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Text(AppConfig.appName, style: theme.textTheme.headlineMedium),
            const SizedBox(width: 10),
            Text('v${AppConfig.version}', style: theme.textTheme.labelSmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _tts.enabled ? 'Silenciar a Axel' : 'Activar voz de Axel',
            icon: Icon(_tts.enabled ? Icons.volume_up : Icons.volume_off),
            onPressed: _toggleSpeaker,
          ),
          IconButton(
            tooltip: 'Chat nuevo',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _busy ? null : _newChat,
          ),
          IconButton(
            tooltip: 'Cuaderno',
            icon: const Icon(Icons.menu_book),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const NotebookScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: HalftoneBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _emptyArea()
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 56, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final msg = _messages[_messages.length - 1 - i];
                          return _Bubble(message: msg);
                        },
                      ),
              ),
              _InputBar(
                controller: _input,
                busy: _busy,
                listening: _listening,
                onSend: _send,
                onMic: _toggleMic,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ComicPanel(
          shadowColor: AppColors.red,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('NO PUDE CARGAR EL MODELO',
                  style: theme.textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(message, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('REINTENTAR')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          ),
          child: ComicPanel(
            color: isUser ? AppColors.blue : AppColors.panel,
            shadowColor: isUser ? AppColors.cyan : AppColors.red,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isUser ? 'TÚ' : 'AXEL', style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                SelectableText(
                  message.content.isEmpty ? '...' : message.content,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.busy,
    required this.listening,
    required this.onSend,
    required this.onMic,
  });

  final TextEditingController controller;
  final bool busy;
  final bool listening;
  final VoidCallback onSend;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: ComicPanel(
              shadowColor: listening ? AppColors.red : AppColors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      decoration: InputDecoration(
                        hintText: listening
                            ? 'Escuchando...'
                            : 'Axel la está chilleando...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: listening ? 'Detener' : 'Hablar',
                    icon: Icon(
                      listening ? Icons.stop_circle : Icons.mic,
                      color: listening ? AppColors.red : AppColors.cyan,
                    ),
                    onPressed: onMic,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: busy ? null : onSend,
            child: ComicPanel(
              color: busy ? AppColors.muted : AppColors.red,
              shadowColor: AppColors.paper,
              shadowOffset: 3,
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.bolt, color: AppColors.paper),
            ),
          ),
        ],
      ),
    );
  }
}