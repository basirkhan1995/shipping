import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/extensions.dart';
import 'package:shipping/Features/Widgets/shimmer.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/model/stk_model.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../../../../Features/Widgets/toast.dart';
import '../../../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../../../Services/repository.dart';
import '../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../bloc/transactions_bloc.dart';
import 'bloc/orders_txn_bloc.dart';
import 'bloc/orders_txn_event.dart';
import 'bloc/orders_txn_state.dart';
import 'model/order_txn_model.dart';

Future<bool?> showOrdersTxnDialog(
    BuildContext context, {
      required String usrName,
      required String baseCurrency,
      String? reference,
    }) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) {
            final bloc = OrdersTxnBloc(
              ctx.read<Repositories>(),
              headerCurrency: baseCurrency,
            );
            if (reference != null && reference.isNotEmpty) {
              bloc.add(OrdersTxnLoadForEditRequested(reference));
            }
            return bloc;
          },
        ),
        BlocProvider<TransactionsBloc>.value(
          value: context.read<TransactionsBloc>(),
        ),
      ],
      child: _OrdersTxnDialog(
        usrName: usrName,
        baseCurrency: baseCurrency,
        reference: reference,
      ),
    ),
  );
}

// Only the actions we still support.
enum _RowAction { none, authorize, unauthorize }

class _OrdersTxnDialog extends StatefulWidget {
  final String usrName;
  final String baseCurrency;
  final String? reference;
  const _OrdersTxnDialog({
    required this.usrName,
    required this.baseCurrency,
    this.reference,
  });

  @override
  State<_OrdersTxnDialog> createState() => _OrdersTxnDialogState();
}

class _OrdersTxnDialogState extends State<_OrdersTxnDialog> {
  final Map<int, _RowControllers> _controllers = {};

  String? _errorMessage;

  bool _formBusy = false;
  _RowAction _pendingAction = _RowAction.none;

  bool get _actionBusy => _pendingAction != _RowAction.none;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _setFormBusy(bool v) {
    if (mounted) setState(() => _formBusy = v);
  }

  void _setPendingAction(_RowAction action) {
    if (mounted) setState(() => _pendingAction = action);
  }

  void _clearPendingAction() {
    if (mounted && _pendingAction != _RowAction.none) {
      setState(() => _pendingAction = _RowAction.none);
    }
  }

  _RowControllers _ctrlFor(OrdersTxnRow row) =>
      _controllers.putIfAbsent(row.rowId, () => _RowControllers(row));

  void _dispatch(OrdersTxnEvent event) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
    context.read<OrdersTxnBloc>().add(event);
  }

  void _onRowComplete() => _dispatch(const OrdersTxnAddRow());

  String? get _reference {
    final s = context.read<OrdersTxnBloc>().state;
    return (s is OrdersTxnEditing) ? s.reference : null;
  }

  String? _currentUserName() {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthenticatedState ? auth.loginData.usrName : null;
  }

  void _dispatchAuthorize() {
    final ref = _reference;
    if (ref == null || ref.isEmpty) return;
    if (_errorMessage != null) setState(() => _errorMessage = null);
    _setPendingAction(_RowAction.authorize);
    context.read<TransactionsBloc>().add(
      AuthorizeTransactionEvent(reference: ref, userName: _currentUserName()),
    );
  }

  void _dispatchUnauthorize() {
    final ref = _reference;
    if (ref == null || ref.isEmpty) return;
    if (_errorMessage != null) setState(() => _errorMessage = null);
    _setPendingAction(_RowAction.unauthorize);
    context.read<TransactionsBloc>().add(
      UnauthorizeTransactionEvent(reference: ref, userName: _currentUserName()),
    );
  }

  Widget _busyLabel(
      BuildContext context, {
        required bool busy,
        required String busyText,
        required String idleText,
      }) {
    if (!busy) return Text(idleText);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(busyText),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OrdersTxnBloc, OrdersTxnState>(
          listener: _ordersTxnListener,
        ),
        BlocListener<TransactionsBloc, TransactionsState>(
          listenWhen: (prev, next) {
            if (next is! TransactionsLoadedState) return false;
            return next.actionSuccess != null ||
                next.actionError != null ||
                next.actionInProgress != null;
          },
          listener: _transactionsListener,
        ),
      ],
      child: BlocBuilder<OrdersTxnBloc, OrdersTxnState>(
        builder: (context, state) {
          final editing = _toEditing(state);
          final formBusy = _formBusy || state is OrdersTxnSubmitting;

          final blocRowBusy = context.select<TransactionsBloc, bool>((b) {
            final s = b.state;
            if (s is! TransactionsLoadedState) return false;
            final ref = editing.reference;
            if (ref == null || ref.isEmpty) return false;
            return s.actionInProgress == ref;
          });
          final rowBusy = _actionBusy || blocRowBusy;
          final anyBusy = formBusy || rowBusy;

          return ZFormDialog(
            width: MediaQuery.of(context).size.width * 0.7,
            icon: Icons.dynamic_feed_outlined,
            title: editing.isEditing
                ? '${editing.txnType} · ${editing.reference} · ${editing.entryDate.toFormattedDate()} | ${editing.entryDate?.shamsiDateString}'
                : widget.reference??"",
            isActionTrue: false,
            onAction: null,
            child: _buildBody(context, editing, formBusy, rowBusy, anyBusy),
          );
        },
      ),
    );
  }

  void _ordersTxnListener(BuildContext context, OrdersTxnState state) {
    if (state is OrdersTxnSuccess) {
      _setFormBusy(false);
      _clearPendingAction();
      ToastManager.show(
        context: context,
        title: 'Orders transaction',
        message: state.message,
        type: ToastType.success,
      );
      Navigator.of(context).pop(true);
    } else if (state is OrdersTxnDeleted) {
      _setFormBusy(false);
      _clearPendingAction();
      ToastManager.show(
        context: context,
        title: 'Orders transaction',
        message: 'Transaction ${state.reference} deleted.',
        type: ToastType.success,
      );
      Navigator.of(context).pop(true);
    } else if (state is OrdersTxnFailure) {
      _setFormBusy(false);
      _clearPendingAction();
      setState(() => _errorMessage = state.message);
    } else if (state is OrdersTxnEditing &&
        state.reference != null &&
        state.rows.isNotEmpty) {
      _clearPendingAction();
    }
  }

  void _transactionsListener(BuildContext context, TransactionsState state) {
    if (state is! TransactionsLoadedState) return;

    final success = state.actionSuccess;
    if (success != null) {
      _clearPendingAction();
      ToastManager.show(
        context: context,
        title: 'Orders transaction',
        message: success,
        type: ToastType.success,
      );
      context.read<TransactionsBloc>().add(const ClearRowActionSuccessEvent());

      final ref = _reference;
      if (ref != null && ref.isNotEmpty) {
        if (success.toLowerCase().contains('deleted')) {
          if (mounted) Navigator.of(context).pop(true);
        } else {
          context.read<OrdersTxnBloc>().add(
            OrdersTxnLoadForEditRequested(ref),
          );
        }
      }
      return;
    }

    final error = state.actionError;
    if (error != null) {
      _clearPendingAction();
      setState(() => _errorMessage = error);
      context.read<TransactionsBloc>().add(const ClearRowActionErrorEvent());
    }
  }

  OrdersTxnEditing _toEditing(OrdersTxnState state) {
    if (state is OrdersTxnEditing) return state;
    if (state is OrdersTxnFailure) {
      final rows = state.rows;
      final debit = rows.fold<double>(0, (a, r) => a + r.debit);
      final credit = rows.fold<double>(0, (a, r) => a + r.credit);
      return OrdersTxnEditing(
        rows: rows,
        totalDebit: debit,
        totalCredit: credit,
        reference: state.reference,
        status: state.status,
        stateText: state.stateText,
        makerName: state.makerName,
        headerCurrency: state.headerCurrency,
      );
    }
    if (state is OrdersTxnLoadingForEdit) {
      return const OrdersTxnEditing(rows: [], totalDebit: 0, totalCredit: 0);
    }
    return const OrdersTxnEditing(rows: [], totalDebit: 0, totalCredit: 0);
  }

  Set<String> _usedAccountCcyKeys(int currentRowId) {
    final state = context.read<OrdersTxnBloc>().state;
    if (state is! OrdersTxnEditing) return const {};
    final keys = <String>{};
    for (final r in state.rows) {
      if (r.rowId == currentRowId) continue;
      final n = r.accountNumber;
      final c = r.currency;
      if (n == null || c == null || c.isEmpty) continue;
      keys.add('$n::$c');
    }
    return keys;
  }

  /// Sum debit/credit per currency across all rows.
  /// e.g. {'AFN': 8000.0, 'USD': 300.0}
  ({Map<String, double> debit, Map<String, double> credit}) _groupedTotals(
      OrdersTxnEditing state,
      ) {
    final debit = <String, double>{};
    final credit = <String, double>{};
    for (final r in state.rows) {
      final ccy = (r.currency == null || r.currency!.isEmpty)
          ? (state.headerCurrency ?? widget.baseCurrency)
          : r.currency!;
      if (r.debit > 0) {
        debit[ccy] = (debit[ccy] ?? 0) + r.debit;
      }
      if (r.credit > 0) {
        credit[ccy] = (credit[ccy] ?? 0) + r.credit;
      }
    }
    return (debit: debit, credit: credit);
  }

  Widget _buildBody(
      BuildContext context,
      OrdersTxnEditing state,
      bool formBusy,
      bool rowBusy,
      bool anyBusy,
      ) {
    final isPending = state.isPending;
    final isAuthorized = state.isAuthorized;

    final auth = context.read<AuthBloc>().state;
    final loginName = auth is AuthenticatedState
        ? auth.loginData.usrName
        : null;
    final isMaker =
        state.isEditing &&
            state.makerName != null &&
            loginName != null &&
            state.makerName == loginName;


    final authorizeBusy = _pendingAction == _RowAction.authorize;
    final unauthorizeBusy = _pendingAction == _RowAction.unauthorize;

    final headerCcy = state.headerCurrency ?? widget.baseCurrency;
    final grouped = _groupedTotals(state);

    // Line rows are ALWAYS read-only now — no editing of items.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [

        Row(
          children: [
            // ── Header info strip ────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (state.isEditing) ...[
                      if (state.makerName != null && state.makerName!.isNotEmpty)
                        _pill(
                          '${AppLocalizations.of(context)!.maker}: '
                              '${state.makerName}',
                          Colors.indigo,
                        ),
                      _pill(
                        '${AppLocalizations.of(context)!.authorizer}: '
                            '${state.stateText == 'Authorized' && state.status == 1 ? (state.makerName == loginName ? '—' : loginName ?? '—') : '—'}',
                        Colors.teal,
                      ),
                      _pill(
                        '${AppLocalizations.of(context)!.status}: '
                            '${state.stateText ?? '—'}',
                        state.isAuthorized
                            ? Colors.green
                            : state.isPending
                            ? Colors.orange
                            : Colors.grey,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Grouped-by-currency totals (never a "not balanced" error) ──
            if (!state.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _currencyTotalsGroup(
                      label: AppLocalizations.of(context)!.totalDebit,
                      color: Colors.green,
                      byCcy: grouped.debit,
                    ),
                    const SizedBox(width: 8),
                    _currencyTotalsGroup(
                      label: AppLocalizations.of(context)!.totalCredit,
                      color: Colors.blue,
                      byCcy: grouped.credit,
                    ),
                  ],
                ),
              ),
          ],
        ),

        if (_errorMessage != null && _errorMessage!.isNotEmpty)
          _banner(_errorMessage!, Colors.red),


        // ── Rows (content-height, capped so a long list still scrolls) ──
        if (state.isEmpty)
          _emptyState()
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: state.rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final row = state.rows[i];
                final isLast = i == state.rows.length - 1;
                final usedKeys = _usedAccountCcyKeys(row.rowId);
                return _OrdersTxnRowWidget(
                  key: ValueKey(
                    'row-${row.rowId}-${(usedKeys.toList()..sort()).join("|")}',
                  ),
                  index: i,
                  row: row,
                  controllers: _ctrlFor(row),
                  headerCurrency: headerCcy,
                  enabled: false,
                  isLast: isLast,
                  onRowComplete: isLast ? _onRowComplete : null,
                  onChanged: _dispatch,
                  usedAccountCcyKeys: usedKeys,
                );
              },
            ),
          ),

        // ── Footer: Cancel / Authorize / Unauthorize ────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: Row(
            spacing: 8,
            children: [
              ZOutlineButton(
                onPressed: anyBusy
                    ? null
                    : () => Navigator.of(context).pop(false),
                backgroundHover: Theme.of(context).colorScheme.error,
                label: Text(AppLocalizations.of(context)!.cancel),
              ),

              // Pending → Authorize
              //
              // Rendered whenever the txn is Pending and the user is
              // known, EVEN IF the user is the maker. For the maker the
              // button is DISABLED (onPressed: null) so they can see it
              // but cannot authorize their own transaction. If you want
              // the maker to be able to authorize too, delete the
              // `isMaker ? null :` guard below.
              if (state.isEditing && isPending && loginName != null)
                ZOutlineButton(
                  onPressed: anyBusy
                      ? null
                      : (isMaker ? null : _dispatchAuthorize),
                  icon: authorizeBusy
                      ? null
                      : Icons.check_circle_outline_rounded,
                  isActive:  !authorizeBusy && !isMaker,
                  disable: !(!authorizeBusy && !isMaker),
                  label: _busyLabel(
                    context,
                    busy: authorizeBusy,
                    busyText: AppLocalizations.of(context)!.authorizing,
                    idleText: AppLocalizations.of(context)!.authorize,
                  ),
                ),

              // Authorized → Unauthorize
              if (state.isEditing && isAuthorized)
                ZOutlineButton(
                  onPressed: anyBusy ? null : _dispatchUnauthorize,
                  icon: unauthorizeBusy ? null : Icons.undo_rounded,
                  isActive: !unauthorizeBusy,
                  label: _busyLabel(
                    context,
                    busy: unauthorizeBusy,
                    busyText: AppLocalizations.of(context)!.unauthorize,
                    idleText: AppLocalizations.of(context)!.unauthorize,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState() => Center(
    child: widget.reference != null && widget.reference!.isNotEmpty
        ? UniversalShimmer.dataList(itemCount: 10,showCheckbox: true,numberOfColumns: 4)
        : Text(
      AppLocalizations.of(context)!.atLeastTwoRow,
      textAlign: TextAlign.center,
    ),
  );

  /// One pill-group per currency under the given label.
  /// Renders nothing if the map is empty.
  Widget _currencyTotalsGroup({
    required String label,
    required Color color,
    required Map<String, double> byCcy,
  }) {
    if (byCcy.isEmpty) return const SizedBox.shrink();
    final entries = byCcy.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Wrap(
      spacing: 1.5,
      runSpacing: 4,
      children: [
        _pill(label, color),
        for (final e in entries)
          _pill('${e.key} ${e.value.toAmount()}', color),
      ],
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(1),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        color: color,
        letterSpacing: 1,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
    ),
  );

  Widget _banner(String text, Color color) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: color, fontSize: 12)),
        ),
      ],
    ),
  );
}

// ── Row controllers ─────────────────────────────────────────────

class _RowControllers {
  final TextEditingController account;
  final TextEditingController debit;
  final TextEditingController credit;
  final TextEditingController narration;

  final FocusNode accountFocus = FocusNode();
  final FocusNode debitFocus = FocusNode();
  final FocusNode creditFocus = FocusNode();
  final FocusNode narrationFocus = FocusNode();

  _RowControllers(OrdersTxnRow row)
      : account = TextEditingController(text: _initialAccountText(row)),
        debit = TextEditingController(
          text: row.debit > 0 ? row.debit.toStringAsFixed(2) : '',
        ),
        credit = TextEditingController(
          text: row.credit > 0 ? row.credit.toStringAsFixed(2) : '',
        ),
        narration = TextEditingController(text: row.narration);

  static String _initialAccountText(OrdersTxnRow row) {
    final hasName = row.accountName != null && row.accountName!.isNotEmpty;
    final hasNumber = row.accountNumber != null;
    final ccy = row.currency ?? '';
    if (hasNumber && hasName && ccy.isNotEmpty) {
      return '${row.accountNumber} | ${row.accountName} | $ccy';
    }
    if (hasNumber && hasName) {
      return '${row.accountNumber} | ${row.accountName}';
    }
    if (hasNumber) return row.accountNumber!.toString();
    if (hasName) return row.accountName!;
    return '';
  }

  void dispose() {
    account.dispose();
    debit.dispose();
    credit.dispose();
    narration.dispose();
    accountFocus.dispose();
    debitFocus.dispose();
    creditFocus.dispose();
    narrationFocus.dispose();
  }
}

// ── Row widget (view-only) ─────────────────────────────────────

class _OrdersTxnRowWidget extends StatefulWidget {
  final int index;
  final OrdersTxnRow row;
  final _RowControllers controllers;
  final String headerCurrency;
  final bool enabled;
  final bool isLast;
  final VoidCallback? onRowComplete;
  final void Function(OrdersTxnUpdateRow) onChanged;
  final Set<String> usedAccountCcyKeys;

  const _OrdersTxnRowWidget({
    super.key,
    required this.index,
    required this.row,
    required this.controllers,
    required this.headerCurrency,
    required this.enabled,
    required this.isLast,
    required this.onChanged,
    required this.usedAccountCcyKeys,
    this.onRowComplete,
  });

  @override
  State<_OrdersTxnRowWidget> createState() => _OrdersTxnRowWidgetState();
}

class _OrdersTxnRowWidgetState extends State<_OrdersTxnRowWidget> {
  bool _focusedOnce = false;
  bool _accountLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _focusedOnce) return;
      if (widget.isLast && widget.enabled) {
        _focusedOnce = true;
        widget.controllers.accountFocus.requestFocus();
      }
    });
  }

  void _triggerSearch(String query) {
    if (!mounted) return;
    setState(() => _accountLoading = true);
    context.read<StkAccountsBloc>().add(
      LoadStkAccountsEvent(query: query),
    );
  }

  void _triggerFetchAll() {
    if (!mounted) return;
    setState(() => _accountLoading = true);
    context.read<StkAccountsBloc>().add(const LoadStkAccountsEvent());
  }

  void _onNarrationDone() {
    if (!widget.isLast) return;
    widget.onRowComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final c = widget.controllers;

    final showCurrencyDrop =
        widget.row.accountNumber != null && widget.row.currency != null;

    final scopedLoading = _accountLoading;

    return BlocListener<StkAccountsBloc, StkAccountsState>(
      listenWhen: (prev, next) =>
      prev is StkAccountsLoadingState && next is! StkAccountsLoadingState,
      listener: (_, _) {
        if (mounted && _accountLoading) {
          setState(() => _accountLoading = false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  color: color.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: GenericTextField<StkAccountModel, StkAccountsBloc, StkAccountsState>(
                controller: c.account,
                title: '',
                hintText: AppLocalizations.of(context)!.accNameOrNumber,
                isEnabled: false,
                readOnly: true,
                bloc: context.read<StkAccountsBloc>(),
                focusNode: c.accountFocus,
                textInputAction: TextInputAction.none,
                showAllOnFocus: true,
                stateToLoading: (_) => scopedLoading,
                loadingBuilder: (context) => scopedLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const SizedBox.shrink(),
                fetchAllFunction: (_) => _triggerFetchAll(),
                searchFunction: (_, q) {
                  if (q.trim().isEmpty) return;
                  _triggerSearch(q);
                },
                itemBuilder: (context, account) {
                  final ownCcy = account.accCurrency;
                  final effectiveCcy = (ownCcy != null && ownCcy.isNotEmpty)
                      ? ownCcy
                      : widget.headerCurrency;
                  final matchesHeader =
                      effectiveCcy == widget.headerCurrency;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${account.accNumber} · ${account.accName ?? ''}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Row(
                          spacing: 5,
                          children: [
                            Text(account.accBalance.toAmount()),
                            Text(
                              effectiveCcy,
                              style: TextStyle(
                                fontSize: 11,
                                color: matchesHeader
                                    ? color.primary
                                    : color.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                itemToString: (a) =>
                '${a.accNumber} | ${a.accName} | '
                    '${a.accCurrency ?? widget.headerCurrency}',
                stateToItems: (s) {
                  if (s is! StkAccountsLoadedState) {
                    return const <StkAccountModel>[];
                  }

                  const excluded = <int>{10101011};

                  final ccyByAcc = <int, Set<String>>{};
                  for (final a in s.accounts) {
                    final n = a.accNumber;
                    if (n == null) continue;
                    final c = a.accCurrency;
                    if (c == null || c.isEmpty) continue;
                    ccyByAcc.putIfAbsent(n, () => <String>{}).add(c);
                  }

                  final filtered = <StkAccountModel>[];
                  for (final a in s.accounts) {
                    if (excluded.contains(a.accNumber)) continue;

                    final key = '${a.accNumber}::${a.accCurrency ?? ''}';
                    final ownKey =
                        '${widget.row.accountNumber ?? ''}::'
                        '${widget.row.currency ?? ''}';
                    if (key != ownKey &&
                        widget.usedAccountCcyKeys.contains(key)) {
                      continue;
                    }

                    if (a.accCategory == 8) {
                      filtered.add(a);
                      continue;
                    }

                    final n = a.accNumber;
                    final isMultiCcy =
                        n != null && (ccyByAcc[n]?.length ?? 0) > 1;
                    if (isMultiCcy) {
                      filtered.add(a);
                      continue;
                    }

                    filtered.add(a);
                  }

                  final seen = <String>{};
                  return filtered.where((a) {
                    final k = '${a.accNumber}::${a.accCurrency ?? ''}';
                    if (seen.contains(k)) return false;
                    seen.add(k);
                    return true;
                  }).toList();
                },
                onSelected: (a) {
                  if (!widget.enabled) return;
                  final effectiveCcy = (a.accCurrency?.isNotEmpty == true)
                      ? a.accCurrency!
                      : widget.headerCurrency;
                  c.account.text =
                  '${a.accNumber} | ${a.accName ?? ''} | $effectiveCcy';

                  widget.onChanged(
                    OrdersTxnUpdateRow(
                      rowId: widget.row.rowId,
                      accountNumber: a.accNumber,
                      accountName: a.accName,
                      currency: effectiveCcy,
                    ),
                  );

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) c.debitFocus.requestFocus();
                  });
                },
                validator: (v) =>
                (widget.row.accountNumber == null) ? 'Required' : null,
                showCurrencySelector: showCurrencyDrop,
                isCurrencySelectorEnabled: false, // view-only
                selectedCurrencyCodeOverride:
                widget.row.currency ?? widget.headerCurrency,
                onCurrencySelectorChanged: (_) {}, // view-only
              ),
            ),

            SizedBox(
              width: 130,
              child: ZTextFieldEntitled(
                controller: c.debit,
                title: '',
                isRequired: false,
                isEnabled: widget.enabled,
                focusNode: c.debitFocus,
                textInputAction: TextInputAction.none,
                hint: AppLocalizations.of(context)!.debit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormat: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onFieldSubmitted: (_) => c.creditFocus.requestFocus(),
                onChanged: (v) {
                  if (!widget.enabled) return;
                  final d = double.tryParse(v) ?? 0;
                  if (d > 0) c.credit.clear();
                  widget.onChanged(
                    OrdersTxnUpdateRow(
                      rowId: widget.row.rowId,
                      debit: d,
                      credit: d > 0 ? 0 : widget.row.credit,
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: 130,
              child: ZTextFieldEntitled(
                controller: c.credit,
                title: '',
                hint: AppLocalizations.of(context)!.credit,
                isRequired: false,
                isEnabled: widget.enabled,
                focusNode: c.creditFocus,
                textInputAction: TextInputAction.none,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormat: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onFieldSubmitted: (_) => c.narrationFocus.requestFocus(),
                onChanged: (v) {
                  if (!widget.enabled) return;
                  final cr = double.tryParse(v) ?? 0;
                  if (cr > 0) c.debit.clear();
                  widget.onChanged(
                    OrdersTxnUpdateRow(
                      rowId: widget.row.rowId,
                      credit: cr,
                      debit: cr > 0 ? 0 : widget.row.debit,
                    ),
                  );
                },
              ),
            ),

            Expanded(
              flex: 2,
              child: ZTextFieldEntitled(
                controller: c.narration,
                hint: AppLocalizations.of(context)!.narration,
                title: '',
                isRequired: false,
                isEnabled: widget.enabled,
                focusNode: c.narrationFocus,
                textInputAction: TextInputAction.none,
                onFieldSubmitted: (_) {
                  if (!widget.enabled) return;
                  widget.onChanged(
                    OrdersTxnUpdateRow(
                      rowId: widget.row.rowId,
                      narration: c.narration.text,
                    ),
                  );
                  _onNarrationDone();
                },
                onChanged: (v) {
                  if (!widget.enabled) return;
                  widget.onChanged(
                    OrdersTxnUpdateRow(
                      rowId: widget.row.rowId,
                      narration: v,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}