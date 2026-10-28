import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/ui/widgets/spider_web_loader.dart';
import 'package:voice_agent_flutter/ui/widgets/web_game.dart';

/// Pantalla de espera mientras Gemma se carga: animación o minijuego.
class ModelLoader extends StatefulWidget {
  const ModelLoader({super.key});

  @override
  State<ModelLoader> createState() => _ModelLoaderState();
}

class _ModelLoaderState extends State<ModelLoader> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 8),
      child: Column(
        children: [
          Expanded(
            child: _playing ? const WebGame() : const SpiderWebLoader(),
          ),
          Text(
            'AXEL ESTÁ DESPERTANDO...',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _playing
                ? 'Atrapa los bichos mientras carga el cerebro'
                : 'Cargando a Gemma, tarda unos segundos',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => setState(() => _playing = !_playing),
            child: Text(_playing ? 'VER LA TELARAÑA' : 'JUGAR MIENTRAS CARGA'),
          ),
        ],
      ),
    );
  }
}