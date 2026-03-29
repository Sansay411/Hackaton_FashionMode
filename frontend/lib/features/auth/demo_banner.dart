import 'package:flutter/material.dart';

import '../../core/widgets/glass_panel.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({
    super.key,
    required this.visible,
    this.message,
  });

  final bool visible;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 20,
      backgroundColor: colorScheme.surface,
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 16,
            color: colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (message ?? 'Включен демо-режим').toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
