import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../Features/Widgets/extensions.dart';
import '../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../Features/Widgets/z_dialog.dart';
import '../../../../../../Features/Widgets/toast.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../Services/repository.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Finance/View/Currencies/model/ccy_model.dart';
import '../../../Stakeholder/model/stk_model.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../bloc/transactions_bloc.dart';
import 'bloc/fund_transfer_bloc.dart';
import 'model/ft_model.dart';

// ═════════════════════════════════════════════════════════════════
// FORM
// ═════════════════════════════════════════════════════════════════

class FundTransferForm extends StatefulWidget {
  final String usrName;
  final String baseCurrency;
  final FundTransferDetail? initialDetail;
  final String? stateText;

  /// Optional — scopes the **account picker** to one stakeholder.
  /// Has nothing to do with loading the transaction itself.
  final int? perId;

  final VoidCallback? onSubmitRequested;
  final void Function(FundTransferFormResult result) onSubmit;

  const FundTransferForm({
    super.key,
    required this.usrName,
    required this.baseCurrency,
    required this.onSubmit,
    this.onSubmitRequested,
    this.initialDetail,
    this.stateText,
    this.perId,
  });

  @override
  State<FundTransferForm> createState() => FundTransferFormState();
}

class FundTransferFormResult {
  final String? reference;
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

  FundTransferLeg? _fromLeg;
  FundTransferLeg? _toLeg;

  String? _fromCcyOverride;
  String? _toCcyOverride;

  bool _print = true;

  static const int _stakeholderCategory = 8;

  bool get _isEditable =>
      widget.stateText == null || widget.stateText == 'Pending';

  int? get _fromAccountNo => _fromAcc?.accNumber ?? _fromLeg?.account;
  int? get _toAccountNo => _toAcc?.accNumber ?? _toLeg?.account;

  int? get _fromCategory => _fromAcc?.accCategory ?? _fromLeg?.accCategory;
  int? get _toCategory => _toAcc?.accCategory ?? _toLeg?.accCategory;

  bool get _fromIsStakeholder => _fromCategory == _stakeholderCategory;
  bool get _toIsStakeholder => _toCategory == _stakeholderCategory;

  String? get _fromCcyEffective {
    if (_fromIsStakeholder) {
      return _fromAcc?.accCurrency ?? _fromLeg?.currency ?? widget.baseCurrency;
    }
    return _fromCcyOverride ??
        _fromAcc?.accCurrency ??
        _fromLeg?.currency ??
        widget.baseCurrency;
  }

  String? get _toCcyEffective {
    if (_toIsStakeholder) {
      return _toAcc?.accCurrency ?? _toLeg?.currency ?? widget.baseCurrency;
    }
    return _toCcyOverride ??
        _toAcc?.accCurrency ??
        _toLeg?.currency ??
        widget.baseCurrency;
  }

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

    _fromCcyOverride = from?.currency ?? widget.baseCurrency;
    _toCcyOverride = to?.currency ?? widget.baseCurrency;

    if (from != null) {
      _fromCtrl.text = _rowKeyFromParts(
        from.account,
        from.accountName,
        from.currency,
      );
    }
    if (to != null) {
      _toCtrl.text = _rowKeyFromParts(to.account, to.accountName, to.currency);
    }

    _amountCtrl.text = (from?.amount ?? 0).toStringAsFixed(2);
    _narrationCtrl.text = from?.narration ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (from != null) {
        context.read<StkAccountsBloc>().add(
          LoadStkAccountsEvent(
            query: '${from.account}',
            perId: widget.perId,
          ),
        );
      }
      if (to != null) {
        context.read<StkAccountsBloc>().add(
          LoadStkAccountsEvent(
            query: '${to.account}',
            perId: widget.perId,
          ),
        );
      }
    });
  }

  void _applyPendingAccountSync(List<StakeholderAccount> rows) {
    bool changed = false;
    StakeholderAccount? newFrom = _fromAcc;
    StakeholderAccount? newTo = _toAcc;

    final fromNo = _pendingFromAccountNo;
    final fromCcy = _pendingFromCcy;
    if (fromNo != null && fromCcy != null) {
      for (final a in rows) {
        if (a.accNumber == fromNo && a.accCurrency == fromCcy) {
          newFrom = a;
          changed = true;
          break;
        }
      }
    }

    final toNo = _pendingToAccountNo;
    final toCcy = _pendingToCcy;
    if (toNo != null && toCcy != null) {
      for (final a in rows) {
        if (a.accNumber == toNo && a.accCurrency == toCcy) {
          newTo = a;
          changed = true;
          break;
        }
      }
    }

    _pendingFromAccountNo = null;
    _pendingFromCcy = null;
    _pendingToAccountNo = null;
    _pendingToCcy = null;

    if (!changed) return;
    setState(() {
      _fromAcc = newFrom;
      _toAcc = newTo;
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

  int? _accountNumberOf(TextEditingController c) {
    final text = c.text.trim();
    if (text.isEmpty) return null;
    final bar = text.indexOf('|');
    final numText = (bar == -1 ? text : text.substring(0, bar)).trim();
    return int.tryParse(numText);
  }

  bool submit() {
    if (!_isEditable) return false;

    if (_formKey.currentState?.validate() != true) return false;

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '').trim());
    if (amount == null || amount <= 0) return false;

    final fromNo = _fromAccountNo;
    final toNo = _toAccountNo;
    if (fromNo == null || toNo == null) return false;

    if (fromNo == toNo && _fromCcyEffective == _toCcyEffective) {
      _toastError(AppLocalizations.of(context)!.sameAccount);
      return false;
    }
    if (_fromCcyEffective != _toCcyEffective) {
      _toastError(AppLocalizations.of(context)!.currencyMismatch);
      return false;
    }

    widget.onSubmit(
      FundTransferFormResult(
        reference: widget.initialDetail?.reference,
        usrName: widget.usrName,
        fromAccount: fromNo,
        fromAccCcy: _fromCcyEffective ?? widget.baseCurrency,
        toAccount: toNo,
        toAccCcy: _toCcyEffective ?? widget.baseCurrency,
        amount: amount,
        narration: _narrationCtrl.text.trim(),
      ),
    );
    return true;
  }

  void _toastError(String msg) => ToastManager.show(
    context: context,
    title: 'Check form',
    message: msg,
    type: ToastType.error,
  );

  int? _pendingFromAccountNo;
  String? _pendingFromCcy;
  int? _pendingToAccountNo;
  String? _pendingToCcy;

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return BlocListener<StkAccountsBloc, StkAccountsState>(
      listenWhen: (prev, next) =>
      next is StkAccountsLoadedState &&
          (_pendingFromAccountNo != null || _pendingToAccountNo != null),
      listener: (context, state) {
        if (state is! StkAccountsLoadedState) return;
        _applyPendingAccountSync(state.accounts);
      },
      child: Form(
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
                  effectiveCurrencyOverride: _fromCcyEffective,
                )
              else if (_fromLeg != null)
                _LegDetailsCard(
                  leg: _fromLeg!,
                  label: tr.debitAccount,
                  effectiveCurrency: _fromCcyEffective,
                ),

              _buildToPicker(),
              if (_toAcc != null)
                _AccountDetailsCard(
                  account: _toAcc!,
                  fallbackCurrency: widget.baseCurrency,
                  label: tr.creditAccount,
                  effectiveCurrencyOverride: _toCcyEffective,
                )
              else if (_toLeg != null)
                _LegDetailsCard(
                  leg: _toLeg!,
                  label: tr.creditAccount,
                  effectiveCurrency: _toCcyEffective,
                ),

              _buildAmountField(),
              _buildNarrationField(),
              if (_isEditable) _buildToggles(),
            ],
          ),
        ),
      ),
    );
  }

  String _rowKey(StakeholderAccount a) => _rowKeyFromParts(
    a.accNumber,
    a.accName,
    a.accCurrency ?? widget.baseCurrency,
  );

  String _rowKeyFromParts(int? accNumber, String? accName, String? ccy) {
    final n = accNumber?.toString() ?? '';
    final nm = accName ?? '';
    final c = (ccy == null || ccy.isEmpty) ? widget.baseCurrency : ccy;
    return '$n | $nm | $c';
  }

  String _rowLabel(StakeholderAccount a) {
    final n = a.accNumber?.toString() ?? '';
    final nm = a.accName ?? '';
    return '$n | $nm';
  }

  Widget _buildFromPicker() => _accountPicker(
    key: const ValueKey('debit'),
    controller: _fromCtrl,
    focusNode: _fromFocus,
    title: AppLocalizations.of(context)!.debitAccount,
    selected: _fromAcc,
    isStakeholder: _fromIsStakeholder,
    currentCurrency: _fromCcyEffective,
    currencyOverride: _fromCcyEffective,
    allowedCategories: null,
    onCurrencySelected: (ccy) {
      final code = ccy?.ccyCode ?? widget.baseCurrency;
      final accountNo = _fromAcc?.accNumber;

      setState(() => _fromCcyOverride = code);

      if (accountNo == null || _fromIsStakeholder) return;

      _pendingFromAccountNo = accountNo;
      _pendingFromCcy = code;

      context.read<StkAccountsBloc>().add(
        LoadStkAccountsEvent(
          query: '$accountNo',
          perId: widget.perId,
        ),
      );
    },
    onSelected: (a) {
      setState(() {
        _fromAcc = a;
        _fromLeg = null;
        _fromCcyOverride = a.accCategory == _stakeholderCategory
            ? a.accCurrency
            : (a.accCurrency ?? widget.baseCurrency);
        _fromCtrl.text = _rowKey(a);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _toFocus.requestFocus();
      });
    },
    excludeAccount: _toAccountNo,
    excludeCurrency: _toCcyEffective,
  );

  Widget _buildToPicker() => _accountPicker(
    key: const ValueKey('credit'),
    controller: _toCtrl,
    focusNode: _toFocus,
    title: AppLocalizations.of(context)!.creditAccount,
    selected: _toAcc,
    isStakeholder: _toIsStakeholder,
    currentCurrency: _toCcyEffective,
    currencyOverride: _toCcyEffective,
    allowedCategories: null,
    onCurrencySelected: (ccy) {
      final code = ccy?.ccyCode ?? widget.baseCurrency;
      final accountNo = _toAcc?.accNumber;

      setState(() => _toCcyOverride = code);

      if (accountNo == null || _toIsStakeholder) return;

      _pendingToAccountNo = accountNo;
      _pendingToCcy = code;

      context.read<StkAccountsBloc>().add(
        LoadStkAccountsEvent(
          query: '$accountNo',
          perId: widget.perId,
        ),
      );
    },
    onSelected: (a) {
      setState(() {
        _toAcc = a;
        _toLeg = null;
        _toCcyOverride = a.accCategory == _stakeholderCategory
            ? a.accCurrency
            : (a.accCurrency ?? widget.baseCurrency);
        _toCtrl.text = _rowKey(a);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _amountFocus.requestFocus();
      });
    },
    excludeAccount: _fromAccountNo,
    excludeCurrency: _fromCcyEffective,
  );

  Widget _accountPicker({
    required Key key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String title,
    required StakeholderAccount? selected,
    required bool isStakeholder,
    required String? currentCurrency,
    required String? currencyOverride,
    required ValueChanged<CurrenciesModel?> onCurrencySelected,
    required ValueChanged<StakeholderAccount> onSelected,
    Set<int>? allowedCategories = const {1, 8},
    int? excludeAccount,
    String? excludeCurrency,
  }) {
    final accountNo = _accountNumberOf(controller);
    final showCcySelector = _isEditable && !isStakeholder && accountNo != null;

    return GenericTextField<
        StakeholderAccount,
        StkAccountsBloc,
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
        bloc.add(
          LoadStkAccountsEvent(query: q, perId: widget.perId),
        );
      },
      itemBuilder: (context, account) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _rowLabel(account),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              _accountBadge(account),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      itemToString: _rowKey,
      stateToItems: (s) {
        if (s is! StkAccountsLoadedState) {
          return const <StakeholderAccount>[];
        }
        return s.accounts.where((a) {
          if (allowedCategories != null &&
              !allowedCategories.contains(a.accCategory)) {
            return false;
          }
          final rowCcy = (a.accCurrency ?? widget.baseCurrency)
              .trim()
              .toUpperCase();
          final exCcy = (excludeCurrency ?? '').trim().toUpperCase();
          if (excludeAccount != null &&
              a.accNumber == excludeAccount &&
              rowCcy == exCcy) {
            return false;
          }
          return true;
        }).toList();
      },
      stateToLoading: (s) => s is StkAccountsLoadingState,
      onSelected: onSelected,
      showCurrencySelector: showCcySelector,
      isCurrencySelectorEnabled: _isEditable,
      selectedCurrencyCodeOverride: currencyOverride,
      onCurrencySelectorChanged: onCurrencySelected,
      validator: (_) {
        if (!_isEditable) return null;
        if (widget.initialDetail != null) return null;
        return selected == null ? 'Required' : null;
      },
    );
  }

  String _accountBadge(StakeholderAccount a) {
    final balance = a.accBalance.toAmount();
    final ccy = a.accCurrency ?? widget.baseCurrency;
    return '$balance $ccy'.trim();
  }

  Widget _buildAmountField() => ZTextFieldEntitled(
    controller: _amountCtrl,
    title:
    '${AppLocalizations.of(context)!.amount} (${_fromCcyEffective ?? widget.baseCurrency})',
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
      _Check(
        label: AppLocalizations.of(context)!.print,
        value: _print,
        onChanged: (v) => setState(() => _print = v),
      ),
    ],
  );
}

// ═════════════════════════════════════════════════════════════════
// DIALOG
// ═════════════════════════════════════════════════════════════════

Future<bool?> showFundTransferDialog(
    BuildContext context, {
      required String usrName,
      required String baseCurrency,
      String? reference,

      /// Optional — forwarded to the form so the **account picker** is
      /// scoped to one stakeholder. Does NOT affect the detail fetch.
      int? perId,
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
              // ✅ No perId — the reference identifies the transaction.
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
        perId: perId,
      ),
    ),
  );
}

class _FundTransferDialog extends StatefulWidget {
  final String usrName;
  final String baseCurrency;
  final String? reference;
  final int? perId;

  const _FundTransferDialog({
    required this.usrName,
    required this.baseCurrency,
    this.reference,
    this.perId,
  });

  @override
  State<_FundTransferDialog> createState() => _FundTransferDialogState();
}

class _FundTransferDialogState extends State<_FundTransferDialog> {
  String? _localError;
  final _formKey = GlobalKey<FundTransferFormState>();

  bool _formBusy = false;
  bool _actionBusy = false;

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

  void _onFormSubmit() {
    final st = _formKey.currentState;
    if (st == null) return;

    _clearLocalError();
    _setFormBusy(true);

    final dispatched = st.submit();
    if (!dispatched) _setFormBusy(false);
  }

  void _dispatchAuthorize(BuildContext context) {
    final ref = reference;
    if (ref == null || ref.isEmpty) return;
    _clearLocalError();
    _setActionBusy(true);
    context.read<TransactionsBloc>().add(
      AuthorizeTransactionEvent(
          reference: ref, userName: _loginName(context)),
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
      ReverseTransactionEvent(
          reference: ref, userName: _loginName(context)),
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

    _clearLocalError();
    _setActionBusy(true);

    context.read<TransactionsBloc>().add(
      DeleteTransactionEvent(
          reference: ref, userName: _loginName(context)),
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
        BlocListener<FundTransferBloc, FundTransferState>(
          listener: (context, state) {
            if (state is FundTransferSubmitSuccess) {
              _setFormBusy(false);
              ToastManager.show(
                context: context,
                title: 'Saved',
                message: state.message,
                type: ToastType.success,
              );
              context.read<FundTransferBloc>().add(
                const ClearFundTransferSuccessEvent(),
              );
              Navigator.of(context).pop(true);
              return;
            }
            if (state is FundTransferError) {
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
                // ✅ No perId — reload the same transaction by reference.
                context.read<FundTransferBloc>().add(
                  LoadFundTransferDetailEvent(ref),
                );
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
      child: BlocBuilder<FundTransferBloc, FundTransferState>(
        builder: (context, state) {
          final cashBusy = _formBusy || state is FundTransferSubmitting;

          final rowBusy = _actionBusy ||
              context.select<TransactionsBloc, bool>((bloc) {
                final s = bloc.state;
                if (s is! TransactionsLoadedState) return false;
                final ref = reference;
                if (ref == null || ref.isEmpty) return false;
                return s.actionInProgress == ref;
              });

          final anyBusy = cashBusy || rowBusy;

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

          if (isEditing && loaded == null && state is! FundTransferError) {
            return ZFormDialog(
              width: 640,
              icon: Icons.swap_horiz_rounded,
              title:
              '${AppLocalizations.of(context)!.fundTransfer} · $reference',
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
              constraints: const BoxConstraints(
                maxHeight: 600,
                minWidth: 640,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state is FundTransferError && state.message.isNotEmpty)
                    _banner(state.message, Theme.of(context).colorScheme.error),

                  if (_localError != null && _localError!.isNotEmpty)
                    _banner(_localError!, Theme.of(context).colorScheme.error),

                  // ── Audit strip ─────────────────────────────
                  if (loaded != null && _hasAuditData(loaded))
                    _TransactionAuditStrip(detail: loaded),

                  Flexible(
                    fit: FlexFit.loose,
                    child: FundTransferForm(
                      key: _formKey,
                      usrName: usrName,
                      baseCurrency: baseCurrency,
                      initialDetail: loaded,
                      stateText: stateText,
                      perId: widget.perId, // ← only used for the account picker
                      onSubmitRequested: _onFormSubmit,
                      onSubmit: (result) {
                        _clearLocalError();
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
                            backgroundHover:
                            Theme.of(context).colorScheme.error,
                            icon:
                            rowBusy ? null : Icons.delete_outline_rounded,
                            label: _busyLabel(
                              context,
                              busy: rowBusy,
                              busyText:
                              AppLocalizations.of(context)!.deleting,
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
                              busyText:
                              AppLocalizations.of(context)!.updating,
                              idleText: AppLocalizations.of(context)!.update,
                            ),
                          ),
                        ],

                        if (isEditing &&
                            isPending &&
                            !isMaker &&
                            loginName != null)
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
                              idleText:
                              AppLocalizations.of(context)!.authorize,
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

  bool _hasAuditData(FundTransferDetail d) =>
      d.stateText.isNotEmpty ||
          d.maker.isNotEmpty ||
          (d.checker ?? '').isNotEmpty;

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

// ═════════════════════════════════════════════════════════════════
// AUDIT STRIP
// ═════════════════════════════════════════════════════════════════

class _TransactionAuditStrip extends StatelessWidget {
  final FundTransferDetail detail;
  const _TransactionAuditStrip({required this.detail});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = _StatusPalette.of(context, detail.stateText);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(4),

      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 6,
        children: [
          _AuditChip(
            icon: Icons.circle,
            iconColor: palette.fg,
            iconSize: 8,
            bg: palette.bg,
            fg: palette.fg,
            label: detail.stateText.toUpperCase(),
          ),
          if (detail.maker.isNotEmpty)
            _AuditChip(
              icon: Icons.person_outline,
              iconColor: scheme.onSurfaceVariant,
              bg: Colors.transparent,
              fg: scheme.onSurfaceVariant,
              label: '${tr.maker.toUpperCase()}: ${detail.maker}',
              boldValue: true,
            ),
          if ((detail.checker ?? '').isNotEmpty)
            _AuditChip(
              icon: Icons.verified_user_outlined,
              iconColor: scheme.onSurfaceVariant,
              bg: Colors.transparent,
              fg: scheme.onSurfaceVariant,
              label: '${tr.authorizer.toUpperCase()}: ${detail.checker}',
              boldValue: true,
            ),
          _AuditChip(
            icon: Icons.schedule_outlined,
            iconColor: scheme.onSurfaceVariant,
            bg: Colors.transparent,
            fg: scheme.onSurfaceVariant,
            label:
            '${detail.entryDate.toFormattedDate()} | ${detail.entryDate.shamsiDateString}',
          ),
        ],
      ),
    );
  }
}

class _AuditChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final Color bg;
  final Color fg;
  final String label;
  final bool boldValue;

  const _AuditChip({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.fg,
    required this.label,
    this.iconSize = 12,
    this.boldValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final colonIdx = label.indexOf(':');
    final keyPart =
    colonIdx == -1 ? '' : label.substring(0, colonIdx + 1).trim();
    final valuePart =
    colonIdx == -1 ? label : label.substring(colonIdx + 1).trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(width: 5),
          if (keyPart.isNotEmpty) ...[
            Text(
              keyPart,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: fg.withValues(alpha: 0.75),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 3),
          ],
          Text(
            valuePart,
            style: TextStyle(
              fontSize: 11,
              fontWeight: boldValue ? FontWeight.w700 : FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPalette {
  final Color bg;
  final Color fg;
  const _StatusPalette(this.bg, this.fg);

  factory _StatusPalette.of(BuildContext context, String status) {
    final isDark =
        Theme.of(context).colorScheme.brightness == Brightness.dark;
    final key = status.toLowerCase();

    final (Color hue, Color lightFg, Color darkFg) = switch (key) {
      'authorized' => (
      const Color(0xFF22C55E),
      const Color(0xFF166534),
      const Color(0xFF86EFAC),
      ),
      'pending' => (
      const Color(0xFFF59E0B),
      const Color(0xFF92400E),
      const Color(0xFFFCD34D),
      ),
      'reversed' => (
      const Color(0xFF6366F1),
      const Color(0xFF3730A3),
      const Color(0xFFA5B4FC),
      ),
      'deleted' => (
      const Color(0xFFEF4444),
      const Color(0xFF991B1B),
      const Color(0xFFFCA5A5),
      ),
      _ => (
      const Color(0xFF9CA3AF),
      const Color(0xFF374151),
      const Color(0xFFE5E7EB),
      ),
    };

    final bg = hue.withValues(alpha: isDark ? 0.20 : 0.14);
    final fg = isDark ? darkFg : lightFg;
    return _StatusPalette(bg, fg);
  }
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
          row(tr.accountNumber, account.accNumber?.toString() ?? ''),
          row(tr.accountName, account.accName ?? ''),
          row(
            tr.balance,
            '${account.accBalance.toAmount()} ${account.accCurrency ?? effectiveCcy}',
          ),
          if (isStakeholder && status != null)
            row(tr.status, status == 1 ? tr.active : tr.blocked),
        ],
      ),
    );
  }
}

class _LegDetailsCard extends StatelessWidget {
  final FundTransferLeg leg;
  final String label;
  final String? effectiveCurrency;

  const _LegDetailsCard({
    required this.leg,
    required this.label,
    this.effectiveCurrency,
  });

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

    final ccy =
    leg.currency.isNotEmpty ? leg.currency : (effectiveCurrency ?? '');

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
          row(tr.amount, '${leg.amount.toStringAsFixed(2)} $ccy'),
        ],
      ),
    );
  }
}