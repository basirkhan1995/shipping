import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/znavigator.dart';
import 'package:shipping/Routes/Home/View/Report/AllBalances/all_balances.dart';
import 'package:shipping/Routes/Home/View/Report/CashBalances/all_cash.dart';
import 'package:shipping/Routes/Home/View/Report/IncomeStatement/income_statement.dart';
import 'package:shipping/Routes/Home/View/Report/Inventory/Cardx/Ui/cardx.dart';
import 'package:shipping/Routes/Home/View/Report/Inventory/OrdersReport/Ui/order_report.dart';
import 'package:shipping/Routes/Home/View/Report/Inventory/StockAvailability/product_report.dart';
import 'package:shipping/Routes/Home/View/Report/TrialBalance/trial_balance.dart';
import 'package:shipping/Routes/Home/View/Report/AllTransactions/txn_report.dart';
import 'package:shipping/Routes/Home/View/Report/UserLog/user_log_report.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../Features/Other/responsive_widget.dart';
import '../Settings/Visibility/bloc/settings_visible_bloc.dart';
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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
    final tr = AppLocalizations.of(context)!;
    final visibility = context.watch<SettingsVisibleBloc>().state;
    // ── Sections. Each has its own title and its own grid of cards. ─
    final sections = <_ReportSection>[
      _ReportSection(
        title: tr.financialReports,
        reports: [
          _ReportData(
            icon: Icons.receipt_long_outlined,
            title: tr.accountStatement.toUpperCase(),
            description:
            tr.accountStatementHint,
            onTap: (ctx) =>
                ZNavigator.goto(context: ctx, AccountStatementView()),
          ),
          _ReportData(
            icon: Icons.account_balance_outlined,
            title: tr.glStatement,
            description:
            tr.glStatementHint,
            onTap: (ctx) => ZNavigator.goto(context: ctx, GlStatementView()),
          ),
          _ReportData(
            icon: Icons.balance_outlined,
            title: tr.balanceSheet.toUpperCase(),
            description: tr.balanceSheetHint,
            onTap: (ctx) => ZNavigator.goto(context: ctx, BalanceSheetView()),
          ),
          _ReportData(
            icon: Icons.rule_folder_outlined,
            title: tr.trialBalance.toUpperCase(),
            description:
            tr.trialBalanceHint,
            onTap: (ctx) => ZNavigator.goto(context: ctx, TrialBalanceView()),
          ),
          _ReportData(
            icon: Icons.manage_search_outlined,
            title: tr.transactionDetails.toUpperCase(),
            description: tr.transactionDetailsHint,
            onTap: (ctx) =>
                ZNavigator.goto(context: ctx, TxnByReferenceView()),
          ),
          _ReportData(
            icon: Icons.point_of_sale_outlined,
            title: tr.cashBalance,
            description: tr.cashBalanceHint,
            onTap: (ctx) =>
                ZNavigator.goto(context: ctx, CashBalancesBranchWiseView()),
          ),
          _ReportData(
            icon: Icons.account_balance_wallet_outlined,
            title: tr.cashBalance.toUpperCase(),
            description: tr.treasuryHint,
            onTap: (ctx) => ZNavigator.goto(context: ctx, TreasuryView()),
          ),
          _ReportData(
            icon: Icons.line_axis_rounded,
            title: tr.profitAndLoss.toUpperCase(),
            description: tr.profitAndLossHint,
            onTap: (ctx) =>
                ZNavigator.goto(context: ctx, IncomeStatementView()),
          ),
          _ReportData(
            icon: Icons.call_received_outlined,
            title: tr.receivables,
            description:
            tr.receivablesHint,
            onTap: (ctx) => ZNavigator.goto(
              context: ctx,
              const ArApReportPage(initialType: 'ar'),
            ),
          ),
          _ReportData(
            icon: Icons.call_made_outlined,
            title: tr.payables,
            description:
            tr.payablesHint,
            onTap: (ctx) => ZNavigator.goto(
              context: ctx,
              const ArApReportPage(initialType: 'ap'),
            ),
          ),
          _ReportData(
            icon: Icons.all_inclusive_rounded,
            title: tr.allBalances.toUpperCase(),
            description: tr.allBalancesHint,
            onTap: (ctx) =>
                ZNavigator.goto(context: ctx, const AllBalancesView()),
          ),
          _ReportData(
            icon: Icons.all_inclusive_rounded,
            title: tr.allTransactions,
            description: tr.allTransactionsHint,
            onTap: (ctx) => ZNavigator.goto(
              context: ctx,
              const AllTransactionReportView(),
            ),
          ),
        ],
      ),

      // ── HR SECTION ────────────────────────────────────────
      _ReportSection(
        title: tr.hrTitle.toUpperCase(),
        reports: [
          _ReportData(
            icon: Icons.verified_user_rounded,
            title: tr.userLog.toUpperCase(),
            description: tr.userLogHint,
            onTap: (ctx) =>
                ZNavigator.goto(context: ctx, const UserLogReportView()),
          ),
          _ReportData(
            icon: Icons.location_on_rounded,
            title: tr.attendance.toUpperCase(),
            description: tr.attendanceHint,
            onTap: (ctx) =>
                ZNavigator.goto(context: ctx, const UserLogReportView()),
          ),
        ],
      ),

      // ── Stock SECTION ────────────────────────────────────────
      if(visibility.orders)
      _ReportSection(
        title: tr.stock.toUpperCase(),
        reports: [
          _ReportData(
            icon: Icons.swap_horiz_rounded,
            title: tr.productMovement.toUpperCase(),
            description: tr.productMovementHint,
            onTap: (ctx) => ZNavigator.goto(context: ctx, const StockRecordReportView()),
          ),
          _ReportData(
            icon: Icons.inventory_rounded,
            title: tr.stockBalance.toUpperCase(),
            description: tr.stockBalanceHint,
            onTap: (ctx) =>
                ZNavigator.goto(context: ctx, const ProductReportView()),
          ),
          _ReportData(
            icon: Icons.add_shopping_cart_rounded,
            title: tr.saleInvoices.toUpperCase(),
            description: tr.saleInvoiceReportHint,
            onTap: (ctx) => ZNavigator.goto(context: ctx, const OrderReportView(orderName: "Sale")),
          ),
          _ReportData(
            icon: Icons.shopping_cart_checkout_rounded,
            title: tr.purchaseInvoices.toUpperCase(),
            description: tr.purchaseInvoiceReportHint,
            onTap: (ctx) => ZNavigator.goto(context: ctx, const OrderReportView(orderName: "Purchase")),
          ),
        ],
      ),

      // ── TRANSPORT SECTION ─────────────────────────────────
      if(visibility.shipping)
      _ReportSection(
        title: tr.transportCargo,
        reports: [
          _ReportData(
            icon: Icons.verified_user_rounded,
            title: tr.shipments,
            description: tr.shipmentsHint,
            onTap: (ctx) =>
                ZNavigator.goto(context: ctx, const UserLogReportView()),
          ),
          _ReportData(
            icon: Icons.verified_user_rounded,
            title: tr.shipmentInvoice,
            description: tr.shipmentInvoiceHint,
            onTap: (ctx) =>
                ZNavigator.goto(context: ctx, const UserLogReportView()),
          ),
        ],
      ),
    ];

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ──────────────────────────────────
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.line_axis_rounded,
                  size: 30,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.reports,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: scheme.primary,
                      ),
                    ),
                    Text(
                      tr.reportHint,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: scheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── One section per category ─────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = _columnsFor(constraints.maxWidth);
              const gap = 9.0;
              final cardWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var s = 0; s < sections.length; s++) ...[
                    if (s > 0) const SizedBox(height: 14),
                    _SectionHeader(
                      title: sections[s].title,
                      primary: scheme.primary,
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: sections[s].reports.map((r) => SizedBox(
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
                    ),
                  ],
                ],
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
// Section header
// =====================================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color primary;
  const _SectionHeader({required this.title, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: primary,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Data holders
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

class _ReportSection {
  final String title;
  final List<_ReportData> reports;
  const _ReportSection({required this.title, required this.reports});
}

// =====================================================================
// Report card — compacted ~25%
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
    final iconSize = widget.compact ? 44.0 : 52.0;
    final innerIconSize = widget.compact ? 24.0 : 28.0;
    final titleSize = widget.compact ? 15.0 : 17.0;
    final descSize = widget.compact ? 13.0 : 13.5;
    final pad = widget.compact ? 12.0 : 14.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered
              ? scheme.surfaceContainerHighest.withValues(alpha: .08)
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
            borderRadius: BorderRadius.circular(7),
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top row: bigger icon badge + arrow
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

                  // ── Title — larger, up to 2 lines so long names fit
                  Text(
                    widget.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: titleSize,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    maxLines: 2,
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