import 'package:flutter/material.dart';

import '../../../../../../Features/Other/responsive_widget.dart';



class PayrollView extends StatelessWidget {
  const PayrollView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile:  _MobileView(),
      tablet:  _TabletView(),
      desktop: _DesktopView(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _MobileView extends StatelessWidget {
  const _MobileView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Payroll'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TABLET
// ═══════════════════════════════════════════════════════════════════
class _TabletView extends StatelessWidget {
  const _TabletView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Payroll'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _DesktopView extends StatelessWidget {
  const _DesktopView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Payroll'),
      ),
    );
  }
}