import 'package:flutter/material.dart';

class FlowerSpinner extends StatefulWidget {
  final double size;
  final bool isLoading;
  final Color? color;

  const FlowerSpinner({
    super.key,
    this.size = 24.0,
    this.isLoading = true,
    this.color,
  });

  @override
  State<FlowerSpinner> createState() => _FlowerSpinnerState();
}

class _FlowerSpinnerState extends State<FlowerSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
    
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(FlowerSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
        // Decelerate to next full rotation
        _controller.animateTo(1.0, 
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Image.asset(
            'assets/images/flower.png',
            width: widget.size,
            height: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}