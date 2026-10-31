
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../Features/Widgets/search_field.dart';
import '../../Finance/View/Currencies/features/currency_drop.dart';
import '../../Finance/View/Currencies/model/ccy_model.dart';
import 'bloc/ar_ap_report_bloc.dart';
import 'bloc/ar_ap_report_event.dart';
import 'bloc/ar_ap_report_state.dart';
import 'model/ar_ap_model.dart';

class ArApReportPage extends StatelessWidget {
  /// ''  = All (receivables + payables)
  /// 'ar' = Receivables only
  /// 'ap' = Payables only
  final String initialType;

  const ArApReportPage({super.key, this.initialType = ''});

  @override
  Widget build(BuildContext context) {
    return _ArApReportView(initialType: initialType);
  }
}

class _ArApReportView extends StatefulWidget {
  final String initialType;

  const _ArApReportView({required this.initialType});

  @override
  State<_ArApReportView> createState() => _ArApReportViewState();
}

class _ArApReportViewState extends State<_ArApReportView> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialType.isNotEmpty) {
      context.read<ArApReportBloc>().add(
        FilterArApReport(type: widget.initialType),
      );
    } else {
      context.read<ArApReportBloc>().add(const LoadArApReport());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialType == 'ar'
              ? 'Receivables'
              : widget.initialType == 'ap'
              ? 'Payables'
              : 'Receivables & Payables',
        ),
        actions: [
          IconButton(
            tooltip: 'Export to Excel',
            icon: const Icon(Icons.grid_on_outlined),
            onPressed: () {
              // TODO: hook up Excel export
            },
          ),
          IconButton(
            tooltip: 'Export to PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              // TODO: hook up PDF export
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<ArApReportBloc>()
                .add(const LoadArApReport()),
          ),
        ],
      ),
      body: BlocConsumer<ArApReportBloc, ArApReportState>(
        listener: (context, state) {
          if (state is ArApReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final filters = switch (state) {
            ArApReportLoaded s => s.filters,
            ArApReportLoading s => s.filters,
            ArApReportError s => s.filters,
            _ => ArApFilters(
              name: '',
              ccy: '',
              type: widget.initialType,
              includeZero: false,
            ),
          };

          final lockedType = widget.initialType;

          return Column(
            children: [
              _FilterHeader(
                filters: filters,
                nameController: _nameCtrl,
                onNameChanged: (v) {
                  context.read<ArApReportBloc>().add(
                    FilterArApReport(
                      name: v,
                      ccy: filters.ccy,
                      type: lockedType,
                      includeZero: filters.includeZero,
                    ),
                  );
                },
                onCurrencyChanged: (ccyCode) {
                  context.read<ArApReportBloc>().add(
                    FilterArApReport(
                      name: filters.name,
                      ccy: ccyCode,
                      type: lockedType,
                      includeZero: filters.includeZero,
                    ),
                  );
                },
                onIncludeZeroChanged: (v) {
                  context.read<ArApReportBloc>().add(
                    FilterArApReport(
                      name: filters.name,
                      ccy: filters.ccy,
                      type: lockedType,
                      includeZero: v,
                    ),
                  );
                },
              ),
              Expanded(
                child: switch (state) {
                  ArApReportInitial() || ArApReportLoading() =>
                  const Center(child: CircularProgressIndicator()),
                  ArApReportError s => _ErrorView(
                    message: s.message,
                    onRetry: () => context
                        .read<ArApReportBloc>()
                        .add(const LoadArApReport()),
                  ),
                  ArApReportLoaded s => _LoadedView(
                    state: s,
                    lockedType: lockedType,
                  ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Loaded content
// ─────────────────────────────────────────────────────────────────
class _LoadedView extends StatelessWidget {
  final ArApReportLoaded state;
  final String lockedType;

  const _LoadedView({required this.state, required this.lockedType});

  @override
  Widget build(BuildContext context) {
    final t = lockedType.isNotEmpty ? lockedType : state.filters.type;
    final showAr = t == '' || t == 'ar';
    final showAp = t == '' || t == 'ap';

    final children = <Widget>[];

    if (showAr) {
      children.add(Expanded(
        child: AccountTable(
          title: 'Receivables',
          rows: state.receivables,
          totals: state.totals.receivables,
        ),
      ));
    }

    if (showAp) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 12));
      children.add(Expanded(
        child: AccountTable(
          title: 'Payables',
          rows: state.payables,
          totals: state.totals.payables,
        ),
      ));
    }

    if (children.isEmpty) {
      return const Center(child: Text('Nothing to show for this filter.'));
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: children),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Header: search + currency (your CurrencyDropdown) + include-zero
// ═════════════════════════════════════════════════════════════════
class _FilterHeader extends StatelessWidget {
  final ArApFilters filters;
  final TextEditingController nameController;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<bool> onIncludeZeroChanged;

  const _FilterHeader({
    required this.filters,
    required this.nameController,
    required this.onNameChanged,
    required this.onCurrencyChanged,
    required this.onIncludeZeroChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 0.7),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth >= 720;

          final search = _LabeledField(
            label: 'Search by name',
            child: SizedBox(
              height: 44,
              child: ReusableSearchBar(
                controller: nameController,
                height: 44,
                hintText: AppLocalizations.of(context)!.searchAccounts,
                debounceDuration: const Duration(milliseconds: 350),
                onChanged: onNameChanged,
                onSubmitted: onNameChanged,
              ),
            ),
          );

          final currency = _LabeledField(
            label: AppLocalizations.of(context)!.currencies,
            child: SizedBox(
              height: 44,
              // 👇 Your shared widget with allowAll enabled.
              child: CurrencyDropdown(
                allowAll: true,
                height: 44,
                initiallySelectedSingle: filters.ccy.isEmpty
                    ? null
                    : CurrenciesModel(ccyCode: filters.ccy),
                onSingleChanged: (ccy) {
                  onCurrencyChanged(ccy?.ccyCode ?? '');
                },
              ),
            ),
          );

          final includeZero = _LabeledField(
            label: AppLocalizations.of(context)!.balanceFilter,
            child: SizedBox(
              height: 44,
              child: _IncludeZeroChip(
                value: filters.includeZero,
                onChanged: onIncludeZeroChanged,
              ),
            ),
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: 12),
                currency,
                const SizedBox(height: 12),
                includeZero,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 7, child: search),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: currency),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: includeZero),
            ],
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Labelled field wrapper
// ═════════════════════════════════════════════════════════════════
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Compact include-zero chip
// ═════════════════════════════════════════════════════════════════
class _IncludeZeroChip extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _IncludeZeroChip({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: value
              ? scheme.primary.withValues(alpha: .08)
              : scheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: value ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: value ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value ? 'Showing zero balances' : 'Hiding zero balances',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: value ? scheme.primary : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// One flat table (reused for AR and AP) — minimal, no color, no elevation
// ═════════════════════════════════════════════════════════════════
class AccountTable extends StatelessWidget {
  final String title;
  final List<ArApAccount> rows;
  final Map<String, double> totals;

  const AccountTable({
    super.key,
    required this.title,
    required this.rows,
    required this.totals,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Simple title bar ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${rows.length})',
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Rows ────────────────────────────────────────────
        Expanded(
          child: rows.isEmpty
              ? const Center(child: Text('No accounts'))
              : ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => _AccountRow(account: rows[i]),
          ),
        ),

        const Divider(height: 1),
        TotalsBar(totals: totals),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  final ArApAccount account;

  const _AccountRow({required this.account});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        account.fullName,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${account.accNumber} · ${account.accName} · ${account.accCurrency}',
        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        account.absBalance.toStringAsFixed(2),
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Per-currency totals (flat, no background)
// ═════════════════════════════════════════════════════════════════
class TotalsBar extends StatelessWidget {
  final Map<String, double> totals;

  const TotalsBar({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (totals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(
          'Total  ·  0.00',
          style: TextStyle(
            fontSize: 12.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: scheme.surfaceContainerLow,
      child: Wrap(
        spacing: 20,
        runSpacing: 4,
        children: totals.entries
            .map((e) => Text(
          '${e.key}  ${e.value.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ))
            .toList(),
      ),
    );
  }
}