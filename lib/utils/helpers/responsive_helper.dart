import 'package:flutter/material.dart';

class ResponsiveHelper {
  /// Get responsive value based on screen width
  static double getResponsiveValue({
    required BuildContext context,
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= 1024 && desktop != null) {
      return desktop;
    } else if (width >= 600 && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// Get responsive font size
  static double getFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      // Small phones
      return baseSize * 0.9;
    } else if (width >= 600 && width < 1024) {
      // Tablets
      return baseSize * 1.1;
    } else if (width >= 1024) {
      // Desktop
      return baseSize * 1.2;
    } else {
      // Normal phones
      return baseSize;
    }
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, double baseSpacing) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return baseSpacing * 0.8;
    } else if (width >= 600) {
      return baseSpacing * 1.2;
    } else {
      return baseSpacing;
    }
  }

  /// Get horizontal padding based on screen width
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return 16.0;
    } else if (width >= 600 && width < 1024) {
      return 40.0;
    } else if (width >= 1024) {
      return 80.0;
    } else {
      return 24.0;
    }
  }

  /// Get vertical padding based on screen height
  static double getVerticalPadding(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    
    if (height < 600) {
      return 16.0;
    } else if (height >= 800) {
      return 40.0;
    } else {
      return 24.0;
    }
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Get max content width for centered layouts
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      return double.infinity;
    } else if (width < 1024) {
      return 600.0;
    } else {
      return 800.0;
    }
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return baseSize * 0.9;
    } else if (width >= 600) {
      return baseSize * 1.1;
    } else {
      return baseSize;
    }
  }

  /// Get screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return ScreenSize.small;
    } else if (width < 600) {
      return ScreenSize.medium;
    } else if (width < 1024) {
      return ScreenSize.large;
    } else {
      return ScreenSize.extraLarge;
    }
  }
}

enum ScreenSize {
  small,    // < 360
  medium,   // 360 - 599
  large,    // 600 - 1023
  extraLarge, // >= 1024
}
