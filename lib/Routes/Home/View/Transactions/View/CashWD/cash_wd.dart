// features/journal/cash/view/cash_txn_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/model/stk_model.dart';

import '../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';

import '../../../../../../Features/Widgets/z_dialog.dart';
import '../../../../../../Features/Widgets/toast.dart';
import '../../../../../../Services/repository.dart';

import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../model/trn_model.dart';
import 'bloc/cash_txn_bloc.dart';
import 'bloc/cash_txn_event.dart';

/// Configuration that differs per transaction type.
class CashTxnSpec {
  final String typeCode;
  final IconData icon;
  final String Function(BuildContext) title;

  /// Account categories to show (comma-separated). Default '8' = stakeholder.
  /// Pass 'all' or empty to show all categories.
  final String accountInclude;

  /// Account numbers to exclude (comma-separated), e.g. '10101011'.
  final String accountExclude;

  /// When true, only accounts whose currency == baseCurrency (or whose
  /// currency is null) are shown. Only meaningful for GL-style accounts.
  final bool restrictToBaseCurrency;

  /// Whether to show the "Set reminder" checkbox (only CHDP / CHWL).
  final bool allowReminder;

  /// Only honoured for stakeholder accounts (category 8).
  /// GL / INCM / XPNS accounts are always forced to baseCurrency.
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

class CashTxnForm extends StatefulWidget {
  final CashTxnSpec spec;
  final String usrName;
  final String baseCurrency;
  final ValueChanged<TransactionDraft> onSubmit;
  final GlobalKey<CashTxnFormState>? formKey;

  const CashTxnForm({
    super.key,
    required this.spec,
    required this.usrName,
    required this.baseCurrency,
    required this.onSubmit,
    this.formKey,
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

  /// Category 8 = stakeholder. Only these use the account's own currency;
  /// everything else posts in the base currency.
  static const int _stakeholderCategory = 8;

  @override
  void initState() {
    super.initState();
    _ccy = widget.baseCurrency;

    // Wait two frames so the dialog route and ZTextFieldEntitled finish
    // their own focus setup — avoids the Amount→Account flash.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _accountFocus.requestFocus();
      });
    });
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
    final ok = _formKey.currentState?.validate() == true;
    debugPrint(
      'CashTxnForm.submit: valid=$ok acc=${_acc?.accNumber} ccy=$_ccy',
    );
    if (!ok) return;
    if (_acc == null || _acc!.accNumber == null) return;

    widget.onSubmit(TransactionDraft(
      trnType: widget.spec.typeCode,
      usrName: widget.usrName,
      trdAccount: _acc!.accNumber!,
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
        title: 'Accounts',
        hintText: 'Start typing to search…',
        isRequired: true,
        bloc: context.read<StkAccountsBloc>(),
        focusNode: _accountFocus,
        textInputAction: TextInputAction.none,
        showAllOnFocus: false,
        fetchAllFunction: null,
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

            // Currency rule:
            //   • Stakeholder (cat 8) → use the account's own currency
            //     (unless editableCurrency, in which case keep caller's value)
            //   • Any other category   → always base currency.
            final isStakeholder = a.accCategory == _stakeholderCategory;
            if (!isStakeholder) {
              _ccy = widget.baseCurrency;
            } else if (!widget.spec.editableCurrency) {
              _ccy = a.accCurrency ?? widget.baseCurrency;
            }
          });

          // Defer focus jump so the overlay's tap handler finishes first.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _amountFocus.requestFocus();
          });
        },
        validator: (v) => (_acc == null) ? 'Required' : null,
      );

  // ── Filter rules ────────────────────────────────────────────────
  //   1. Category — required unless spec says 'all'.
  //   2. Account-number excludes.
  //   3. Currency — only when restrictToBaseCurrency is true AND the
  //      account actually has a currency. `null` currency = treat as base
  //      (GL/INCM/XPNS may not have an accountDetails row yet).
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
      // 1) Category.
      if (include.isNotEmpty && !include.contains(a.accCategory)) {
        return false;
      }
      // 2) Excludes.
      if (exclude.contains(a.accNumber.toString())) return false;
      // 3) Currency — null counts as base.
      if (widget.spec.restrictToBaseCurrency &&
          widget.baseCurrency.isNotEmpty &&
          a.accCurrency != null &&
          a.accCurrency != widget.baseCurrency) {
        return false;
      }
      return true;
    }).toList();
  }

  // ── Amount ─────────────────────────────────────────────────────
  Widget _buildAmountField() => ZTextFieldEntitled(
    controller: _amountCtrl,
    title: 'Amount',
    isRequired: true,
    focusNode: _amountFocus,
    textInputAction: TextInputAction.none,
    onFieldSubmitted: (_) => _narrationFocus.requestFocus(),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormat: [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
    ],
    validator: (v) {
      final n = double.tryParse((v ?? '').replaceAll(',', ''));
      if (n == null || n <= 0) return 'Must be greater than zero';
      return null;
    },
  );

  // ── Narration ──────────────────────────────────────────────────
  Widget _buildNarrationField() => ZTextFieldEntitled(
    controller: _narrationCtrl,
    title: 'Narration',
    focusNode: _narrationFocus,
    textInputAction: TextInputAction.none,
    onFieldSubmitted: (_) => submit(),
    keyboardType: TextInputType.multiline,
    validator: (v) =>
    (v == null || v.trim().isEmpty) ? 'Required' : null,
  );

  // ── Toggles ────────────────────────────────────────────────────
  Widget _buildToggles() => Row(
    spacing: 12,
    children: [
      if (widget.spec.allowReminder)
        _Check(
          label: 'Set reminder',
          value: _reminder,
          onChanged: (v) => setState(() => _reminder = v),
        ),
      _Check(
        label: 'Print',
        value: _print,
        onChanged: (v) => setState(() => _print = v),
      ),
    ],
  );

  Widget _buildReminderPicker() => ZDatePicker(
    label: 'Due date',
    disablePastDate: true,
    value: _reminderDate?.toIso8601String(),
    onDateChanged: (v) =>
        setState(() => _reminderDate = DateTime.tryParse(v)),
  );
}

// ═════════════════════════════════════════════════════════════════
// Dialog
// ═════════════════════════════════════════════════════════════════

Future<bool?> showCashTxnDialog(
    BuildContext context, {
      required CashTxnSpec spec,
      required String usrName,
      required String baseCurrency,
    }) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider(
      create: (ctx) => CashTxnBloc(ctx.read<Repositories>()),
      child: _CashTxnDialog(
        spec: spec,
        usrName: usrName,
        baseCurrency: baseCurrency,
      ),
    ),
  );
}

class _CashTxnDialog extends StatelessWidget {
  final CashTxnSpec spec;
  final String usrName;
  final String baseCurrency;

  const _CashTxnDialog({
    required this.spec,
    required this.usrName,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<CashTxnFormState>();

    return BlocConsumer<CashTxnBloc, CashTxnState>(
      listener: (context, state) {
        if (state is CashTxnSuccess) {
          Navigator.of(context).pop(true);
        } else if (state is CashTxnFailure) {
          ToastManager.show(
            context: context,
            title: 'Failed',
            message: state.message,
            type: ToastType.error,
          );
        }
      },
      builder: (context, state) {
        final busy = state is CashTxnSubmitting;

        return ZFormDialog(
          width: 600,
          icon: spec.icon,
          title: spec.title(context),
          actionLabel: busy
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 3),
          )
              : const Text('Create'),
          onAction: busy ? null : () => formKey.currentState?.submit(),
          child: CashTxnForm(
            formKey: formKey,
            spec: spec,
            usrName: usrName,
            baseCurrency: baseCurrency,
            onSubmit: (draft) =>
                context.read<CashTxnBloc>().add(CashTxnCreateRequested(draft)),
          ),
        );
      },
    );
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

  /// Effective currency to display when the account has no currency of
  /// its own. Always base currency for GL / INCM / XPNS accounts.
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

    // Effective currency the transaction will actually use.
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
          row('Currency', effectiveCcy),
          // Status only exists for stakeholder accounts.
          if (isStakeholder && status != null)
            row('Status', status == 1 ? 'Active' : 'Blocked'),
        ],
      ),
    );
  }
}