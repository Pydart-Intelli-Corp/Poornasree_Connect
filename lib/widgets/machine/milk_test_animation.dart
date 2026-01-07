import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A reusable animated widget for electronic sensor testing visualization
/// Shows a realistic electronic sensor diagnostic animation
class MilkTestAnimation extends StatefulWidget {
  final Color primaryColor;
  final double size;

  const MilkTestAnimation({
    super.key,
    this.primaryColor = const Color(0xFFf59e0b),
    this.size = 44,
  });

  @override
  State<MilkTestAnimation> createState() => _MilkTestAnimationState();
}

class _MilkTestAnimationState extends State<MilkTestAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _signalController;
  late AnimationController _scanController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _signalAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Pulse animation for center chip
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Signal flow animation
    _signalController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _signalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _signalController, curve: Curves.linear),
    );

    // Scan line animation
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _signalController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circuit board background pattern
          _buildCircuitPattern(),
          // Signal waves radiating outward
          _buildSignalWaves(),
          // Center sensor chip
          _buildSensorChip(),
          // Data flow indicators
          _buildDataFlow(),
          // Scanning ring
          _buildScanRing(),
        ],
      ),
    );
  }

  Widget _buildCircuitPattern() {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _CircuitPainter(
        color: widget.primaryColor.withValues(alpha: 0.15),
      ),
    );
  }

  Widget _buildSignalWaves() {
    return AnimatedBuilder(
      animation: _signalController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            final delay = (index * 0.33 + _signalAnimation.value) % 1.0;
            final scale = 0.4 + (delay * 0.6);
            final opacity = (1.0 - delay) * 0.5;

            return Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size * 0.8,
                height: widget.size * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.primaryColor.withValues(alpha: opacity),
                    width: 1.5,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSensorChip() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: widget.size * 0.35,
          height: widget.size * 0.35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFF1a1a2e),
            border: Border.all(
              color: widget.primaryColor.withValues(alpha: _pulseAnimation.value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: _pulseAnimation.value * 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Chip grid pattern
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(widget.size * 0.03),
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                children: List.generate(4, (index) {
                  final isActive = (index + (_signalAnimation.value * 4).floor()) % 4 == 0;
                  return Container(
                    decoration: BoxDecoration(
                      color: isActive
                          ? widget.primaryColor.withValues(alpha: 0.8)
                          : widget.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataFlow() {
    return AnimatedBuilder(
      animation: _signalController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Top data line
            _buildDataLine(0, -widget.size * 0.35),
            // Bottom data line
            _buildDataLine(math.pi, widget.size * 0.35),
            // Left data line
            _buildDataLine(math.pi * 0.5, 0, isHorizontal: true, offsetX: -widget.size * 0.35),
            // Right data line
            _buildDataLine(math.pi * 1.5, 0, isHorizontal: true, offsetX: widget.size * 0.35),
          ],
        );
      },
    );
  }

  Widget _buildDataLine(double angle, double offsetY, {bool isHorizontal = false, double offsetX = 0}) {
    final progress = _signalAnimation.value;
    final dotCount = 3;

    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: SizedBox(
        width: isHorizontal ? widget.size * 0.15 : 4,
        height: isHorizontal ? 4 : widget.size * 0.15,
        child: Stack(
          children: List.generate(dotCount, (index) {
            final dotProgress = ((progress + index * 0.33) % 1.0);
            final opacity = math.sin(dotProgress * math.pi);
            final position = dotProgress * (isHorizontal ? widget.size * 0.15 : widget.size * 0.15);

            return Positioned(
              left: isHorizontal ? position : 0,
              top: isHorizontal ? 0 : position,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.primaryColor.withValues(alpha: opacity * 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: opacity * 0.5),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildScanRing() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        final rotation = _scanAnimation.value * 2 * math.pi;

        return Transform.rotate(
          angle: rotation,
          child: Container(
            width: widget.size * 0.7,
            height: widget.size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.transparent,
                  widget.primaryColor.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.6],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CircuitPainter extends CustomPainter {
  final Color color;

  _CircuitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.25;

    // Draw circuit traces from center outward
    // Top
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, 2),
      paint,
    );
    // Bottom
    canvas.drawLine(
      Offset(center.dx, center.dy + radius),
      Offset(center.dx, size.height - 2),
      paint,
    );
    // Left
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(2, center.dy),
      paint,
    );
    // Right
    canvas.drawLine(
      Offset(center.dx + radius, center.dy),
      Offset(size.width - 2, center.dy),
      paint,
    );

    // Corner dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(2, 2), 2, dotPaint);
    canvas.drawCircle(Offset(size.width - 2, 2), 2, dotPaint);
    canvas.drawCircle(Offset(2, size.height - 2), 2, dotPaint);
    canvas.drawCircle(Offset(size.width - 2, size.height - 2), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
