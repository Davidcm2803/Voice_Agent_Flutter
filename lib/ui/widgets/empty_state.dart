import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';
import 'package:voice_agent_flutter/ui/widgets/comic_panel.dart';

/// Pantalla inicial: logo + "AXEL AGENT".
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  static const String logoAsset = 'assets/branding/law.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Transform.rotate(
        angle: -0.05,
        child: ComicPanel(
          shadowColor: AppColors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                logoAsset,
                width: 200,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 10),
              Text('AXEL AGENT', style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}