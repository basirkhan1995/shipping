import 'package:flutter/material.dart';
import 'package:shipping/Features/Widgets/znavigator.dart';
import '../../../../Features/Other/responsive_widget.dart';
import 'AccountStatement/acc_statement.dart';
import 'BalanceSheet/balance_sheet.dart';
import 'GLStatement/gl_statement.dart';

class ReportView extends StatelessWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileView(),
      tablet: _TabletView(),
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
      backgroundColor: Colors.transparent,
      body: _ReportBody(padding: EdgeInsets.fromLTRB(16, 16, 16, 24)),
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
      backgroundColor: Colors.transparent,
      body: _ReportBody(padding: EdgeInsets.fromLTRB(20, 18, 20, 28)),
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
      backgroundColor: Colors.transparent,
      body: _ReportBody(padding: EdgeInsets.fromLTRB(24, 20, 24, 32)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED BODY
// ═══════════════════════════════════════════════════════════════════
class _ReportBody extends StatelessWidget {
  final EdgeInsets padding;
  const _ReportBody({required this.padding});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.line_axis_rounded,
                  size: 32,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Choose a report to view',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ── Section title ────────────────────────────────
          Text(
            'FINANCIAL REPORTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // ── Statement ────────────────────────────────────────
          _ReportCard(
            icon: Icons.receipt_long_outlined,
            title: 'Account Statement',
            description:
            'Transaction history for a single account with opening '
                'balance, running balance, and debit / credit breakdown. '
                'Printable as PDF and exportable to Excel.',
            accent: scheme.primary,
            bg: scheme.primaryContainer,
            onTap: () {
              ZNavigator.goto(context: context,AccountStatementView());
            },
          ),

          const SizedBox(height: 6),
          // ── GL ────────────────────────────────────────
          _ReportCard(
            icon: Icons.receipt_long_outlined,
            title: 'GL Statement',
            description:
            'Transaction history for a single account with opening '
                'balance, running balance, and debit / credit breakdown. '
                'Printable as PDF and exportable to Excel.',
            accent: scheme.primary,
            bg: scheme.primaryContainer,
            onTap: () {
              ZNavigator.goto(context: context,GlStatementView());
            },
          ),

          const SizedBox(height: 6),
          // ── GL ────────────────────────────────────────
          _ReportCard(
            icon: Icons.receipt_long_outlined,
            title: 'Balance Sheet',
            description:
            'Transaction history for a single account with opening '
                'balance, running balance, and debit / credit breakdown. '
                'Printable as PDF and exportable to Excel.',
            accent: scheme.primary,
            bg: scheme.primaryContainer,
            onTap: () {
              ZNavigator.goto(context: context,BalanceSheetView());
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Report card
// =====================================================================
class _ReportCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Color bg;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.bg,
    required this.onTap,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered
              ? scheme.surfaceContainer.withValues(alpha: .08)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hovered
                ? widget.accent.withValues(alpha: 0.4)
                : scheme.outline.withValues(alpha: 0.2),
            width: _hovered ? 1.4 : 0.8,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.bg.withValues(alpha: .4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: widget.bg, width: 1.3),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon,
                      size: 26,
                      color: widget.accent,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Arrow
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 150),
                      offset: _hovered ? const Offset(0.15, 0) : Offset.zero,
                      child: Icon(
                        Icons.arrow_forward_ios_outlined,
                        size: 16,
                        color: _hovered
                            ? widget.accent
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}