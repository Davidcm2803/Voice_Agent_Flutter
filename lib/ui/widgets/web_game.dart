import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';

class _Target {
  _Target(this.pos, this.expires);

  final Offset pos;
  final DateTime expires;
}

/// Minijuego: toca los bichos antes de que desaparezcan.
class WebGame extends StatefulWidget {
  const WebGame({super.key});

  @override
  State<WebGame> createState() => _WebGameState();
}

class _WebGameState extends State<WebGame> {
  static const double _size = 56;

  final math.Random _rng = math.Random();
  final List<_Target> _targets = [];
  Timer? _timer;
  Size _area = Size.zero;
  int _score = 0;
  int _missed = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _area.width <= _size || _area.height <= _size) return;
    final now = DateTime.now();
    setState(() {
      final before = _targets.length;
      _targets.removeWhere((t) => now.isAfter(t.expires));
      _missed += before - _targets.length;
      _targets.add(_Target(
        Offset(
          _rng.nextDouble() * (_area.width - _size),
          _rng.nextDouble() * (_area.height - _size),
        ),
        now.add(const Duration(milliseconds: 1500)),
      ));
    });
  }

  void _hit(_Target t) {
    setState(() {
      _targets.remove(t);
      _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'ATRAPADOS: $_score   ·   PERDIDOS: $_missed',
            style: theme.textTheme.labelSmall,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              _area = box.biggest;
              return ClipRect(
                child: Stack(
                  children: [
                    for (final t in _targets)
                      Positioned(
                        left: t.pos.dx,
                        top: t.pos.dy,
                        child: GestureDetector(
                          onTapDown: (_) => _hit(t),
                          child: Container(
                            width: _size,
                            height: _size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.red,
                              border:
                                  Border.all(color: AppColors.paper, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.cyan,
                                  offset: Offset(3, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.bug_report,
                                color: AppColors.paper),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}