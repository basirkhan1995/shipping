import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../Features/Date/z_generic_date.dart';
import '../../../../../Features/Date/z_range_picker.dart';
import '../../../../../Features/Other/responsive_widget.dart';
import '../../../../../Features/Widgets/extensions.dart';
import '../../../../../Features/Widgets/zbutton.dart';
import '../../../../../l10n/app_localizations.dart';
import 'bloc/income_statement_bloc.dart';
import 'model/income_stmt_model.dart';

class IncomeStatementView extends StatelessWidget {
  const IncomeStatementView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _MobileIncomeStatement(),
      tablet: const _MobileIncomeStatement(),
      desktop: const _DesktopIncomeStatement(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Design tokens — keep the whole screen visually coherent.
// ═════════════════════════════════════════════════════════════════
class _Tokens {
  static const green = Color(0xFF059669);
  static const red = Color(0xFFDC2626);
}

// ═════════════════════════════════════════════════════════════════
// MOBILE — single-column, card-based
// ═════════════════════════════════════════════════════════════════
class _MobileIncomeStatement extends StatefulWidget {
  const _MobileIncomeStatement();

  @override
  State<_MobileIncomeStatement> createState() => _MobileIncomeStatementState();
}

class _MobileIncomeStatementState extends State<_MobileIncomeStatement> {
  String fromDate = DateTime.now()
      .subtract(const Duration(days: 30))
      .toApiStartDate();
  String toDate = DateTime.now().toApiEndDate();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncomeStatementBloc>().add(ResetIncomeStatementEvent());
    });
  }

  void _load() {
    context.read<IncomeStatementBloc>().add(
      LoadIncomeStatementEvent(startDate: fromDate, endDate: toDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          tr.incomeStatement,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        titleSpacing: 0,
      ),
      body: BlocBuilder<IncomeStatementBloc, IncomeStatementState>(
        builder: (context, state) {
          final loading = state is IncomeStatementLoadingState;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PeriodCard(
                  fromDate: fromDate,
                  toDate: toDate,
                  onFromChanged: (v) => setState(() => fromDate = v),
                  onToChanged: (v) => setState(() => toDate = v),
                ),
                const SizedBox(height: 12),
                _GenerateButton(loading: loading, onPressed: _load),
                const SizedBox(height: 16),
                if (state is IncomeStatementLoadingState)
                  const _LoadingBlock(label: 'Loading income statement…'),
                if (state is IncomeStatementErrorState)
                  _ErrorBlock(message: state.message),
                if (state is IncomeStatementLoadedState) ...[
                  _SummaryStrip(summary: state.summary, compact: true),
                  const SizedBox(height: 16),
                  _SectionList(
                    title: tr.income.toUpperCase(),
                    items: state.incomeStatement
                        .where((i) => i.type == 'INCOME')
                        .toList(),
                    baseCurrency: state.summary.baseCurrency ?? 'USD',
                    color: _Tokens.green,
                    icon: Icons.trending_up_rounded,
                    total: state.summary.totalIncome ?? 0,
                  ),
                  const SizedBox(height: 14),
                  _SectionList(
                    title: tr.expenses.toUpperCase(),
                    items: state.incomeStatement
                        .where((i) => i.type == 'EXPENSE')
                        .toList(),
                    baseCurrency: state.summary.baseCurrency ?? 'USD',
                    color: _Tokens.red,
                    icon: Icons.trending_down_rounded,
                    total: state.summary.totalExpenses ?? 0,
                  ),
                  const SizedBox(height: 16),
                  _NetProfitCard(
                    amount: state.summary.netProfit ?? 0,
                    currency: state.summary.baseCurrency ?? 'USD',
                    status: state.summary.status,
                  ),
                ],
                if (state is IncomeStatementInitial) const _EmptyState(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// DESKTOP — header filter bar + split main/summary
// ═════════════════════════════════════════════════════════════════
class _DesktopIncomeStatement extends StatefulWidget {
  const _DesktopIncomeStatement();

  @override
  State<_DesktopIncomeStatement> createState() =>
      _DesktopIncomeStatementState();
}

class _DesktopIncomeStatementState extends State<_DesktopIncomeStatement> {
  late String fromDate;
  late String toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1).toApiStartDate();
    toDate = DateTime(now.year, now.month, now.day).toApiEndDate();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncomeStatementBloc>().add(ResetIncomeStatementEvent());
    });
  }

  void _load() {
    context.read<IncomeStatementBloc>().add(
      LoadIncomeStatementEvent(
        startDate: fromDate.toApiStartDate(),
        endDate: toDate.toApiEndDate(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          tr.incomeStatement,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _DesktopFilterBar(
            fromDate: fromDate,
            toDate: toDate,
            onStartChanged: (v) => setState(() => fromDate = v),
            onEndChanged: (v) {
              setState(() => toDate = v);
              _load();
            },
            onApply: _load,
          ),
          Expanded(
            child: BlocBuilder<IncomeStatementBloc, IncomeStatementState>(
              builder: (context, state) {
                if (state is IncomeStatementLoadingState) {
                  return const _LoadingBlock(
                    label: 'Loading income statement…',
                  );
                }
                if (state is IncomeStatementErrorState) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _ErrorBlock(message: state.message),
                    ),
                  );
                }
                if (state is IncomeStatementLoadedState) {
                  return _DesktopBody(
                    items: state.incomeStatement,
                    summary: state.summary,
                  );
                }
                return const _EmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Filter bar (desktop)
// ═════════════════════════════════════════════════════════════════
class _DesktopFilterBar extends StatelessWidget {
  final String fromDate;
  final String toDate;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;
  final VoidCallback onApply;

  const _DesktopFilterBar({
    required this.fromDate,
    required this.toDate,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Text(
            'Period',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 300,
            child: ZRangeDatePicker(
              label: '',
              initialStartDate: DateTime.tryParse(fromDate),
              initialEndDate: DateTime.tryParse(toDate),
              startValue: fromDate,
              endValue: toDate,
              onStartDateChanged: onStartChanged,
              onEndDateChanged: onEndChanged,
              minYear: 2000,
              maxYear: 2100,
            ),
          ),
          const SizedBox(width: 10),
          ZOutlineButton(
            height: 44,
            isActive: true,
            onPressed: onApply,
            icon: Icons.assessment_outlined,
            label: Text(
              tr.applyFilter,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Desktop body — table (3) + summary (1)
// ═════════════════════════════════════════════════════════════════
class _DesktopBody extends StatelessWidget {
  final List<IncomeStatementModel> items;
  final IncomeStatementSummary summary;

  const _DesktopBody({required this.items, required this.summary});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final baseCurrency = summary.baseCurrency ?? 'USD';

    final incomeItems = items.where((i) => i.type == 'INCOME').toList();
    final expenseItems = items.where((i) => i.type == 'EXPENSE').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left — the statement
          Expanded(
            flex: 3,
            child: _StatementTable(
              incomeItems: incomeItems,
              expenseItems: expenseItems,
              baseCurrency: baseCurrency,
              summary: summary,
              incomeTitle: tr.income.toUpperCase(),
              expenseTitle: tr.expenses.toUpperCase(),
            ),
          ),
          const SizedBox(width: 20),
          // ── Right — summary
          SizedBox(width: 380, child: _SummaryCard(summary: summary)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Statement table — clean, aligned, sectioned
// ═════════════════════════════════════════════════════════════════
class _StatementTable extends StatelessWidget {
  final List<IncomeStatementModel> incomeItems;
  final List<IncomeStatementModel> expenseItems;
  final String baseCurrency;
  final IncomeStatementSummary summary;
  final String incomeTitle;
  final String expenseTitle;

  const _StatementTable({
    required this.incomeItems,
    required this.expenseItems,
    required this.baseCurrency,
    required this.summary,
    required this.incomeTitle,
    required this.expenseTitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            child: Row(
              children: [
                _h(tr.accountName, flex: 4),
                _h(tr.category, flex: 2),
                _h('${tr.amount} ($baseCurrency)', flex: 2, end: true),
                _h(tr.amount, flex: 2, end: true),
              ],
            ),
          ),

          // ── Income
          _SectionHeader(
            title: incomeTitle,
            total: summary.totalIncome ?? 0,
            currency: baseCurrency,
            color: _Tokens.green,
            icon: Icons.trending_up_rounded,
          ),
          if (incomeItems.isEmpty)
            _EmptyRow(text: 'No income items in this period')
          else
            ...incomeItems.map(
              (i) => _DataRow(item: i, baseCurrency: baseCurrency),
            ),

          // ── Expense
          _SectionHeader(
            title: expenseTitle,
            total: summary.totalExpenses ?? 0,
            currency: baseCurrency,
            color: _Tokens.red,
            icon: Icons.trending_down_rounded,
          ),
          if (expenseItems.isEmpty)
            _EmptyRow(text: 'No expense items in this period')
          else
            ...expenseItems.map(
              (i) => _DataRow(item: i, baseCurrency: baseCurrency),
            ),

          // ── Net row
          _NetRow(summary: summary, baseCurrency: baseCurrency),
        ],
      ),
    );
  }

  Widget _h(String text, {int flex = 1, bool end = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: end ? TextAlign.end : TextAlign.start,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final double total;
  final String currency;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.total,
    required this.currency,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.06),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            '${total.toAmount()} $currency',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IncomeStatementModel item;
  final String baseCurrency;

  const _DataRow({required this.item, required this.baseCurrency});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sameCcy = item.currency == baseCurrency;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.10)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.accountName ?? '',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.accountNumber != null && item.accountNumber != 0)
                  Text(
                    '#${item.accountNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.category ?? '—',
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              sameCcy
                  ? (item.amountBase ?? 0).toAmount()
                  : (item.amountBase ?? 0).toAmount(),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (item.amountOriginal ?? 0).toAmount(),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12.5),
                ),
                if (!sameCcy && item.currency != null)
                  Text(
                    item.currency!,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;
  const _EmptyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.10)),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontStyle: FontStyle.italic,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _NetRow extends StatelessWidget {
  final IncomeStatementSummary summary;
  final String baseCurrency;

  const _NetRow({required this.summary, required this.baseCurrency});

  @override
  Widget build(BuildContext context) {
    final net = summary.netProfit ?? 0;
    final pos = net >= 0;
    final color = pos ? _Tokens.green : _Tokens.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(
          top: BorderSide(color: color.withValues(alpha: 0.30), width: 1.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            pos
                ? Icons.arrow_circle_up_rounded
                : Icons.arrow_circle_down_rounded,
            size: 22,
            color: color,
          ),
          const SizedBox(width: 10),
          Text(
            pos ? 'NET PROFIT' : 'NET LOSS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            '${net.toAmount()} $baseCurrency',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Summary card (desktop right rail)
// ═════════════════════════════════════════════════════════════════
class _SummaryCard extends StatelessWidget {
  final IncomeStatementSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final baseCurrency = summary.baseCurrency ?? 'USD';
    final net = summary.netProfit ?? 0;
    final pos = net >= 0;
    final netColor = pos ? _Tokens.green : _Tokens.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.summarize_outlined,
                  size: 22,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                tr.summary,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryLine(
            context,
            tr.financialPeriod,
            '${summary.startDate ?? ''} – ${summary.endDate ?? ''}',
            icon: Icons.calendar_today_outlined,
          ),
          _summaryLine(
            context,
            tr.baseCurrency,
            baseCurrency,
            icon: Icons.money_outlined,
          ),
          const Divider(height: 24),
          _summaryLine(
            context,
            tr.totalIncome,
            '${(summary.totalIncome ?? 0).toAmount()} $baseCurrency',
            icon: Icons.trending_up_rounded,
            color: _Tokens.green,
          ),
          _summaryLine(
            context,
            tr.totalExpense,
            '${(summary.totalExpenses ?? 0).toAmount()} $baseCurrency',
            icon: Icons.trending_down_rounded,
            color: _Tokens.red,
          ),
          const Divider(height: 24),

          // Net box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: netColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: netColor.withValues(alpha: 0.30),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      pos ? 'Net ${tr.profit}' : 'Net ${tr.loss}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: netColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: netColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        summary.status ?? '',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: netColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${net.toAmount()} $baseCurrency',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: netColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Mobile composite cards
// ═════════════════════════════════════════════════════════════════
class _PeriodCard extends StatelessWidget {
  final String fromDate;
  final String toDate;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;

  const _PeriodCard({
    required this.fromDate,
    required this.toDate,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Period',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ZDatePicker(
            label: tr.fromDate,
            value: fromDate,
            onDateChanged: onFromChanged,
          ),
          const SizedBox(height: 10),
          ZDatePicker(
            label: tr.toDate,
            value: toDate,
            onDateChanged: onToChanged,
          ),
        ],
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _GenerateButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.assessment_outlined, size: 20),
        label: Text(
          loading ? 'Generating…' : 'Generate Income Statement',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final IncomeStatementSummary summary;
  final bool compact;

  const _SummaryStrip({required this.summary, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final baseCurrency = summary.baseCurrency ?? 'USD';
    final net = summary.netProfit ?? 0;
    final pos = net >= 0;
    final netColor = pos ? _Tokens.green : _Tokens.red;

    final tiles = <Widget>[
      _StripTile(
        label: tr.totalIncome,
        value: (summary.totalIncome ?? 0).toAmount(),
        currency: baseCurrency,
        color: _Tokens.green,
        icon: Icons.trending_up_rounded,
      ),
      _StripTile(
        label: tr.totalExpense,
        value: (summary.totalExpenses ?? 0).toAmount(),
        currency: baseCurrency,
        color: _Tokens.red,
        icon: Icons.trending_down_rounded,
      ),
      _StripTile(
        label: pos ? tr.netProfit : tr.loss,
        value: net.toAmount(),
        currency: baseCurrency,
        color: netColor,
        icon: pos
            ? Icons.arrow_circle_up_rounded
            : Icons.arrow_circle_down_rounded,
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _StripTile extends StatelessWidget {
  final String label;
  final String value;
  final String currency;
  final Color color;
  final IconData icon;

  const _StripTile({
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            currency,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  final String title;
  final List<IncomeStatementModel> items;
  final String baseCurrency;
  final Color color;
  final IconData icon;
  final double total;

  const _SectionList({
    required this.title,
    required this.items,
    required this.baseCurrency,
    required this.color,
    required this.icon,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: color.withValues(alpha: 0.06),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    items.length.toString(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'No items in this period',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...items.map(
              (i) => _MobileRow(item: i, baseCurrency: baseCurrency),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              border: Border(
                top: BorderSide(color: color.withValues(alpha: 0.25)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${total.toAmount()} $baseCurrency',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileRow extends StatelessWidget {
  final IncomeStatementModel item;
  final String baseCurrency;

  const _MobileRow({required this.item, required this.baseCurrency});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sameCcy = item.currency == baseCurrency;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.10)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.accountName ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.category != null && item.category!.isNotEmpty)
                  Text(
                    item.category!,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (item.amountBase ?? 0).toAmount(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!sameCcy && item.currency != null)
                Text(
                  '${(item.amountOriginal ?? 0).toAmount()} ${item.currency}',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetProfitCard extends StatelessWidget {
  final double amount;
  final String currency;
  final String? status;

  const _NetProfitCard({
    required this.amount,
    required this.currency,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final pos = amount >= 0;
    final color = pos ? _Tokens.green : _Tokens.red;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                pos
                    ? Icons.arrow_circle_up_rounded
                    : Icons.arrow_circle_down_rounded,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                pos ? 'NET PROFIT' : 'NET LOSS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: color,
                ),
              ),
              const Spacer(),
              if (status != null && status!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${amount.toAmount()} $currency',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Shared state blocks
// ═════════════════════════════════════════════════════════════════
class _LoadingBlock extends StatelessWidget {
  final String label;
  const _LoadingBlock({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  const _ErrorBlock({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.error.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: scheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 14),
          Text(
            'No data yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a period and generate the statement',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
