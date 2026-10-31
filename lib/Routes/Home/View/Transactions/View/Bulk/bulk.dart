import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/extensions.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/model/stk_model.dart';
import 'package:shipping/l10n/app_localizations.dart';

import '../../../../../../../../Features/Widgets/z_dialog.dart';
import '../../../../../../../../Features/Widgets/toast.dart';
import '../../../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../../../Services/repository.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Finance/View/Currencies/features/currency_drop.dart';
import '../../../Finance/View/Currencies/model/ccy_model.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../bloc/transactions_bloc.dart';
import 'bloc/bulk_transfer_bloc.dart';
import 'bloc/bulk_transfer_event.dart';
import 'bloc/bulk_transfer_state.dart';
import 'model/bulk_model.dart';

Future<bool?> showBulkTransferDialog(
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
            final bloc = BulkTransferBloc(ctx.read<Repositories>());
            if (reference != null && reference.isNotEmpty) {
              bloc.add(BulkTransferLoadForEditRequested(reference));
            }
            return bloc;
          },
        ),
        BlocProvider<TransactionsBloc>.value(
          value: context.read<TransactionsBloc>(),
        ),
      ],
      child: _BulkTransferDialog(
        usrName: usrName,
        baseCurrency: baseCurrency,
        reference: reference,
      ),
    ),
  );
}

class _BulkTransferDialog extends StatefulWidget {
  final String usrName;
  final String baseCurrency;
  final String? reference;
  const _BulkTransferDialog({
    required this.usrName,
    required this.baseCurrency,
    this.reference,
  });

  @override
  State<_BulkTransferDialog> createState() => _BulkTransferDialogState();
}

class _BulkTransferDialogState extends State<_BulkTransferDialog> {
  late String _headerCurrency;
  final Map<int, _RowControllers> _controllers = {};

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _headerCurrency = widget.baseCurrency;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  _RowControllers _ctrlFor(BulkTransferRow row) =>
      _controllers.putIfAbsent(row.rowId, () => _RowControllers(row));

  void _dispatch(BulkTransferEvent event) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
    context.read<BulkTransferBloc>().add(event);
  }

  // ✅ FIX: only push the new currency to non-stakeholder rows.
  // Stakeholder accounts (category 8) keep their own accCurrency.
  void _changeHeaderCurrency(String ccy) {
    setState(() {
      _headerCurrency = ccy;
      _errorMessage = null;
    });
    final cur = context.read<BulkTransferBloc>().state;
    if (cur is! BulkTransferEditing) return;

    for (final row in cur.rows) {
      if (_isStakeholderAccount(row)) continue;
      context.read<BulkTransferBloc>().add(BulkTransferUpdateRow(
        rowId: row.rowId,
        currency: ccy,
      ));
    }
  }

  /// Heuristic — stakeholder accounts live in 500000–9999999 in this API,
  /// GL accounts are >= 10_000_000.
  bool _isStakeholderAccount(BulkTransferRow row) {
    final n = row.accountNumber;
    if (n == null) return false;
    return n >= 500000 && n < 10000000;
  }

  void _onRowComplete() => _dispatch(const BulkTransferAddRow());

  void _onSubmit() {
    if (_errorMessage != null) setState(() => _errorMessage = null);

    final state = context.read<BulkTransferBloc>().state;
    if (state is BulkTransferEditing) {
      // 🔎 Debug: show exactly what will be POSTed. If `ccy` is empty
      // for any row, PHP will return {"msg":"empty"} and nothing saves.
      final preview = state.rows.map((r) => r.toRecord()).toList();
      debugPrint('BULK POST records=$preview');
    }

    context.read<BulkTransferBloc>().add(
      BulkTransferSubmitted(userName: widget.usrName),
    );
  }

  // ── row actions dispatched to TransactionsBloc ────────────
  String? get _reference {
    final s = context.read<BulkTransferBloc>().state;
    return (s is BulkTransferEditing) ? s.reference : null;
  }

  String? _currentUserName() {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthenticatedState ? auth.loginData.usrName : null;
  }

  void _dispatchAuthorize() {
    final ref = _reference;
    if (ref == null || ref.isEmpty) return;
    if (_errorMessage != null) setState(() => _errorMessage = null);
    context.read<TransactionsBloc>().add(
      AuthorizeTransactionEvent(
        reference: ref,
        userName: _currentUserName(),
      ),
    );
  }

  void _dispatchUnauthorize() {
    final ref = _reference;
    if (ref == null || ref.isEmpty) return;
    if (_errorMessage != null) setState(() => _errorMessage = null);
    context.read<TransactionsBloc>().add(
      UnauthorizeTransactionEvent(
        reference: ref,
        userName: _currentUserName(),
      ),
    );
  }

  void _dispatchReverse() {
    final ref = _reference;
    if (ref == null || ref.isEmpty) return;
    if (_errorMessage != null) setState(() => _errorMessage = null);
    context.read<TransactionsBloc>().add(
      ReverseTransactionEvent(
        reference: ref,
        userName: _currentUserName(),
      ),
    );
  }

  Future<void> _dispatchDelete() async {
    final ref = _reference;
    if (ref == null || ref.isEmpty) return;

    final tr = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(tr.delete),
        content: Text(
          'Permanently delete transaction $ref?\n\n'
              'This removes the header and every line. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(tr.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    if (_errorMessage != null) setState(() => _errorMessage = null);

    context.read<TransactionsBloc>().add(
      DeleteTransactionEvent(
        reference: ref,
        userName: _currentUserName(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BulkTransferBloc, BulkTransferState>(
          listener: _bulkListener,
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
      child: BlocBuilder<BulkTransferBloc, BulkTransferState>(
        builder: (context, bulkState) {
          final editing = _toEditing(bulkState);
          final busy = bulkState is BulkTransferSubmitting;
          final isActionBusy = context.select<TransactionsBloc, bool>(
                (b) =>
            b.state is TransactionsLoadedState &&
                (b.state as TransactionsLoadedState).actionInProgress != null,
          );

          return ZFormDialog(
            width: MediaQuery.of(context).size.width * 0.7,
            icon: Icons.dynamic_feed_outlined,
            title: editing.isEditing
                ? '${AppLocalizations.of(context)!.editBulkTransfer} · ${editing.reference}'
                : AppLocalizations.of(context)!.bulkTransfer,
            isActionTrue: false,
            onAction: null,
            child: _buildBody(
              context,
              editing,
              busy || isActionBusy,
              isActionBusy,
            ),
          );
        },
      ),
    );
  }

  void _bulkListener(BuildContext context, BulkTransferState state) {
    if (state is BulkTransferSuccess) {
      ToastManager.show(
        context: context,
        title: 'Bulk transfer',
        message: state.message,
        type: ToastType.success,
      );
      Navigator.of(context).pop(true);
    } else if (state is BulkTransferDeleted) {
      ToastManager.show(
        context: context,
        title: 'Bulk transfer',
        message: 'Transaction ${state.reference} deleted.',
        type: ToastType.success,
      );
      Navigator.of(context).pop(true);
    } else if (state is BulkTransferFailure) {
      setState(() => _errorMessage = state.message);
    } else if (state is BulkTransferEditing &&
        state.reference != null &&
        state.rows.isNotEmpty) {
      final ccy = state.rows.first.currency;
      if (ccy != null && ccy.isNotEmpty && _headerCurrency != ccy && mounted) {
        setState(() => _headerCurrency = ccy);
      }
    }
  }

  void _transactionsListener(BuildContext context, TransactionsState state) {
    if (state is! TransactionsLoadedState) return;

    final success = state.actionSuccess;
    if (success != null) {
      ToastManager.show(
        context: context,
        title: 'Bulk transfer',
        message: success,
        type: ToastType.success,
      );
      context.read<TransactionsBloc>().add(const ClearRowActionSuccessEvent());

      final ref = _reference;
      if (ref != null && ref.isNotEmpty) {
        if (success.toLowerCase().contains('deleted')) {
          if (mounted) Navigator.of(context).pop(true);
        } else {
          context.read<BulkTransferBloc>().add(
            BulkTransferLoadForEditRequested(ref),
          );
        }
      }
      return;
    }

    final error = state.actionError;
    if (error != null) {
      setState(() => _errorMessage = error);
      context.read<TransactionsBloc>().add(const ClearRowActionErrorEvent());
    }
  }

  BulkTransferEditing _toEditing(BulkTransferState state) {
    if (state is BulkTransferEditing) return state;
    if (state is BulkTransferFailure) {
      final rows = state.rows;
      final debit = rows.fold<double>(0, (a, r) => a + r.debit);
      final credit = rows.fold<double>(0, (a, r) => a + r.credit);
      return BulkTransferEditing(
        rows: rows,
        totalDebit: debit,
        totalCredit: credit,
        reference: state.reference,
        status: state.status,
        stateText: state.stateText,
        makerName: state.makerName,
      );
    }
    if (state is BulkTransferLoadingForEdit) {
      return const BulkTransferEditing(
        rows: [],
        totalDebit: 0,
        totalCredit: 0,
      );
    }
    return const BulkTransferEditing(rows: [], totalDebit: 0, totalCredit: 0);
  }

  Widget _buildBody(
      BuildContext context,
      BulkTransferEditing state,
      bool busy,
      bool isActionBusy,
      ) {
    final isPending = state.isPending;
    final isAuthorized = state.isAuthorized;

    final auth = context.read<AuthBloc>().state;
    final loginName =
    auth is AuthenticatedState ? auth.loginData.usrName : null;
    final isMaker = state.isEditing &&
        state.makerName != null &&
        loginName != null &&
        state.makerName == loginName;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 140,
                child: CurrencyDropdown(
                  title: AppLocalizations.of(context)!.currencyTitle,
                  isMulti: false,
                  height: 35,
                  disableAction: busy,
                  initiallySelectedSingle:
                  CurrenciesModel(ccyCode: _headerCurrency),
                  onSingleChanged: (ccy) {
                    if (ccy?.ccyCode == null) return;
                    _changeHeaderCurrency(ccy!.ccyCode!);
                  },
                ),
              ),
              const SizedBox(width: 8),
              ZOutlineButton(
                height: 42,
                isActive: true,
                onPressed: busy
                    ? null
                    : () => _dispatch(const BulkTransferAddRow()),
                icon: Icons.add,
                label: Text(AppLocalizations.of(context)!.addRow),
              ),
              const Spacer(),
              if (!state.isEmpty) ...[
                _pill(
                  '${AppLocalizations.of(context)!.debit} '
                      '${state.totalDebit.toStringAsFixed(2)}',
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _pill(
                  '${AppLocalizations.of(context)!.credit} '
                      '${state.totalCredit.toStringAsFixed(2)}',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _pill(
                  'Diff ${state.difference.toStringAsFixed(2)}',
                  state.isBalanced ? Colors.green : Colors.red,
                ),
              ],
            ],
          ),
        ),

        // ── Inline warnings ──────────────────────────────────────
        if (_errorMessage != null && _errorMessage!.isNotEmpty)
          _banner(_errorMessage!, Colors.red),

        if (!state.isEmpty && state.hasCurrencyMix)
          _banner(
            'Rows use different currencies. Pick one currency for all rows.',
            Colors.orange,
          ),

        if (!state.isEmpty && !state.isBalanced)
          _banner('Total debit must equal total credit.', Colors.red),

        // ── Rows ─────────────────────────────────────────────────
        Expanded(
          child: state.isEmpty
              ? _emptyState()
              : ListView.separated(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: state.rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final row = state.rows[i];
              final isLast = i == state.rows.length - 1;
              return _BulkRowWidget(
                key: ValueKey(row.rowId),
                index: i,
                row: row,
                controllers: _ctrlFor(row),
                headerCurrency: _headerCurrency,
                enabled:
                !busy && (!state.isEditing || (isPending && isMaker)),
                isLast: isLast,
                onRowComplete: isLast ? _onRowComplete : null,
                onChanged: _dispatch,
              );
            },
          ),
        ),

        // ── Footer ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: Row(
            spacing: 8,
            children: [
              ZOutlineButton(
                onPressed: () => Navigator.of(context).pop(false),
                backgroundHover: Theme.of(context).colorScheme.error,
                label: Text(AppLocalizations.of(context)!.cancel),
              ),

              // Pending + maker → Delete + Authorize
              if (state.isEditing &&
                  isPending &&
                  isMaker &&
                  !busy &&
                  !isActionBusy) ...[
                ZOutlineButton(
                  onPressed: _dispatchDelete,
                  backgroundHover: Theme.of(context).colorScheme.error,
                  icon: Icons.delete_outline_rounded,
                  label: Text(AppLocalizations.of(context)!.delete),
                ),
                ZOutlineButton(
                  onPressed: _dispatchAuthorize,
                  icon: Icons.check_circle_outline_rounded,
                  isActive: true,
                  label: Text(AppLocalizations.of(context)!.authorize),
                ),
              ],

              // Authorized → Unauthorize + Reverse
              if (state.isEditing &&
                  isAuthorized &&
                  !busy &&
                  !isActionBusy) ...[
                ZOutlineButton(
                  onPressed: _dispatchUnauthorize,
                  icon: Icons.undo_rounded,
                  label: Text(AppLocalizations.of(context)!.unauthorize),
                ),
                ZOutlineButton(
                  onPressed: _dispatchReverse,
                  icon: Icons.replay_rounded,
                  label: Text(AppLocalizations.of(context)!.reverse),
                ),
              ],

              // Save / Update — create mode always; edit mode only if pending+maker
              if (!state.isEditing || (isPending && isMaker))
                ZOutlineButton(
                  icon: Icons.save_alt_rounded,
                  isActive: true,
                  onPressed: !state.canSubmit || busy ? null : _onSubmit,
                  label: busy || isActionBusy
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(state.isEditing
                      ? AppLocalizations.of(context)!.update
                      : AppLocalizations.of(context)!.save),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState() => Center(
    child: widget.reference != null && widget.reference!.isNotEmpty
        ? const CircularProgressIndicator()
        : const Text(
      'Add at least two rows — one debit and one credit — '
          'with the same total.',
      textAlign: TextAlign.center,
    ),
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
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

  _RowControllers(BulkTransferRow row)
      : account = TextEditingController(
    text: _initialAccountText(row),
  ),
        debit = TextEditingController(
          text: row.debit > 0 ? row.debit.toStringAsFixed(2) : '',
        ),
        credit = TextEditingController(
          text: row.credit > 0 ? row.credit.toStringAsFixed(2) : '',
        ),
        narration = TextEditingController(text: row.narration);

  static String _initialAccountText(BulkTransferRow row) {
    final hasName = row.accountName != null && row.accountName!.isNotEmpty;
    final hasNumber = row.accountNumber != null;
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

// ── Row widget ──────────────────────────────────────────────────

class _BulkRowWidget extends StatefulWidget {
  final int index;
  final BulkTransferRow row;
  final _RowControllers controllers;
  final String headerCurrency;
  final bool enabled;
  final bool isLast;
  final VoidCallback? onRowComplete;
  final void Function(BulkTransferUpdateRow) onChanged;

  const _BulkRowWidget({
    super.key,
    required this.index,
    required this.row,
    required this.controllers,
    required this.headerCurrency,
    required this.enabled,
    required this.isLast,
    required this.onChanged,
    this.onRowComplete,
  });

  @override
  State<_BulkRowWidget> createState() => _BulkRowWidgetState();
}

class _BulkRowWidgetState extends State<_BulkRowWidget> {
  bool _focusedOnce = false;

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

  void _onNarrationDone() {
    if (!widget.isLast) return;
    widget.onRowComplete?.call();
  }

  /// Stakeholder accounts (category 8) live in 500000–9999999 in this API.
  bool get _rowIsStakeholder {
    final n = widget.row.accountNumber;
    if (n == null) return false;
    return n >= 500000 && n < 10000000;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final c = widget.controllers;

    // Currency drop only shows once a GL account is picked.
    // Stakeholder currency is fixed by accountDetails, so no drop.
    final showCurrencyDrop =
        widget.row.accountNumber != null && !_rowIsStakeholder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          // ── index badge ────────────────────────────────────────
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

          // ── account picker + currency drop ─────────────────────
          Expanded(
            flex: 3,
            child: GenericTextField<StakeholderAccount, StkAccountsBloc,
                StkAccountsState>(
              controller: c.account,
              title: '',
              hintText: AppLocalizations.of(context)!.accNameOrNumber,
              isRequired: true,
              bloc: context.read<StkAccountsBloc>(),
              focusNode: c.accountFocus,
              textInputAction: TextInputAction.none,
              showAllOnFocus: true,
              fetchAllFunction: (bloc) =>
                  bloc.add(const LoadStkAccountsEvent()),
              searchFunction: (bloc, q) {
                if (q.trim().isEmpty) return;
                bloc.add(LoadStkAccountsEvent(query: q));
              },

              // ✅ FIX: currency-aware list badge.
              //  - Stakeholder → its own accCurrency (red if != header)
              //  - GL         → headerCurrency (always matches because
              //                 stateToItems already filtered to header)
              itemBuilder: (context, account) {
                final isStakeholder = account.accCategory == 8;
                final effectiveCcy = isStakeholder
                    ? (account.accCurrency ?? '')
                    : widget.headerCurrency;
                final matchesHeader = isStakeholder
                    ? effectiveCcy == widget.headerCurrency
                    : true;

                return Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                              color:
                              matchesHeader ? color.primary : color.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              itemToString: (a) => '${a.accNumber} | ${a.accName}',

              // ✅ FIX: filter by header currency.
              //   • 10101011 → excluded entirely
              //   • stakeholder (cat 8) → always shown, own currency
              //   • GL with accCurrency == null → shown (inherits header)
              //   • GL with accCurrency == header → shown
              //   • GL with other accCurrency → hidden
              //   • De-dupe by (account + currency)
              stateToItems: (s) {
                if (s is! StkAccountsLoadedState) {
                  return const <StakeholderAccount>[];
                }

                const excluded = <int>{10101011};

                final filtered = <StakeholderAccount>[];
                for (final a in s.accounts) {
                  if (excluded.contains(a.accNumber)) continue;

                  final isStakeholder = a.accCategory == 8;
                  if (isStakeholder) {
                    filtered.add(a);
                    continue;
                  }

                  if (a.accCurrency == null ||
                      a.accCurrency == widget.headerCurrency) {
                    filtered.add(a);
                  }
                }

                final seen = <String>{};
                return filtered.where((a) {
                  final key = '${a.accNumber}::${a.accCurrency ?? ''}';
                  if (seen.contains(key)) return false;
                  seen.add(key);
                  return true;
                }).toList();
              },
              stateToLoading: (s) => s is StkAccountsLoadingState,

              // ✅ FIX: correct currency resolution on selection.
              //   Stakeholder → its own accCurrency
              //   GL          → headerCurrency (always)
              onSelected: (a) {
                if (!widget.enabled) return;
                c.account.text = '${a.accNumber} | ${a.accName ?? ''}';

                final isStakeholder = a.accCategory == 8;
                final effectiveCcy = isStakeholder
                    ? (a.accCurrency ?? widget.headerCurrency)
                    : widget.headerCurrency;

                widget.onChanged(BulkTransferUpdateRow(
                  rowId: widget.row.rowId,
                  accountNumber: a.accNumber,
                  accountName: a.accName,
                  currency: effectiveCcy,
                ));

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) c.debitFocus.requestFocus();
                });
              },
              validator: (v) =>
              (widget.row.accountNumber == null) ? 'Required' : null,

              // ✅ FIX: expose the currency dropdown on GL rows so the
              // user can see (and change) the row currency.
              showCurrencySelector: showCurrencyDrop,
              isCurrencySelectorEnabled: widget.enabled,
              selectedCurrencyCodeOverride: _rowIsStakeholder
                  ? widget.row.currency
                  : widget.headerCurrency,
              onCurrencySelectorChanged: (ccy) {
                if (!widget.enabled) return;
                if (ccy?.ccyCode == null) return;
                widget.onChanged(BulkTransferUpdateRow(
                  rowId: widget.row.rowId,
                  currency: ccy!.ccyCode,
                ));
              },
            ),
          ),

          // ── debit ─────────────────────────────────────────────
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
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormat: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onFieldSubmitted: (_) => c.creditFocus.requestFocus(),
              onChanged: (v) {
                if (!widget.enabled) return;
                final d = double.tryParse(v) ?? 0;
                if (d > 0) c.credit.clear();
                widget.onChanged(BulkTransferUpdateRow(
                  rowId: widget.row.rowId,
                  debit: d,
                  credit: d > 0 ? 0 : widget.row.credit,
                ));
              },
            ),
          ),

          // ── credit ────────────────────────────────────────────
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
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormat: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onFieldSubmitted: (_) => c.narrationFocus.requestFocus(),
              onChanged: (v) {
                if (!widget.enabled) return;
                final cr = double.tryParse(v) ?? 0;
                if (cr > 0) c.debit.clear();
                widget.onChanged(BulkTransferUpdateRow(
                  rowId: widget.row.rowId,
                  credit: cr,
                  debit: cr > 0 ? 0 : widget.row.debit,
                ));
              },
            ),
          ),

          // ── narration ─────────────────────────────────────────
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
                widget.onChanged(BulkTransferUpdateRow(
                  rowId: widget.row.rowId,
                  narration: c.narration.text,
                ));
                _onNarrationDone();
              },
              onChanged: (v) {
                if (!widget.enabled) return;
                widget.onChanged(BulkTransferUpdateRow(
                  rowId: widget.row.rowId,
                  narration: v,
                ));
              },
            ),
          ),

          // ── delete ────────────────────────────────────────────
          _deleteButton(color),
        ],
      ),
    );
  }

  Widget _deleteButton(ColorScheme color) {
    final enabled = widget.enabled;
    bool hovering = false;
    return StatefulBuilder(
      builder: (context, setLocal) {
        final bg = !enabled
            ? color.error.withValues(alpha: .04)
            : hovering
            ? color.error.withValues(alpha: .20)
            : color.error.withValues(alpha: .08);

        final borderColor = enabled
            ? color.error.withValues(alpha: hovering ? .45 : .20)
            : color.error.withValues(alpha: .08);

        final fg =
        !enabled ? color.error.withValues(alpha: .4) : color.error;

        return Tooltip(
          message: 'Remove row',
          child: MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: (_) {
              if (enabled) setLocal(() => hovering = true);
            },
            onExit: (_) {
              if (enabled) setLocal(() => hovering = false);
            },
            child: GestureDetector(
              onTap: enabled
                  ? () => context
                  .read<BulkTransferBloc>()
                  .add(BulkTransferRemoveRow(widget.row.rowId))
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: enabled && hovering
                      ? [
                    BoxShadow(
                      color: color.error.withValues(alpha: .18),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                      : null,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: fg,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}