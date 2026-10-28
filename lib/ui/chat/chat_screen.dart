import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/core/axel_persona.dart';
import 'package:voice_agent_flutter/core/config.dart';
import 'package:voice_agent_flutter/llm/llm_provider.dart';
import 'package:voice_agent_flutter/llm/providers/echo_provider.dart';
import 'package:voice_agent_flutter/ui/settings/settings_screen.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';
import 'package:voice_agent_flutter/ui/widgets/comic_panel.dart';
import 'package:voice_agent_flutter/ui/widgets/empty_state.dart';
import 'package:voice_agent_flutter/ui/widgets/halftone_background.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final LlmProvider _llm = EchoProvider(); // TODO: inyectar proveedor real
  final List<ChatMessage> _messages = [];
  final TextEditingController _input = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _llm.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();

    setState(() {
      _messages.add(ChatMessage.user(text));
      _messages.add(const ChatMessage.assistant(''));
      _busy = true;
    });

    final history = _messages.sublist(0, _messages.length - 1);
    final buffer = StringBuffer();

    try {
      await for (final chunk in _llm.generate([
        const ChatMessage.system(AxelPersona.systemPrompt),
        ...history,
      ])) {
        buffer.write(chunk);
        if (!mounted) return;
        setState(() {
          _messages[_messages.length - 1] =
              ChatMessage.assistant(buffer.toString());
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[_messages.length - 1] =
              ChatMessage.assistant('Error: $e');
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$what: prÃ³ximamente')));
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
                    ? const EmptyState()
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
                onSend: _send,
                onMic: () => _comingSoon('Voz'),
              ),
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
                Text(isUser ? 'TÃš' : 'AXEL', style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(
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
    required this.onSend,
    required this.onMic,
  });

  final TextEditingController controller;
  final bool busy;
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
              shadowColor: AppColors.blue,
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
                      decoration: const InputDecoration(
                        hintText: 'HÃ¡blale a Axel...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic, color: AppColors.cyan),
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