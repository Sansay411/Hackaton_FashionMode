import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
    this.isGhost = false,
    this.isExpanded = true,
    this.minHeight = 52,
    this.fontSize = 13,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isGhost;
  final bool isExpanded;
  final double minHeight;
  final double fontSize;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final baseStyle = theme.textTheme.labelLarge?.copyWith(fontSize: fontSize);

    final button = isGhost
        ? TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              minimumSize: Size(double.infinity, minHeight),
              backgroundColor: backgroundColor ?? Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              label.toUpperCase(),
              style: baseStyle?.copyWith(
                color: foregroundColor ?? scheme.onSurface,
              ),
            ),
          )
        : isOutlined
            ? OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, minHeight),
                  backgroundColor: backgroundColor ?? Colors.transparent,
                  side: BorderSide(color: scheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: baseStyle?.copyWith(
                    color: foregroundColor ?? scheme.onSurface,
                  ),
                ),
              )
            : FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor: backgroundColor ?? scheme.primary,
                  foregroundColor: foregroundColor ?? scheme.onPrimary,
                  minimumSize: Size(double.infinity, minHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: baseStyle?.copyWith(
                    color: foregroundColor ?? scheme.onPrimary,
                  ),
                ),
              );

    if (isExpanded) {
      return button;
    }

    return IntrinsicWidth(child: button);
  }
}
