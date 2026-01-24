import 'package:flutter/material.dart';
import '../feedback/flower_spinner.dart';
import '../../../utils/utils.dart';
import '../../../utils/helpers/size_config.dart';

enum CustomButtonType { primary, secondary, outline, text }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = CustomButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case CustomButtonType.primary:
        return AppTheme.primaryGreen;
      case CustomButtonType.secondary:
        return AppTheme.primaryTeal;
      case CustomButtonType.outline:
        return Colors.transparent;
      case CustomButtonType.text:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    switch (widget.type) {
      case CustomButtonType.primary:
      case CustomButtonType.secondary:
        return Colors.white;
      case CustomButtonType.outline:
      case CustomButtonType.text:
        return AppTheme.primaryGreen;
    }
  }

  BorderSide? _getBorder() {
    switch (widget.type) {
      case CustomButtonType.outline:
        return BorderSide(
          color: AppTheme.primaryGreen,
          width: SizeConfig.normalize(2),
        );
      default:
        return null;
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.isFullWidth ? double.infinity : widget.width,
            height: widget.height ?? SizeConfig.normalize(56),
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              onTap: widget.isLoading ? null : widget.onPressed,
              child: Container(
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(SizeConfig.radiusRegular),
                  border: _getBorder() != null
                      ? Border.all(
                          color: _getBorder()!.color,
                          width: _getBorder()!.width,
                        )
                      : null,
                  boxShadow:
                      widget.type == CustomButtonType.primary ||
                          widget.type == CustomButtonType.secondary
                      ? [
                          BoxShadow(
                            color: _getBackgroundColor().withOpacity(0.3),
                            blurRadius: SizeConfig.normalize(8),
                            offset: Offset(0, SizeConfig.normalize(4)),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding:
                        widget.padding ??
                        EdgeInsets.symmetric(
                          horizontal: SizeConfig.spaceRegular + 4,
                          vertical: SizeConfig.spaceRegular,
                        ),
                    child: widget.isLoading
                        ? Center(
                            child: FlowerSpinner(
                              size: SizeConfig.iconSizeMedium,
                              color: _getTextColor(),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: _getTextColor(),
                                  size: SizeConfig.iconSizeMedium,
                                ),
                                SizedBox(width: SizeConfig.spaceSmall),
                              ],
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: Text(
                                    widget.text,
                                    style: TextStyle(
                                      color: _getTextColor(),
                                      fontSize: SizeConfig.fontSizeRegular,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
