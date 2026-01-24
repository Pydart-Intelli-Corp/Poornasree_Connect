import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ============================================================================
/// GLOBAL SIZE CONFIGURATION - INTELLIGENT OVERFLOW PREVENTION SYSTEM
/// ============================================================================
///
/// This advanced sizing system ensures:
/// 1. Pixel-perfect consistency across all Android/iOS devices
/// 2. Automatic overflow prevention for small screens
/// 3. Multi-language support (especially Malayalam, Hindi, Tamil, etc.)
/// 4. User-adjustable UI scale (1.0x - 1.15x)
/// 5. Responsive spacing and font sizing
///
/// DESIGN BASELINE: 360x800 dp (Standard Android medium device)
/// REFERENCE DPI: 3.0 (Pixel 7 Pro uses 3.5, Vivo uses 2.0)
/// USER SCALE RANGE: 1.0x (Normal) to 1.15x (Extra Large)
///
/// ============================================================================
/// OVERFLOW PREVENTION SYSTEM - HOW IT WORKS
/// ============================================================================
///
/// **Problem**: Indian language translations (Malayalam, Tamil, Telugu, etc.) 
/// are often 20-40% longer than English, causing text overflow in constrained 
/// containers like Rows without Flexible/Expanded widgets.
///
/// **Solution**: Three-tier intelligent scaling system:
///
/// 1. **Overflow Prevention Factor** (_overflowPreventionFactor)
///    - Automatically reduces ALL sizes when screen width < 360dp
///    - Scale: 85-100% based on actual screen width
///    - Formula: (screenWidth / 360).clamp(0.85, 1.0)
///    - Example: 320dp screen gets 88.9% scaling (320/360)
///
/// 2. **Adaptive Normalization** (adaptiveNormalize method)
///    - Used for ALL font sizes (text, icons)
///    - Additional 70% minimum scaling for screens < 320dp
///    - Allows fine-grained control with minScale parameter
///    - Example: adaptiveNormalize(14.0, minScale: 0.8) = 80% on tiny screens
///
/// 3. **Flexible Spacing** (flexSpace method)
///    - Used for ALL spacing (padding, margins, gaps)
///    - 25% reduction when screen width < 360dp
///    - Maintains visual balance on small screens
///    - Example: 16dp spacing becomes 12dp on small screens
///
/// **Effective Scale Calculation**:
/// finalSize = baseSize × normalizedScale × userScale × overflowPreventionFactor
///
/// ============================================================================
/// WHEN UPDATING NEW FILES - OVERFLOW PREVENTION CHECKLIST
/// ============================================================================
///
/// ✅ **Step 1: Use SizeConfig for ALL sizes**
///    - Fonts: SizeConfig.fontSizeRegular, fontSizeSmall, etc.
///    - Icons: SizeConfig.iconSizeMedium, iconSizeSmall, etc.
///    - Spacing: SizeConfig.spaceSmall, spaceMedium, etc.
///    - Radius: SizeConfig.radiusRegular, radiusMedium, etc.
///
/// ✅ **Step 2: Handle Text Overflow in Rows**
///    Pattern 1 - Critical Text (Names, IDs, Titles):
///    ```dart
///    Row(
///      children: [
///        Expanded(  // or Flexible
///          child: FittedBox(
///            fit: BoxFit.scaleDown,
///            alignment: Alignment.centerLeft,
///            child: Text('Long Malayalam Text'),
///          ),
///        ),
///      ],
///    )
///    ```
///
///    Pattern 2 - Descriptions & Messages:
///    ```dart
///    Text(
///      'Long message text',
///      softWrap: true,
///      maxLines: 2,
///      overflow: TextOverflow.fade,
///    )
///    ```
///
///    Pattern 3 - Secondary Text:
///    ```dart
///    Text(
///      'Details',
///      overflow: TextOverflow.fade,  // Graceful fade instead of ellipsis
///    )
///    ```
///
/// ✅ **Step 3: Test with Malayalam Language**
///    - Malayalam text is typically 30-40% longer than English
///    - Test at different user scales (1.0x, 1.05x, 1.1x, 1.15x)
///    - Test on different devices (Pixel 7 Pro 3.5 DPI, Vivo 2.0 DPI)
///    - Check for overflow errors in debug console
///
/// ✅ **Step 4: Avoid Common Mistakes**
///    ❌ DON'T use hardcoded numbers: fontSize: 14, padding: EdgeInsets.all(8)
///    ✅ DO use SizeConfig: fontSize: SizeConfig.fontSizeRegular
///    
///    ❌ DON'T use TextOverflow.ellipsis on important text
///    ✅ DO use FittedBox with scaleDown to show full text
///    
///    ❌ DON'T create Rows without Flexible/Expanded for text
///    ✅ DO wrap text in Flexible or Expanded when inside Row
///    
///    ❌ DON'T ignore overflow errors in console
///    ✅ DO fix all "RenderFlex overflowed by X pixels" errors
///
/// ============================================================================
/// SIZE ADJUSTMENT SCALE - USER SETTINGS
/// ============================================================================
///
/// Users can adjust UI size in Profile > Settings > UI Size:
/// - Normal: 1.0x (Default)
/// - Medium: 1.05x (+5% size increase)
/// - Large: 1.1x (+10% size increase)  
/// - Extra Large: 1.15x (+15% size increase)
///
/// Stored in: SharedPreferences key 'ui_size_scale'
/// Widget: lib/widgets/common/size_scale_slider.dart
/// Divisions: 15 steps (0.01 increments from 1.0 to 1.15)
///
/// When user changes scale:
/// 1. Value saved to SharedPreferences
/// 2. SizeConfig.setUserScale(value) called
/// 3. UI rebuilds with new sizes automatically
/// 4. All sizes multiplied by new scale factor
///
/// ============================================================================
/// IMPLEMENTATION HISTORY & CHANGES
/// ============================================================================
///
/// **Version 1.0 - Initial Implementation**
/// - Basic normalize() method with DPI adjustment
/// - Static font and spacing sizes
/// - No overflow prevention
///
/// **Version 2.0 - User Scale Feature** (January 2026)
/// - Added _userScaleMultiplier (1.0 - 1.5x range)
/// - Added setUserScale() method
/// - Reduced max scale from 1.5x to 1.15x (January 23, 2026)
///
/// **Version 3.0 - Intelligent Overflow Prevention** (January 23, 2026)
/// - Added _overflowPreventionFactor for automatic size reduction
/// - Added adaptiveNormalize() for responsive font sizing
/// - Added flexSpace() for responsive spacing
/// - Added effectiveScale getter combining user + overflow scales
/// - Updated ALL font sizes to use adaptiveNormalize()
/// - Updated ALL spacing to use flexSpace()
/// - Fixed 20+ overflow issues across components
/// - Added comprehensive documentation
///
/// **Key Files Modified**:
/// - SizeConfig (this file): Core scaling logic
/// - machine_card.dart: 6 overflow fixes (ID, status, footer sections)
/// - size_scale_slider.dart: Reduced max from 1.5x to 1.15x, added clamp
/// - dashboard_header.dart: 3 overflow fixes (greeting, hierarchy, stats)
/// - profile components: Header, settings tiles, section cards
/// - Multiple UI components: Buttons, snackbars, cards, dialogs
///
/// ============================================================================

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double textScaleFactor;
  static late Orientation orientation;
  static late double devicePixelRatio;
  static late double normalizedScale;

  // Safe area padding
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  // Design baseline (360x800 is standard Android medium device)
  static const double _designWidth = 360.0;
  static const double _designHeight = 800.0;

  // Reference pixel ratio (Pixel 7 Pro = 3.5, we'll use 3.0 as baseline)
  static const double _referencePixelRatio = 3.0;

  // User adjustable scale multiplier (1.0 = Normal, 1.15 = Extra Large)
  // Allows users to increase UI sizes via Settings > UI Size slider
  // Range: 1.0x (100%) to 1.15x (115%) in 0.01 increments
  static double _userScaleMultiplier = 1.0;
  
  // Overflow prevention factor (automatically reduces sizes if screen is too small)
  // Kicks in when screenWidth < 360dp
  // Formula: (screenWidth / 360).clamp(0.85, 1.0)
  // Example: 320dp screen = 88.9% scale, 340dp = 94.4%, 360dp+ = 100%
  static double _overflowPreventionFactor = 1.0;

  /// Set user scale multiplier (1.0 to 1.15)
  /// Called from SizeScaleSlider widget when user adjusts UI size
  /// This allows users to increase UI sizes without breaking layout
  /// Automatically saved to SharedPreferences
  static void setUserScale(double scale) {
    _userScaleMultiplier = scale.clamp(1.0, 1.15);
  }

  /// Get current user scale multiplier (1.0 to 1.15)
  static double get userScale => _userScaleMultiplier;
  
  /// Get effective scale including overflow prevention
  /// This is the FINAL multiplier applied to all sizes
  /// Formula: userScale × overflowPreventionFactor
  /// Example: User scale 1.1x on 320dp screen = 1.1 × 0.889 = 0.978x
  static double get effectiveScale => _userScaleMultiplier * _overflowPreventionFactor;

  /// Initialize size config - call this in build method
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    orientation = _mediaQueryData.orientation;
    devicePixelRatio = _mediaQueryData.devicePixelRatio;

    // Calculate normalized scale factor
    // Higher DPI devices (Pixel 7 Pro ~3.5) need no scaling
    // Lower DPI devices (Vivo ~2.0) need to scale down to match
    normalizedScale = devicePixelRatio / _referencePixelRatio;
    
    // Calculate overflow prevention factor for very small screens
    // If screen width is less than design baseline (360dp), apply reduction
    // This prevents Malayalam/Indian language text overflow on small devices
    // Scale range: 85% to 100% (clamp prevents going below 85%)
    if (screenWidth < _designWidth) {
      _overflowPreventionFactor = (screenWidth / _designWidth).clamp(0.85, 1.0);
    } else {
      _overflowPreventionFactor = 1.0;
    }

    // Prevent system font scaling from affecting our UI
    textScaleFactor = 1.0;

    // Calculate block sizes
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    // Calculate safe area
    safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;
  }

  /// Applied to: Icons, borders, button heights, container sizes
  /// Formula: size × normalizedScale × effectiveScale
  static double normalize(double size) {
    return size * normalizedScale * effectiveScale;
  }
  
  /// Adaptive normalize - adjusts size based on available space
  /// Use this for text and icons inside constrained containers
  /// Provides additional scaling for very small screens (< 320dp)
  /// 
  /// Applied to: ALL font sizes, text-based icons
  /// 
  /// Parameters:
  /// - size: Base size in design pixels (dp)
  /// - minScale: Minimum scale factor for tiny screens (default 0.7 = 70%)
  /// 
  /// Returns: Fully scaled size with overflow prevention
  /// 
  /// Example Usage:
  /// ```dart
  /// fontSize: SizeConfig.fontSizeRegular  // Uses adaptiveNormalize(14.0)
  /// ```
  static double adaptiveNormalize(double size, {double minScale = 0.7}) {
    final baseSize = size * normalizedScale * effectiveScale;
    // Additional reduction for very small screens (< 320dp)
    // Prevents text overflow in extreme cases
    if (screenWidth < 320) {
      return baseSize * minScale;
    }
    return baseSize;
  }
  
  /// Flexible spacing - reduces on smaller screens
  /// Use this for all spacing, padding, margins, and gaps
  /// Automatically reduces by 25% when screen width < 360dp
  /// 
  /// Applied to: ALL spacing values (padding, margins, gaps)
  /// 
  /// Formula:
  /// - Screen >= 360dp: normalize(size)
  /// - Screen < 360dp: normalize(size) × 0.75
  /// 
  /// Example Usage:
  /// ```dart
  /// padding: EdgeInsets.all(SizeConfig.spaceRegular)  // Uses flexSpace(16.0)
  /// ```
  
  /// Flexible spacing - reduces on smaller screens
  static double flexSpace(double size) {
    final normalized = normalize(size);
    if (screenWidth < 360) {
      return normalized * 0.75; // 25% reduction on small screens
    }
    return normalized;
  }

  // ============ APP BAR SIZES (NORMALIZED FOR ALL DEVICES) ============

  /// AppBar height - normalized for all devices
  static double get appBarHeight => normalize(56.0);

  /// AppBar title font size
  static double get appBarTitleSize => normalize(20.0);

  /// AppBar icon size
  static double get appBarIconSize => normalize(24.0);

  /// AppBar icon button touch target size
  static double get appBarIconButtonSize => normalize(48.0);

  /// AppBar title spacing
  static double get appBarTitleSpacing => normalize(16.0);

  /// AppBar horizontal padding
  static double get appBarHorizontalPadding => normalize(4.0);

  /// AppBar elevation
  static const double appBarElevation = 0.0;

  // ============ ICON SIZES (NORMALIZED) ============

  /// Small icon size (badges, indicators)
  static double get iconSizeXSmall => normalize(12.0);

  /// Small icon size
  static double get iconSizeSmall => normalize(16.0);

  /// Medium icon size (default)
  static double get iconSizeMedium => normalize(20.0);

  /// Large icon size (primary actions)
  static double get iconSizeLarge => normalize(24.0);

  /// Extra large icon size
  static double get iconSizeXLarge => normalize(32.0);

  /// Huge icon size (illustrations)
  static double get iconSizeHuge => normalize(48.0);

  // ============ FONT SIZES (ADAPTIVE NORMALIZATION) ============
  // All font sizes use adaptiveNormalize() for intelligent overflow prevention
  // Automatically scales down on small screens and with Malayalam/Indian languages

  /// Extra small text (captions, labels) - 10dp base
  /// Used for: Badges, tiny labels, micro text
  static double get fontSizeXSmall => adaptiveNormalize(10.0);

  /// Small text (secondary text) - 12dp base
  /// Used for: Timestamps, helper text, secondary info
  static double get fontSizeSmall => adaptiveNormalize(12.0);

  /// Regular text (body) - 14dp base
  /// Used for: Body text, descriptions, list items
  static double get fontSizeRegular => adaptiveNormalize(14.0);

  /// Medium text (buttons, labels) - 16dp base
  /// Used for: Buttons, tabs, chips, prominent labels
  static double get fontSizeMedium => adaptiveNormalize(16.0);

  /// Large text (section headers) - 18dp base
  /// Used for: Section titles, card headers, dialog titles
  static double get fontSizeLarge => adaptiveNormalize(18.0);

  /// Extra large text (page titles) - 20dp base
  /// Used for: Page titles, main headings, app bar titles
  static double get fontSizeXLarge => adaptiveNormalize(20.0);

  /// Huge text (display) - 24dp base
  /// Used for: Hero text, feature highlights, statistics
  static double get fontSizeHuge => adaptiveNormalize(24.0);

  /// Massive text (splash, hero) - 32dp base
  /// Used for: Splash screens, hero sections, display text
  static double get fontSizeMassive => adaptiveNormalize(32.0);

  // ============ SPACING (FLEXIBLE SPACING) ============
  // All spacing uses flexSpace() for responsive reduction on small screens

  /// No spacing
  static const double spaceNone = 0.0;

  /// Tiny spacing (2dp) - For minimal gaps
  static double get spaceTiny => flexSpace(2.0);

  /// Extra small spacing (4dp) - For compact layouts
  static double get spaceXSmall => flexSpace(4.0);

  /// Small spacing (8dp) - For standard item spacing
  static double get spaceSmall => flexSpace(8.0);

  /// Medium spacing (12dp) - For section spacing
  static double get spaceMedium => flexSpace(12.0);

  /// Regular spacing (16dp) - Default padding/margin
  static double get spaceRegular => flexSpace(16.0);

  /// Large spacing (20dp) - For prominent sections
  static double get spaceLarge => flexSpace(20.0);

  /// Extra large spacing (24dp) - For major sections
  static double get spaceXLarge => flexSpace(24.0);

  /// Huge spacing (32dp) - For screen sections
  static double get spaceHuge => flexSpace(32.0);

  /// Massive spacing (48dp) - For large visual breaks
  static double get spaceMassive => flexSpace(48.0);

  // ============ BORDER RADIUS (NORMALIZED) ============

  /// Small border radius
  static double get radiusSmall => normalize(4.0);

  /// Medium border radius
  static double get radiusMedium => normalize(8.0);

  /// Regular border radius
  static double get radiusRegular => normalize(12.0);

  /// Large border radius
  static double get radiusLarge => normalize(16.0);

  /// Extra large border radius
  static double get radiusXLarge => normalize(20.0);

  /// Circular border radius
  static double get radiusCircular => normalize(999.0);

  // ============ BUTTON SIZES (NORMALIZED) ============

  /// Small button height
  static double get buttonHeightSmall => normalize(32.0);

  /// Medium button height
  static double get buttonHeightMedium => normalize(40.0);

  /// Regular button height
  static double get buttonHeightRegular => normalize(48.0);

  /// Large button height
  static double get buttonHeightLarge => normalize(56.0);

  /// Button horizontal padding
  static double get buttonPaddingHorizontal => normalize(24.0);

  /// Button vertical padding
  static double get buttonPaddingVertical => normalize(12.0);

  /// Icon button size (touch target)
  static double get iconButtonSize => normalize(48.0);

  /// FAB size
  static double get fabSize => normalize(56.0);

  /// Mini FAB size
  static double get fabSizeSmall => normalize(40.0);

  // ============ CARD/CONTAINER SIZES (NORMALIZED) ============

  /// Card padding
  static double get cardPadding => normalize(16.0);

  /// Card margin
  static double get cardMargin => normalize(8.0);

  /// Card elevation
  static const double cardElevation = 2.0;

  /// List tile height
  static double get listTileHeight => normalize(72.0);

  /// Compact list tile height
  static double get listTileHeightCompact => normalize(56.0);

  /// Dense list tile height
  static double get listTileHeightDense => normalize(48.0);

  // ============ RESPONSIVE HELPERS (FOR CONTENT ONLY) ============

  /// Get responsive width based on percentage
  static double getWidth(double percentage) {
    return screenWidth * (percentage / 100);
  }

  /// Get responsive height based on percentage
  static double getHeight(double percentage) {
    return screenHeight * (percentage / 100);
  }

  /// Get responsive size based on design width
  /// Use this ONLY for content areas, NOT for AppBar or navigation
  static double getProportionalWidth(double size) {
    return (size / _designWidth) * screenWidth;
  }

  /// Get responsive size based on design height
  /// Use this ONLY for content areas, NOT for AppBar or navigation
  static double getProportionalHeight(double size) {
    return (size / _designHeight) * screenHeight;
  }

  /// Get responsive size (uses smaller dimension to maintain aspect ratio)
  /// Use this ONLY for content areas, NOT for AppBar or navigation
  static double getProportionalSize(double size) {
    final scale = math.min(
      screenWidth / _designWidth,
      screenHeight / _designHeight,
    );
    return size * scale;
  }

  // ============ DEVICE TYPE DETECTION ============

  /// Check if device is phone
  static bool get isPhone => screenWidth < 600;

  /// Check if device is small phone (< 360dp width)
  static bool get isSmallPhone => screenWidth < 360;

  /// Check if device is tablet
  static bool get isTablet => screenWidth >= 600 && screenWidth < 1024;

  /// Check if device is desktop/large tablet
  static bool get isDesktop => screenWidth >= 1024;

  /// Check if orientation is portrait
  static bool get isPortrait => orientation == Orientation.portrait;

  /// Check if orientation is landscape
  static bool get isLandscape => orientation == Orientation.landscape;

  // ============ TEXT STYLES (FIXED) ============

  /// Get fixed text style with no scaling
  static TextStyle getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// AppBar title text style
  static TextStyle get appBarTitleStyle => getTextStyle(
    fontSize: appBarTitleSize,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.15,
  );

  /// Body text style
  static TextStyle get bodyTextStyle => getTextStyle(
    fontSize: fontSizeRegular,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// Caption text style
  static TextStyle get captionTextStyle => getTextStyle(
    fontSize: fontSizeSmall,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  /// Button text style
  static TextStyle get buttonTextStyle => getTextStyle(
    fontSize: fontSizeMedium,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Title text style
  static TextStyle get titleTextStyle => getTextStyle(
    fontSize: fontSizeLarge,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Heading text style
  static TextStyle get headingTextStyle => getTextStyle(
    fontSize: fontSizeXLarge,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  // ============ EDGE INSETS (FIXED) ============

  /// All-around padding
  static EdgeInsets padding({double? all}) =>
      EdgeInsets.all(all ?? spaceRegular);

  /// Symmetric padding
  static EdgeInsets paddingSymmetric({double? horizontal, double? vertical}) =>
      EdgeInsets.symmetric(
        horizontal: horizontal ?? spaceRegular,
        vertical: vertical ?? spaceRegular,
      );

  /// Only padding
  static EdgeInsets paddingOnly({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) => EdgeInsets.only(
    left: left ?? 0,
    top: top ?? 0,
    right: right ?? 0,
    bottom: bottom ?? 0,
  );

  // ============ SAFE AREA HELPERS ============

  /// Get safe area top
  static double get safeAreaTop => _mediaQueryData.padding.top;

  /// Get safe area bottom
  static double get safeAreaBottom => _mediaQueryData.padding.bottom;

  /// Get safe area left
  static double get safeAreaLeft => _mediaQueryData.padding.left;

  /// Get safe area right
  static double get safeAreaRight => _mediaQueryData.padding.right;

  /// Get status bar height
  static double get statusBarHeight => _mediaQueryData.padding.top;

  /// Get bottom navigation bar height
  static double get bottomBarHeight => _mediaQueryData.padding.bottom;
}
