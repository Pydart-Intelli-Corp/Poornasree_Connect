import 'dart:ui';
import 'package:flutter/material.dart';
import 'flower_spinner.dart';

/// Snackbar type for styling
enum SnackbarType { info, success, error, warning, loading }

/// Modern, animated custom snackbar with glassmorphism design
class CustomSnackbar {
  static OverlayEntry? _currentOverlay;

  /// Get theme colors based on snackbar type
  static _SnackbarColors _getColors(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return _SnackbarColors(
          primary: const Color(0xFF10B981),
          background: const Color(0xFF10B981).withOpacity(0.12),
          border: const Color(0xFF10B981).withOpacity(0.3),
          icon: const Color(0xFF059669),
          text: const Color(0xFF065F46),
        );
      case SnackbarType.error:
        return _SnackbarColors(
          primary: const Color(0xFFEF4444),
          background: const Color(0xFFEF4444).withOpacity(0.12),
          border: const Color(0xFFEF4444).withOpacity(0.3),
          icon: const Color(0xFFDC2626),
          text: const Color(0xFF991B1B),
        );
      case SnackbarType.warning:
        return _SnackbarColors(
          primary: const Color(0xFFF59E0B),
          background: const Color(0xFFF59E0B).withOpacity(0.12),
          border: const Color(0xFFF59E0B).withOpacity(0.3),
          icon: const Color(0xFFD97706),
          text: const Color(0xFF92400E),
        );
      case SnackbarType.loading:
        return _SnackbarColors(
          primary: const Color(0xFF6366F1),
          background: const Color(0xFF6366F1).withOpacity(0.12),
          border: const Color(0xFF6366F1).withOpacity(0.3),
          icon: const Color(0xFF4F46E5),
          text: const Color(0xFF3730A3),
        );
      case SnackbarType.info:
        return _SnackbarColors(
          primary: const Color(0xFF3B82F6),
          background: const Color(0xFF3B82F6).withOpacity(0.12),
          border: const Color(0xFF3B82F6).withOpacity(0.3),
          icon: const Color(0xFF2563EB),
          text: const Color(0xFF1E40AF),
        );
    }
  }

  /// Get icon based on snackbar type
  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle_rounded;
      case SnackbarType.error:
        return Icons.error_rounded;
      case SnackbarType.warning:
        return Icons.warning_rounded;
      case SnackbarType.loading:
        return Icons.sync_rounded;
      case SnackbarType.info:
        return Icons.info_rounded;
    }
  }

  /// Dismiss current snackbar if any
  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Dismiss with animation callback (unused)
  // static void _dismissWithAnimation(VoidCallback onComplete) {
  //   onComplete();
  // }

  /// Main show method with full customization
  static void show(
    BuildContext context, {
    required String message,
    String? submessage,
    bool isLoading = false,
    bool isError = false,
    bool isSuccess = false,
    bool isWarning = false,
    Duration duration = const Duration(seconds: 4),
    double? progress,
    VoidCallback? onDismiss,
    bool dismissible = true,
  }) {
    // Determine type
    SnackbarType type = SnackbarType.info;
    if (isLoading) type = SnackbarType.loading;
    if (isError) type = SnackbarType.error;
    if (isSuccess) type = SnackbarType.success;
    if (isWarning) type = SnackbarType.warning;

    _showAnimated(
      context,
      message: message,
      submessage: submessage,
      type: type,
      duration: duration,
      progress: progress,
      onDismiss: onDismiss,
      dismissible: dismissible,
    );
  }

  /// Show animated snackbar
  static void _showAnimated(
    BuildContext context, {
    required String message,
    String? submessage,
    required SnackbarType type,
    required Duration duration,
    double? progress,
    VoidCallback? onDismiss,
    bool dismissible = true,
  }) {
    // Dismiss any existing snackbar
    dismiss();

    final overlay = Overlay.of(context);
    final colors = _getColors(type);

    _currentOverlay = OverlayEntry(
      builder: (context) => _AnimatedSnackbarWidget(
        message: message,
        submessage: submessage,
        type: type,
        colors: colors,
        duration: duration,
        progress: progress,
        dismissible: dismissible,
        onDismiss: () {
          // Let widget animate out before removing overlay
        },
        onAnimationComplete: () {
          dismiss();
          onDismiss?.call();
        },
      ),
    );

    overlay.insert(_currentOverlay!);

    // Auto dismiss (unless loading with no timeout) - handled by widget internally now
    // Animation will be triggered by the widget's timer
  }

  /// Show loading snackbar
  static void showLoading(
    BuildContext context, {
    required String message,
    String submessage = 'Please wait...',
    double? progress,
  }) {
    _showAnimated(
      context,
      message: message,
      submessage: submessage,
      type: SnackbarType.loading,
      duration: const Duration(minutes: 5),
      progress: progress,
      dismissible: false,
    );
  }

  /// Show error snackbar
  static void showError(
    BuildContext context, {
    required String message,
    String? submessage,
    Duration duration = const Duration(seconds: 5),
  }) {
    _showAnimated(
      context,
      message: message,
      submessage: submessage,
      type: SnackbarType.error,
      duration: duration,
    );
  }

  /// Show success snackbar
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? submessage,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showAnimated(
      context,
      message: message,
      submessage: submessage,
      type: SnackbarType.success,
      duration: duration,
    );
  }

  /// Show warning snackbar
  static void showWarning(
    BuildContext context, {
    required String message,
    String? submessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showAnimated(
      context,
      message: message,
      submessage: submessage,
      type: SnackbarType.warning,
      duration: duration,
    );
  }

  /// Show info snackbar
  static void showInfo(
    BuildContext context, {
    required String message,
    String? submessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showAnimated(
      context,
      message: message,
      submessage: submessage,
      type: SnackbarType.info,
      duration: duration,
    );
  }
}

/// Color scheme for snackbar
class _SnackbarColors {
  final Color primary;
  final Color background;
  final Color border;
  final Color icon;
  final Color text;

  _SnackbarColors({
    required this.primary,
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
  });
}

/// Animated snackbar widget
class _AnimatedSnackbarWidget extends StatefulWidget {
  final String message;
  final String? submessage;
  final SnackbarType type;
  final _SnackbarColors colors;
  final Duration duration;
  final double? progress;
  final bool dismissible;
  final VoidCallback onDismiss;
  final VoidCallback onAnimationComplete;

  const _AnimatedSnackbarWidget({
    required this.message,
    this.submessage,
    required this.type,
    required this.colors,
    required this.duration,
    this.progress,
    required this.dismissible,
    required this.onDismiss,
    required this.onAnimationComplete,
  });

  @override
  State<_AnimatedSnackbarWidget> createState() =>
      _AnimatedSnackbarWidgetState();
}

class _AnimatedSnackbarWidgetState extends State<_AnimatedSnackbarWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Slide & fade animation (slower for smoother effect)
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    // Progress bar animation
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideController.forward();
    if (widget.type != SnackbarType.loading) {
      _progressController.forward();
    }
    
    // Set up auto-dismiss timer
    if (widget.type != SnackbarType.loading || widget.duration.inMinutes < 5) {
      Future.delayed(widget.duration, () {
        if (mounted) {
          _triggerAutoDismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _slideController.reverse().then((_) {
      widget.onAnimationComplete();
    });
  }

  void _triggerAutoDismiss() {
    _slideController.reverse().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: GestureDetector(
                onHorizontalDragEnd: widget.dismissible
                    ? (details) {
                        if (details.primaryVelocity != null &&
                            details.primaryVelocity!.abs() > 100) {
                          _handleDismiss();
                        }
                      }
                    : null,
                onTap: widget.dismissible ? _handleDismiss : null,
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isSmallScreen ? screenWidth - 24 : 400,
                          minWidth: 280,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900.withOpacity(0.85)
                              : Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.colors.border,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.colors.primary.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                              spreadRadius: -4,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Main content
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Icon container with glow effect
                                  _buildIconContainer(isDark),
                                  const SizedBox(width: 14),
                                  // Text content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.message,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : widget.colors.text,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (widget.submessage != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.submessage!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: isDark
                                                  ? Colors.grey.shade400
                                                  : Colors.grey.shade600,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (widget.dismissible) ...[
                                    const SizedBox(width: 8),
                                    _buildCloseButton(isDark),
                                  ],
                                ],
                              ),
                            ),
                            // Progress indicator (removed for all types)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(bool isDark) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: widget.colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.colors.border.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.colors.primary.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: _buildAnimatedIcon(),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    switch (widget.type) {
      case SnackbarType.loading:
        return const FlowerSpinner(size: 22);
      case SnackbarType.success:
        return _AnimatedCheckmark(color: widget.colors.icon);
      case SnackbarType.error:
        return _AnimatedErrorIcon(color: widget.colors.icon);
      case SnackbarType.warning:
        return _AnimatedWarningIcon(color: widget.colors.icon);
      case SnackbarType.info:
        return _AnimatedIcon(
          icon: CustomSnackbar._getIcon(widget.type),
          color: widget.colors.icon,
          type: widget.type,
        );
    }
  }

  Widget _buildCloseButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleDismiss,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  // Widget _buildProgressBar() { // Unused
  //   return Container(
  //     height: 4,
  //     decoration: BoxDecoration(
  //       color: widget.colors.background,
  //       borderRadius: const BorderRadius.only(
  //         bottomLeft: Radius.circular(16),
  //         bottomRight: Radius.circular(16),
  //       ),
  //     ),
  //     child: LayoutBuilder(
  //       builder: (context, constraints) {
  //         return Stack(
  //           children: [
  //           Container(
  //             width: constraints.maxWidth * (widget.progress! / 100),
  //             decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 colors: [
  //                   widget.colors.primary,
  //                   widget.colors.primary.withOpacity(0.7),
  //                 ],
  //               ),
  //               borderRadius: const BorderRadius.only(
  //                 bottomLeft: Radius.circular(16),
  //                 bottomRight: Radius.circular(16),
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //       },
  //     ),
  //   );
  // }

  // Widget _buildTimerBar() { // Unused
  //   return AnimatedBuilder(
  //     animation: _progressController,
  //     builder: (context, child) {
  //       return Container(
  //         height: 3,
  //         decoration: const BoxDecoration(
  //           borderRadius: BorderRadius.only(
  //             bottomLeft: Radius.circular(16),
  //             bottomRight: Radius.circular(16),
  //           ),
  //         ),
  //         child: LayoutBuilder(
  //           builder: (context, constraints) {
  //             return Stack(
  //               children: [
  //                 // Background
  //                 Container(
  //                   width: constraints.maxWidth,
  //                   decoration: BoxDecoration(
  //                     color: widget.colors.background,
  //                     borderRadius: const BorderRadius.only(
  //                       bottomLeft: Radius.circular(16),
  //                       bottomRight: Radius.circular(16),
  //                     ),
  //                   ),
  //                 ),
  //                 // Progress
  //                 Container(
  //                   width:
  //                       constraints.maxWidth * (1 - _progressController.value),
  //                   decoration: BoxDecoration(
  //                     gradient: LinearGradient(
  //                       colors: [
  //                         widget.colors.primary,
  //                         widget.colors.primary.withOpacity(0.6),
  //                       ],
  //                     ),
  //                     borderRadius: const BorderRadius.only(
  //                       bottomLeft: Radius.circular(16),
  //                       bottomRight: Radius.circular(16),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }
}

/// Animated checkmark with drawing effect
class _AnimatedCheckmark extends StatefulWidget {
  final Color color;

  const _AnimatedCheckmark({required this.color});

  @override
  State<_AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<_AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: CustomPaint(
            size: const Size(24, 24),
            painter: _CheckmarkPainter(
              progress: _progressAnimation.value,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Checkmark path
    final startX = size.width * 0.2;
    final startY = size.height * 0.5;
    final midX = size.width * 0.4;
    final midY = size.height * 0.7;
    final endX = size.width * 0.8;
    final endY = size.height * 0.3;

    path.moveTo(startX, startY);
    
    if (progress <= 0.5) {
      // First segment (start to mid)
      final segmentProgress = progress / 0.5;
      path.lineTo(
        startX + (midX - startX) * segmentProgress,
        startY + (midY - startY) * segmentProgress,
      );
    } else {
      // Complete first segment
      path.lineTo(midX, midY);
      
      // Second segment (mid to end)
      final segmentProgress = (progress - 0.5) / 0.5;
      path.lineTo(
        midX + (endX - midX) * segmentProgress,
        midY + (endY - midY) * segmentProgress,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Animated error icon with shake effect
class _AnimatedErrorIcon extends StatefulWidget {
  final Color color;

  const _AnimatedErrorIcon({required this.color});

  @override
  State<_AnimatedErrorIcon> createState() => _AnimatedErrorIconState();
}

class _AnimatedErrorIconState extends State<_AnimatedErrorIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 12.5),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 12.5),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _shakeAnimation.value,
            child: Icon(
              Icons.error_rounded,
              color: widget.color,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}

/// Animated warning icon with pulse effect
class _AnimatedWarningIcon extends StatefulWidget {
  final Color color;

  const _AnimatedWarningIcon({required this.color});

  @override
  State<_AnimatedWarningIcon> createState() => _AnimatedWarningIconState();
}

class _AnimatedWarningIconState extends State<_AnimatedWarningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: Icon(
            Icons.warning_rounded,
            color: widget.color,
            size: 24,
          ),
        );
      },
    );
  }
}

/// Animated icon with entrance effect
class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final SnackbarType type;

  const _AnimatedIcon({
    required this.icon,
    required this.color,
    required this.type,
  });

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Icon(widget.icon, color: widget.color, size: 22),
          ),
        );
      },
    );
  }
}
