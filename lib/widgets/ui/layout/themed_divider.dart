import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

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
    return Divider(
      height: height,
      indent: indent,
      endIndent: endIndent,
      color: context.borderColor,
    );
  }
}
