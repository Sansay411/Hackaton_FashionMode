import 'package:flutter/material.dart';

import '../utils/display_text.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    late final Color background;
    late final Color foreground;
    late final BorderSide border;

    switch (normalized) {
      case 'ready':
      case 'completed':
        background = const Color(0xFFF5E39B);
        foreground = Colors.black;
        border = BorderSide.none;
        break;
      case 'in_production':
      case 'active':
        background = Colors.white.withValues(alpha: 0.10);
        foreground = Colors.white;
        border = BorderSide(color: Colors.white.withValues(alpha: 0.10));
        break;
      case 'accepted':
      case 'queued':
        background = Colors.white.withValues(alpha: 0.03);
        foreground = Colors.white;
        border = BorderSide(color: Colors.white.withValues(alpha: 0.16));
        break;
      default:
        background = Colors.white.withValues(alpha: 0.03);
        foreground = Colors.white70;
        border = BorderSide(color: Colors.white.withValues(alpha: 0.10));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: border == BorderSide.none ? null : Border.fromBorderSide(border),
      ),
      child: Text(
        statusLabel(status).toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontSize: 11,
            ),
      ),
    );
  }
}
