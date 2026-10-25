import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Date/shamsi_converter.dart';
import '../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../Features/Widgets/toast.dart';
import '../../../../Features/Date/z_range_picker.dart';
import '../../../../Features/zdropdown.dart';
import 'bloc/transactions_bloc.dart';
import 'model/trn_model.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileView(),
      tablet: _DesktopView(),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: const Center(child: Placeholder()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP / TABLET
// ═══════════════════════════════════════════════════════════════════
class _DesktopView extends StatefulWidget {
  const _DesktopView();

  @override
  State<_DesktopView> createState() => _DesktopViewState();
}

class _DesktopViewState extends State<_DesktopView> {
  // ── Status options
  static const _statusOptions = <_StatusOption>[
    _StatusOption('all', 'All'),
    _StatusOption('pending', 'Pending'),
    _StatusOption('auth', 'Authorized'),
    _StatusOption('reversed', 'Reversed'),
    _StatusOption('deleted', 'Deleted'),
  ];

  // ── Types (no duplicates)
  static const _typeOptions = <_TypeOption>[
    _TypeOption('CHDP', 'Cash Deposit'),
    _TypeOption('CHWL', 'Cash Withdraw'),
    _TypeOption('INCM', 'Post Income'),
    _TypeOption('XPNS', 'Post Expense'),
    _TypeOption('GLDR', 'GL Debit'),
    _TypeOption('GLCR', 'GL Credit'),
    _TypeOption('ATAT', 'Fund Transfer'),
    _TypeOption('CRFX', 'Cross Currency'),
    _TypeOption('BULK', 'Bulk insertion'),
  ];

  final _searchCtrl = TextEditingController();

  late _StatusOption _status;
  late String _from;
  late String _to;
  final Set<_TypeOption> _types = {};

  late final String _defaultFrom;
  late final String _defaultTo;

  @override
  void initState() {
    super.initState();
    _status = _statusOptions.first;         // 'all'
    _types.addAll(_typeOptions);            // all types pre-selected

    final now = DateTime.now();
    final today = _iso(now);
    _defaultFrom = today;
    _defaultTo = today;
    _from = today;
    _to = today;

    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  bool get _hasActiveFilters {
    if (_status.value != _statusOptions.first.value) return true;
    if (_from != _defaultFrom) return true;
    if (_to != _defaultTo) return true;
    if (_searchCtrl.text.trim().isNotEmpty) return true;
    if (_types.length != _typeOptions.length) return true;
    if (!_typeOptions.every(_types.contains)) return true;
    return false;
  }

  void _reload() {
    final typeFilter =
    _types.isEmpty || _types.length == _typeOptions.length
        ? null
        : _types.map((e) => e.code).toSet().join(',');

    context.read<TransactionsBloc>().add(
      LoadTransactionsEvent(
        status: _status.value,
        from: _from,
        to: _to,
        type: typeFilter,
        search: _searchCtrl.text.trim().isEmpty
            ? null
            : _searchCtrl.text.trim(),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _status = _statusOptions.first;
      _from = _defaultFrom;
      _to = _defaultTo;
      _types
        ..clear()
        ..addAll(_typeOptions);
      _searchCtrl.clear();
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: color.surface,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderRow(textTheme, color),
            const SizedBox(height: 10),
            _buildFilterRow(color, textTheme),
            const SizedBox(height: 10),
            _buildTableHeader(color, textTheme),
            const SizedBox(height: 6),
            Expanded(child: _buildBody(color)),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeaderRow(TextTheme textTheme, ColorScheme color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            'Transactions',
            style: textTheme.titleLarge?.copyWith(color: color.outline),
          ),
        ),


        Row(
          children: [
            if (_hasActiveFilters) ...[
              ZOutlineButton(
                width: 130,
                icon: Icons.filter_alt_off_outlined,
                label: const Text('Clear filter'),
                onPressed: _clearFilters,
              ),
              const SizedBox(width: 8),
            ],
            ZOutlineButton(
              width: 110,
              icon: Icons.refresh,
              label: const Text('Refresh'),
              onPressed: _reload,
            ),
            const SizedBox(width: 8),
            ZOutlineButton(
              width: 130,
              icon: Icons.add,
              isActive: true,
              label: const Text('New'),
              onPressed: () => ToastManager.show(
                context: context,
                title: 'New transaction',
                message: 'Coming soon',
                type: ToastType.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Filter row ─────────────────────────────────────────────────
  Widget _buildFilterRow(ColorScheme color, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 5,
          child: ReusableSearchBar(
            height: 40,
            controller: _searchCtrl,
            onChanged: (_) {
              setState(() {});
              _reload();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ZRangeDatePicker(
            label: 'Date range',
            startValue: _from,
            endValue: _to,
            onStartDateChanged: (v) {
              setState(() => _from = v);
              _reload();
            },
            onEndDateChanged: (v) {
              setState(() => _to = v);
              _reload();
            },

            padding: EdgeInsets.zero,
            gregorianTextStyle: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ZDropdown<_TypeOption>(
            title: 'Type',
            items: _typeOptions,
            multiSelect: true,
            selectedItems: _types.toList(),
            initialValue: 'All types',
            itemLabel: (t) => t.label,
            height: 40,
            onItemSelected: (_) {},
            onMultiSelectChanged: (list) {
              setState(() {
                _types
                  ..clear()
                  ..addAll(list);
              });
              _reload();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ZDropdown<_StatusOption>(
            title: 'Status',
            items: _statusOptions,
            selectedItem: _status,
            initialValue: _status.label,
            itemLabel: (s) => s.label,
            height: 40,
            onItemSelected: (s) {
              setState(() => _status = s);
              _reload();
            },
          ),
        ),
      ],
    );
  }

  // ── Table header ───────────────────────────────────────────────
  // Order: Date | Reference | Type | Maker | Narration | Amount | Status
  Widget _buildTableHeader(ColorScheme color, TextTheme textTheme) {
    final titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: .9),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text('Date', style: titleStyle),
          ),
          SizedBox(
            width: 180,
            child: Text('Reference', style: titleStyle),
          ),
          SizedBox(
            width: 150,
            child: Text('Type', style: titleStyle),
          ),
          SizedBox(
            width: 140,
            child: Text('Maker', style: titleStyle),
          ),
          Expanded(
            child: Text('Narration', style: titleStyle),
          ),
          SizedBox(
            width: 180,
            child: Text(
              'Amount',
              textAlign: TextAlign.right,
              style: titleStyle,
            ),
          ),
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text('Status',textAlign: TextAlign.end, style: titleStyle),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────
  Widget _buildBody(ColorScheme color) {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        if (state is TransactionsLoadingState) {
          if (state.previous.isNotEmpty) {
            return _buildList(state.previous, color, dim: true);
          }
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TransactionsErrorState) {
          return _buildError(state.message, color);
        }
        if (state is TransactionsLoadedState) {
          if (state.rows.isEmpty) {
            return _buildEmpty(color);
          }
          return _buildList(state.rows, color);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildList(List<TransactionRow> rows, ColorScheme color,
      {bool dim = false}) {
    return Opacity(
      opacity: dim ? .6 : 1,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: color.outlineVariant.withValues(alpha: .2),
        ),
        itemBuilder: (_, i) => _TransactionRowWidget(
          row: rows[i],
          isOdd: i.isOdd,
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 48, color: color.onSurface.withValues(alpha: .3)),
          const SizedBox(height: 12),
          Text(
            'No transactions for the selected filters',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.onSurface.withValues(alpha: .6),
            ),
          ),
          const SizedBox(height: 12),
          ZOutlineButton(
            label: const Text('Clear filter'),
            onPressed: _clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message, ColorScheme color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: color.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ZOutlineButton(
              label: const Text('Try again'),
              icon: Icons.refresh,
              onPressed: _reload,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Row widget
// Order: Date | Reference | Type | Maker | Narration | Amount+CCY | Status
// ═══════════════════════════════════════════════════════════════════
class _TransactionRowWidget extends StatelessWidget {
  final TransactionRow row;
  final bool isOdd;
  const _TransactionRowWidget({required this.row, required this.isOdd});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isOdd ? color.primary.withValues(alpha: .04) : null,
      ),
      child: Row(
        children: [
          // ── Date
          SizedBox(
            width: 140,
            child: Text(
              row.entryDate.toFullDateTime,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: color.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ── Reference
          SizedBox(
            width: 180,
            child: Text(
              row.reference,
              style: textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ── Type
          SizedBox(
            width: 150,
            child: Text(
              row.typeName.isEmpty ? row.typeCode : row.typeName,
              style: textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ── Maker
          SizedBox(
            width: 140,
            child: Text(
              row.maker,
              style: textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ── Narration
          Expanded(
            child: Text(
              row.narration ?? '—',
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // ── Amount + Currency
          SizedBox(
            width: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    row.amountFormatted,
                    textAlign: TextAlign.right,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (row.currencies.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    row.currencies,
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // ── Status
          SizedBox(
            width: 110,
            child: _StatusPill(row: row),
          ),
        ],
      ),
    );
  }

}

class _StatusPill extends StatelessWidget {
  final TransactionRow row;
  const _StatusPill({required this.row});

  @override
  Widget build(BuildContext context) {
    final status = row.statusText.toLowerCase();
    final (bg, fg, label) = switch (status) {
      'authorized' => (
      const Color(0xFF22C55E).withValues(alpha: .12),
      const Color(0xFF166534),
      'Authorized',
      ),
      'pending' => (
      const Color(0xFFF59E0B).withValues(alpha: .12),
      const Color(0xFF92400E),
      'Pending',
      ),
      'reversed' => (
      const Color(0xFF6366F1).withValues(alpha: .12),
      const Color(0xFF3730A3),
      'Reversed',
      ),
      'deleted' => (
      const Color(0xFFEF4444).withValues(alpha: .12),
      const Color(0xFF991B1B),
      'Deleted',
      ),
      _ => (
      Colors.grey.withValues(alpha: .15),
      Colors.grey.shade700,
      row.statusText,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),

      child: Text(
        label,
        textAlign: TextAlign.end,
        style: TextStyle(
          fontSize: 10,

          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Filter option types
// ═══════════════════════════════════════════════════════════════════
class _StatusOption {
  final String value;
  final String label;
  const _StatusOption(this.value, this.label);
  @override
  bool operator ==(Object other) =>
      other is _StatusOption && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

class _TypeOption {
  final String code;
  final String label;
  const _TypeOption(this.code, this.label);
  @override
  bool operator ==(Object other) =>
      other is _TypeOption && other.code == code;
  @override
  int get hashCode => code.hashCode;
}