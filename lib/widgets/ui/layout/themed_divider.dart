import 'package:flutter/material.dart';

/// A divider that automatically adapts to dark/light theme
class ThemedDivider extends StatelessWidget {
  final double height;
  final double indent;
  final double endIndent;

  const ThemedDivider({
    super.key,
    this.height = 1,
    this.indent = 0,
    this.endIndent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Divider(
      height: height,
      indent: indent,
      endIndent: endIndent,
      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
    );
  }
}
