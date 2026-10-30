import 'package:flutter/material.dart';
import 'package:shipping/Features/Widgets/znavigator.dart';
import 'package:shipping/Routes/Home/View/Report/CashBalances/all_cash.dart';
import 'package:shipping/Routes/Home/View/Report/IncomeStatement/income_statement.dart';
import 'package:shipping/Routes/Home/View/Report/TrialBalance/trial_balance.dart';
import '../../../../Features/Other/responsive_widget.dart';
import 'AccountStatement/acc_statement.dart';
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

          // ── Account Statement ────────────────────────────
          _ReportCard(
            icon: Icons.receipt_long_outlined,
            title: 'Account Statement',
            description:
            'Ledger activity for a single account with running balance.',
            accent: scheme.primary,
            bg: scheme.primaryContainer,
            onTap: () {
              ZNavigator.goto(context: context, AccountStatementView());
            },
          ),

          const SizedBox(height: 6),

          // ── GL Statement ─────────────────────────────────
          _ReportCard(
            icon: Icons.account_balance_outlined,
            title: 'GL Statement',
            description:
            'General ledger activity and balances for a chosen account.',
            accent: scheme.primary,
            bg: scheme.primaryContainer,
            onTap: () {
              ZNavigator.goto(context: context, GlStatementView());
            },
          ),

          const SizedBox(height: 6),

          // ── Balance Sheet ────────────────────────────────
          _ReportCard(
            icon: Icons.balance_outlined,
            title: 'Balance Sheet',
            description:
            'Assets, liabilities and equity as of a chosen date.',
            accent: scheme.primary,
            bg: scheme.primaryContainer,
            onTap: () {
              ZNavigator.goto(context: context, BalanceSheetView());
            },
          ),

          const SizedBox(height: 6),

          // ── Trial Balance ────────────────────────────────
          _ReportCard(
            icon: Icons.rule_folder_outlined,
            title: 'Trial Balance',
            description:
            'Debit and credit totals with automatic balance check.',
            accent: scheme.primary,
            bg: scheme.primaryContainer,
            onTap: () {
              ZNavigator.goto(context: context, TrialBalanceView());
            },
          ),

          const SizedBox(height: 6),

          // ── Transaction Details ──────────────────────────
          _ReportCard(
            icon: Icons.manage_search_outlined,
            title: 'Transaction Details',
            description:
            'Look up any transaction by its reference number.',
            accent: scheme.primary,
            bg: scheme.primaryContainer,
            onTap: () {
              ZNavigator.goto(context: context, TxnByReferenceView());
            },
          ),

          const SizedBox(height: 6),

          // ── Branch Cash Balance ──────────────────────────
          _ReportCard(
            icon: Icons.point_of_sale_outlined,
            title: 'Branch Cash Balance',
            description:
            'Cash position for the current branch.',
            accent: scheme.primary,
            bg: scheme.primaryContainer,
            onTap: () {
              ZNavigator.goto(context: context, CashBalancesBranchWiseView());
            },
          ),

          const SizedBox(height: 6),

          // ── Cash Balances (all branches) ─────────────────
          _ReportCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Cash Balances',
            description:
            'Cash position across all branches.',
            accent: scheme.primary,
            bg: scheme.primaryContainer,
            onTap: () {
              ZNavigator.goto(context: context, TreasuryView());
            },
          ),

          const SizedBox(height: 6),

          // ── Income Statement ─────────────────
          _ReportCard(
            icon: Icons.line_axis_rounded,
            title: 'Profit & Loss',
            description:
            'Income & Expense statement',
            accent: scheme.primary,
            bg: scheme.primaryContainer,
            onTap: () {
              ZNavigator.goto(context: context, IncomeStatementView());
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