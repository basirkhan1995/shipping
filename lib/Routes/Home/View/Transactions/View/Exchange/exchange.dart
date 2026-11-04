import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/cover.dart';
import '../../../../../../Features/Widgets/extensions.dart';
import '../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../Features/Widgets/z_dialog.dart';
import '../../../../../../Features/Widgets/toast.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../Services/api_exception.dart';
import '../../../../../../Services/repository.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Finance/View/ExchangeRate/bloc/exchange_rate_bloc.dart';
import '../../../Finance/View/Currencies/model/ccy_model.dart';
import '../../../Stakeholder/model/stk_model.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../bloc/transactions_bloc.dart';
import 'bloc/exchange_bloc.dart';
import 'model/ex_model.dart';

class ExchangeForm extends StatefulWidget {
  final String usrName;
  final String baseCurrency;
  final ExchangeDetail? initialDetail;
  final String? stateText;
  final GlobalKey<ExchangeFormState>? formKey;
  final void Function(ExchangeFormResult result) onSubmit;

  const ExchangeForm({
    super.key,
    required this.usrName,
    required this.baseCurrency,
    required this.onSubmit,
    this.initialDetail,
    this.stateText,
    this.formKey,
  });

  @override
  State<ExchangeForm> createState() => ExchangeFormState();
}

class ExchangeFormResult {
  final String? reference;
  final String usrName;
  final ExchangeLeg debit;
  final ExchangeLeg credit;

  const ExchangeFormResult({
    this.reference,
    required this.usrName,
    required this.debit,
    required this.credit,
  });
}

/// Which field last produced a value. Used by the two-way amount mirror
/// so that typing in one field updates the other without feedback loops.
enum _AmountSource { none, amount, rate, creditAmount }

class ExchangeFormState extends State<ExchangeForm> {
  final _internalKey = GlobalKey<FormState>();
  GlobalKey<FormState> get _formKey => _internalKey;

  final _debitCtrl = TextEditingController();
  final _creditCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _creditAmountCtrl = TextEditingController();
  final _narrationCtrl = TextEditingController();

  final _debitFocus = FocusNode();
  final _creditFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _rateFocus = FocusNode();
  final _creditAmountFocus = FocusNode();
  final _narrationFocus = FocusNode();

  StakeholderAccount? _debitAcc;
  StakeholderAccount? _creditAcc;
  ExchangeLeg? _debitLeg;
  ExchangeLeg? _creditLeg;

  String? _debitCcy;
  String? _creditCcy;

  int? _pendingDebitAccountNo;
  String? _pendingDebitCurrency;
  int? _pendingCreditAccountNo;
  String? _pendingCreditCurrency;

  double? _rate;
  bool _loadingRate = false;
  int _rateRequestId = 0;
  StreamSubscription<ExchangeRateState>? _rateSub;
  bool _print = true;

  /// ── PER-FIELD LOADING FLAGS ──────────────────────────────
  /// Each account picker owns its own spinner flag. When the debit
  /// field triggers a search, only `_debitLoading` flips — so the
  /// credit picker never shows a spinner it didn't cause.
  bool _debitLoading = false;
  bool _creditLoading = false;

  /// Inline validation error shown at the top of the form.
  String? _formError;

  /// Last field the user typed in. Used to know which side is
  /// authoritative when the API-driven rate arrives.
  _AmountSource _amountSource = _AmountSource.none;

  /// Reentrancy guard for the amount/rate/credit-amount mirror.
  bool _mirroring = false;

  bool get _isEditable =>
      widget.stateText == null || widget.stateText == 'Pending';

  int? get _debitAccountNo => _debitAcc?.accNumber ?? _debitLeg?.account;
  int? get _creditAccountNo => _creditAcc?.accNumber ?? _creditLeg?.account;

  String? get _debitCcyEffective =>
      _debitCcy ??
          _debitAcc?.accCurrency ??
          _debitLeg?.currency ??
          widget.baseCurrency;

  String? get _creditCcyEffective =>
      _creditCcy ??
          _creditAcc?.accCurrency ??
          _creditLeg?.currency ??
          widget.baseCurrency;

  @override
  void initState() {
    super.initState();
    _applyDetail(widget.initialDetail);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isEditable) _debitFocus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant ExchangeForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDetail?.reference !=
        widget.initialDetail?.reference) {
      setState(() => _applyDetail(widget.initialDetail));
    }
  }

  void _applyDetail(ExchangeDetail? d) {
    if (d == null) return;

    final dr = d.debit;
    final cr = d.credit;
    _debitLeg = dr;
    _creditLeg = cr;
    _debitCcy = dr?.currency;
    _creditCcy = cr?.currency;

    if (dr != null) {
      _debitCtrl.text = '${dr.account} | ${dr.accountName}';
      _amountCtrl.text = dr.amount.toStringAsFixed(2);
    }
    if (cr != null) {
      _creditCtrl.text = '${cr.account} | ${cr.accountName}';
      _creditAmountCtrl.text = cr.amount.toStringAsFixed(2);
    }

    final r = d.rate;
    _rate = r;
    _rateCtrl.text = (r ?? 1).toStringAsFixed(6);
    _narrationCtrl.text = dr?.narration ?? cr?.narration ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (dr != null) {
        context.read<StkAccountsBloc>().add(
          LoadStkAccountsEvent(query: '${dr.account}'),
        );
      }
      if (cr != null) {
        context.read<StkAccountsBloc>().add(
          LoadStkAccountsEvent(query: '${cr.account}'),
        );
      }
    });
  }

  void _changeSelectedCurrency({
    required bool isDebit,
    required String currencyCode,
  }) {
    final selected = isDebit ? _debitAcc : _creditAcc;
    final accountNo = selected?.accNumber ??
        (isDebit ? _debitLeg?.account : _creditLeg?.account);
    if (accountNo == null) return;

    setState(() {
      if (isDebit) {
        _debitCcy = currencyCode;
        _pendingDebitAccountNo = accountNo;
        _pendingDebitCurrency = currencyCode;
      } else {
        _creditCcy = currencyCode;
        _pendingCreditAccountNo = accountNo;
        _pendingCreditCurrency = currencyCode;
      }
      _rate = null;
      _rateCtrl.clear();
    });

    final currentState = context.read<StkAccountsBloc>().state;
    if (currentState is StkAccountsLoadedState) {
      StakeholderAccount? matching;
      for (final account in currentState.accounts) {
        if (account.accNumber == accountNo &&
            account.accCurrency == currencyCode) {
          matching = account;
          break;
        }
      }
      if (matching != null) {
        _applyCurrencyAccountRow(
          isDebit: isDebit,
          account: matching,
          accountNo: accountNo,
          currencyCode: currencyCode,
        );
        _maybeFetchRate();
        return;
      }
    }

    context.read<StkAccountsBloc>().add(
      LoadStkAccountsEvent(query: '$accountNo'),
    );
    _maybeFetchRate();
  }

  void _applyCurrencyAccountRow({
    required bool isDebit,
    required StakeholderAccount account,
    required int accountNo,
    required String currencyCode,
  }) {
    if (account.accNumber != accountNo ||
        account.accCurrency != currencyCode) {
      return;
    }
    setState(() {
      if (isDebit) {
        _debitAcc = account;
        _pendingDebitAccountNo = null;
        _pendingDebitCurrency = null;
      } else {
        _creditAcc = account;
        _pendingCreditAccountNo = null;
        _pendingCreditCurrency = null;
      }
    });
  }

  void _syncPendingCurrencyRows(List<StakeholderAccount> rows) {
    final debitNo = _pendingDebitAccountNo;
    final debitCcy = _pendingDebitCurrency;
    final creditNo = _pendingCreditAccountNo;
    final creditCcy = _pendingCreditCurrency;

    StakeholderAccount? debitMatch;
    StakeholderAccount? creditMatch;
    for (final account in rows) {
      if (debitNo != null &&
          debitCcy != null &&
          account.accNumber == debitNo &&
          account.accCurrency == debitCcy) {
        debitMatch = account;
      }
      if (creditNo != null &&
          creditCcy != null &&
          account.accNumber == creditNo &&
          account.accCurrency == creditCcy) {
        creditMatch = account;
      }
    }

    if (debitMatch == null && creditMatch == null) return;
    setState(() {
      if (debitMatch != null) {
        _debitAcc = debitMatch;
        _pendingDebitAccountNo = null;
        _pendingDebitCurrency = null;
      }
      if (creditMatch != null) {
        _creditAcc = creditMatch;
        _pendingCreditAccountNo = null;
        _pendingCreditCurrency = null;
      }
    });
  }

  @override
  void dispose() {
    _rateSub?.cancel();
    _debitCtrl.dispose();
    _creditCtrl.dispose();
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _creditAmountCtrl.dispose();
    _narrationCtrl.dispose();
    _debitFocus.dispose();
    _creditFocus.dispose();
    _amountFocus.dispose();
    _rateFocus.dispose();
    _creditAmountFocus.dispose();
    _narrationFocus.dispose();
    super.dispose();
  }

  // ── Form-error helpers ─────────────────────────────────────
  void _setFormError(String msg) {
    if (!mounted) return;
    setState(() => _formError = msg);
  }

  void _clearFormError() {
    if (_formError == null) return;
    if (!mounted) return;
    setState(() => _formError = null);
  }

  // ── Rate fetching ──────────────────────────────────────────
  Future<void> _fetchRate(String fromCcy, String toCcy) async {
    if (fromCcy == toCcy) {
      _setRate(1.0);
      return;
    }

    final bloc = context.read<ExchangeRateBloc>();
    final startId = bloc.state is ExchangeRateLoadedState
        ? (bloc.state as ExchangeRateLoadedState).requestId
        : 0;

    setState(() => _loadingRate = true);
    bloc.add(GetExchangeRateEvent(fromCcy: fromCcy, toCcy: toCcy));

    try {
      final rate = await _awaitRate(
        bloc: bloc,
        startId: startId,
        fromCcy: fromCcy,
        toCcy: toCcy,
      );
      if (!mounted) return;
      _clearFormError();
      _setRate(rate);
    } on ApiException catch (e) {
      if (!mounted) return;
      _setFormError(e.message);
    } finally {
      if (mounted) setState(() => _loadingRate = false);
    }
  }

  Future<double> _awaitRate({
    required ExchangeRateBloc bloc,
    required int startId,
    required String fromCcy,
    required String toCcy,
  }) {
    _rateSub?.cancel();
    final completer = Completer<double>();
    _rateSub = bloc.stream.listen((s) {
      if (s is ExchangeRateLoadedState &&
          s.requestId > startId &&
          s.fromCcy == fromCcy &&
          s.toCcy == toCcy) {
        _rateSub?.cancel();
        _rateSub = null;
        if (!completer.isCompleted) {
          final parsed = double.tryParse(s.rate ?? '');
          completer.complete(parsed ?? 1.0);
        }
      } else if (s is ExchangeRateErrorState) {
        _rateSub?.cancel();
        _rateSub = null;
        if (!completer.isCompleted) {
          completer.completeError(ApiException(s.message));
        }
      }
    });

    if (!mounted) {
      _rateSub?.cancel();
      _rateSub = null;
      if (!completer.isCompleted) completer.complete(1.0);
    }
    return completer.future;
  }

  /// Apply a rate that came from the API or currency change. The rate
  /// field is the source of truth; the last user-edited amount side
  /// stays fixed and the other side recalculates.
  void _setRate(double rate) {
    setState(() {
      _rate = rate;
      _rateCtrl.text = rate.toStringAsFixed(6);
    });
    if (_amountSource == _AmountSource.creditAmount) {
      _recalcAmountFromCreditAndRate();
    } else {
      _recalcCreditFromRate();
    }
  }

  // ── Two-way mirror ─────────────────────────────────────────
  void _recalcCreditFromRate() {
    if (_mirroring) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    final rate = _rate;
    if (amount == null || amount <= 0 || rate == null || rate <= 0) return;

    _mirroring = true;
    final computed = (amount * rate).toStringAsFixed(2);
    if (_creditAmountCtrl.text != computed) {
      _creditAmountCtrl.text = computed;
    }
    _mirroring = false;
  }

  void _recalcAmountFromCreditAndRate() {
    if (_mirroring) return;
    final credit =
    double.tryParse(_creditAmountCtrl.text.replaceAll(',', ''));
    final rate = _rate;
    if (credit == null || credit <= 0 || rate == null || rate <= 0) return;

    _mirroring = true;
    final computed = (credit / rate).toStringAsFixed(2);
    if (_amountCtrl.text != computed) {
      _amountCtrl.text = computed;
    }
    _mirroring = false;
  }

  // ── Submit ─────────────────────────────────────────────────
  void submit() {
    if (!_isEditable) return;

    if (_formKey.currentState?.validate() != true) {
      _setFormError('Please fix the highlighted fields.');
      return;
    }

    final debitAmt = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    final creditAmt =
    double.tryParse(_creditAmountCtrl.text.replaceAll(',', ''));
    if (debitAmt == null || debitAmt <= 0) {
      _setFormError('Enter a debit amount greater than zero.');
      return;
    }
    if (creditAmt == null || creditAmt <= 0) {
      _setFormError('Enter a credit amount greater than zero.');
      return;
    }

    final debitNo = _debitAccountNo;
    final creditNo = _creditAccountNo;
    if (debitNo == null) {
      _setFormError('Pick a debit account.');
      return;
    }
    if (creditNo == null) {
      _setFormError('Pick a credit account.');
      return;
    }

    final sameAccountAndCurrency = debitNo == creditNo &&
        _normalizeCurrency(_debitCcyEffective) ==
            _normalizeCurrency(_creditCcyEffective);

    if (sameAccountAndCurrency) {
      _setFormError(AppLocalizations.of(context)!.sameAccount);
      return;
    }
    if (_normalizeCurrency(_debitCcyEffective) ==
        _normalizeCurrency(_creditCcyEffective)) {
      _setFormError(AppLocalizations.of(context)!.sameCurrencyForExchange);
      return;
    }

    _clearFormError();

    final narration = _narrationCtrl.text.trim();
    widget.onSubmit(ExchangeFormResult(
      reference: widget.initialDetail?.reference,
      usrName: widget.usrName,
      debit: ExchangeLeg(
        account: debitNo,
        accountName: _debitAcc?.accName ?? _debitLeg?.accountName ?? '',
        currency: _debitCcyEffective ?? '',
        amount: debitAmt,
        drCr: 'Dr',
        narration: narration,
      ),
      credit: ExchangeLeg(
        account: creditNo,
        accountName: _creditAcc?.accName ?? _creditLeg?.accountName ?? '',
        currency: _creditCcyEffective ?? '',
        amount: creditAmt,
        drCr: 'Cr',
        narration: narration,
      ),
    ));
  }

  String _normalizeCurrency(String? currency) =>
      (currency ?? '').trim().toUpperCase();

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return BlocListener<StkAccountsBloc, StkAccountsState>(
      listenWhen: (previous, next) =>
      next is StkAccountsLoadedState &&
          (_pendingDebitAccountNo != null ||
              _pendingCreditAccountNo != null),
      listener: (context, state) {
        if (state is StkAccountsLoadedState) {
          _syncPendingCurrencyRows(state.accounts);
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_formError != null && _formError!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: _InlineErrorBanner(
                  message: _formError!,
                  onDismiss: () => setState(() => _formError = null),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    _buildDebitPicker(),
                    if (_debitAcc != null)
                      _AccountDetailsCard(
                        account: _debitAcc!,
                        fallbackCurrency: widget.baseCurrency,
                        label: tr.debitAccount,
                        effectiveCurrency: _debitCcyEffective,
                      )
                    else if (_debitLeg != null)
                      _LegDetailsCard(
                        leg: _debitLeg!,
                        label: tr.debitAccount,
                      ),
                    _buildCreditPicker(),
                    if (_creditAcc != null)
                      _AccountDetailsCard(
                        account: _creditAcc!,
                        fallbackCurrency: widget.baseCurrency,
                        label: tr.creditAccount,
                        effectiveCurrency: _creditCcyEffective,
                      )
                    else if (_creditLeg != null)
                      _LegDetailsCard(
                        leg: _creditLeg!,
                        label: tr.creditAccount,
                      ),
                    _buildAmountRow(),
                    _buildNarrationField(),
                    if (_isEditable) _buildToggles(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pickers ────────────────────────────────────────────────
  Widget _buildDebitPicker() => _accountPicker(
    key: const ValueKey('debit'),
    controller: _debitCtrl,
    focusNode: _debitFocus,
    title: AppLocalizations.of(context)!.debitAccount,
    selected: _debitAcc,
    isLoading: _debitLoading,
    onLoadingChanged: (v) {
      if (mounted) setState(() => _debitLoading = v);
    },
    onSelected: (a) {
      _clearFormError();
      setState(() {
        _debitAcc = a;
        _debitLeg = null;
        _debitCcy = a.accCurrency ?? widget.baseCurrency;
      });
      _maybeFetchRate();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _creditFocus.requestFocus();
      });
    },
    excludeAccount: _creditAccountNo,
    excludeCurrency: _creditCcyEffective,
    isDebit: true,
    allowedCategories: null,
  );

  Widget _buildCreditPicker() => _accountPicker(
    key: const ValueKey('credit'),
    controller: _creditCtrl,
    focusNode: _creditFocus,
    title: AppLocalizations.of(context)!.creditAccount,
    selected: _creditAcc,
    isLoading: _creditLoading,
    onLoadingChanged: (v) {
      if (mounted) setState(() => _creditLoading = v);
    },
    onSelected: (a) {
      _clearFormError();
      setState(() {
        _creditAcc = a;
        _creditLeg = null;
        _creditCcy = a.accCurrency ?? widget.baseCurrency;
      });
      _maybeFetchRate();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _amountFocus.requestFocus();
      });
    },
    excludeAccount: _debitAccountNo,
    excludeCurrency: _debitCcyEffective,
    isDebit: false,
    allowedCategories: null,
  );

  Widget _accountPicker({
    required Key key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String title,
    required StakeholderAccount? selected,
    required ValueChanged<StakeholderAccount> onSelected,
    required bool isLoading,
    required ValueChanged<bool> onLoadingChanged,
    int? excludeAccount,
    String? excludeCurrency,
    required bool isDebit,
    Set<int>? allowedCategories = const {1, 8},
  }) {
    final leg = isDebit ? _debitLeg : _creditLeg;
    final canShowCcySelector = _isEditable &&
        (selected?.accCategory == 1 ||
            (selected == null && leg != null));

    // The bloc is global, so every `GenericTextField` shares its
    // loading state. To keep the spinner on the field that caused
    // it, we wrap the widget in a `BlocListener` that flips the
    // per-field flag OFF once the bloc finishes loading.
    return BlocListener<StkAccountsBloc, StkAccountsState>(
      listenWhen: (prev, next) =>
      prev is StkAccountsLoadingState && next is! StkAccountsLoadingState,
      listener: (_, _) {
        if (isLoading) onLoadingChanged(false);
      },
      child: GenericTextField<StakeholderAccount, StkAccountsBloc,
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

        // ── Scoped loading: only THIS field's own flag ─────
        stateToLoading: (_) => isLoading,
        loadingBuilder: (context) => isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const SizedBox.shrink(),

        searchFunction: (bloc, q) {
          if (q.trim().isEmpty) return;
          onLoadingChanged(true);
          bloc.add(LoadStkAccountsEvent(query: q));
        },

        itemBuilder: (context, account) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${account.accNumber} | ${account.accName}',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (account.accCurrency != null)
                Text(
                  '${account.accBalance} | ${account.accCurrency!}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
        itemToString: (a) =>
        '${a.accNumber} | ${a.accName} | ${a.accCurrency ?? widget.baseCurrency}',
        stateToItems: (s) {
          if (s is! StkAccountsLoadedState) {
            return const <StakeholderAccount>[];
          }
          return s.accounts.where((a) {
            if (allowedCategories != null &&
                !allowedCategories.contains(a.accCategory)) {
              return false;
            }

            final rowCurrency =
            _normalizeCurrency(a.accCurrency ?? widget.baseCurrency);
            final selectedCurrency = _normalizeCurrency(excludeCurrency);

            if (excludeAccount != null &&
                a.accNumber == excludeAccount &&
                rowCurrency == selectedCurrency) {
              return false;
            }
            return true;
          }).toList();
        },
        onSelected: onSelected,
        showCurrencySelector: canShowCcySelector,
        isCurrencySelectorEnabled: canShowCcySelector,
        selectedCurrencyCodeOverride:
        isDebit ? _debitCcyEffective : _creditCcyEffective,
        onCurrencySelectorChanged: (CurrenciesModel? currency) {
          final code = currency?.ccyCode;
          if (code == null || code.isEmpty) return;
          _clearFormError();
          _changeSelectedCurrency(isDebit: isDebit, currencyCode: code);
        },
        validator: (_) {
          if (!_isEditable) return null;
          if (widget.initialDetail != null) return null;
          return selected == null ? 'Required' : null;
        },
      ),
    );
  }

  // ── Amount / rate / credit ─────────────────────────────────
  Widget _buildAmountRow() {
    final tr = AppLocalizations.of(context)!;
    final debitCcy = _debitCcyEffective ?? '';
    final creditCcy = _creditCcyEffective ?? '';

    return Column(
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: ZTextFieldEntitled(
                controller: _amountCtrl,
                title: '${tr.amount} ($debitCcy)',
                isRequired: true,
                isEnabled: _isEditable,
                focusNode: _amountFocus,
                textInputAction: TextInputAction.none,
                onFieldSubmitted: (_) => _rateFocus.requestFocus(),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormat: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) {
                  _clearFormError();
                  _amountSource = _AmountSource.amount;
                  final amount = double.tryParse(
                    _amountCtrl.text.replaceAll(',', ''),
                  );
                  final rate = _rate;
                  if (amount != null &&
                      amount > 0 &&
                      rate != null &&
                      rate > 0) {
                    _recalcCreditFromRate();
                  }
                },
                validator: (v) {
                  if (!_isEditable) return null;
                  final n = double.tryParse((v ?? '').replaceAll(',', ''));
                  if (n == null || n <= 0) {
                    return 'Must be greater than zero';
                  }
                  return null;
                },
              ),
            ),
            Expanded(child: _buildRateField(debitCcy, creditCcy)),
            Expanded(
              child: ZTextFieldEntitled(
                controller: _creditAmountCtrl,
                title: '${tr.amount} ($creditCcy)',
                isRequired: true,
                isEnabled: _isEditable,
                focusNode: _creditAmountFocus,
                textInputAction: TextInputAction.none,
                onFieldSubmitted: (_) => _narrationFocus.requestFocus(),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormat: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) {
                  _clearFormError();
                  _amountSource = _AmountSource.creditAmount;
                  final credit = double.tryParse(
                    _creditAmountCtrl.text.replaceAll(',', ''),
                  );
                  final rate = _rate;
                  if (credit != null &&
                      credit > 0 &&
                      rate != null &&
                      rate > 0) {
                    _recalcAmountFromCreditAndRate();
                  }
                },
                validator: (v) {
                  if (!_isEditable) return null;
                  final n = double.tryParse((v ?? '').replaceAll(',', ''));
                  if (n == null || n <= 0) {
                    return 'Must be greater than zero';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        if (debitCcy.isNotEmpty &&
            creditCcy.isNotEmpty &&
            debitCcy != creditCcy)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _loadingRate
                    ? 'Fetching rate…'
                    : _rate == null
                    ? 'Set rate manually'
                    : '1 $debitCcy = ${_rate!.toStringAsFixed(6)} $creditCcy',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (debitCcy.isNotEmpty &&
            creditCcy.isNotEmpty &&
            debitCcy == creditCcy)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr.sameCurrencyForExchange,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRateField(String debitCcy, String creditCcy) {
    final tr = AppLocalizations.of(context)!;
    final disabled = debitCcy.isEmpty ||
        creditCcy.isEmpty ||
        debitCcy == creditCcy ||
        !_isEditable;

    return Stack(
      children: [
        ZTextFieldEntitled(
          controller: _rateCtrl,
          title: tr.fxRate,
          isRequired: true,
          isEnabled: !disabled,
          focusNode: _rateFocus,
          textInputAction: TextInputAction.none,
          onFieldSubmitted: (_) => _creditAmountFocus.requestFocus(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormat: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (_) {
            _clearFormError();
            _amountSource = _AmountSource.rate;
            final parsed =
            double.tryParse(_rateCtrl.text.replaceAll(',', ''));
            if (parsed != null && parsed > 0) {
              setState(() => _rate = parsed);
              _recalcCreditFromRate();
            }
          },
          validator: (v) {
            if (disabled) return null;
            final n = double.tryParse((v ?? '').replaceAll(',', ''));
            if (n == null || n <= 0) return 'Required';
            return null;
          },
        ),
        if (_loadingRate)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNarrationField() => ZTextFieldEntitled(
    controller: _narrationCtrl,
    title: AppLocalizations.of(context)!.narration,
    isEnabled: _isEditable,
    focusNode: _narrationFocus,
    textInputAction: TextInputAction.none,
    onFieldSubmitted: (_) => submit(),
    onChanged: (_) => _clearFormError(),
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

  // ── Rate retrigger ─────────────────────────────────────────
  void _maybeFetchRate() {
    final from = _debitCcyEffective;
    final to = _creditCcyEffective;
    if (from == null || to == null || from.isEmpty || to.isEmpty) return;

    if (from == to) {
      _setRate(1.0);
      return;
    }

    if (_rate != null &&
        widget.initialDetail != null &&
        _debitAcc == null &&
        _creditAcc == null) {
      return;
    }

    _rateRequestId++;
    final myId = _rateRequestId;
    _fetchRate(from, to).then((_) {
      if (myId != _rateRequestId) return;
    });
  }
}

// DIALOG — provisions ExchangeBloc, reuses TransactionsBloc

Future<bool?> showExchangeDialog(
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
            final bloc = ExchangeBloc(ctx.read<Repositories>());
            if (reference != null && reference.isNotEmpty) {
              bloc.add(LoadExchangeDetailEvent(reference));
            }
            return bloc;
          },
        ),
        BlocProvider<TransactionsBloc>.value(
          value: context.read<TransactionsBloc>(),
        ),
        BlocProvider<ExchangeRateBloc>.value(
          value: context.read<ExchangeRateBloc>(),
        ),
      ],
      child: _ExchangeDialog(
        usrName: usrName,
        baseCurrency: baseCurrency,
        reference: reference,
      ),
    ),
  );
}

class _ExchangeDialog extends StatelessWidget {
  final String usrName;
  final String baseCurrency;
  final String? reference;

  const _ExchangeDialog({
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
          'Delete exchange $ref?\n\n'
              'The record will be marked as Deleted and its balance will be reversed.',
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
    final formKey = GlobalKey<ExchangeFormState>();

    return MultiBlocListener(
      listeners: [
        BlocListener<ExchangeBloc, ExchangeState>(
          listener: (context, state) {
            if (state is ExchangeSubmitSuccess) {
              ToastManager.show(
                context: context,
                title: 'Saved',
                message: state.message,
                type: ToastType.success,
              );
              context
                  .read<ExchangeBloc>()
                  .add(const ClearExchangeSuccessEvent());
              Navigator.of(context).pop(true);
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
                context
                    .read<ExchangeBloc>()
                    .add(LoadExchangeDetailEvent(ref));
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
      child: BlocBuilder<ExchangeBloc, ExchangeState>(
        builder: (context, state) {
          final busy = state is ExchangeSubmitting;
          final loaded =
          state is ExchangeDetailLoaded ? state.detail : null;
          final stateText = loaded?.stateText;
          final isPending = stateText == null || stateText == 'Pending';
          final isAuthorized = stateText == 'Authorized';
          final loginName = _loginName(context);
          final isMaker = loaded == null || (loaded.maker.isNotEmpty && loginName != null && loaded.maker == loginName);
          final isEditing = _isEditing;

          if (isEditing && loaded == null && state is! ExchangeError) {
            return ZFormDialog(
              width: 720,
              icon: Icons.swap_horiz_rounded,
              title: 'Exchange · $reference',
              isActionTrue: false,
              onAction: null,
              child: const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return ZFormDialog(
            width: 720,
            icon: Icons.swap_horiz_rounded,
            title: isEditing ? '${AppLocalizations.of(context)!.exchange} · $reference' : AppLocalizations.of(context)!.newExchange,
            isActionTrue: false,
            onAction: null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state is ExchangeError && state.message.isNotEmpty)
                    _banner(
                      state.message,
                      Theme.of(context).colorScheme.error,
                    ),
                  Flexible(
                    child: ExchangeForm(
                      key: ValueKey(reference ?? 'new'),
                      formKey: formKey,
                      usrName: usrName,
                      baseCurrency: baseCurrency,
                      initialDetail: loaded,
                      stateText: stateText,
                      onSubmit: (result) {
                        if (isEditing) {
                          context.read<ExchangeBloc>().add(
                            EditExchangeEvent(
                              reference: result.reference!,
                              usrName: result.usrName,
                              debit: result.debit,
                              credit: result.credit,
                            ),
                          );
                        } else {
                          context.read<ExchangeBloc>().add(
                            AddExchangeEvent(
                              usrName: result.usrName,
                              debit: result.debit,
                              credit: result.credit,
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
                          onPressed: () =>
                              Navigator.of(context).pop(false),
                          label: Text(
                            AppLocalizations.of(context)!.cancel,
                          ),
                        ),
                        if (isEditing && isPending && isMaker && !busy) ...[
                          ZOutlineButton(
                            onPressed: () => _dispatchDelete(context),
                            backgroundHover: Theme.of(context).colorScheme.error,
                            icon: Icons.delete_outline_rounded,
                            label: Text(AppLocalizations.of(context)!.delete),
                          ),
                          ZOutlineButton(
                            isActive: true,
                            onPressed: () => formKey.currentState?.submit(),
                            icon: Icons.save_alt_rounded,
                            label: Text(AppLocalizations.of(context)!.save),
                          ),
                        ],
                        if (isEditing &&
                            isPending &&
                            !isMaker &&
                            loginName != null &&
                            !busy) ...[
                          ZOutlineButton(
                            isActive: true,
                            onPressed: () => _dispatchAuthorize(context),
                            icon: Icons.check_circle_outline_rounded,
                            label: Text(AppLocalizations.of(context)!.authorize),
                          ),
                        ],
                        if (isEditing && isAuthorized && !busy) ...[
                          ZOutlineButton(
                            onPressed: () => _dispatchUnauthorize(context),
                            icon: Icons.undo_rounded,
                            label: Text(AppLocalizations.of(context)!.unauthorize),
                          ),
                          ZOutlineButton(
                            onPressed: () => _dispatchReverse(context),
                            icon: Icons.replay_rounded,
                            label: Text(AppLocalizations.of(context)!.reverse),
                          ),
                        ],
                        if (!isEditing)
                          ZOutlineButton(
                            isActive: true,
                            onPressed: busy
                                ? null
                                : () => formKey.currentState?.submit(),
                            icon: Icons.save_alt_rounded,
                            label: Text(
                              AppLocalizations.of(context)!.save,
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
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

// Shared widgets

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

class _InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const _InlineErrorBanner({
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.error.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.error.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: color.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color.error, fontSize: 12),
            ),
          ),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close_rounded,
                  color: color.error,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountDetailsCard extends StatelessWidget {
  final StakeholderAccount account;
  final String fallbackCurrency;
  final String label;
  final String? effectiveCurrency;

  const _AccountDetailsCard({
    required this.account,
    required this.fallbackCurrency,
    this.label = 'Account details',
    this.effectiveCurrency,
  });

  static const int _stakeholderCategory = 8;

  @override
  Widget build(BuildContext context) {
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

    final isStakeholder = account.accCategory == _stakeholderCategory;
    final status = account.accStatus;
    final effectiveCcy = account.accCategory == 1
        ? (effectiveCurrency ?? account.accCurrency ?? fallbackCurrency)
        : (account.accCurrency ??
        (fallbackCurrency.isEmpty ? '' : fallbackCurrency));

    return ZCover(
      padding: const EdgeInsets.all(12),
      radius: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: title?.copyWith(fontWeight: FontWeight.bold)),
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

class _LegDetailsCard extends StatelessWidget {
  final ExchangeLeg leg;
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