import 'package:flutter/material.dart';

/// A widget that provides dynamic bottom padding to prevent content
/// from being hidden behind the navigation bar and FAB.
class SafeBottomPadding extends StatelessWidget {
  const SafeBottomPadding({super.key});

  /// Returns the total bottom padding needed for a screen
  /// to avoid content being hidden behind NavBar and FAB
  static double getPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // NavBar height (65) + small buffer (16) + safe area bottom
    return 65 + 16 + mediaQuery.padding.bottom;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: getPadding(context));
  }
}

/// A SliverToBoxAdapter that provides safe bottom padding
class SliverSafeBottomPadding extends StatelessWidget {
  const SliverSafeBottomPadding({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SafeBottomPadding(),
    );
  }
}
