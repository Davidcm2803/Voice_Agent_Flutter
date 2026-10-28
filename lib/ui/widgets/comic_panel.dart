import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';

/// Panel con borde grueso y sombra dura, como un recuadro de cómic.
class ComicPanel extends StatelessWidget {
  const ComicPanel({
    super.key,
    required this.child,
    this.color = AppColors.panel,
    this.shadowColor = AppColors.red,
    this.borderColor = AppColors.paper,
    this.padding = const EdgeInsets.all(12),
    this.shadowOffset = 4,
  });

  final Widget child;
  final Color color;
  final Color shadowColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final double shadowOffset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor, width: 2.5),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}