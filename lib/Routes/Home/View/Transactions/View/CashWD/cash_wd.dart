// features/journal/cash/view/cash_txn_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/extensions.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';                     // ZOutlineButton
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

  const CashTxnSpec({
    required this.typeCode,
    required this.icon,
    required this.title,
    this.accountInclude = '8',
    this.accountExclude = '',
    this.restrictToBaseCurrency = false,
    this.allowReminder = false,
    this.editableCurrency = false,
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
  final GlobalKey<CashTxnFormState>? formKey;
  final TransactionDraft? initialDraft;
  final String? stateText;

  const CashTxnForm({
    super.key,
    required this.spec,
    required this.usrName,
    required this.baseCurrency,
    required this.onSubmit,
    this.formKey,
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

  static const int _stakeholderCategory = 8;

  bool get _isEditable =>
      widget.stateText == null || widget.stateText == 'Pending';

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
      _accountCtrl.text = draft.trdAccount.toString();
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

  void submit() {
    if (!_isEditable) return;
    final ok = _formKey.currentState?.validate() == true;
    debugPrint(
      'CashTxnForm.submit: valid=$ok acc=${_acc?.accNumber} '
          'draftAcc=${widget.initialDraft?.trdAccount} ccy=$_ccy',
    );
    if (!ok) return;

    // In edit mode _acc is null because the draft only carries the number.
    // Fall back to the draft's account number so Update works.
    final draft = widget.initialDraft;
    final accNumber = _acc?.accNumber ?? draft?.trdAccount;
    if (accNumber == null) {
      debugPrint('CashTxnForm.submit: no account number — aborting');
      return;
    }

    widget.onSubmit(TransactionDraft(
      trnReference: draft?.trnReference,
      trnType: widget.spec.typeCode,
      usrName: widget.usrName,
      trdAccount: accNumber,
      trdCcy: _ccy ?? widget.baseCurrency,
      trdAmount: _amountCtrl.text.replaceAll(',', '').trim(),
      trdNarration: _narrationCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        // ── FIX #3 — constrain height so the dialog doesn't fill the screen
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            _buildAccountPicker(),
            if (_acc != null)
              _AccountDetailsCard(
                account: _acc!,
                fallbackCurrency: widget.baseCurrency,
              ),
            _buildAmountField(),
            _buildNarrationField(),
            _buildToggles(),
            if (_reminder) _buildReminderPicker(),
          ],
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
          bloc.add(LoadStkAccountsEvent(query: q));
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
        validator: (v) =>
        (_acc == null && widget.initialDraft?.trdAccount == null)
            ? 'Required'
            : null,
      );

  List<StakeholderAccount> _filterAccounts(List<StakeholderAccount> all) {
    final includeRaw = widget.spec.accountInclude.trim();
    final includeAll =
        includeRaw.isEmpty || includeRaw.toLowerCase() == 'all';

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
    inputFormat: [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
    ],
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
    onFieldSubmitted: (_) => submit(),
    keyboardType: TextInputType.multiline,
    validator: (v) =>
    (!_isEditable || (v != null && v.trim().isNotEmpty))
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
    onDateChanged: (v) =>
        setState(() => _reminderDate = DateTime.tryParse(v)),
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

class _CashTxnDialog extends StatelessWidget {
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

  bool get _isEditing => reference != null && reference!.isNotEmpty;

  String? _loginName(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthenticatedState ? auth.loginData.usrName : null;
  }

  void _dispatchAuthorize(BuildContext context) {
    final ref = reference;
    if (ref == null || ref.isEmpty) return;
    context.read<TransactionsBloc>().add(
      AuthorizeTransactionEvent(
        reference: ref,
        userName: _loginName(context),
      ),
    );
  }

  void _dispatchUnauthorize(BuildContext context) {
    final ref = reference;
    if (ref == null || ref.isEmpty) return;
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
    context.read<TransactionsBloc>().add(
      ReverseTransactionEvent(
        reference: ref,
        userName: _loginName(context),
      ),
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
        content: Text(
          'Delete transaction $ref?\n\nThis cannot be undone.',
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
    if (!context.mounted) return;

    context.read<TransactionsBloc>().add(
      DeleteTransactionEvent(
        reference: ref,
        userName: _loginName(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<CashTxnFormState>();

    return MultiBlocListener(
      listeners: [
        // ── Cash bloc: save / load-for-edit result ─────────────────
        BlocListener<CashTxnBloc, CashTxnState>(
          listener: (context, state) {
            if (state is CashTxnSuccess) {
              ToastManager.show(
                context: context,
                title: 'Saved',
                message: 'Transaction saved.',
                type: ToastType.success,
              );
              Navigator.of(context).pop(true);
            }
            // Failures render as the inline banner, not a toast —
            // keeps the dialog open so the user can retry.
          },
        ),

        // ── Transactions bloc: row actions (auth / unauth / reverse / delete) ──
        // FIX #4 — after every successful action, reload the transaction
        // so `stateText` (and therefore the footer buttons) updates without
        // requiring the user to close and reopen the dialog.
        BlocListener<TransactionsBloc, TransactionsState>(
          listenWhen: (prev, next) =>
          next is TransactionsLoadedState &&
              (next.actionSuccess != null || next.actionError != null),
          listener: (context, state) {
            if (state is! TransactionsLoadedState) return;

            final success = state.actionSuccess;
            if (success != null) {
              ToastManager.show(
                context: context,
                title: 'Success',
                message: success,
                type: ToastType.success,
              );
              context
                  .read<TransactionsBloc>()
                  .add(const ClearRowActionSuccessEvent());

              final ref = reference;
              if (ref != null && ref.isNotEmpty) {
                // If it was a delete, the txn is gone — close the dialog.
                if (success.toLowerCase().contains('deleted')) {
                  Navigator.of(context).pop(true);
                  return;
                }
                // Otherwise reload so the stateText and the footer refresh.
                context.read<CashTxnBloc>().add(CashTxnLoadRequested(ref));
              }
            }

            final error = state.actionError;
            if (error != null) {
              ToastManager.show(
                context: context,
                title: 'Failed',
                message: error,
                type: ToastType.error,
              );
              context
                  .read<TransactionsBloc>()
                  .add(const ClearRowActionErrorEvent());
            }
          },
        ),
      ],
      child: BlocBuilder<CashTxnBloc, CashTxnState>(
        builder: (context, state) {
          final busy = state is CashTxnSubmitting;
          final loaded = state is CashTxnLoadedForEdit ? state : null;

          final stateText = loaded?.stateText;
          final isPending = stateText == null || stateText == 'Pending';
          final isAuthorized = stateText == 'Authorized';

          final loginName = _loginName(context);
          final isMaker = loaded == null ||
              (loaded.makerName != null &&
                  loginName != null &&
                  loaded.makerName == loginName);

          final initial = loaded?.draft;
          final isEditing = _isEditing;

          // ── Loading gate ────────────────────────────────────────
          if (isEditing && loaded == null && state is! CashTxnFailure) {
            return ZFormDialog(
              width: 600,
              icon: spec.icon,
              title: '${spec.title(context)} · $reference',
              isActionTrue: false,
              onAction: null,
              child: const SizedBox(
                height: 220,                                     // FIX #3
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
            child: ConstrainedBox(                              // FIX #3
              constraints: const BoxConstraints(maxHeight: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Inline error banner ───────────────────────
                  if (state is CashTxnFailure && state.message.isNotEmpty)
                    _banner(state.message,
                        Theme.of(context).colorScheme.error),

                  // ── Form ──────────────────────────────────────
                  Flexible(                                     // FIX #3
                    child: CashTxnForm(
                      key: ValueKey(reference ?? 'new'),
                      formKey: formKey,
                      spec: spec,
                      usrName: usrName,
                      baseCurrency: baseCurrency,
                      initialDraft: initial,
                      stateText: stateText,
                      onSubmit: (draft) {
                        if (isEditing) {
                          context
                              .read<CashTxnBloc>()
                              .add(CashTxnUpdateRequested(draft));
                        } else {
                          context
                              .read<CashTxnBloc>()
                              .add(CashTxnCreateRequested(draft));
                        }
                      },
                    ),
                  ),

                  // ── Footer with ZOutlineButton (FIX #2) ───────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ZOutlineButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          label: Text(AppLocalizations.of(context)!.cancel),
                        ),

                        // Pending + maker → Delete · Authorize · Update
                        if (isEditing &&
                            isPending &&
                            isMaker &&
                            !busy) ...[
                          ZOutlineButton(
                            onPressed: () => _dispatchDelete(context),
                            backgroundHover:
                            Theme.of(context).colorScheme.error,
                            icon: Icons.delete_outline_rounded,
                            label:
                            Text(AppLocalizations.of(context)!.delete),
                          ),
                          ZOutlineButton(
                            isActive: true,
                            onPressed: () => _dispatchAuthorize(context),
                            icon: Icons.check_circle_outline_rounded,
                            label: Text(AppLocalizations.of(context)!.authorize),
                          ),
                          ZOutlineButton(
                            isActive: true,
                            onPressed: () =>
                                formKey.currentState?.submit(),
                            icon: Icons.save_alt_rounded,
                            label: Text(AppLocalizations.of(context)!.update),
                          ),
                        ],

                        // Authorized → Unauthorize · Reverse
                        if (isEditing && isAuthorized && !busy) ...[
                          ZOutlineButton(
                            onPressed: () =>
                                _dispatchUnauthorize(context),
                            icon: Icons.undo_rounded,
                            label: Text(AppLocalizations.of(context)!.unauthorize),
                          ),
                          ZOutlineButton(
                            onPressed: () => _dispatchReverse(context),
                            icon: Icons.replay_rounded,
                            label: Text(AppLocalizations.of(context)!.reverse),
                          ),
                        ],

                        // Create mode → Save
                        if (!isEditing)
                          ZOutlineButton(
                            isActive: true,
                            onPressed: busy
                                ? null
                                : () => formKey.currentState?.submit(),
                            icon: Icons.save_alt_rounded,
                            label:
                            Text(AppLocalizations.of(context)!.save),
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
          child: Text(text,
              style: TextStyle(color: color, fontSize: 12)),
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
        visualDensity:
        const VisualDensity(horizontal: -4, vertical: -4),
        value: value,
        onChanged: (v) => onChanged(v ?? false),
      ),
      Text(label),
    ],
  );
}

class _AccountDetailsCard extends StatelessWidget {
  final StakeholderAccount account;
  final String fallbackCurrency;

  const _AccountDetailsCard({
    required this.account,
    required this.fallbackCurrency,
  });

  static const int _stakeholderCategory = 8;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final title = Theme.of(context).textTheme.titleSmall;

    Widget row(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label, style: title)),
          Expanded(
            child: Text(
              value,
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
    final effectiveCcy = account.accCurrency ??
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
          Text('Account details',
              style: title?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(),
          row('Account number', account.accNumber?.toString() ?? ''),
          row('Account name', account.accName ?? ''),
          row('Balance', "${account.accBalance.toAmount()} $effectiveCcy"),
          if (isStakeholder && status != null) row('Status', status == 1 ? 'Active' : 'Blocked'),
        ],
      ),
    );
  }
}