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

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 20,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: 16,
            color: Color(0xFFF5E39B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              (message ?? 'Включен демо-режим').toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
