import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';

/// Fondo oscuro con puntos de semitono estilo cómic.
class HalftoneBackground extends StatelessWidget {
  const HalftoneBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.night, AppColors.ink],
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _HalftonePainter(AppColors.red.withValues(alpha: 0.22)),
          ),
        ),
        child,
      ],
    );
  }
}

class _HalftonePainter extends CustomPainter {
  _HalftonePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 14.0;
    final paint = Paint()..color = color;
    final fadeHeight = size.height * 0.6;

    for (double y = 0; y < fadeHeight; y += spacing) {
      final t = 1 - (y / fadeHeight);
      final radius = 0.5 + 2.8 * t;
      final row = (y / spacing).round();
      final startX = row.isEven ? 0.0 : spacing / 2;
      for (double x = startX; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HalftonePainter oldDelegate) =>
      oldDelegate.color != color;
}