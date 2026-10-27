// Routes/Home/View/Journal/View/TransactionsView/transactions_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Date/shamsi_converter.dart';
import 'package:shipping/Features/Widgets/noData_widget.dart';
import 'package:shipping/l10n/app_localizations.dart';

import '../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../Features/Widgets/toast.dart';
import '../../../../Features/Date/z_range_picker.dart';
import '../../../../Features/Other/global_shortcut.dart';
import '../../../../Features/zdropdown.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import '../../../Auth/model/user_model.dart';
import '../Settings/View/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'View/Bulk/bulk.dart';
import 'View/CashWD/cash_wd.dart';
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
  static const _statusOptions = <_StatusOption>[
    _StatusOption('all'),
    _StatusOption('pending'),
    _StatusOption('auth'),
    _StatusOption('reversed'),
    _StatusOption('deleted'),
  ];

  static const _typeOptions = <_TypeOption>[
    _TypeOption('CHDP'),
    _TypeOption('CHWL'),
    _TypeOption('INCM'),
    _TypeOption('XPNS'),
    _TypeOption('GLDR'),
    _TypeOption('GLCR'),
    _TypeOption('ATAT'),
    _TypeOption('CRFX'),
    _TypeOption('BULK'),
  ];

  static const _actionGroups = <_ActionGroup>[
    _ActionGroup(
      titleKey: 'cashFlow',
      buttons: [
        _ActionButtonSpec(
          code: 'CHDP',
          icon: Icons.arrow_downward_rounded,
          permission: 21,
        ),
        _ActionButtonSpec(
          code: 'CHWL',
          icon: Icons.arrow_upward_rounded,
          permission: 22,
        ),
        _ActionButtonSpec(
          code: 'INCM',
          icon: Icons.trending_up_rounded,
          permission: 23,
        ),
        _ActionButtonSpec(
          code: 'XPNS',
          icon: Icons.trending_down_rounded,
          permission: 24,
        ),
      ],
    ),
    _ActionGroup(
      titleKey: 'journal',
      buttons: [
        _ActionButtonSpec(
          code: 'ATAT',
          icon: Icons.swap_horiz_rounded,
          permission: 25,
        ),
      ],
    ),
    _ActionGroup(
      titleKey: 'bulk',
      buttons: [
        _ActionButtonSpec(
          code: 'BULK',
          icon: Icons.dynamic_feed_outlined,
          permission: 26,
        ),
      ],
    ),
    _ActionGroup(
      titleKey: 'exchange',
      buttons: [
        _ActionButtonSpec(
          code: 'CRFX',
          icon: Icons.currency_exchange_rounded,
          permission: 27,
        ),
      ],
    ),
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
    _status = _statusOptions.first;
    _types.addAll(_typeOptions);

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

  bool _checkPermission(LoginData login, int permission) {
    return login.hasPermission(permission) ?? false;
  }

  CashTxnSpec _cashSpecFor(String code) {
    final tr = AppLocalizations.of(context)!;
    switch (code) {
      case 'CHDP':
        return CashTxnSpec(
          typeCode: 'CHDP',
          icon: Icons.arrow_downward_rounded,
          title: (_) => tr.cashDeposit,
          accountInclude: 'all',
          allowReminder: true,
        );
      case 'CHWL':
        return CashTxnSpec(
          typeCode: 'CHWL',
          icon: Icons.arrow_upward_rounded,
          title: (_) => tr.cashWithdraw,
          accountInclude: 'all',
          allowReminder: true,
        );
      case 'INCM':
        return CashTxnSpec(
          typeCode: 'INCM',
          icon: Icons.trending_up_rounded,
          title: (_) => tr.income,
          accountInclude: '9,10',
          editableCurrency: true,
        );
      case 'XPNS':
        return CashTxnSpec(
          typeCode: 'XPNS',
          icon: Icons.trending_down_rounded,
          title: (_) => tr.expense,
          accountInclude: '11,12',
          editableCurrency: true,
        );
      case 'GLDR':
        return CashTxnSpec(
          typeCode: 'GLDR',
          icon: Icons.menu_book_rounded,
          title: (_) => tr.glDebit,
          accountInclude: '1,2,3,4,5,6,7',
          accountExclude: '10101011',
          editableCurrency: true,
        );
      case 'GLCR':
        return CashTxnSpec(
          typeCode: 'GLCR',
          icon: Icons.menu_book_rounded,
          title: (_) => tr.glCredit,
          accountInclude: '1,2,3,4,5,6,7',
          accountExclude: '10101011',
          editableCurrency: true,
        );
      default:
        throw ArgumentError('Unsupported cash type: $code');
    }
  }

  String _baseCurrency() {
    final state = context.read<CompanyProfileBloc>().state;
    if (state is CompanyProfileLoadedState) {
      return state.company.comLocalCcy ?? '';
    }
    return '';
  }

  // ── Open the cash dialog (single call site) ───────────────────
  Future<void> _openCashDialog(String code) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthenticatedState) return;

    final saved = await showCashTxnDialog(
      context,
      spec: _cashSpecFor(code),
      usrName: auth.loginData.usrName ?? '',
      baseCurrency: _baseCurrency(),
    );

    if (!mounted) return;
    if (saved == true) {
      _reload();
      final tr = AppLocalizations.of(context)!;
      ToastManager.show(
        context: context,
        title: tr.save,
        message: _buttonLabel(tr, code),
        type: ToastType.success,
      );
    }
  }

  // ── Open the bulk dialog (create OR edit) ─────────────────────
  Future<void> _openBulkDialog({String? reference}) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthenticatedState) return;

    final saved = await showBulkTransferDialog(
      context,
      usrName: auth.loginData.usrName ?? '',
      baseCurrency: _baseCurrency(),
      reference: reference, // ← null → create, non-null → edit
    );

    if (!mounted) return;
    if (saved == true) {
      _reload();
      final tr = AppLocalizations.of(context)!;
      ToastManager.show(
        context: context,
        title: tr.save,
        message: reference != null
            ? 'Bulk transfer updated'
            : 'Bulk transfer created',
        type: ToastType.success,
      );
    }
  }

  // ── Shared "coming soon" toast for un-built flows ─────────────
  void _comingSoon(String code) {
    final tr = AppLocalizations.of(context)!;
    ToastManager.show(
      context: context,
      title: _buttonLabel(tr, code),
      message: 'Coming soon',
      type: ToastType.error,
    );
  }

  /// Open the bulk dialog for any ATAT / BULK row — regardless of status.
  /// The dialog itself gates edit / delete / authorize / unauthorize
  /// on both the transaction's current state AND the caller being the maker.
  Future<void> _onRowTapped(TransactionListItem row) async {
    final type = row.typeCode.toUpperCase();
    final isBulkType = type == 'ATAT' || type == 'BULK';

    if (!isBulkType) {
      // Cash / GL / FX rows: no bulk dialog for these — their own
      // edit flows (or read-only detail screens) would go here.
      return;
    }

    await _openBulkDialog(reference: row.reference);
  }

  void _onActionTapped(_ActionButtonSpec spec) {
    final auth = context.read<AuthBloc>().state;
    final allowed = auth is AuthenticatedState &&
        _checkPermission(auth.loginData, spec.permission);

    if (!allowed) {
      final tr = AppLocalizations.of(context)!;
      ToastManager.show(
        context: context,
        title: tr.accessDenied,
        message: tr.noPermission,
        type: ToastType.error,
      );
      return;
    }

    switch (spec.code) {
      case 'CHDP':
      case 'CHWL':
      case 'INCM':
      case 'XPNS':
      case 'GLDR':
      case 'GLCR':
        _openCashDialog(spec.code);
        break;

      case 'ATAT':
      case 'BULK':
        _openBulkDialog();
        break;

      case 'CRFX':
        _comingSoon(spec.code);
        break;
    }
  }

  // ── Shortcuts (F1–F9) ─────────────────────────────────────────
  late final Map<ShortcutActivator, VoidCallback> _shortcuts = {
    const SingleActivator(LogicalKeyboardKey.f1): () =>
        _openCashDialog('CHDP'),
    const SingleActivator(LogicalKeyboardKey.f2): () =>
        _openCashDialog('CHWL'),
    const SingleActivator(LogicalKeyboardKey.f3): () =>
        _openCashDialog('INCM'),
    const SingleActivator(LogicalKeyboardKey.f4): () =>
        _openCashDialog('XPNS'),
    const SingleActivator(LogicalKeyboardKey.f5): () => _openBulkDialog(),
    const SingleActivator(LogicalKeyboardKey.f6): () => _openBulkDialog(),
    const SingleActivator(LogicalKeyboardKey.f7): () => _comingSoon('CRFX'),
    const SingleActivator(LogicalKeyboardKey.f8): () =>
        _openCashDialog('GLCR'),
    const SingleActivator(LogicalKeyboardKey.f9): () =>
        _openCashDialog('GLDR'),
  };

  // ── Localization resolvers ────────────────────────────────────
  String _statusLabel(AppLocalizations tr, _StatusOption s) =>
      switch (s.value) {
        'all' => tr.all,
        'pending' => tr.pending,
        'auth' => tr.authorized,
        'reversed' => tr.reversed,
        'deleted' => tr.deleted,
        _ => s.value,
      };

  String _typeLabel(AppLocalizations tr, _TypeOption t) => switch (t.code) {
    'CHDP' => tr.cashDeposit,
    'CHWL' => tr.cashWithdraw,
    'INCM' => tr.income,
    'XPNS' => tr.expense,
    'GLDR' => tr.glDebit,
    'GLCR' => tr.glCredit,
    'ATAT' => tr.fundTransfer,
    'CRFX' => tr.fxTransaction,
    'BULK' => tr.bulkTransaction,
    _ => t.code,
  };

  String _groupTitle(AppLocalizations tr, String key) => switch (key) {
    'cashFlow' => tr.cashFlow,
    'journal' => tr.journal,
    'bulk' => tr.bulkTransaction,
    'exchange' => tr.exchange,
    _ => key,
  };

  String _buttonLabel(AppLocalizations tr, String code) => switch (code) {
    'CHDP' => tr.cashDeposit,
    'CHWL' => tr.cashWithdraw,
    'INCM' => tr.income,
    'XPNS' => tr.expense,
    'ATAT' => tr.journal,
    'BULK' => tr.bulkTransaction,
    'CRFX' => tr.fxTransaction,
    _ => code,
  };

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = authState.loginData;

    return Scaffold(
      backgroundColor: color.surface,
      body: GlobalShortcuts(
        shortcuts: _shortcuts,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
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
              const SizedBox(width: 12),
              _buildActionPanel(color, textTheme, login),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionPanel(
      ColorScheme color,
      TextTheme textTheme,
      LoginData login,
      ) {
    bool can(int perm) => _checkPermission(login, perm);

    final visibleGroups = _actionGroups
        .map(
          (g) => _ActionGroup(
        titleKey: g.titleKey,
        buttons: g.buttons.where((b) => can(b.permission)).toList(),
      ),
    )
        .where((g) => g.buttons.isNotEmpty)
        .toList();

    if (visibleGroups.isEmpty) return const SizedBox.shrink();

    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.primary.withValues(alpha: .1)),
        boxShadow: [
          BoxShadow(
            blurRadius: 3,
            spreadRadius: 2,
            color: color.surfaceContainerHighest.withValues(alpha: .03),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                AppLocalizations.of(context)!.newTransaction,
                style: textTheme.titleSmall?.copyWith(
                  color: color.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Divider(
              height: 12,
              color: color.outlineVariant.withValues(alpha: .2),
            ),
            ...visibleGroups.map((g) => _buildActionGroup(g, color, textTheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGroup(
      _ActionGroup group,
      ColorScheme color,
      TextTheme textTheme,
      ) {
    final tr = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _groupTitle(tr, group.titleKey),
                    style: textTheme.labelMedium?.copyWith(
                      color: color.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ...group.buttons.map(
                (spec) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ZOutlineButton(
                width: double.infinity,
                height: 36,
                icon: spec.icon,
                iconSize: 16,
                label: Text(
                  _buttonLabel(tr, spec.code),
                  style: const TextStyle(fontSize: 12.5),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () => _onActionTapped(spec),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(TextTheme textTheme, ColorScheme color) {
    final tr = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            tr.transactions,
            style: textTheme.titleLarge?.copyWith(color: color.outline),
          ),
        ),
        Row(
          children: [
            if (_hasActiveFilters) ...[
              ZOutlineButton(
                width: 130,
                height: 35,
                icon: Icons.filter_alt_off_outlined,
                isActive: true,
                label: Text(tr.clearFilters),
                onPressed: _clearFilters,
              ),
              const SizedBox(width: 8),
            ],
            ZOutlineButton(
              width: 110,
              height: 35,
              icon: Icons.refresh,
              label: Text(tr.refresh),
              onPressed: _reload,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterRow(ColorScheme color, TextTheme textTheme) {
    final tr = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 5,
          child: ReusableSearchBar(
            height: 41,
            controller: _searchCtrl,
            onChanged: (_) {
              setState(() {});
              _reload();
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: ZRangeDatePicker(
            label: tr.date,
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
            gregorianTextStyle: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ZDropdown<_TypeOption>(
            title: tr.type,
            items: _typeOptions,
            multiSelect: true,
            selectedItems: _types.toList(),
            initialValue: tr.all,
            itemLabel: (t) => _typeLabel(tr, t),
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
            title: tr.status,
            items: _statusOptions,
            selectedItem: _status,
            initialValue: _statusLabel(tr, _status),
            itemLabel: (s) => _statusLabel(tr, s),
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

  Widget _buildTableHeader(ColorScheme color, TextTheme textTheme) {
    final titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);
    final tr = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: .9),
      ),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(tr.date, style: titleStyle)),
          SizedBox(width: 180, child: Text(tr.reference, style: titleStyle)),
          SizedBox(width: 150, child: Text(tr.type, style: titleStyle)),
          SizedBox(width: 140, child: Text(tr.maker, style: titleStyle)),
          Expanded(child: Text(tr.narration, style: titleStyle)),
          SizedBox(
            width: 180,
            child: Text(
              tr.amount,
              textAlign: TextAlign.right,
              style: titleStyle,
            ),
          ),
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                tr.status,
                textAlign: TextAlign.end,
                style: titleStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildList(
      List<TransactionListItem> rows,
      ColorScheme color, {
        bool dim = false,
      }) {
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
          // ✅ Row tap → open bulk edit when the row is editable.
          onTap: dim ? null : _onRowTapped,
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme color) {
    final tr = AppLocalizations.of(context)!;
    return Center(
      child: NoDataWidget(
        title: tr.noTransaction,
        message: tr.noTransactionMsg,
        enableAction: false,
      ),
    );
  }

  Widget _buildError(String message, ColorScheme color) {
    final tr = AppLocalizations.of(context)!;
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
              label: Text(tr.tryAgain),
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
// Spec classes for the right-panel action buttons
// ═══════════════════════════════════════════════════════════════════
class _ActionGroup {
  final String titleKey;
  final List<_ActionButtonSpec> buttons;
  const _ActionGroup({required this.titleKey, required this.buttons});
}

class _ActionButtonSpec {
  final String code;
  final IconData icon;
  final int permission;
  const _ActionButtonSpec({
    required this.code,
    required this.icon,
    required this.permission,
  });
}

// ═══════════════════════════════════════════════════════════════════
// Row widget
// ═══════════════════════════════════════════════════════════════════
class _TransactionRowWidget extends StatelessWidget {
  final TransactionListItem row;
  final bool isOdd;

  /// Optional tap handler — set to non-null only when the row is
  /// editable (pending ATAT / BULK). Tapping a non-editable row is a
  /// no-op; the callback itself decides what to do.
  final void Function(TransactionListItem)? onTap;

  const _TransactionRowWidget({
    required this.row,
    required this.isOdd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap != null ? () => onTap!(row) : null,
      hoverColor: color.primary.withValues(alpha: .03),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isOdd ? color.primary.withValues(alpha: .04) : null,
        ),
        child: Row(
          children: [
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
            SizedBox(
              width: 150,
              child: Text(
                row.typeName.isEmpty ? row.typeCode : row.typeName,
                style: textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 140,
              child: Text(
                row.maker,
                style: textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
            SizedBox(
              width: 110,
              child: _StatusPill(row: row),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final TransactionListItem row;
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
  const _StatusOption(this.value);
  @override
  bool operator ==(Object other) =>
      other is _StatusOption && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

class _TypeOption {
  final String code;
  const _TypeOption(this.code);
  @override
  bool operator ==(Object other) => other is _TypeOption && other.code == code;
  @override
  int get hashCode => code.hashCode;
}