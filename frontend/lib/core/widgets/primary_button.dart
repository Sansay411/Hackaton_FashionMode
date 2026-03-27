import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
    this.isExpanded = true,
    this.minHeight = 52,
    this.fontSize = 13,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isExpanded;
  final double minHeight;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: fontSize);

    final button = isOutlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, minHeight),
              backgroundColor: Colors.white.withValues(alpha: 0.02),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              label.toUpperCase(),
              style: baseStyle,
            ),
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF5E39B),
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, minHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              label.toUpperCase(),
              style: baseStyle?.copyWith(color: Colors.black),
            ),
          );

    if (isExpanded) {
      return button;
    }

    return IntrinsicWidth(child: button);
  }
}
