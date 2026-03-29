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
    final scheme = Theme.of(context).colorScheme;
    final normalized = status.toLowerCase();
    late final Color background;
    late final Color foreground;
    late final BorderSide border;

    switch (normalized) {
      case 'ready':
      case 'completed':
        background = scheme.secondaryContainer;
        foreground = scheme.primary;
        border = BorderSide.none;
        break;
      case 'high':
        background = scheme.primary;
        foreground = scheme.onPrimary;
        border = BorderSide.none;
        break;
      case 'medium':
        background = scheme.onPrimary;
        foreground = scheme.onSurface;
        border = BorderSide(color: scheme.outline);
        break;
      case 'low':
        background = scheme.onPrimary;
        foreground = scheme.onSurfaceVariant;
        border = BorderSide(color: scheme.outline);
        break;
      case 'in_production':
      case 'in_progress':
      case 'active':
        background = scheme.surface;
        foreground = scheme.onSurface;
        border = BorderSide(color: scheme.outline);
        break;
      case 'assigned':
        background = scheme.surface;
        foreground = scheme.onSurface;
        border = BorderSide(color: scheme.outline);
        break;
      case 'accepted':
      case 'paid':
      case 'queued':
        background = scheme.onPrimary;
        foreground = scheme.onSurface;
        border = BorderSide(color: scheme.outline);
        break;
      default:
        background = scheme.onPrimary;
        foreground = scheme.onSurfaceVariant;
        border = BorderSide(color: scheme.outline);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border:
            border == BorderSide.none ? null : Border.fromBorderSide(border),
      ),
      child: Text(
        statusLabel(status),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontSize: 9,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
