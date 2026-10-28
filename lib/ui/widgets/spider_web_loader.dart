import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';

/// Telaraña que pulsa con una araña colgando y balanceándose.
/// Dibujada en código: sin imágenes ni logos de terceros.
class SpiderWebLoader extends StatefulWidget {
  const SpiderWebLoader({super.key});

  @override
  State<SpiderWebLoader> createState() => _SpiderWebLoaderState();
}

class _SpiderWebLoaderState extends State<SpiderWebLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _WebPainter(_c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _WebPainter extends CustomPainter {
  _WebPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.58);
    final r = math.min(size.width, size.height * 0.9) * 0.36;

    final line = Paint()
      ..color = AppColors.paper.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const spokes = 12;
    for (var i = 0; i < spokes; i++) {
      final a = i * 2 * math.pi / spokes;
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * r, line);
    }

    for (var ring = 1; ring <= 5; ring++) {
      final rr = r * ring / 5;
      final path = Path();
      for (var i = 0; i <= spokes; i++) {
        final a = i * 2 * math.pi / spokes;
        final p = c +
            Offset(math.cos(a), math.sin(a)) * (rr * (i.isOdd ? 0.93 : 1.0));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, line);
    }

    // Pulso rojo que sale del centro.
    final pulse = Paint()
      ..color = AppColors.red.withValues(alpha: 0.9 * (1 - t))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, r * (0.15 + 0.85 * t), pulse);

    // Araña colgando de un hilo.
    final sway = math.sin(t * 2 * math.pi);
    final anchor = Offset(size.width / 2, 0);
    final pos = Offset(
      size.width / 2 + sway * size.width * 0.18,
      size.height * 0.2 + math.cos(t * 2 * math.pi) * 10,
    );
    canvas.drawLine(
      anchor,
      pos,
      Paint()
        ..color = AppColors.paper
        ..strokeWidth = 1.5,
    );

    final leg = Paint()
      ..color = AppColors.paper
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 4; i++) {
      final dy = (i - 1.5) * 5.0;
      canvas.drawLine(
          pos + Offset(0, dy), pos + Offset(-18, dy - 6 + sway * 3), leg);
      canvas.drawLine(
          pos + Offset(0, dy), pos + Offset(18, dy - 6 - sway * 3), leg);
    }

    final body = Paint()..color = AppColors.red;
    canvas.drawCircle(pos, 9, body);
    canvas.drawCircle(pos + const Offset(0, -10), 6, body);
    final eye = Paint()..color = AppColors.paper;
    canvas.drawCircle(pos + const Offset(-2.5, -11), 1.8, eye);
    canvas.drawCircle(pos + const Offset(2.5, -11), 1.8, eye);
  }

  @override
  bool shouldRepaint(_WebPainter oldDelegate) => oldDelegate.t != t;
}