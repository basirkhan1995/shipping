import 'package:flutter/material.dart';

/// Breakpoint constants — defined once, used everywhere.
/// Matches Material Design 3 window size classes.
class Breakpoints {
  Breakpoints._();

  /// Compact window class (phones in portrait).
  static const double mobile = 600;

  /// Medium window class (tablets, phones in landscape, small windows).
  static const double tablet = 1100;

  /// Expanded window class (desktops, large tablets in landscape).
  static const double desktop = 1100;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  // ─────────────────────────────────────────────────────────────
  // Static helpers — now based on the widget's own constraints,
  // not the full window. Call these from inside a LayoutBuilder.
  // ─────────────────────────────────────────────────────────────

  /// True when the given [width] falls in the compact class.
  static bool isMobileWidth(double width) => width < Breakpoints.mobile;

  /// True when the given [width] falls in the medium class.
  static bool isTabletWidth(double width) =>
      width >= Breakpoints.mobile && width < Breakpoints.tablet;

  /// True when the given [width] falls in the expanded class.
  static bool isDesktopWidth(double width) => width >= Breakpoints.tablet;

  // ─────────────────────────────────────────────────────────────
  // Context-based helpers — kept for convenience, but note these
  // use the *window* width, not the widget's local constraints.
  // Prefer the width-based helpers above inside LayoutBuilder.
  // ─────────────────────────────────────────────────────────────

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < Breakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= Breakpoints.mobile && w < Breakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

  // ─────────────────────────────────────────────────────────────
  // Build — LayoutBuilder gives us the real available width.
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= Breakpoints.tablet) {
          return desktop;
        }

        if (width >= Breakpoints.mobile && tablet != null) {
          return tablet!;
        }

        return mobile;
      },
    );
  }
}