import 'package:flutter/material.dart';
import 'package:shipping/Features/Widgets/znavigator.dart';
import 'package:shipping/Routes/Home/View/Report/CashBalances/all_cash.dart';
import 'package:shipping/Routes/Home/View/Report/IncomeStatement/income_statement.dart';
import 'package:shipping/Routes/Home/View/Report/TrialBalance/trial_balance.dart';
import '../../../../Features/Other/responsive_widget.dart';
import 'AccountStatement/acc_statement.dart';
import 'ArAndAp/ar_ap.dart';
import 'BalanceSheet/balance_sheet.dart';
import 'GLStatement/gl_statement.dart';
import 'CashBalances/cash_branch.dart';
import 'TxnByReference/transaction_ref.dart';

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

    // ── The 8 report cards, in order ─────────────────────────────
    final reports = <_ReportData>[
      _ReportData(
        icon: Icons.receipt_long_outlined,
        title: 'Account Statement',
        description:
        'Ledger activity for a single account with running balance.',
        onTap: (ctx) =>
            ZNavigator.goto(context: ctx, AccountStatementView()),
      ),
      _ReportData(
        icon: Icons.account_balance_outlined,
        title: 'GL Statement',
        description:
        'General ledger activity and balances for a chosen account.',
        onTap: (ctx) => ZNavigator.goto(context: ctx, GlStatementView()),
      ),
      _ReportData(
        icon: Icons.balance_outlined,
        title: 'Balance Sheet',
        description:
        'Assets, liabilities and equity as of a chosen date.',
        onTap: (ctx) => ZNavigator.goto(context: ctx, BalanceSheetView()),
      ),
      _ReportData(
        icon: Icons.rule_folder_outlined,
        title: 'Trial Balance',
        description:
        'Debit and credit totals with automatic balance check.',
        onTap: (ctx) => ZNavigator.goto(context: ctx, TrialBalanceView()),
      ),
      _ReportData(
        icon: Icons.manage_search_outlined,
        title: 'Transaction Details',
        description:
        'Look up any transaction by its reference number.',
        onTap: (ctx) => ZNavigator.goto(context: ctx, TxnByReferenceView()),
      ),
      _ReportData(
        icon: Icons.point_of_sale_outlined,
        title: 'Branch Cash Balance',
        description: 'Cash position for the current branch.',
        onTap: (ctx) =>
            ZNavigator.goto(context: ctx, CashBalancesBranchWiseView()),
      ),
      _ReportData(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Cash Balances',
        description: 'Cash position across all branches.',
        onTap: (ctx) => ZNavigator.goto(context: ctx, TreasuryView()),
      ),
      _ReportData(
        icon: Icons.line_axis_rounded,
        title: 'Profit & Loss',
        description: 'Income & expense statement.',
        onTap: (ctx) =>
            ZNavigator.goto(context: ctx, IncomeStatementView()),
      ),

      // ── NEW: Receivables card ─────────────────────────────────────
      _ReportData(
        icon: Icons.call_received_outlined,
        title: 'Receivables',
        description:
        'Accounts where customers owe money to the business.',
        onTap: (ctx) => ZNavigator.goto(
          context: ctx,
          const ArApReportPage(initialType: 'ar'),   // ← AR only
        ),
      ),

      // ── NEW: Payables card ────────────────────────────────────────
      _ReportData(
        icon: Icons.call_made_outlined,
        title: 'Payables',
        description:
        'Accounts where the business owes money to suppliers.',
        onTap: (ctx) => ZNavigator.goto(
          context: ctx,
          const ArApReportPage(initialType: 'ap'),   // ← AP only
        ),
      ),
    ];

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
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'FINANCIAL REPORTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Responsive grid of report cards ──────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = _columnsFor(constraints.maxWidth);
              const gap = 10.0;
              final cardWidth =
                  (constraints.maxWidth - gap * (cols - 1)) / cols;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: reports
                    .map(
                      (r) => SizedBox(
                    width: cardWidth,
                    child: _ReportCard(
                      icon: r.icon,
                      title: r.title,
                      description: r.description,
                      accent: scheme.primary,
                      bg: scheme.primaryContainer,
                      compact: cols >= 3,
                      onTap: () => r.onTap(context),
                    ),
                  ),
                )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  int _columnsFor(double width) {
    if (width >= 1000) return 3;
    if (width >= 600) return 2;
    return 1;
  }
}

// =====================================================================
// Data holder — one per report
// =====================================================================
class _ReportData {
  final IconData icon;
  final String title;
  final String description;
  final void Function(BuildContext) onTap;

  const _ReportData({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
}

// =====================================================================
// Report card — adapts to compact (3-col) mode
// =====================================================================
class _ReportCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Color bg;
  final VoidCallback onTap;
  final bool compact;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.bg,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Compact mode = 3-col; the card will be narrower, so rebalance
    // the icon size and paddings.
    final iconSize = widget.compact ? 44.0 : 52.0;
    final innerIconSize = widget.compact ? 22.0 : 26.0;
    final titleSize = widget.compact ? 14.5 : 15.5;
    final descSize = widget.compact ? 12.0 : 12.5;

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
              padding: EdgeInsets.all(widget.compact ? 12 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top row: icon badge + arrow
                  Row(
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: widget.bg.withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: widget.bg, width: 1.3),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          widget.icon,
                          size: innerIconSize,
                          color: widget.accent,
                        ),
                      ),
                      const Spacer(),
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 150),
                        offset:
                        _hovered ? const Offset(0.15, 0) : Offset.zero,
                        child: Icon(
                          Icons.arrow_forward_ios_outlined,
                          size: 14,
                          color: _hovered
                              ? widget.accent
                              : scheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Title
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // ── Description
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: descSize,
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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