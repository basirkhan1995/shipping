import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shipping/Features/Widgets/search_field.dart';
import '../../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../Features/Other/responsive_widget.dart';
import '../../../../../Features/Widgets/extensions.dart';
import '../../../../../Features/Widgets/noData_widget.dart';
import '../../../../../Features/Widgets/toast.dart';
import '../../../../../Features/Widgets/utils.dart';
import '../../../../../Features/Widgets/zbutton.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../Finance/View/GlAccounts/GlCategories/category_view.dart';
import '../../Settings/View/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'Print/all_balances_excel.dart';
import 'Print/print.dart';
import 'bloc/all_balances_bloc.dart';
import 'model/all_balances_model.dart';

// ═════════════════════════════════════════════════════════════════
// Design tokens
// ═════════════════════════════════════════════════════════════════
class _T {
  static const green = Color(0xFF059669);
  static const red   = Color(0xFFDC2626);
}

class AllBalancesView extends StatelessWidget {
  const AllBalancesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Tablet(),
      desktop: _Desktop(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Shared controller for the filter state
// ═════════════════════════════════════════════════════════════════
class _FilterState {
  int? catId;
  String? catName;
  String search = '';
}

// ═════════════════════════════════════════════════════════════════
// DESKTOP
// ═════════════════════════════════════════════════════════════════
class _Desktop extends StatefulWidget {
  const _Desktop();
  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final _f = _FilterState();
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<AllBalancesBloc>().add(LoadAllBalancesEvent(catId: _f.catId));
  }

  Future<void> _exportToExcel() async {
    final state = context.read<AllBalancesBloc>().state;
    if (state is! AllBalancesLoadedState || state.balances.isEmpty) {
      ToastManager.show(
        context: context,
        title: "No Data",
        message: "No balances to export",
        type: ToastType.warning,
      );
      return;
    }
    final fileName =
        "All_Balances_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx";
    await AllBalancesExcelService.exportToExcel(
      balances: state.balances,
      fileName: fileName,
      context: context,
      filterCategory: _f.catName,
    );
  }

  Future<void> _printAllBalances() async {
    final state = context.read<AllBalancesBloc>().state;
    if (state is! AllBalancesLoadedState) {
      ToastManager.show(
        context: context,
        title: "Attention",
        message: "Please load the data first.",
        type: ToastType.warning,
      );
      return;
    }
    final companyState = context.read<CompanyProfileBloc>().state;
    ReportModel company = ReportModel();
    if (companyState is CompanyProfileLoadedState) {
      company = ReportModel(
        comName: companyState.company.comName ?? '',
        comAddress: companyState.company.addName ?? '',
        compPhone: companyState.company.comPhone ?? '',
        comEmail: companyState.company.comEmail ?? '',
        statementDate: DateTime.now().toFullDateTime,
        comLogo: companyState.company.comLogo != null
            ? base64Decode(companyState.company.comLogo!)
            : null,
      );
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<List<AllBalancesModel>>(
        data: state.balances,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return AllBalancesPrintSettings().printPreview(
            balances: data,
            language: language,
            orientation: orientation,
            company: company,
            pageFormat: pageFormat,
          );
        },
        onPrint: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
          required selectedPrinter,
          required copies,
          required pages,
        }) {
          return AllBalancesPrintSettings().printDocument(
            balances: data,
            language: language,
            orientation: orientation,
            company: company,
            pageFormat: pageFormat,
            selectedPrinter: selectedPrinter,
            copies: copies,
            pages: pages,
          );
        },
        onSave: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return AllBalancesPrintSettings().createDocument(
            balances: data,
            language: language,
            orientation: orientation,
            company: company,
            pageFormat: pageFormat,
          );
        },
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
        titleSpacing: 0,
        toolbarHeight: 60,
        title: Text(
          tr.accounts,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 320,
                  child: _SearchBox(
                    controller: _searchCtrl,
                    hint: '',
                    onChanged: (v) => setState(() => _f.search = v),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 200,
                  child: GlSubCategoriesDrop(
                    mainCategoryId: 0,
                    showAllOption: true,
                    onChanged: (e) {
                      setState(() {
                        _f.catId = e?.acgId;
                        _f.catName = e?.acgName;
                      });
                      _reload();
                    },
                  ),
                ),
                if (_f.catId != null) ...[
                  const SizedBox(width: 8),
                  ZOutlineButton(
                    width: 130,
                    backgroundHover: scheme.error,
                    isActive: true,
                    onPressed: () {
                      setState(() {
                        _f.catId = null;
                        _f.catName = null;
                      });
                      context
                          .read<AllBalancesBloc>()
                          .add(ResetAllBalancesEvent());
                    },
                    icon: Icons.filter_alt_off_outlined,
                    label: Text(tr.clearFilters),
                  ),
                ],
                const SizedBox(width: 8),
                ZOutlineButton(
                  width: 100,
                  onPressed: _exportToExcel,
                  icon: Icons.file_copy_rounded,
                  label: const Text('Excel'),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  width: 100,
                  onPressed: _printAllBalances,
                  icon: Icons.print,
                  label: Text(tr.print),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  width: 120,
                  onPressed: _reload,
                  isActive: true,
                  icon: Icons.refresh,
                  label: Text(tr.refresh),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _Body(
        filter: _f,
        showTableLayout: true,
        onReload: _reload,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// TABLET
// ═════════════════════════════════════════════════════════════════
class _Tablet extends StatefulWidget {
  const _Tablet();
  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  final _f = _FilterState();
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<AllBalancesBloc>().add(LoadAllBalancesEvent(catId: _f.catId));
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          tr.accounts,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _SearchBox(
                    controller: _searchCtrl,
                    hint: 'Search account name…',
                    onChanged: (v) => setState(() => _f.search = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlSubCategoriesDrop(
                    title: tr.accountCategory,
                    mainCategoryId: 0,
                    showAllOption: true,
                    onChanged: (e) {
                      setState(() {
                        _f.catId = e?.acgId;
                        _f.catName = e?.acgName;
                      });
                      _reload();
                    },
                  ),
                ),
                if (_f.catId != null) ...[
                  const SizedBox(width: 8),
                  ZOutlineButton(
                    width: 48,
                    height: 48,
                    isActive: true,
                    onPressed: () {
                      setState(() {
                        _f.catId = null;
                        _f.catName = null;
                      });
                      context
                          .read<AllBalancesBloc>()
                          .add(ResetAllBalancesEvent());
                    },
                    icon: Icons.filter_alt_off_outlined,
                    label: const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _Body(
              filter: _f,
              showTableLayout: true,
              onReload: _reload,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MOBILE
// ═════════════════════════════════════════════════════════════════
class _Mobile extends StatefulWidget {
  const _Mobile();
  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  final _f = _FilterState();
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<AllBalancesBloc>().add(LoadAllBalancesEvent(catId: _f.catId));
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          tr.accounts,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              spacing: 8,
              children: [
                _SearchBox(
                  controller: _searchCtrl,
                  hint: 'Search accounts',
                  onChanged: (v) => setState(() => _f.search = v),
                ),
                GlSubCategoriesDrop(
                  title: tr.accountCategory,
                  mainCategoryId: 0,
                  showAllOption: true,
                  onChanged: (e) {
                    setState(() {
                      _f.catId = e?.acgId;
                      _f.catName = e?.acgName;
                    });
                    _reload();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _Body(
              filter: _f,
              showTableLayout: false,
              onReload: _reload,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SHARED BODY
// ═════════════════════════════════════════════════════════════════
class _Body extends StatelessWidget {
  final _FilterState filter;
  final bool showTableLayout;
  final VoidCallback onReload;

  const _Body({
    required this.filter,
    required this.showTableLayout,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<AllBalancesBloc, AllBalancesState>(
      builder: (context, state) {
        if (state is AllBalancesInitial) {
          return NoDataWidget(
            title: tr.accounts,
            message: "Purchase all account balances here",
            enableAction: false,
          );
        }
        if (state is AllBalancesLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is! AllBalancesLoadedState) {
          return const SizedBox.shrink();
        }

        // Client-side name search
        final query = filter.search.trim().toLowerCase();
        final rows = query.isEmpty
            ? state.balances
            : state.balances
            .where((r) =>
            (r.accName ?? '').toLowerCase().contains(query))
            .toList();

        if (rows.isEmpty) {
          return NoDataWidget(
            title: tr.noData,
            message: tr.noDataFound,
            enableAction: false,
          );
        }

        final totals = _totalsByCurrency(rows);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TotalsStrip(totals: totals),
              const SizedBox(height: 12),
              if (showTableLayout) _header(context),
              if (showTableLayout) const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => showTableLayout
                      ? _TableRow(item: rows[i], index: i)
                      : _MobileCard(item: rows[i]),
                ),
              ),
              _Footer(
                count: rows.length,
                totals: totals,
                scheme: scheme,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _h(tr.accountName, flex: 4),
          _h(tr.accountCategory, flex: 3),
          _h(tr.balance, flex: 3, end: true),
        ],
      ),
    );
  }

  Widget _h(String t, {int flex = 1, bool end = false}) => Expanded(
    flex: flex,
    child: Text(
      t,
      textAlign: end ? TextAlign.end : TextAlign.start,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
  );

  Map<String, double> _totalsByCurrency(List<AllBalancesModel> rows) {
    final out = <String, double>{};
    for (final r in rows) {
      final c = r.trdCcy ?? 'UNK';
      out[c] = (out[c] ?? 0) + (double.tryParse(r.balance ?? '0') ?? 0);
    }
    return out;
  }
}

// ═════════════════════════════════════════════════════════════════
// TABLE ROW (desktop / tablet)
// ═════════════════════════════════════════════════════════════════
class _TableRow extends StatelessWidget {
  final AllBalancesModel item;
  final int index;

  const _TableRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final balance = double.tryParse(item.balance ?? '0') ?? 0;
    final pos = balance >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: index.isOdd
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.20)
            : scheme.surface,
        borderRadius: BorderRadius.circular(3),
        border:  Border(
          bottom: BorderSide(
            color: scheme.outline.withValues(alpha: 0.10),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.accName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.trdAccount != null)
                  Text(
                    '#${item.trdAccount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.acgName ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    item.balance?.toAmount() ?? '0.00',
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: pos ? _T.green : _T.red,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.trdCcy ?? '',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Utils.currencyColors(item.trdCcy ?? ''),
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

// ═════════════════════════════════════════════════════════════════
// MOBILE CARD
// ═════════════════════════════════════════════════════════════════
class _MobileCard extends StatelessWidget {
  final AllBalancesModel item;

  const _MobileCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final balance = double.tryParse(item.balance ?? '0') ?? 0;
    final pos = balance >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.accName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (item.acgName != null && item.acgName!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.acgName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          if (item.trdAccount != null) ...[
            const SizedBox(height: 2),
            Text(
              '#${item.trdAccount}',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Balance',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                item.balance?.toAmount() ?? '0.00',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: pos ? _T.green : _T.red,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item.trdCcy ?? '',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Utils.currencyColors(item.trdCcy ?? ''),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// TOTALS STRIP
// ═════════════════════════════════════════════════════════════════
class _TotalsStrip extends StatelessWidget {
  final Map<String, double> totals;
  const _TotalsStrip({required this.totals});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (totals.isEmpty) return const SizedBox.shrink();

    final entries = totals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(4),
            border:
            Border.all(color: scheme.outline.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.key,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Utils.currencyColors(e.key),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                e.value.toAmount(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: e.value >= 0 ? _T.green : _T.red,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// FOOTER
// ═════════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  final int count;
  final Map<String, double> totals;
  final ColorScheme scheme;

  const _Footer({
    required this.count,
    required this.totals,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Text(
            '$count row${count == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 11.5,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ...totals.entries.map((e) => Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Text(
                  '${e.key} ',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Utils.currencyColors(e.key),
                  ),
                ),
                Text(
                  e.value.toAmount(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: e.value >= 0 ? _T.green : _T.red,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SEARCH BOX
// ═════════════════════════════════════════════════════════════════
class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ReusableSearchBar(
      controller: controller,
      onChanged: onChanged,
    );
  }
}