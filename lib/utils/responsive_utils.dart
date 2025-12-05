import 'package:flutter/material.dart';

/// Responsive utilities for adaptive UI design
class ResponsiveUtils {
  final BuildContext context;
  late final MediaQueryData _mediaQuery;
  late final Size _screenSize;
  late final EdgeInsets _padding;
  late final EdgeInsets _viewInsets;
  late final EdgeInsets _viewPadding;

  ResponsiveUtils(this.context) {
    _mediaQuery = MediaQuery.of(context);
    _screenSize = _mediaQuery.size;
    _padding = _mediaQuery.padding;
    _viewInsets = _mediaQuery.viewInsets;
    _viewPadding = _mediaQuery.viewPadding;
  }

  /// Screen dimensions
  double get screenWidth => _screenSize.width;
  double get screenHeight => _screenSize.height;
  Size get screenSize => _screenSize;

  /// Safe area padding (includes notches, status bar, etc.)
  EdgeInsets get safeAreaPadding => _padding;
  double get topSafeArea => _padding.top;
  double get bottomSafeArea => _padding.bottom;
  double get leftSafeArea => _padding.left;
  double get rightSafeArea => _padding.right;

  /// View insets (keyboard, etc.)
  EdgeInsets get viewInsets => _viewInsets;
  double get keyboardHeight => _viewInsets.bottom;

  /// View padding (combination of safe area and view insets)
  EdgeInsets get viewPadding => _viewPadding;

  /// Device orientation
  bool get isPortrait => _mediaQuery.orientation == Orientation.portrait;
  bool get isLandscape => _mediaQuery.orientation == Orientation.landscape;

  /// Accessibility settings
  double get textScaleFactor => _mediaQuery.textScaler.scale(1.0);
  bool get boldText => _mediaQuery.boldText;
  bool get highContrast =>
      _mediaQuery.highContrast ||
      _mediaQuery.platformBrightness == Brightness.dark;
  bool get invertColors => _mediaQuery.invertColors;
  bool get accessibleNavigation => _mediaQuery.accessibleNavigation;

  /// Device type categorization
  bool get isSmallPhone => screenWidth < 360;
  bool get isPhone => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;
  bool get isLargeScreen => screenWidth >= 1200;

  /// Responsive breakpoints
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Responsive spacing
  double spacing(double base) {
    return responsive(mobile: base, tablet: base * 1.2, desktop: base * 1.5);
  }

  /// Responsive font size
  double fontSize(double base) {
    final scaledSize = base * textScaleFactor;
    return responsive(
      mobile: scaledSize,
      tablet: scaledSize * 1.1,
      desktop: scaledSize * 1.2,
    );
  }

  /// Grid column count
  int gridColumns({int mobile = 2, int tablet = 3, int desktop = 4}) {
    return responsive(mobile: mobile, tablet: tablet, desktop: desktop);
  }

  /// Maximum content width for large screens
  double get maxContentWidth =>
      responsive(mobile: screenWidth, tablet: 800, desktop: 1200);

  /// Responsive padding
  EdgeInsets responsivePadding({
    double mobile = 16.0,
    double? tablet,
    double? desktop,
  }) {
    final padding = responsive(
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
      desktop: desktop ?? mobile * 2,
    );
    return EdgeInsets.all(padding);
  }

  /// Horizontal padding that respects safe areas
  EdgeInsets get horizontalSafePadding => EdgeInsets.symmetric(
    horizontal: spacing(16) + (leftSafeArea + rightSafeArea) / 2,
  );

  /// Vertical padding that respects safe areas
  EdgeInsets get verticalSafePadding => EdgeInsets.symmetric(
    vertical: spacing(16) + (topSafeArea + bottomSafeArea) / 2,
  );

  /// Card aspect ratio
  double get cardAspectRatio =>
      responsive(mobile: 0.65, tablet: 0.75, desktop: 0.8);

  /// Icon size
  double iconSize(double base) =>
      responsive(mobile: base, tablet: base * 1.2, desktop: base * 1.3);
}

/// Extension on BuildContext for easy access
extension ResponsiveContext on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  bool get isPhone => ResponsiveUtils(this).isPhone;
  bool get isTablet => ResponsiveUtils(this).isTablet;
  bool get isDesktop => ResponsiveUtils(this).isDesktop;
}
