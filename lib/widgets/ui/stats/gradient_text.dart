import 'package:flutter/material.dart';

class GradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final List<Color>? gradientColors;
  final TextAlign? textAlign;

  const GradientText({
    super.key,
    required this.text,
    this.fontSize = 36,
    this.fontWeight = FontWeight.w800,
    this.gradientColors,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: gradientColors ?? [Colors.white, const Color(0xFFF0F0F0)],
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
