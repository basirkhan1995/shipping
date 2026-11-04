import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Date/shamsi_converter.dart';
import 'package:shipping/Features/PrintSettings/print_preview.dart';
import 'package:shipping/Features/PrintSettings/report_model.dart';
import 'package:shipping/Features/Widgets/cover.dart';
import 'package:shipping/Features/Widgets/extensions.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/model/stk_model.dart';
import 'package:shipping/Routes/Home/View/Transactions/View/CashWD/voucher/voucher.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../Features/Widgets/z_dialog.dart';
import '../../../../../../Services/repository.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Settings/View/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../bloc/transactions_bloc.dart';
import '../../model/trn_model.dart';
import 'bloc/cash_txn_bloc.dart';
import 'bloc/cash_txn_event.dart';
import 'model/wd_model.dart';

// ═════════════════════════════════════════════════════════════════
// SPEC
// ═════════════════════════════════════════════════════════════════

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

  /// True if the current logged-in user is the one who created this txn.
  final bool isMaker;

  /// Optional external trigger so the dialog (mouse click) and the
  /// narration field (Enter key) go through the *same* submit path.
  final VoidCallback? onSubmitRequested;

  final TransactionDraft? initialDraft;
  final String? stateText;

  /// Notifies the dialog when the "Print" checkbox changes.
  final ValueChanged<bool>? onPrintChanged;

  const CashTxnForm({
    super.key,
    this.isMaker = true,
    required this.spec,
    required this.usrName,
    required this.baseCurrency,
    required this.onSubmit,
    this.onSubmitRequested,
    this.initialDraft,
    this.stateText,
    this.onPrintChanged,
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

  /// Edit-mode fallback: the account number from the loaded draft.
  int? _draftAccountNo;

  /// Pending sync request
  int? _pendingAccountNo;

  static const int _stakeholderCategory = 8;

  /// Exposed so the dialog can read the current "Print" toggle.
  bool get printEnabled => _print;

  /// Form is editable ONLY IF it is Pending (or new) AND the current user is the Maker.
  bool get _isEditable {
    final isPending = widget.stateText == null || widget.stateText == 'Pending';
    return isPending && widget.isMaker;
  }

  int? get _effectiveAccountNo => _acc?.accNumber ?? _draftAccountNo;

  @override
  void initState() {
    super.initState();
    _ccy = widget.baseCurrency;
    _applyDraft(widget.initialDraft);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPrintChanged?.call(_print);
    });

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

  bool submit() {
    if (!_isEditable) return false;

    final ok = _formKey.currentState?.validate() == true;
    if (!ok) return false;

    final draft = widget.initialDraft;
    final accNumber = _effectiveAccountNo;
    if (accNumber == null) return false;

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

              if (_acc != null)
                _AccountDetailsCard(
                  account: _acc!,
                  fallbackCurrency: widget.baseCurrency,
                  label: tr.accountDetails,
                  effectiveCurrencyOverride: _ccy,
                )
              else if (_effectiveAccountNo != null)
                _PendingAccountCard(
                  accountNo: _effectiveAccountNo!,
                  fallbackCurrency: widget.baseCurrency,
                  effectiveCurrency: _ccy ?? widget.baseCurrency,
                  label: tr.accountDetails,
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
        isEnabled: _isEditable,
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
    readOnly: !_isEditable,
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
    readOnly: !_isEditable,
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
          onChanged: _onReminderToggled,
        ),
      if (_isEditable)
        _Check(
          label: AppLocalizations.of(context)!.print,
          value: _print,
          onChanged: (v) {
            setState(() => _print = v);
            widget.onPrintChanged?.call(v);
          },
        ),
    ],
  );

  Future<void> _onReminderToggled(bool value) async {
    if (!value) {
      setState(() {
        _reminder = false;
        _reminderDate = null;
      });
      return;
    }

    setState(() => _reminder = true);

    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (!mounted) return;

    if (picked == null) {
      setState(() {
        _reminder = false;
        _reminderDate = null;
      });
      return;
    }

    setState(() => _reminderDate = picked);
  }

  Widget _buildReminderPicker() {
    if (_reminderDate == null) return const SizedBox.shrink();

    return InkWell(
      onTap: _isEditable
          ? () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _reminderDate!,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (!mounted || picked == null) return;
        setState(() => _reminderDate = picked);
      }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.dueDate,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          MaterialLocalizations.of(context).formatMediumDate(_reminderDate!),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// DIALOG ENTRY
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

/// Which row-action button is currently in flight.
enum _RowAction { none, delete, authorize, unauthorize, reverse }

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

  final _formKey = GlobalKey<CashTxnFormState>();

  bool _formBusy = false;
  _RowAction _pendingAction = _RowAction.none;

  /// Mirrors the "Print" checkbox inside the form.
  bool _shouldPrint = true;

  bool get _actionBusy => _pendingAction != _RowAction.none;

  CashTxnSpec get spec => widget.spec;
  String get usrName => widget.usrName;
  String get baseCurrency => widget.baseCurrency;
  String? get reference => widget.reference;

  bool get _isEditing => reference != null && reference!.isNotEmpty;

  // ═════════════════════════════════════════════════════════════
  // AUTH
  // ═════════════════════════════════════════════════════════════

  String? _loginName(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthenticatedState ? auth.loginData.usrName : null;
  }

  // ═════════════════════════════════════════════════════════════
  // COMPANY
  // ═════════════════════════════════════════════════════════════

  ReportModel _reportFromState(CompanyProfileState state) {
    final report = ReportModel();
    if (state is CompanyProfileLoadedState) {
      report.comName = state.company.comName ?? '';
      report.comAddress = state.company.addName ?? '';
      report.compPhone = state.company.comPhone ?? '';
      report.comEmail = state.company.comEmail ?? '';
      report.comWhatsApp = state.company.comWhatsapp ?? '';
      report.comWebsite = state.company.comWebsite ?? '';
      report.comFacebook = state.company.comFb ?? '';
      report.comInstagram = state.company.comInsta ?? '';
      report.statementDate = DateTime.now().toFullDateTime;

      final base64Logo = state.company.comLogo;
      if (base64Logo != null && base64Logo.isNotEmpty) {
        try {
          report.comLogo = base64Decode(base64Logo);
        } catch (_) {
          report.comLogo = Uint8List(0);
        }
      }
    }
    return report;
  }

  // ═════════════════════════════════════════════════════════════
  // PRINT
  // ═════════════════════════════════════════════════════════════

  Future<void> _printVoucher(BuildContext context, CashTxnDetail data) async {
    final company = _reportFromState(
      context.read<CompanyProfileBloc>().state,
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PrintPreviewDialog<CashTxnDetail>(
        data: data,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return CashTxnVoucherPrintSettings().printPreview(
            company: company,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            data: data,
          );
        },
        onPrint: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
          required selectedPrinter,
          required copies,
          required pages,
        }) {
          return CashTxnVoucherPrintSettings().printDocument(
            company: company,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            selectedPrinter: selectedPrinter,
            data: data,
            copies: copies,
            pages: pages,
          );
        },
        onSave: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return CashTxnVoucherPrintSettings().createDocument(
            data: data,
            company: company,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
          );
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // BUSY HELPERS
  // ═════════════════════════════════════════════════════════════

  void _clearLocalError() {
    if (_localError != null && mounted) {
      setState(() => _localError = null);
    }
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

  void _onFormSubmit() {
    final st = _formKey.currentState;
    if (st == null) return;

    _shouldPrint = st.printEnabled;
    _clearLocalError();
    _setFormBusy(true);

    final dispatched = st.submit();
    if (!dispatched) _setFormBusy(false);
  }

  // ═════════════════════════════════════════════════════════════
  // ROW ACTIONS
  // ═════════════════════════════════════════════════════════════

  void _dispatchAuthorize(BuildContext context) {
    final ref = reference;
    if (ref == null || ref.isEmpty) return;
    _clearLocalError();
    _setPendingAction(_RowAction.authorize);
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
    _clearLocalError();
    _setPendingAction(_RowAction.unauthorize);
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
    _setPendingAction(_RowAction.reverse);
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
    _setPendingAction(_RowAction.delete);

    context.read<TransactionsBloc>().add(
      DeleteTransactionEvent(
        reference: ref,
        userName: _loginName(context),
      ),
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

  // ═════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CashTxnBloc, CashTxnState>(
          listener: (context, state) async {
            if (state is CashTxnSuccess) {
              _setFormBusy(false);

              // ── AUTO PRINT ───────────────────────────────
              if (_shouldPrint) {
                final detail = state.detail;
                if (detail != null) {
                  await _printVoucher(context, detail);
                }
              }

              // Guard against async gap
              if (!context.mounted) return;

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
              _clearPendingAction();
              if (mounted && _localError != null) {
                setState(() => _localError = null);
              }
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
              _clearPendingAction();
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

          final blocRowBusy = context.select<TransactionsBloc, bool>((bloc) {
            final s = bloc.state;
            if (s is! TransactionsLoadedState) return false;
            final ref = reference;
            if (ref == null || ref.isEmpty) return false;
            return s.actionInProgress == ref;
          });
          final rowBusy = _actionBusy || blocRowBusy;
          final anyBusy = cashBusy || rowBusy;

          final deleteBusy = _pendingAction == _RowAction.delete;
          final authorizeBusy = _pendingAction == _RowAction.authorize;
          final unauthorizeBusy = _pendingAction == _RowAction.unauthorize;
          final reverseBusy = _pendingAction == _RowAction.reverse;

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
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state is CashTxnFailure && state.message.isNotEmpty)
                    _banner(
                      state.message,
                      Theme.of(context).colorScheme.error,
                    ),

                  if (_localError != null && _localError!.isNotEmpty)
                    _banner(
                      _localError!,
                      Theme.of(context).colorScheme.error,
                    ),

                  if (initial != null && _hasAuditData(initial))
                    _TransactionAuditStrip(draft: initial),

                  Flexible(
                    child: CashTxnForm(
                      key: _formKey,
                      spec: spec,
                      usrName: usrName,
                      baseCurrency: baseCurrency,
                      initialDraft: initial,
                      stateText: stateText,
                      isMaker: isMaker, // <-- PASSED HERE
                      onSubmitRequested: _onFormSubmit,
                      onPrintChanged: (v) => _shouldPrint = v,
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

                        // ── REPRINT (edit mode only) ───────────
                        if (isEditing && loaded != null)
                          ZOutlineButton(
                            isActive: !anyBusy,
                            onPressed: anyBusy
                                ? null
                                : () => _printVoucher(
                              context,
                              loaded.detail,
                            ),
                            icon: Icons.print_outlined,
                            label: Text(
                              AppLocalizations.of(context)!.print,
                            ),
                          ),

                        if (isEditing && isPending && isMaker) ...[
                          ZOutlineButton(
                            onPressed: anyBusy
                                ? null
                                : () => _dispatchDelete(context),
                            backgroundHover:
                            Theme.of(context).colorScheme.error,
                            icon: deleteBusy
                                ? null
                                : Icons.delete_outline_rounded,
                            label: _busyLabel(
                              context,
                              busy: deleteBusy,
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

                        if (isEditing && isPending && !isMaker)
                          ZOutlineButton(
                            isActive: !authorizeBusy,
                            onPressed: anyBusy
                                ? null
                                : () => _dispatchAuthorize(context),
                            icon: authorizeBusy
                                ? null
                                : Icons.check_circle_outline_rounded,
                            label: _busyLabel(
                              context,
                              busy: authorizeBusy,
                              busyText:
                              AppLocalizations.of(context)!.authorizing,
                              idleText:
                              AppLocalizations.of(context)!.authorize,
                            ),
                          ),

                        if (isEditing && isAuthorized) ...[
                          ZOutlineButton(
                            isActive: !unauthorizeBusy,
                            onPressed: anyBusy
                                ? null
                                : () => _dispatchUnauthorize(context),
                            icon: unauthorizeBusy
                                ? null
                                : Icons.undo_rounded,
                            label: _busyLabel(
                              context,
                              busy: unauthorizeBusy,
                              busyText: AppLocalizations.of(context)!
                                  .unauthorize,
                              idleText: AppLocalizations.of(context)!
                                  .unauthorize,
                            ),
                          ),
                          ZOutlineButton(
                            isActive: !reverseBusy,
                            onPressed: anyBusy
                                ? null
                                : () => _dispatchReverse(context),
                            icon: reverseBusy
                                ? null
                                : Icons.replay_rounded,
                            label: _busyLabel(
                              context,
                              busy: reverseBusy,
                              busyText:
                              AppLocalizations.of(context)!.reversing,
                              idleText:
                              AppLocalizations.of(context)!.reverse,
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
                              busyText:
                              AppLocalizations.of(context)!.saving,
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

  /// True when the draft carries any audit data worth rendering.
  bool _hasAuditData(TransactionDraft d) =>
      d.trnStateText != null ||
          d.trnStatus != null ||
          (d.maker ?? '').isNotEmpty ||
          (d.checker ?? '').isNotEmpty ||
          d.trnEntryDate != null;

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
          child:
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ),
      ],
    ),
  );
}

// ═════════════════════════════════════════════════════════════════
// AUDIT STRIP
// ═════════════════════════════════════════════════════════════════

class _TransactionAuditStrip extends StatelessWidget {
  final TransactionDraft draft;
  const _TransactionAuditStrip({required this.draft});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final statusLabel =
        draft.trnStateText ?? _statusFallback(draft.trnStatus);
    final palette = _StatusPalette.of(context, statusLabel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 6,
        children: [
          _AuditChip(
            icon: Icons.circle,
            iconColor: palette.fg,
            iconSize: 8,
            bg: palette.bg,
            fg: palette.fg,
            boldValue: true,
            label: statusLabel.toUpperCase(),
          ),
          if ((draft.maker ?? '').isNotEmpty)
            _AuditChip(
              icon: Icons.person,
              iconSize: 15,
              iconColor: scheme.onSurfaceVariant,
              bg: Colors.transparent,
              fg: scheme.onSurfaceVariant,
              label: '${tr.maker.toUpperCase()}: ${draft.maker}',
              boldValue: true,
            ),
          if ((draft.checker ?? '').isNotEmpty)
            _AuditChip(
              icon: Icons.verified_user_outlined,
              iconSize: 15,
              iconColor: scheme.onSurfaceVariant,
              bg: Colors.transparent,
              fg: scheme.onSurfaceVariant,
              label: '${tr.authorizer.toUpperCase()}: ${draft.checker}',
              boldValue: true,
            ),
          if (draft.trnEntryDate != null)
            _AuditChip(
              icon: Icons.schedule_rounded,
              iconSize: 15,
              iconColor: scheme.onSurfaceVariant,
              bg: Colors.transparent,
              fg: scheme.onSurfaceVariant,
              label:
              "${draft.trnEntryDate!.toFormattedDate()} | ${draft.trnEntryDate!.shamsiDateString}",
            ),
        ],
      ),
    );
  }

  String _statusFallback(int? status) {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Authorized';
      case 2:
        return 'Reversed';
      case 3:
        return 'Deleted';
      default:
        return 'Unknown';
    }
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
    final title = Theme.of(context).textTheme.titleSmall?.copyWith(
      letterSpacing: 0.3,
      fontWeight: FontWeight.w500,
    );

    Widget row(String k, String v, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 170, child: Text(k, style: title)),
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
    final tr = AppLocalizations.of(context)!;
    final effectiveCcy = account.accCurrency ??
        effectiveCurrencyOverride ??
        (fallbackCurrency.isEmpty ? '' : fallbackCurrency);

    return ZCover(
      padding: const EdgeInsets.all(12),
      radius: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: title?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: .05,
            ),
          ),
          SizedBox(height: 2),
          const Divider(),
          SizedBox(height: 2),
          row(tr.accountNumber.toUpperCase(),
              account.accNumber?.toString() ?? ''),
          row(tr.accountName.toUpperCase(), account.accName ?? ''),
          row(
            tr.balance.toUpperCase(),
            '${account.accBalance.toAmount()} '
                '${account.accCurrency ?? effectiveCcy}',
          ),
          if (isStakeholder && status != null)
            row(
              tr.status.toUpperCase(),
              status == 1
                  ? tr.active.toUpperCase()
                  : tr.blocked.toUpperCase(),
            ),
        ],
      ),
    );
  }
}

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
              Text(label,
                  style:
                  title?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
          const Divider(),
          row(AppLocalizations.of(context)!.accountNumber,
              accountNo.toString()),
          row(AppLocalizations.of(context)!.currency, ccy),
        ],
      ),
    );
  }
}