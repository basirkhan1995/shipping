import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../Features/Widgets/extensions.dart';
import '../../../../../../Features/Widgets/zbutton.dart';           // ZOutlineButton
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../Features/Widgets/z_dialog.dart';
import '../../../../../../Features/Widgets/toast.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../Services/repository.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Stakeholder/model/stk_model.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../bloc/transactions_bloc.dart';
import 'bloc/fund_transfer_bloc.dart';
import 'model/ft_model.dart';

// ═════════════════════════════════════════════════════════════════
// FORM — add / edit a fund transfer (debit → credit)
// ═════════════════════════════════════════════════════════════════

class FundTransferForm extends StatefulWidget {
  final String usrName;
  final String baseCurrency;
  final FundTransferDetail? initialDetail;
  final String? stateText;
  final GlobalKey<FundTransferFormState>? formKey;

  /// Emits a draft ready for `FundTransferBloc.add/edit`.
  final void Function(FundTransferFormResult result) onSubmit;

  const FundTransferForm({
    super.key,
    required this.usrName,
    required this.baseCurrency,
    required this.onSubmit,
    this.initialDetail,
    this.stateText,
    this.formKey,
  });

  @override
  State<FundTransferForm> createState() => FundTransferFormState();
}

/// Form output — used by `FundTransferBloc`.
class FundTransferFormResult {
  final String? reference; // null → create, set → edit
  final String usrName;
  final int fromAccount;
  final String fromAccCcy;
  final int toAccount;
  final String toAccCcy;
  final double amount;
  final String narration;

  const FundTransferFormResult({
    this.reference,
    required this.usrName,
    required this.fromAccount,
    required this.fromAccCcy,
    required this.toAccount,
    required this.toAccCcy,
    required this.amount,
    required this.narration,
  });
}

class FundTransferFormState extends State<FundTransferForm> {
  final _internalKey = GlobalKey<FormState>();
  GlobalKey<FormState> get _formKey => _internalKey;

  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _narrationCtrl = TextEditingController();

  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _narrationFocus = FocusNode();

  StakeholderAccount? _fromAcc;
  StakeholderAccount? _toAcc;

  /// Fallback legs from the loaded detail (edit mode).
  FundTransferLeg? _fromLeg;
  FundTransferLeg? _toLeg;

  String? _fromCcy;
  String? _toCcy;
  bool _print = true;

  /// Account categories valid as a transfer endpoint (Cash/Bank + Stakeholder).
  static const Set<int> _transferableCategories = {1, 8};

  bool get _isEditable =>
      widget.stateText == null || widget.stateText == 'Pending';

  // ── Derived account numbers / currencies (pick OR leg) ────────
  int? get _fromAccountNo => _fromAcc?.accNumber ?? _fromLeg?.account;
  int? get _toAccountNo   => _toAcc?.accNumber   ?? _toLeg?.account;

  String? get _fromCcyEffective =>
      _fromCcy ?? _fromLeg?.currency ?? widget.baseCurrency;
  String? get _toCcyEffective =>
      _toCcy ?? _toLeg?.currency ?? widget.baseCurrency;

  @override
  void initState() {
    super.initState();
    _applyDetail(widget.initialDetail);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isEditable) _fromFocus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant FundTransferForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldRef = oldWidget.initialDetail?.reference;
    final newRef = widget.initialDetail?.reference;
    if (oldRef != newRef) {
      setState(() => _applyDetail(widget.initialDetail));
    }
  }

  void _applyDetail(FundTransferDetail? d) {
    if (d == null) return;

    final from = d.fromLeg;
    final to = d.toLeg;

    _fromLeg = from;
    _toLeg = to;

    _fromCcy = from?.currency ?? widget.baseCurrency;
    _toCcy = to?.currency ?? widget.baseCurrency;

    if (from != null) {
      _fromCtrl.text = '${from.account} | ${from.accountName}';
    }
    if (to != null) {
      _toCtrl.text = '${to.account} | ${to.accountName}';
    }

    _amountCtrl.text = (from?.amount ?? 0).toStringAsFixed(2);
    _narrationCtrl.text = d.narration;

    // Load the two accounts so the details cards render.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (from != null) {
        context.read<StkAccountsBloc>().add(
          LoadStkAccountsEvent(query: '${from.account}'),
        );
      }
      if (to != null) {
        context.read<StkAccountsBloc>().add(
          LoadStkAccountsEvent(query: '${to.account}'),
        );
      }
    });
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _amountCtrl.dispose();
    _narrationCtrl.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    _amountFocus.dispose();
    _narrationFocus.dispose();
    super.dispose();
  }

  void submit() {
    if (!_isEditable) return;
    if (_formKey.currentState?.validate() != true) return;

    final amount = double.tryParse(
      _amountCtrl.text.replaceAll(',', '').trim(),
    );
    if (amount == null || amount <= 0) return;

    final fromNo = _fromAccountNo;
    final toNo = _toAccountNo;
    if (fromNo == null || toNo == null) return;

    if (fromNo == toNo) {
      _toastError(AppLocalizations.of(context)!.sameAccount);
      return;
    }
    if (_fromCcyEffective != _toCcyEffective) {
      _toastError(AppLocalizations.of(context)!.currencyMismatch);
      return;
    }

    widget.onSubmit(FundTransferFormResult(
      reference: widget.initialDetail?.reference,
      usrName: widget.usrName,
      fromAccount: fromNo,
      fromAccCcy: _fromCcyEffective ?? widget.baseCurrency,
      toAccount: toNo,
      toAccCcy: _toCcyEffective ?? widget.baseCurrency,
      amount: amount,
      narration: _narrationCtrl.text.trim(),
    ));
  }

  void _toastError(String msg) => ToastManager.show(
    context: context,
    title: 'Check form',
    message: msg,
    type: ToastType.error,
  );

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            _buildFromPicker(),
            if (_fromAcc != null)
              _AccountDetailsCard(
                account: _fromAcc!,
                fallbackCurrency: widget.baseCurrency,
                label: tr.debitAccount,
              )
            else if (_fromLeg != null)
              _LegDetailsCard(leg: _fromLeg!, label: tr.debitAccount),

            _buildToPicker(),
            if (_toAcc != null)
              _AccountDetailsCard(
                account: _toAcc!,
                fallbackCurrency: widget.baseCurrency,
                label: tr.creditAccount,
              )
            else if (_toLeg != null)
              _LegDetailsCard(leg: _toLeg!, label: tr.creditAccount),

            _buildAmountField(),
            _buildNarrationField(),
            if (_isEditable) _buildToggles(),
          ],
        ),
      ),
    );
  }

  // ── Account pickers ────────────────────────────────────────────
  Widget _buildFromPicker() => _accountPicker(
    key: const ValueKey('debit'),
    controller: _fromCtrl,
    focusNode: _fromFocus,
    title: AppLocalizations.of(context)!.debitAccount,
    selected: _fromAcc,
    onSelected: (a) {
      setState(() {
        _fromAcc = a;
        _fromLeg = null; // user overrode the loaded leg
        _fromCcy = a.accCurrency ?? widget.baseCurrency;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _toFocus.requestFocus();
      });
    },
    excludeAccount: _toAccountNo,
  );

  Widget _buildToPicker() => _accountPicker(
    key: const ValueKey('credit'),
    controller: _toCtrl,
    focusNode: _toFocus,
    title: AppLocalizations.of(context)!.creditAccount,
    selected: _toAcc,
    onSelected: (a) {
      setState(() {
        _toAcc = a;
        _toLeg = null;
        _toCcy = a.accCurrency ?? widget.baseCurrency;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _amountFocus.requestFocus();
      });
    },
    excludeAccount: _fromAccountNo,
  );

  Widget _accountPicker({
    required Key key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String title,
    required StakeholderAccount? selected,
    required ValueChanged<StakeholderAccount> onSelected,
    int? excludeAccount,
  }) {
    return GenericTextField<StakeholderAccount, StkAccountsBloc,
        StkAccountsState>(
      key: key,
      controller: controller,
      title: title,
      hintText: AppLocalizations.of(context)!.accNameOrNumber,
      isRequired: true,
      bloc: context.read<StkAccountsBloc>(),
      focusNode: focusNode,
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

            Text(
              '${account.accBalance} | ${account.accCurrency}',
              style: Theme.of(context).textTheme.bodyLarge,
            )
          ],
        ),
      ),
      itemToString: (a) => '${a.accNumber} | ${a.accName}',
      stateToItems: (s) {
        if (s is! StkAccountsLoadedState) {
          return const <StakeholderAccount>[];
        }
        return s.accounts.where((a) {
          if (!_transferableCategories.contains(a.accCategory)) return false;
          if (excludeAccount != null && a.accNumber == excludeAccount) {
            return false;
          }
          return true;
        }).toList();
      },
      stateToLoading: (s) => s is StkAccountsLoadingState,
      onSelected: onSelected,
      validator: (_) {
        // Edit mode: legs already populate the accounts — don't re-require.
        if (!_isEditable) return null;
        if (widget.initialDetail != null) return null;
        return selected == null ? 'Required' : null;
      },
    );
  }

  // ── Amount & narration ─────────────────────────────────────────
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
      _Check(
        label: AppLocalizations.of(context)!.print,
        value: _print,
        onChanged: (v) => setState(() => _print = v),
      ),
    ],
  );
}

// ═════════════════════════════════════════════════════════════════
// DIALOG — provisions FundTransferBloc, reuses TransactionsBloc
// ═════════════════════════════════════════════════════════════════

Future<bool?> showFundTransferDialog(
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
            final bloc = FundTransferBloc(ctx.read<Repositories>());
            if (reference != null && reference.isNotEmpty) {
              bloc.add(LoadFundTransferDetailEvent(reference));
            }
            return bloc;
          },
        ),
        BlocProvider<TransactionsBloc>.value(
          value: context.read<TransactionsBloc>(),
        ),
      ],
      child: _FundTransferDialog(
        usrName: usrName,
        baseCurrency: baseCurrency,
        reference: reference,
      ),
    ),
  );
}

class _FundTransferDialog extends StatelessWidget {
  final String usrName;
  final String baseCurrency;
  final String? reference;

  const _FundTransferDialog({
    required this.usrName,
    required this.baseCurrency,
    this.reference,
  });

  bool get _isEditing => reference != null && reference!.isNotEmpty;

  String? _loginName(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthenticatedState ? auth.loginData.usrName : null;
  }

  // ── Row actions → TransactionsBloc ─────────────────────────────
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
        content: Text('Delete fund transfer $ref?\n\nThis cannot be undone.'),
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
    if (confirmed != true || !context.mounted) return;

    context.read<TransactionsBloc>().add(
      DeleteTransactionEvent(
        reference: ref,
        userName: _loginName(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FundTransferFormState>();

    return MultiBlocListener(
      listeners: [
        // ── FundTransferBloc: add / edit result ─────────────────
        BlocListener<FundTransferBloc, FundTransferState>(
          listener: (context, state) {
            if (state is FundTransferSubmitSuccess) {
              ToastManager.show(
                context: context,
                title: 'Saved',
                message: state.message,
                type: ToastType.success,
              );
              context
                  .read<FundTransferBloc>()
                  .add(const ClearFundTransferSuccessEvent());
              Navigator.of(context).pop(true);
            }
          },
        ),

        // ── TransactionsBloc: authorize / unauthorize / reverse / delete ──
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
                if (success.toLowerCase().contains('deleted')) {
                  Navigator.of(context).pop(true);
                  return;
                }
                // Reload the transfer so stateText + footer refresh.
                context
                    .read<FundTransferBloc>()
                    .add(LoadFundTransferDetailEvent(ref));
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
      child: BlocBuilder<FundTransferBloc, FundTransferState>(
        builder: (context, state) {
          final busy = state is FundTransferSubmitting;
          final loaded =
          state is FundTransferDetailLoaded ? state.detail : null;

          final stateText = loaded?.stateText;
          final isPending = stateText == null || stateText == 'Pending';
          final isAuthorized = stateText == 'Authorized';

          final loginName = _loginName(context);
          final isMaker = loaded == null ||
              (loaded.maker.isNotEmpty &&
                  loginName != null &&
                  loaded.maker == loginName);

          final isEditing = _isEditing;

          // ── Loading gate ────────────────────────────────────
          if (isEditing && loaded == null && state is! FundTransferError) {
            return ZFormDialog(
              width: 640,
              icon: Icons.swap_horiz_rounded,
              title: '${AppLocalizations.of(context)!.fundTransfer} · $reference',
              isActionTrue: false,
              onAction: null,
              child: const SizedBox(
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return ZFormDialog(
            width: 640,
            icon: Icons.swap_horiz_rounded,
            title: isEditing
                ? '${AppLocalizations.of(context)!.fundTransfer} · $reference'
                : AppLocalizations.of(context)!.newFundTransfer,
            isActionTrue: false,
            onAction: null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: double.infinity),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Inline error banner ─────────────────────
                  if (state is FundTransferError && state.message.isNotEmpty)
                    _banner(
                      state.message,
                      Theme.of(context).colorScheme.error,
                    ),

                  // ── Form ────────────────────────────────────
                  Flexible(
                    child: FundTransferForm(
                      key: ValueKey(reference ?? 'new'),
                      formKey: formKey,
                      usrName: usrName,
                      baseCurrency: baseCurrency,
                      initialDetail: loaded,
                      stateText: stateText,
                      onSubmit: (result) {
                        if (isEditing) {
                          context.read<FundTransferBloc>().add(
                            EditFundTransferEvent(
                              reference: result.reference!,
                              usrName: result.usrName,
                              fromAccCcy: result.fromAccCcy,
                              toAccCcy: result.toAccCcy,
                              fromAccount: result.fromAccount,
                              toAccount: result.toAccount,
                              amount: result.amount,
                              narration: result.narration,
                            ),
                          );
                        } else {
                          context.read<FundTransferBloc>().add(
                            AddFundTransferEvent(
                              usrName: result.usrName,
                              fromAccount: result.fromAccount,
                              fromAccCcy: result.fromAccCcy,
                              toAccount: result.toAccount,
                              toAccCcy: result.toAccCcy,
                              amount: result.amount,
                              narration: result.narration,
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  // ── Footer ─────────────────────────────────
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
                        if (isEditing && isPending && isMaker && !busy) ...[
                          ZOutlineButton(
                            onPressed: () => _dispatchDelete(context),
                            backgroundHover:
                            Theme.of(context).colorScheme.error,
                            icon: Icons.delete_outline_rounded,
                            label: Text(AppLocalizations.of(context)!.delete),
                          ),
                          ZOutlineButton(
                            isActive: true,
                            onPressed: () => _dispatchAuthorize(context),
                            icon: Icons.check_circle_outline_rounded,
                            label:
                            Text(AppLocalizations.of(context)!.authorize),
                          ),
                          ZOutlineButton(
                            isActive: true,
                            onPressed: () => formKey.currentState?.submit(),
                            icon: Icons.save_alt_rounded,
                            label: Text(AppLocalizations.of(context)!.update),
                          ),
                        ],

                        // Authorized → Unauthorize · Reverse
                        if (isEditing && isAuthorized && !busy) ...[
                          ZOutlineButton(
                            onPressed: () => _dispatchUnauthorize(context),
                            icon: Icons.undo_rounded,
                            label: Text(
                              AppLocalizations.of(context)!.unauthorize,
                            ),
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
                            label: Text(AppLocalizations.of(context)!.save),
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
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 12),
          ),
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
  final String label;

  const _AccountDetailsCard({
    required this.account,
    required this.fallbackCurrency,
    this.label = 'Account details',
  });

  static const int _stakeholderCategory = 8;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final title = Theme.of(context).textTheme.titleSmall;
    final tr = AppLocalizations.of(context)!;
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
          Text(label,
              style: title?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(),
          row(tr.accountNumber, account.accNumber?.toString() ?? ''),
          row(tr.accountName, account.accName ?? ''),
          row(tr.balance, '${account.accBalance.toAmount()} $effectiveCcy'),
          if (isStakeholder && status != null)
            row(tr.status, status == 1 ? tr.active : tr.blocked),
        ],
      ),
    );
  }
}

/// Lightweight card shown while the full [StakeholderAccount] isn't loaded
/// yet (edit mode). Renders directly from the loaded `FundTransferLeg`.
class _LegDetailsCard extends StatelessWidget {
  final FundTransferLeg leg;
  final String label;
  const _LegDetailsCard({required this.leg, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final title = Theme.of(context).textTheme.titleSmall;
    final tr = AppLocalizations.of(context)!;
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(k, style: title)),
          Expanded(child: Text(v, style: title)),
        ],
      ),
    );

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
          row(tr.accountNumber, leg.account.toString()),
          row(tr.accountName, leg.accountName),
          row(tr.amount, '${leg.amount.toStringAsFixed(2)} ${leg.currency}'),
        ],
      ),
    );
  }
}