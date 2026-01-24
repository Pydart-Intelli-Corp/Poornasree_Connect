import 'package:flutter/material.dart';
import '../../../utils/utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/lactosure_reading.dart';
import '../feedback/flower_spinner.dart';

/// Live test overlay that shows real-time progress with animated ticks
class LiveTestOverlay extends StatefulWidget {
  final List<String> machines;
  final ValueNotifier<Set<String>> receivedMachinesNotifier;
  final ValueNotifier<bool> testCompleteNotifier;
  final Map<String, LactosureReading> machineReadings;
  final VoidCallback onDismiss;

  const LiveTestOverlay({
    super.key,
    required this.machines,
    required this.receivedMachinesNotifier,
    required this.testCompleteNotifier,
    required this.machineReadings,
    required this.onDismiss,
  });

  @override
  State<LiveTestOverlay> createState() => _LiveTestOverlayState();
}

class _LiveTestOverlayState extends State<LiveTestOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Track which machines have been animated
  final Set<String> _animatedMachines = {};

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
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

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _slideController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  String _normalizeId(String id) {
    return id.replaceFirst(RegExp(r'^0+'), '');
  }

  bool _machineReceivedData(String machineId, Set<String> receivedMachines) {
    final normalizedId = _normalizeId(machineId);
    for (final received in receivedMachines) {
      if (_normalizeId(received) == normalizedId || received == machineId) {
        return true;
      }
    }
    return false;
  }

  String _formatMachineId(String id) {
    final normalized = id.replaceFirst(RegExp(r'^0+'), '');
    return normalized.isEmpty ? '0' : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: widget.testCompleteNotifier,
      builder: (context, isComplete, _) {
        return ValueListenableBuilder<Set<String>>(
          valueListenable: widget.receivedMachinesNotifier,
          builder: (context, receivedMachines, _) {
            final allReceived =
                receivedMachines.length >= widget.machines.length;

            final headerColor = isComplete
                ? (allReceived
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B))
                : const Color(0xFF3B82F6);

            final headerIcon = isComplete
                ? (allReceived
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded)
                : Icons.science_rounded;

            final headerText = isComplete
                ? (allReceived ? AppLocalizations().tr('test_complete') : AppLocalizations().tr('test_timeout'))
                : AppLocalizations().tr('testing');

            final subText = isComplete
                ? '${receivedMachines.length}/${widget.machines.length} ${AppLocalizations().tr('machines_responded')}'
                : '${AppLocalizations().tr('waiting_for_machines').replaceAll('{count}', widget.machines.length.toString())}';

            return Positioned(
              top: MediaQuery.of(context).padding.top + SizeConfig.spaceMedium,
              left: SizeConfig.spaceMedium,
              right: SizeConfig.spaceMedium,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: GestureDetector(
                      onTap: isComplete ? _handleDismiss : null,
                      onHorizontalDragEnd: isComplete
                          ? (details) {
                              if (details.primaryVelocity != null &&
                                  details.primaryVelocity!.abs() > 100) {
                                _handleDismiss();
                              }
                            }
                          : null,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: SizeConfig.normalize(360),
                            minWidth: SizeConfig.normalize(280),
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E).withOpacity(0.95)
                                : Colors.white.withOpacity(0.98),
                            borderRadius: BorderRadius.circular(SizeConfig.radiusLarge),
                            border: Border.all(
                              color: headerColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: headerColor.withOpacity(0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                                spreadRadius: -4,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header
                              _buildHeader(
                                isDark: isDark,
                                isComplete: isComplete,
                                headerColor: headerColor,
                                headerIcon: headerIcon,
                                headerText: headerText,
                                subText: subText,
                              ),

                              // Machine list
                              Padding(
                                padding: EdgeInsets.all(SizeConfig.spaceRegular),
                                child: Column(
                                  children: widget.machines.asMap().entries.map(
                                    (entry) {
                                      final index = entry.key;
                                      final machineId = entry.value;
                                      final received = _machineReceivedData(
                                        machineId,
                                        receivedMachines,
                                      );
                                      final isNewlyReceived =
                                          received &&
                                          !_animatedMachines.contains(
                                            machineId,
                                          );

                                      // Mark as animated
                                      if (isNewlyReceived) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              _animatedMachines.add(machineId);
                                            });
                                      }

                                      return LiveMachineStatusRow(
                                        key: ValueKey('machine_$machineId'),
                                        machineId: _formatMachineId(machineId),
                                        received: received,
                                        isComplete: isComplete,
                                        animateNow: isNewlyReceived,
                                        delay: Duration(
                                          milliseconds: index * 100,
                                        ),
                                      );
                                    },
                                  ).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader({
    required bool isDark,
    required bool isComplete,
    required Color headerColor,
    required IconData headerIcon,
    required String headerText,
    required String subText,
  }) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.spaceRegular),
      decoration: BoxDecoration(
        color: headerColor.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(SizeConfig.radiusLarge),
          topRight: Radius.circular(SizeConfig.radiusLarge),
        ),
      ),
      child: Row(
        children: [
          isComplete
              ? AnimatedHeaderIcon(icon: headerIcon, color: headerColor)
              : PulsingIcon(icon: headerIcon, color: headerColor),
          SizedBox(width: SizeConfig.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerText,
                  style: TextStyle(
                    fontSize: SizeConfig.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                  ),
                ),
                SizedBox(height: SizeConfig.spaceTiny),
                Text(
                  subText,
                  style: TextStyle(
                    fontSize: SizeConfig.fontSizeSmall,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          // Close button (always visible)
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: context.textSecondaryColor,
                size: SizeConfig.iconSizeSmall,
              ),
              onPressed: _handleDismiss,
              tooltip: AppLocalizations().tr('close'),
              padding: EdgeInsets.all(SizeConfig.spaceXSmall),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing icon for loading state
class PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double? size;

  const PulsingIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size,
  });

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size ?? SizeConfig.iconSizeXLarge;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, color: widget.color, size: iconSize * 0.55),
      ),
    );
  }
}

/// Animated header icon with bounce effect
class AnimatedHeaderIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double? size;

  const AnimatedHeaderIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size,
  });

  @override
  State<AnimatedHeaderIcon> createState() => _AnimatedHeaderIconState();
}

class _AnimatedHeaderIconState extends State<AnimatedHeaderIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
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
    final iconSize = widget.size ?? SizeConfig.iconSizeXLarge;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(SizeConfig.radiusMedium),
            ),
            child: Icon(
              widget.icon,
              color: widget.color,
              size: iconSize * 0.55,
            ),
          ),
        );
      },
    );
  }
}

/// Live machine status row with animated tick
class LiveMachineStatusRow extends StatefulWidget {
  final String machineId;
  final bool received;
  final bool isComplete;
  final bool animateNow;
  final Duration delay;

  const LiveMachineStatusRow({
    super.key,
    required this.machineId,
    required this.received,
    required this.isComplete,
    this.animateNow = false,
    this.delay = Duration.zero,
  });

  @override
  State<LiveMachineStatusRow> createState() => _LiveMachineStatusRowState();
}

class _LiveMachineStatusRowState extends State<LiveMachineStatusRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.received && !_hasAnimated) {
      _hasAnimated = true;
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant LiveMachineStatusRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate when newly received
    if (widget.received && !oldWidget.received && !_hasAnimated) {
      _hasAnimated = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.spaceXSmall + 2),
      child: Row(
        children: [
          // Machine icon
          Container(
            width: SizeConfig.iconSizeLarge,
            height: SizeConfig.iconSizeLarge,
            decoration: BoxDecoration(
              color: widget.received
                  ? const Color(0xFF10B981).withOpacity(0.15)
                  : context.surfaceColor,
              borderRadius: BorderRadius.circular(SizeConfig.radiusMedium),
            ),
            child: Icon(
              Icons.precision_manufacturing_rounded,
              color: widget.received ? const Color(0xFF10B981) : context.textSecondaryColor,
              size: SizeConfig.iconSizeSmall,
            ),
          ),
          SizedBox(width: SizeConfig.spaceMedium),

          // Machine name
          Expanded(
            child: Text(
              '${AppLocalizations().tr('machine')} ${widget.machineId}',
              style: TextStyle(
                fontSize: SizeConfig.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
          ),

          // Status indicator
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: widget.received
                ? ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      key: const ValueKey('received'),
                      width: SizeConfig.iconSizeLarge,
                      height: SizeConfig.iconSizeLarge,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: const Color(0xFF10B981),
                        size: SizeConfig.iconSizeSmall,
                      ),
                    ),
                  )
                : widget.isComplete
                ? Container(
                    key: const ValueKey('failed'),
                    width: SizeConfig.iconSizeLarge,
                    height: SizeConfig.iconSizeLarge,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: const Color(0xFFEF4444),
                      size: SizeConfig.iconSizeSmall,
                    ),
                  )
                : FlowerSpinner(key: const ValueKey('loading'), size: SizeConfig.iconSizeMedium),
          ),
        ],
      ),
    );
  }
}

/// Animated status icon (tick or cross) with bounce effect
class AnimatedStatusIcon extends StatefulWidget {
  final bool received;
  final Duration delay;
  final double? size;

  const AnimatedStatusIcon({
    super.key,
    required this.received,
    this.delay = Duration.zero,
    this.size,
  });

  @override
  State<AnimatedStatusIcon> createState() => _AnimatedStatusIconState();
}

class _AnimatedStatusIconState extends State<AnimatedStatusIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _showIcon = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _rotateAnimation = Tween<double>(
      begin: -0.2,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _showIcon = true);
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size ?? SizeConfig.iconSizeLarge;
    if (!_showIcon) {
      return SizedBox(width: iconSize, height: iconSize);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: widget.received
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.received
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                            .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.received ? Icons.check_rounded : Icons.close_rounded,
                color: Colors.white,
                size: iconSize * 0.625,
              ),
            ),
          ),
        );
      },
    );
  }
}
