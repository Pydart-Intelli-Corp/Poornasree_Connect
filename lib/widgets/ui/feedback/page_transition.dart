import 'package:flutter/material.dart';

enum TransitionType {
  fade,
  slide,
  slideUp,
  slideDown,
  scale,
  rotation,
  slideAndFade,
  scaleAndFade,
}

class PageTransition extends PageRouteBuilder {
  final Widget child;
  final TransitionType type;
  final Duration duration;
  final Duration reverseDuration;
  final Alignment alignment;
  final Offset? slideOffset;

  PageTransition({
    required this.child,
    this.type = TransitionType.slideAndFade,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration = const Duration(milliseconds: 250),
    this.alignment = Alignment.center,
    this.slideOffset,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, _) => child,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          settings: settings,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
              context,
              animation,
              secondaryAnimation,
              child,
              type,
              alignment,
              slideOffset,
            );
          },
        );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    TransitionType type,
    Alignment alignment,
    Offset? slideOffset,
  ) {
    switch (type) {
      case TransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case TransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: slideOffset ?? const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );

      case TransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );

      case TransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );

      case TransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          )),
          alignment: alignment,
          child: child,
        );

      case TransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );

      case TransitionType.slideAndFade:
        return SlideTransition(
          position: Tween<Offset>(
            begin: slideOffset ?? const Offset(0.0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case TransitionType.scaleAndFade:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
    }
  }
}

// Convenience classes for common transitions
class FadePageRoute extends PageTransition {
  FadePageRoute({
    required super.child,
    super.duration,
    super.settings,
  }) : super(type: TransitionType.fade);
}

class SlidePageRoute extends PageTransition {
  SlidePageRoute({
    required super.child,
    super.duration,
    super.slideOffset,
    super.settings,
  }) : super(type: TransitionType.slide);
}

class SlideUpPageRoute extends PageTransition {
  SlideUpPageRoute({
    required super.child,
    super.duration,
    super.settings,
  }) : super(type: TransitionType.slideUp);
}

class SlideDownPageRoute extends PageTransition {
  SlideDownPageRoute({
    required super.child,
    super.duration,
    super.settings,
  }) : super(type: TransitionType.slideDown);
}

class ScalePageRoute extends PageTransition {
  ScalePageRoute({
    required super.child,
    super.duration,
    super.alignment,
    super.settings,
  }) : super(type: TransitionType.scale);
}

class SlideAndFadePageRoute extends PageTransition {
  SlideAndFadePageRoute({
    required super.child,
    super.duration,
    super.slideOffset,
    super.settings,
  }) : super(type: TransitionType.slideAndFade);
}

class ScaleAndFadePageRoute extends PageTransition {
  ScaleAndFadePageRoute({
    required super.child,
    super.duration,
    super.settings,
  }) : super(type: TransitionType.scaleAndFade);
}

// Hero transition wrapper
class HeroPageRoute<T> extends PageRoute<T> {
  final Widget child;
  final String heroTag;
  final Duration duration;

  HeroPageRoute({
    required this.child,
    required this.heroTag,
    this.duration = const Duration(milliseconds: 400),
    super.settings,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

// Custom page route with enhanced hero transitions
class CustomPageRoute<T> extends MaterialPageRoute<T> {
  final TransitionType transitionType;
  final Duration customDuration;

  CustomPageRoute({
    required super.builder,
    this.transitionType = TransitionType.slideAndFade,
    this.customDuration = const Duration(milliseconds: 300),
    super.settings,
  });

  @override
  Duration get transitionDuration => customDuration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return PageTransition._buildTransition(
      context,
      animation,
      secondaryAnimation,
      child,
      transitionType,
      Alignment.center,
      null,
    );
  }
}