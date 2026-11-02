// features/journal/cash/view/cash_txn_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/extensions.dart';
import 'package:shipping/Features/Widgets/zbutton.dart'; // ZOutlineButton
import 'package:shipping/Routes/Home/View/Stakeholder/model/stk_model.dart';
import 'package:shipping/l10n/app_localizations.dart';

import '../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../Features/Widgets/z_dialog.dart';
import '../../../../../../Features/Widgets/toast.dart';
import '../../../../../../Services/repository.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../bloc/transactions_bloc.dart';
import '../../model/trn_model.dart';
import 'bloc/cash_txn_bloc.dart';
import 'bloc/cash_txn_event.dart';

/// Configuration that differs per transaction type.
class CashTxnSpec {
  final String typeCode;
  final IconData icon;
  final String Function(BuildContext) title;
  final String accountInclude;
  final String accountExclude;
  final bool restrictToBaseCurrency;
  final bool allowReminder;
  final bool editableCurrency;
  final int? perId;
  const CashTxnSpec({
    required this.typeCode,
    required this.icon,
    required this.title,
    this.accountInclude = '8',
    this.accountExclude = '',
    this.restrictToBaseCurrency = false,
    this.allowReminder = false,
    this.editableCurrency = false,
    this.perId,
  });
}

// ═════════════════════════════════════════════════════════════════
// FORM
// ═════════════════════════════════════════════════════════════════

class CashTxnForm extends StatefulWidget {
  final CashTxnSpec spec;
  final String usrName;
  final String baseCurrency;
  final ValueChanged<TransactionDraft> onSubmit;

  /// Optional external trigger so the dialog (mouse click) and the
  /// narration field (Enter key) go through the *same* submit path.
  final VoidCallback? onSubmitRequested;

  final TransactionDraft? initialDraft;
  final String? stateText;

  const CashTxnForm({
    super.key,
    required this.spec,
    required this.usrName,
    required this.baseCurrency,
    required this.onSubmit,
    this.onSubmitRequested,
    this.initialDraft,
    this.stateText,
  });

  @override
  State<CashTxnForm> createState() => CashTxnFormState();
}

class CashTxnFormState extends State<CashTxnForm> {
  final _internalKey = GlobalKey<FormState>();
  GlobalKey<FormState> get _formKey => _internalKey;

  final _accountCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _narrationCtrl = TextEditingController();

  final _accountFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _narrationFocus = FocusNode();

  StakeholderAccount? _acc;
  String? _ccy;
  bool _print = true;
  bool _reminder = false;
  DateTime? _reminderDate;

  /// Edit-mode fallback: the account number from the loaded draft, kept
  /// so we can (a) render the details card before the full row loads and
  /// (b) fetch the full row by number.
  int? _draftAccountNo;

  /// Pending sync request — set when we dispatch a load for a draft
  /// account so the loaded row updates `_acc` once the bloc responds.
  int? _pendingAccountNo;

  static const int _stakeholderCategory = 8;

  bool get _isEditable =>
      widget.stateText == null || widget.stateText == 'Pending';

  /// Effective account number — either the selected row's number or the
  /// draft's number (edit mode before the row has loaded).
  int? get _effectiveAccountNo => _acc?.accNumber ?? _draftAccountNo;

  @override
  void initState() {
    super.initState();
    _ccy = widget.baseCurrency;
    _applyDraft(widget.initialDraft);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isEditable) _accountFocus.requestFocus();
      });
    });
  }

  @override
  void didUpdateWidget(covariant CashTxnForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldRef = oldWidget.initialDraft?.trnReference;
    final newRef = widget.initialDraft?.trnReference;
    final draftArrived =
        oldWidget.initialDraft == null && widget.initialDraft != null;
    final refChanged = oldRef != newRef;

    if (draftArrived || refChanged) {
      setState(() => _applyDraft(widget.initialDraft));
    }
  }

  void _applyDraft(TransactionDraft? draft) {
    if (draft == null) return;

    _ccy = draft.trdCcy ?? widget.baseCurrency;
    _amountCtrl.text = draft.trdAmount ?? '';
    _narrationCtrl.text = draft.trdNarration ?? '';

    if (draft.trdAccount != null) {
      _draftAccountNo = draft.trdAccount;
      _accountCtrl.text = draft.trdAccount.toString();

      // Fetch the full account row so we can render the details card
      // in edit mode (mirroring Fund Transfer's behavior).
      _pendingAccountNo = draft.trdAccount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<StkAccountsBloc>().add(
          LoadStkAccountsEvent(query: '${draft.trdAccount}'),
        );
      });
    } else {
      _draftAccountNo = null;
      _accountCtrl.text = '';
    }
  }

  @override
  void dispose() {
    _accountFocus.dispose();
    _amountFocus.dispose();
    _narrationFocus.dispose();
    _accountCtrl.dispose();
    _amountCtrl.dispose();
    _narrationCtrl.dispose();
    super.dispose();
  }

  /// Sync `_acc` once the bloc returns the row for the pending number.
  /// Runs from a `BlocListener<StkAccountsBloc>` in `build()`.
  void _applyPendingAccountSync(List<StakeholderAccount> rows) {
    final pending = _pendingAccountNo;
    if (pending == null) return;

    StakeholderAccount? found;
    for (final a in rows) {
      if (a.accNumber == pending) {
        found = a;
        break;
      }
    }

    _pendingAccountNo = null;
    if (found == null) return;

    setState(() => _acc = found);
  }

  /// Validates and dispatches the draft.
  ///
  /// Returns `true` when a `TransactionDraft` was actually sent to
  /// `widget.onSubmit`, `false` when validation blocked it.
  bool submit() {
    if (!_isEditable) return false;

    final ok = _formKey.currentState?.validate() == true;
    debugPrint(
      'CashTxnForm.submit: valid=$ok acc=${_acc?.accNumber} '
      'draftAcc=${widget.initialDraft?.trdAccount} ccy=$_ccy',
    );
    if (!ok) return false;

    final draft = widget.initialDraft;
    final accNumber = _effectiveAccountNo;
    if (accNumber == null) {
      debugPrint('CashTxnForm.submit: no account number — aborting');
      return false;
    }

    widget.onSubmit(
      TransactionDraft(
        trnReference: draft?.trnReference,
        trnType: widget.spec.typeCode,
        usrName: widget.usrName,
        trdAccount: accNumber,
        trdCcy: _ccy ?? widget.baseCurrency,
        trdAmount: _amountCtrl.text.replaceAll(',', '').trim(),
        trdNarration: _narrationCtrl.text.trim(),
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return BlocListener<StkAccountsBloc, StkAccountsState>(
      listenWhen: (prev, next) =>
          next is StkAccountsLoadedState && _pendingAccountNo != null,
      listener: (context, state) {
        if (state is! StkAccountsLoadedState) return;
        _applyPendingAccountSync(state.accounts);
      },
      child: Form(
        key: _internalKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              _buildAccountPicker(),

              // Show the details card when we have either the full row
              // or just the draft's account number (edit mode).
              if (_acc != null)
                _AccountDetailsCard(
                  account: _acc!,
                  fallbackCurrency: widget.baseCurrency,
                  label: tr.details,
                  effectiveCurrencyOverride: _ccy,
                )
              else if (_effectiveAccountNo != null)
                _PendingAccountCard(
                  accountNo: _effectiveAccountNo!,
                  fallbackCurrency: widget.baseCurrency,
                  effectiveCurrency: _ccy ?? widget.baseCurrency,
                  label: tr.details,
                ),

              _buildAmountField(),
              _buildNarrationField(),
              _buildToggles(),
              if (_reminder) _buildReminderPicker(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Account picker ─────────────────────────────────────────────
  Widget _buildAccountPicker() =>
      GenericTextField<StakeholderAccount, StkAccountsBloc, StkAccountsState>(
        controller: _accountCtrl,
        title: AppLocalizations.of(context)!.accounts,
        hintText: AppLocalizations.of(context)!.accNameOrNumber,
        isRequired: true,
        bloc: context.read<StkAccountsBloc>(),
        focusNode: _accountFocus,
        textInputAction: TextInputAction.none,
        showAllOnFocus: false,
        fetchAllFunction: null,
        readOnly: !_isEditable,
        searchFunction: (bloc, q) {
          if (q.trim().isEmpty) return;
          bloc.add(LoadStkAccountsEvent(query: q, perId: widget.spec.perId));
        },
        itemBuilder: (context, account) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${account.accNumber} | ${account.accName}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '${account.accBalance.toAmount()} '
                '${account.accCurrency ?? widget.baseCurrency}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        itemToString: (a) => '${a.accNumber} | ${a.accName}',
        stateToItems: (s) {
          if (s is! StkAccountsLoadedState) {
            return const <StakeholderAccount>[];
          }
          return _filterAccounts(s.accounts);
        },
        stateToLoading: (s) => s is StkAccountsLoadingState,
        onSelected: (a) {
          setState(() {
            _acc = a;
            _draftAccountNo = a.accNumber;
            _pendingAccountNo = null;

            final isStakeholder = a.accCategory == _stakeholderCategory;
            if (!isStakeholder) {
              _ccy = widget.baseCurrency;
            } else if (!widget.spec.editableCurrency) {
              _ccy = a.accCurrency ?? widget.baseCurrency;
            }
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _amountFocus.requestFocus();
          });
        },
        validator: (_) => _effectiveAccountNo == null ? 'Required' : null,
      );

  List<StakeholderAccount> _filterAccounts(List<StakeholderAccount> all) {
    final includeRaw = widget.spec.accountInclude.trim();
    final includeAll = includeRaw.isEmpty || includeRaw.toLowerCase() == 'all';

    final include = includeAll
        ? const <int>{}
        : includeRaw
              .split(',')
              .map((s) => int.tryParse(s.trim()))
              .whereType<int>()
              .toSet();

    final exclude = widget.spec.accountExclude
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    return all.where((a) {
      if (include.isNotEmpty && !include.contains(a.accCategory)) {
        return false;
      }
      if (exclude.contains(a.accNumber.toString())) return false;
      if (widget.spec.restrictToBaseCurrency &&
          widget.baseCurrency.isNotEmpty &&
          a.accCurrency != null &&
          a.accCurrency != widget.baseCurrency) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildAmountField() => ZTextFieldEntitled(
    controller: _amountCtrl,
    title: AppLocalizations.of(context)!.amount,
    isRequired: true,
    isEnabled: _isEditable,
    focusNode: _amountFocus,
    textInputAction: TextInputAction.none,
    onFieldSubmitted: (_) => _narrationFocus.requestFocus(),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormat: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    validator: (v) {
      if (!_isEditable) return null;
      final n = double.tryParse((v ?? '').replaceAll(',', ''));
      if (n == null || n <= 0) return 'Must be greater than zero';
      return null;
    },
  );

  Widget _buildNarrationField() => ZTextFieldEntitled(
    controller: _narrationCtrl,
    title: AppLocalizations.of(context)!.narration,
    isEnabled: _isEditable,
    focusNode: _narrationFocus,
    textInputAction: TextInputAction.none,
    onFieldSubmitted: (_) => (widget.onSubmitRequested ?? submit)(),
    keyboardType: TextInputType.multiline,
    validator: (v) => (!_isEditable || (v != null && v.trim().isNotEmpty))
        ? null
        : 'Required',
  );

  Widget _buildToggles() => Row(
    spacing: 12,
    children: [
      if (widget.spec.allowReminder && _isEditable)
        _Check(
          label: AppLocalizations.of(context)!.setReminder,
          value: _reminder,
          onChanged: (v) => setState(() => _reminder = v),
        ),
      if (_isEditable)
        _Check(
          label: AppLocalizations.of(context)!.print,
          value: _print,
          onChanged: (v) => setState(() => _print = v),
        ),
    ],
  );

  Widget _buildReminderPicker() => ZDatePicker(
    label: AppLocalizations.of(context)!.dueDate,
    disablePastDate: true,
    value: _reminderDate?.toIso8601String(),
    onDateChanged: (v) => setState(() => _reminderDate = DateTime.tryParse(v)),
  );
}

// ═════════════════════════════════════════════════════════════════
// DIALOG
// ═════════════════════════════════════════════════════════════════

Future<bool?> showCashTxnDialog(
  BuildContext context, {
  required CashTxnSpec spec,
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
            final bloc = CashTxnBloc(ctx.read<Repositories>());
            if (reference != null && reference.isNotEmpty) {
              bloc.add(CashTxnLoadRequested(reference));
            }
            return bloc;
          },
        ),
        BlocProvider<TransactionsBloc>.value(
          value: context.read<TransactionsBloc>(),
        ),
      ],
      child: _CashTxnDialog(
        spec: spec,
        usrName: usrName,
        baseCurrency: baseCurrency,
        reference: reference,
      ),
    ),
  );
}

class _CashTxnDialog extends StatefulWidget {
  final CashTxnSpec spec;
  final String usrName;
  final String baseCurrency;
  final String? reference;

  const _CashTxnDialog({
    required this.spec,
    required this.usrName,
    required this.baseCurrency,
    this.reference,
  });

  @override
  State<_CashTxnDialog> createState() => _CashTxnDialogState();
}

class _CashTxnDialogState extends State<_CashTxnDialog> {
  String? _localError;

  /// Stable key — attached to `CashTxnForm.key` so `currentState`
  /// resolves to the live `CashTxnFormState` (mouse + Enter share one path).
  final _formKey = GlobalKey<CashTxnFormState>();

  bool _formBusy = false;
  bool _actionBusy = false;

  CashTxnSpec get spec => widget.spec;
  String get usrName => widget.usrName;
  String get baseCurrency => widget.baseCurrency;
  String? get reference => widget.reference;

  bool get _isEditing => reference != null && reference!.isNotEmpty;

  String? _loginName(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthenticatedState ? auth.loginData.usrName : null;
  }

  void _clearLocalError() {
    if (_localError != null && mounted) {
      setState(() => _localError = null);
    }
  }

  void _setFormBusy(bool v) {
    if (mounted) setState(() => _formBusy = v);
  }

  void _setActionBusy(bool v) {
    if (mounted) setState(() => _actionBusy = v);
  }

  // ── Form submit (mouse + keyboard both land here) ─────────────
  void _onFormSubmit() {
    final st = _formKey.currentState;
    if (st == null) return;

    _clearLocalError();
    _setFormBusy(true);

    final dispatched = st.submit();
    if (!dispatched) _setFormBusy(false);
  }

  // ── Row actions ───────────────────────────────────────────────
  void _dispatchAuthorize(BuildContext context) {
    final ref = reference;
    if (ref == null || ref.isEmpty) return;
    _clearLocalError();
    _setActionBusy(true);
    context.read<TransactionsBloc>().add(
      AuthorizeTransactionEvent(reference: ref, userName: _loginName(context)),
    );
  }

  void _dispatchUnauthorize(BuildContext context) {
    final ref = reference;
    if (ref == null || ref.isEmpty) return;
    _clearLocalError();
    _setActionBusy(true);
    context.read<TransactionsBloc>().add(
      UnauthorizeTransactionEvent(
        reference: ref,
        userName: _loginName(context),
      ),
    );
  }

  void _dispatchReverse(BuildContext context) {
    final ref = reference;
    if (ref == null || ref.isEmpty) return;
    _clearLocalError();
    _setActionBusy(true);
    context.read<TransactionsBloc>().add(
      ReverseTransactionEvent(reference: ref, userName: _loginName(context)),
    );
  }

  Future<void> _dispatchDelete(BuildContext context) async {
    final ref = reference;
    if (ref == null || ref.isEmpty) return;

    final tr = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(tr.delete),
        content: Text('Delete transaction $ref?\n\nThis cannot be undone.'),
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
    if (!context.mounted) return;

    _clearLocalError();
    _setActionBusy(true);

    context.read<TransactionsBloc>().add(
      DeleteTransactionEvent(reference: ref, userName: _loginName(context)),
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
        BlocListener<CashTxnBloc, CashTxnState>(
          listener: (context, state) {
            if (state is CashTxnSuccess) {
              _setFormBusy(false);
              ToastManager.show(
                context: context,
                title: 'Saved',
                message: 'Transaction saved.',
                type: ToastType.success,
              );
              Navigator.of(context).pop(true);
              return;
            }
            if (state is CashTxnFailure) {
              _setFormBusy(false);
            }
          },
        ),
        BlocListener<TransactionsBloc, TransactionsState>(
          listenWhen: (prev, next) =>
              next is TransactionsLoadedState &&
              (next.actionSuccess != null || next.actionError != null),
          listener: (context, state) {
            if (state is! TransactionsLoadedState) return;

            final success = state.actionSuccess;
            if (success != null) {
              _setActionBusy(false);
              if (mounted && _localError != null) {
                setState(() => _localError = null);
              }
              ToastManager.show(
                context: context,
                title: 'Success',
                message: success,
                type: ToastType.success,
              );
              context.read<TransactionsBloc>().add(
                const ClearRowActionSuccessEvent(),
              );

              final ref = reference;
              if (ref != null && ref.isNotEmpty) {
                if (success.toLowerCase().contains('deleted')) {
                  Navigator.of(context).pop(true);
                  return;
                }
                context.read<CashTxnBloc>().add(CashTxnLoadRequested(ref));
              }
              return;
            }

            final error = state.actionError;
            if (error != null) {
              _setActionBusy(false);
              if (mounted) {
                setState(() => _localError = error);
              }
              context.read<TransactionsBloc>().add(
                const ClearRowActionErrorEvent(),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<CashTxnBloc, CashTxnState>(
        builder: (context, state) {
          final cashBusy = _formBusy || state is CashTxnSubmitting;

          final rowBusy =
              _actionBusy ||
              context.select<TransactionsBloc, bool>((bloc) {
                final s = bloc.state;
                if (s is! TransactionsLoadedState) return false;
                final ref = reference;
                if (ref == null || ref.isEmpty) return false;
                return s.actionInProgress == ref;
              });

          final anyBusy = cashBusy || rowBusy;

          final loaded = state is CashTxnLoadedForEdit ? state : null;

          final stateText = loaded?.stateText;
          final isPending = stateText == null || stateText == 'Pending';
          final isAuthorized = stateText == 'Authorized';

          final loginName = _loginName(context);
          final isMaker =
              loaded == null ||
              (loaded.makerName != null &&
                  loginName != null &&
                  loaded.makerName == loginName);

          final initial = loaded?.draft;
          final isEditing = _isEditing;

          if (isEditing && loaded == null && state is! CashTxnFailure) {
            return ZFormDialog(
              width: 600,
              icon: spec.icon,
              title: '${spec.title(context)} · $reference',
              isActionTrue: false,
              onAction: null,
              child: const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return ZFormDialog(
            width: 600,
            icon: spec.icon,
            title: isEditing
                ? '${spec.title(context)} · $reference'
                : spec.title(context),
            isActionTrue: false,
            onAction: null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state is CashTxnFailure && state.message.isNotEmpty)
                    _banner(state.message, Theme.of(context).colorScheme.error),

                  if (_localError != null && _localError!.isNotEmpty)
                    _banner(_localError!, Theme.of(context).colorScheme.error),

                  Flexible(
                    child: CashTxnForm(
                      key: _formKey,
                      spec: spec,
                      usrName: usrName,
                      baseCurrency: baseCurrency,
                      initialDraft: initial,
                      stateText: stateText,
                      onSubmitRequested: _onFormSubmit,
                      onSubmit: (draft) {
                        _clearLocalError();
                        if (isEditing) {
                          context.read<CashTxnBloc>().add(
                            CashTxnUpdateRequested(draft),
                          );
                        } else {
                          context.read<CashTxnBloc>().add(
                            CashTxnCreateRequested(draft),
                          );
                        }
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ZOutlineButton(
                          onPressed: anyBusy
                              ? null
                              : () => Navigator.of(context).pop(false),
                          label: Text(AppLocalizations.of(context)!.cancel),
                        ),

                        if (isEditing && isPending && isMaker) ...[
                          ZOutlineButton(
                            onPressed: anyBusy
                                ? null
                                : () => _dispatchDelete(context),
                            backgroundHover: Theme.of(context)
                                .colorScheme
                                .error,
                            icon: rowBusy ? null : Icons.delete_outline_rounded,
                            label: _busyLabel(
                              context,
                              busy: rowBusy,
                              busyText: AppLocalizations.of(context)!.deleting,
                              idleText: AppLocalizations.of(context)!.delete,
                            ),
                          ),
                          ZOutlineButton(
                            isActive: !cashBusy,
                            onPressed: cashBusy ? null : _onFormSubmit,
                            icon: cashBusy ? null : Icons.save_alt_rounded,
                            label: _busyLabel(
                              context,
                              busy: cashBusy,
                              busyText: AppLocalizations.of(context)!.updating,
                              idleText: AppLocalizations.of(context)!.update,
                            ),
                          ),
                        ],

                        if (isEditing && isPending && !isMaker)
                          ZOutlineButton(
                            isActive: !rowBusy,
                            onPressed: rowBusy
                                ? null
                                : () => _dispatchAuthorize(context),
                            icon: rowBusy
                                ? null
                                : Icons.check_circle_outline_rounded,
                            label: _busyLabel(
                              context,
                              busy: rowBusy,
                              busyText: AppLocalizations.of(context)!
                                  .authorizing,
                              idleText: AppLocalizations.of(context)!.authorize,
                            ),
                          ),

                        if (isEditing && isAuthorized) ...[
                          ZOutlineButton(
                            isActive: !rowBusy,
                            onPressed: rowBusy
                                ? null
                                : () => _dispatchUnauthorize(context),
                            icon: rowBusy ? null : Icons.undo_rounded,
                            label: _busyLabel(
                              context,
                              busy: rowBusy,
                              busyText: AppLocalizations.of(context)!
                                  .unauthorize,
                              idleText: AppLocalizations.of(context)!
                                  .unauthorize,
                            ),
                          ),
                          ZOutlineButton(
                            isActive: !rowBusy,
                            onPressed: rowBusy
                                ? null
                                : () => _dispatchReverse(context),
                            icon: rowBusy ? null : Icons.replay_rounded,
                            label: _busyLabel(
                              context,
                              busy: rowBusy,
                              busyText: AppLocalizations.of(context)!.reversing,
                              idleText: AppLocalizations.of(context)!.reverse,
                            ),
                          ),
                        ],

                        if (!isEditing)
                          ZOutlineButton(
                            isActive: !cashBusy,
                            onPressed: cashBusy ? null : _onFormSubmit,
                            icon: cashBusy ? null : Icons.save_alt_rounded,
                            label: _busyLabel(
                              context,
                              busy: cashBusy,
                              busyText: AppLocalizations.of(context)!.saving,
                              idleText: AppLocalizations.of(context)!.save,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _banner(String text, Color color) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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

// ── Shared widgets ──────────────────────────────────────────────

class _Check extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Check({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Row(
    spacing: 5,
    children: [
      Checkbox(
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        value: value,
        onChanged: (v) => onChanged(v ?? false),
      ),
      Text(label),
    ],
  );
}

/// Full details card — mirrors the Fund Transfer version.
class _AccountDetailsCard extends StatelessWidget {
  final StakeholderAccount account;
  final String fallbackCurrency;
  final String label;
  final String? effectiveCurrencyOverride;

  const _AccountDetailsCard({
    required this.account,
    required this.fallbackCurrency,
    this.label = 'Account details',
    this.effectiveCurrencyOverride,
  });

  static const int _stakeholderCategory = 8;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final title = Theme.of(context).textTheme.titleSmall;

    Widget row(String k, String v, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(k, style: title)),
          Expanded(
            child: Text(
              v,
              style: bold
                  ? title?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.w700,
                    )
                  : title,
            ),
          ),
        ],
      ),
    );

    final isStakeholder = account.accCategory == _stakeholderCategory;
    final status = account.accStatus;
    final effectiveCcy =
        account.accCurrency ??
        effectiveCurrencyOverride ??
        (fallbackCurrency.isEmpty ? '' : fallbackCurrency);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: .02),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: title?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(),
          row('Account number', account.accNumber?.toString() ?? ''),
          row('Account name', account.accName ?? ''),
          row(
            'Balance',
            '${account.accBalance.toAmount()} ${account.accCurrency ?? effectiveCcy}',
          ),
          if (isStakeholder && status != null)
            row('Status', status == 1 ? 'Active' : 'Blocked'),
        ],
      ),
    );
  }
}

/// Lightweight card shown while the full [StakeholderAccount] row is
/// still loading in edit mode. Renders from the draft's account number
/// and the known currency so the user sees something immediately.
class _PendingAccountCard extends StatelessWidget {
  final int accountNo;
  final String fallbackCurrency;
  final String? effectiveCurrency;
  final String label;

  const _PendingAccountCard({
    required this.accountNo,
    required this.fallbackCurrency,
    required this.label,
    this.effectiveCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final title = Theme.of(context).textTheme.titleSmall;

    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(k, style: title)),
          Expanded(child: Text(v, style: title)),
        ],
      ),
    );

    final ccy = effectiveCurrency ?? fallbackCurrency;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: .02),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: title?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
          const Divider(),
          row('Account number', accountNo.toString()),
          row('Currency', ccy),
        ],
      ),
    );
  }
}
