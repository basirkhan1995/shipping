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

/// Which row-action button is currently in flight. Drives the spinner
/// on the correct button without making the buttons disappear.
enum _RowAction { none, delete, authorize, unauthorize, reverse }

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

  /// Local busy flags — set on press, cleared on bloc success/failure.
  bool _formBusy = false; // Submit (Save / Update)
  _RowAction _pendingAction = _RowAction.none;

  /// True when any row action is in flight.
  bool get _actionBusy => _pendingAction != _RowAction.none;

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

  _RowControllers _ctrlFor(BulkTransferRow row) =>
      _controllers.putIfAbsent(row.rowId, () => _RowControllers(row));

  void _dispatch(BulkTransferEvent event) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
    context.read<BulkTransferBloc>().add(event);
  }

  void _changeHeaderCurrency(String ccy) {
    setState(() {
      _headerCurrency = ccy;
      _errorMessage = null;
    });
    final cur = context.read<BulkTransferBloc>().state;
    if (cur is! BulkTransferEditing) return;

    for (final row in cur.rows) {
      if (_isStakeholderAccount(row)) continue;
      if (row.currency != null && row.currency!.isNotEmpty) continue;
      context.read<BulkTransferBloc>().add(
        BulkTransferUpdateRow(rowId: row.rowId, currency: ccy),
      );
    }
  }

  bool _isStakeholderAccount(BulkTransferRow row) {
    final n = row.accountNumber;
    if (n == null) return false;
    return n >= 500000 && n < 10000000;
  }

  void _onRowComplete() => _dispatch(const BulkTransferAddRow());

  void _onSubmit() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
    _setFormBusy(true);

    final state = context.read<BulkTransferBloc>().state;
    if (state is BulkTransferEditing) {
      if (!state.canSubmit) {
        _setFormBusy(false);
        return;
      }
      final preview = state.rows.map((r) => r.toRecord()).toList();
      debugPrint('BULK POST records=$preview');
    } else {
      _setFormBusy(false);
      return;
    }

    context.read<BulkTransferBloc>().add(
      BulkTransferSubmitted(userName: widget.usrName),
    );
  }

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

  void _dispatchReverse() {
    final ref = _reference;
    if (ref == null || ref.isEmpty) return;
    if (_errorMessage != null) setState(() => _errorMessage = null);
    _setPendingAction(_RowAction.reverse);
    context.read<TransactionsBloc>().add(
      ReverseTransactionEvent(reference: ref, userName: _currentUserName()),
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
    _setPendingAction(_RowAction.delete);

    context.read<TransactionsBloc>().add(
      DeleteTransactionEvent(reference: ref, userName: _currentUserName()),
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

          final formBusy = _formBusy || bulkState is BulkTransferSubmitting;

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
                ? '${AppLocalizations.of(context)!.editBulkTransfer} · ${editing.reference}'
                : AppLocalizations.of(context)!.bulkTransfer,
            isActionTrue: false,
            onAction: null,
            child: _buildBody(context, editing, formBusy, rowBusy, anyBusy),
          );
        },
      ),
    );
  }

  void _bulkListener(BuildContext context, BulkTransferState state) {
    if (state is BulkTransferSuccess) {
      _setFormBusy(false);
      _clearPendingAction();
      ToastManager.show(
        context: context,
        title: 'Bulk transfer',
        message: state.message,
        type: ToastType.success,
      );
      Navigator.of(context).pop(true);
    } else if (state is BulkTransferDeleted) {
      _setFormBusy(false);
      _clearPendingAction();
      ToastManager.show(
        context: context,
        title: 'Bulk transfer',
        message: 'Transaction ${state.reference} deleted.',
        type: ToastType.success,
      );
      Navigator.of(context).pop(true);
    } else if (state is BulkTransferFailure) {
      _setFormBusy(false);
      _clearPendingAction();
      setState(() => _errorMessage = state.message);
    } else if (state is BulkTransferEditing &&
        state.reference != null &&
        state.rows.isNotEmpty) {
      // Successful reload after an action → clear the action spinner.
      _clearPendingAction();
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
      _clearPendingAction();
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
      _clearPendingAction();
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
      return const BulkTransferEditing(rows: [], totalDebit: 0, totalCredit: 0);
    }
    return const BulkTransferEditing(rows: [], totalDebit: 0, totalCredit: 0);
  }

  Set<String> _usedAccountCcyKeys(int currentRowId) {
    final state = context.read<BulkTransferBloc>().state;
    if (state is! BulkTransferEditing) return const {};
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

  Widget _buildBody(
    BuildContext context,
    BulkTransferEditing state,
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

    // Per-button busy flags.
    final deleteBusy = _pendingAction == _RowAction.delete;
    final updateBusy = formBusy;
    final authorizeBusy = _pendingAction == _RowAction.authorize;
    final unauthorizeBusy = _pendingAction == _RowAction.unauthorize;
    final reverseBusy = _pendingAction == _RowAction.reverse;

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
                  disableAction: anyBusy,
                  initiallySelectedSingle: CurrenciesModel(
                    ccyCode: _headerCurrency,
                  ),
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
                onPressed: anyBusy
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

        if (_errorMessage != null && _errorMessage!.isNotEmpty)
          _banner(_errorMessage!, Colors.red),

        if (!state.isEmpty && state.hasCurrencyMix)
          _banner(
            'Rows use different currencies. Pick one currency for all rows.',
            Colors.orange,
          ),

        if (!state.isEmpty && !state.isBalanced)
          _banner('Total debit must equal total credit.', Colors.red),

        Expanded(
          child: state.isEmpty
              ? _emptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: state.rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final row = state.rows[i];
                    final isLast = i == state.rows.length - 1;
                    final usedKeys = _usedAccountCcyKeys(row.rowId);
                    return _BulkRowWidget(
                      key: ValueKey(
                        'row-${row.rowId}-'
                        '${(usedKeys.toList()..sort()).join("|")}',
                      ),
                      index: i,
                      row: row,
                      controllers: _ctrlFor(row),
                      headerCurrency: _headerCurrency,
                      enabled:
                          !anyBusy &&
                          (!state.isEditing || (isPending && isMaker)),
                      isLast: isLast,
                      onRowComplete: isLast ? _onRowComplete : null,
                      onChanged: _dispatch,
                      usedAccountCcyKeys: usedKeys,
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
              // Cancel — disabled while anything is in flight.
              ZOutlineButton(
                onPressed: anyBusy
                    ? null
                    : () => Navigator.of(context).pop(false),
                backgroundHover: Theme.of(context).colorScheme.error,
                label: Text(AppLocalizations.of(context)!.cancel),
              ),

              // ── Maker, Pending → Delete + Update ─────────────
              if (state.isEditing && isPending && isMaker) ...[
                ZOutlineButton(
                  onPressed: anyBusy ? null : _dispatchDelete,
                  backgroundHover: Theme.of(context).colorScheme.error,
                  icon: deleteBusy ? null : Icons.delete_outline_rounded,
                  label: _busyLabel(
                    context,
                    busy: deleteBusy,
                    busyText: AppLocalizations.of(context)!.deleting,
                    idleText: AppLocalizations.of(context)!.delete,
                  ),
                ),
                ZOutlineButton(
                  icon: updateBusy ? null : Icons.save_alt_rounded,
                  isActive: !updateBusy,
                  onPressed: updateBusy || !state.canSubmit ? null : _onSubmit,
                  label: _busyLabel(
                    context,
                    busy: updateBusy,
                    busyText: AppLocalizations.of(context)!.updating,
                    idleText: AppLocalizations.of(context)!.update,
                  ),
                ),
              ],

              // ── Non-maker, Pending → Authorize ───────────────
              if (state.isEditing && isPending && !isMaker && loginName != null)
                ZOutlineButton(
                  onPressed: anyBusy ? null : _dispatchAuthorize,
                  icon: authorizeBusy
                      ? null
                      : Icons.check_circle_outline_rounded,
                  isActive: !authorizeBusy,
                  label: _busyLabel(
                    context,
                    busy: authorizeBusy,
                    busyText: AppLocalizations.of(context)!.authorizing,
                    idleText: AppLocalizations.of(context)!.authorize,
                  ),
                ),

              // ── Authorized → Unauthorize + Reverse ───────────
              if (state.isEditing && isAuthorized) ...[
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
                ZOutlineButton(
                  onPressed: anyBusy ? null : _dispatchReverse,
                  icon: reverseBusy ? null : Icons.replay_rounded,
                  isActive: !reverseBusy,
                  label: _busyLabel(
                    context,
                    busy: reverseBusy,
                    busyText: AppLocalizations.of(context)!.reversing,
                    idleText: AppLocalizations.of(context)!.reverse,
                  ),
                ),
              ],

              // ── Create mode → Save ───────────────────────────
              if (!state.isEditing)
                ZOutlineButton(
                  icon: formBusy ? null : Icons.save_alt_rounded,
                  isActive: !formBusy,
                  onPressed: formBusy || !state.canSubmit ? null : _onSubmit,
                  label: _busyLabel(
                    context,
                    busy: formBusy,
                    busyText: AppLocalizations.of(context)!.saving,
                    idleText: AppLocalizations.of(context)!.save,
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
    : account = TextEditingController(text: _initialAccountText(row)),
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
  final Set<String> usedAccountCcyKeys;

  const _BulkRowWidget({
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

  bool get _rowIsStakeholder {
    final n = widget.row.accountNumber;
    if (n == null) return false;
    return n >= 500000 && n < 10000000;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final c = widget.controllers;

    final showCurrencyDrop =
        widget.row.accountNumber != null && widget.row.currency != null;

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
            child:
                GenericTextField<
                  StakeholderAccount,
                  StkAccountsBloc,
                  StkAccountsState
                >(
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

                  itemBuilder: (context, account) {
                    final ownCcy = account.accCurrency;
                    final effectiveCcy = (ownCcy != null && ownCcy.isNotEmpty)
                        ? ownCcy
                        : widget.headerCurrency;
                    final matchesHeader = effectiveCcy == widget.headerCurrency;

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
                      return const <StakeholderAccount>[];
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

                    final filtered = <StakeholderAccount>[];
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

                      if (a.accCurrency == null ||
                          a.accCurrency == widget.headerCurrency) {
                        filtered.add(a);
                      }
                    }

                    final seen = <String>{};
                    return filtered.where((a) {
                      final k = '${a.accNumber}::${a.accCurrency ?? ''}';
                      if (seen.contains(k)) return false;
                      seen.add(k);
                      return true;
                    }).toList();
                  },
                  stateToLoading: (s) => s is StkAccountsLoadingState,

                  onSelected: (a) {
                    if (!widget.enabled) return;
                    final effectiveCcy = (a.accCurrency?.isNotEmpty == true)
                        ? a.accCurrency!
                        : widget.headerCurrency;
                    c.account.text =
                        '${a.accNumber} | ${a.accName ?? ''} | $effectiveCcy';

                    widget.onChanged(
                      BulkTransferUpdateRow(
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
                  isCurrencySelectorEnabled:
                      widget.enabled && !_rowIsStakeholder,
                  selectedCurrencyCodeOverride:
                      widget.row.currency ?? widget.headerCurrency,
                  onCurrencySelectorChanged: (ccy) {
                    if (!widget.enabled) return;
                    if (ccy?.ccyCode == null) return;
                    widget.onChanged(
                      BulkTransferUpdateRow(
                        rowId: widget.row.rowId,
                        currency: ccy!.ccyCode,
                      ),
                    );
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
                  BulkTransferUpdateRow(
                    rowId: widget.row.rowId,
                    debit: d,
                    credit: d > 0 ? 0 : widget.row.credit,
                  ),
                );
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
                  BulkTransferUpdateRow(
                    rowId: widget.row.rowId,
                    credit: cr,
                    debit: cr > 0 ? 0 : widget.row.debit,
                  ),
                );
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
                widget.onChanged(
                  BulkTransferUpdateRow(
                    rowId: widget.row.rowId,
                    narration: c.narration.text,
                  ),
                );
                _onNarrationDone();
              },
              onChanged: (v) {
                if (!widget.enabled) return;
                widget.onChanged(
                  BulkTransferUpdateRow(rowId: widget.row.rowId, narration: v),
                );
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

        final fg = !enabled ? color.error.withValues(alpha: .4) : color.error;

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
                  ? () => context.read<BulkTransferBloc>().add(
                      BulkTransferRemoveRow(widget.row.rowId),
                    )
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
                child: Icon(Icons.delete_outline_rounded, size: 18, color: fg),
              ),
            ),
          ),
        );
      },
    );
  }
}
