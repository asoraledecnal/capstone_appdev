import 'package:flutter/material.dart';

/// Simple width-based breakpoints for the dashboard.
///
/// - < [mobile]  -> phone portrait: single column, drawer nav, compact bar
/// - < [tablet]  -> phone landscape / small tablet: still stacked cards,
///                  but top bar shows full labels
/// - >= [tablet] -> desktop/wide layout: permanent sidebar, side-by-side cards
class Breakpoints {
  Breakpoints._();

  static const double mobile = 640;
  static const double tablet = 900;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  /// True when there's enough room for a permanent sidebar + multi-column
  /// card layout (desktop, tablet landscape, wide browser window).
  bool get isWide => screenWidth >= Breakpoints.tablet;

  /// True when the top bar should collapse to a compact/icon-only layout.
  bool get isCompact => screenWidth < Breakpoints.mobile;
}
