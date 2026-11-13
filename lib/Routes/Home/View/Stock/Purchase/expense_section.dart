import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/Finance/View/GlAccounts/bloc/gl_accounts_bloc.dart';
import 'package:shipping/Routes/Home/View/Finance/View/GlAccounts/model/gl_model.dart';
import '../../../../../Features/Other/form_dialog.dart';
import '../../../../../Features/Other/generic_textfield.dart';
import '../../../../../Features/Widgets/extensions.dart';
import '../../../../../Features/Widgets/zbutton.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../Auth/bloc/auth_bloc.dart';
import 'bloc/purchase_invoice_bloc.dart';
import 'model/purchase_invoice_items.dart';

/// Returns only expense accounts (top-level category 4).
/// The GL API returns `accCategory` = the top-level acgCategory,
/// not the acgID — so 4 covers both Operating and Non-Operating expense.
List<GlAccountsModel> _expenseOnly(List<GlAccountsModel> all) =>
    all.where((a) => a.accCategory == 4).toList();

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class ExpensesDialog extends StatelessWidget {
  const ExpensesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
      builder: (context, state) {
        if (state is PurchaseInvoiceLoaded) {
          return _ExpensesDialogContent(payments: state.expenses);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _ExpensesDialogContent extends StatelessWidget {
  final List<PurchasePaymentRecord> payments;

  const _ExpensesDialogContent({required this.payments});

  /// Company base currency from the authenticated session.
  /// Null only if the login payload was malformed (missing company).
  String? _baseCurrency(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      final ccy = authState.loginData.company?.comLocalCcy?.trim();
      if (ccy != null && ccy.isNotEmpty) return ccy;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = payments.fold(0.0, (sum, e) => sum + e.amount);
    final tr = AppLocalizations.of(context)!;
    final baseCurrency = _baseCurrency(context);

    return ZFormDialog(
      title: tr.expenseEntry,
      icon: Icons.outbond_outlined,
      isActionTrue: false,
      padding: const EdgeInsets.all(15),
      width: MediaQuery.of(context).size.width * .7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${tr.expenses} (${payments.length})",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ZOutlineButton(
                  onPressed: () {
                    context.read<PurchaseInvoiceBloc>().add(
                      const AddPaymentEvent(isExpense: true),
                    );
                  },
                  icon: Icons.add,
                  isActive: true,
                  label: Text(tr.addItem),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: payments.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No expenses added',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _ExpenseRow(
                  key: ValueKey(index),
                  index: index,
                  payment: payment,
                  isLastRow: index == payments.length - 1,
                );
              },
            ),
          ),

          if (payments.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr.totalExpense,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  "${totalExpenses.toAmount()} ${baseCurrency ?? ''}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      onAction: () => Navigator.pop(context),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseRow extends StatefulWidget {
  final int index;
  final PurchasePaymentRecord payment;
  final bool isLastRow;

  const _ExpenseRow({
    required this.index,
    required this.payment,
    this.isLastRow = false,
    super.key,
  });

  @override
  State<_ExpenseRow> createState() => _ExpenseRowState();
}

class _ExpenseRowState extends State<_ExpenseRow> {
  late TextEditingController _narrationController;
  late TextEditingController _amountController;
  late TextEditingController _accountController;

  final FocusNode _accountFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _narrationFocusNode = FocusNode();

  Timer? _debounce;
  bool _isUpdating = false;

  /// Company base currency from the authenticated session.
  /// Read fresh each time — no cache, no staleness.
  /// Null only if the login payload was malformed (missing company).
  String? get _baseCurrency {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      final ccy = authState.loginData.company?.comLocalCcy?.trim();
      if (ccy != null && ccy.isNotEmpty) return ccy;
    }
    return null;
  }

  bool get _hasBaseCurrency => (_baseCurrency ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();

    _narrationController =
        TextEditingController(text: widget.payment.narration ?? '');
    _amountController = TextEditingController(
      text: widget.payment.amount > 0 ? widget.payment.amount.toString() : '',
    );
    _accountController =
        TextEditingController(text: _getAccountDisplayText());

    // Focus the account field for new/empty rows.
    if (widget.payment.accountNumber == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _accountFocusNode.canRequestFocus) {
          _accountFocusNode.requestFocus();
        }
      });
    }
  }

  String _getAccountDisplayText() {
    if (widget.payment.accountNumber != 0) {
      return widget.payment.accountNumber.toString();
    }
    return '';
  }

  @override
  void didUpdateWidget(_ExpenseRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isUpdating) return;

    // Narration
    final newNarration = widget.payment.narration ?? '';
    if (_narrationController.text != newNarration) {
      _narrationController.value = TextEditingValue(
        text: newNarration,
        selection: TextSelection.collapsed(offset: newNarration.length),
      );
    }

    // Amount
    final newAmount =
    widget.payment.amount > 0 ? widget.payment.amount.toString() : '';
    if (_amountController.text != newAmount) {
      _amountController.value = TextEditingValue(
        text: newAmount,
        selection: TextSelection.collapsed(offset: newAmount.length),
      );
    }

    // Account
    final newAccountText = _getAccountDisplayText();
    if (_accountController.text != newAccountText) {
      _accountController.text = newAccountText;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _narrationController.dispose();
    _amountController.dispose();
    _accountController.dispose();
    _accountFocusNode.dispose();
    _amountFocusNode.dispose();
    _narrationFocusNode.dispose();
    super.dispose();
  }

  void _updateExpense({
    String? narration,
    double? amount,
    int? accountNumber,
    double? exRate,
    String? currency,
  }) {
    // Resolve to a guaranteed non-empty currency. If none is available,
    // drop the update so we never send an empty `trdCcy` to the server (FK safety).
    final raw = (currency ?? widget.payment.currency).trim();
    if (raw.isEmpty) return;

    _isUpdating = true;
    context.read<PurchaseInvoiceBloc>().add(
      UpdatePaymentEvent(
        index: widget.index,
        narration: narration,
        amount: amount,
        accountNumber: accountNumber,
        exRate: exRate ?? widget.payment.exRate,
        currency: raw,
        isExpense: true,
      ),
    );

    Future.microtask(() {
      if (mounted) _isUpdating = false;
    });
  }

  void _debounceUpdate(VoidCallback action) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), action);
  }

  /// Enter pressed in the amount field: add a new row (if this is the last one),
  /// then let the new row focus its own account field via its `initState`.
  void _onAmountSubmitted() {
    // Flush any pending debounced amount update before we possibly add a row.
    _debounce?.cancel();
    final pendingAmount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    if (pendingAmount > 0) {
      _updateExpense(amount: pendingAmount);
    }

    if (!widget.isLastRow) {
      // Not the last row — just move focus back to this row's account field.
      _accountFocusNode.requestFocus();
      return;
    }

    if (!mounted) return;

    // Append a new expense row. Its `initState` will focus the account field.
    context.read<PurchaseInvoiceBloc>().add(
      const AddPaymentEvent(isExpense: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          children: [
            /// Account Selection
            Expanded(
              flex: 2,
              child: GenericTextField<GlAccountsModel, GlAccountsBloc,
                  GlAccountsState>(
                title: "",
                textFieldStyle: TextFieldStyle.noBorder,
                hintText: tr.accounts,
                controller: _accountController,
                focusNode: _accountFocusNode,
                textInputAction: TextInputAction.next,
                bloc: context.read<GlAccountsBloc>(),
                fetchAllFunction: (bloc) => bloc.add(LoadGlAccountEvent()),
                searchFunction: (bloc, query) => bloc.add(
                  LoadGlAccountEvent(query: query),
                ),
                itemBuilder: (context, account) => Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: Text("${account.accNumber} | ${account.accName}"),
                ),
                itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                stateToLoading: (state) => state is GlAccountsLoadingState,
                stateToItems: (state) {
                  if (state is GlAccountLoadedState) {
                    return _expenseOnly(state.gl);
                  }
                  return [];
                },
                onSelected: (account) {
                  if (!_hasBaseCurrency) {
                    // Login payload is missing a company currency — refuse
                    // to emit an empty `currency` that would break the FK.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr.loading),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    return;
                  }
                  _updateExpense(
                    accountNumber: account.accNumber,
                    currency: _baseCurrency,
                  );
                  // Move focus to narration for a smooth entry flow.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _narrationFocusNode.requestFocus();
                  });
                },
                showClearButton: true,
              ),
            ),

            const SizedBox(width: 8),

            /// Narration
            Expanded(
              flex: 4,
              child: TextField(
                controller: _narrationController,
                focusNode: _narrationFocusNode,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: tr.narration,
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  _debounceUpdate(() {
                    _updateExpense(narration: value);
                  });
                },
                onSubmitted: (_) {
                  _amountFocusNode.requestFocus();
                },
              ),
            ),

            const SizedBox(width: 8),

            /// Amount — Enter submits and adds a new row
            Expanded(
              flex: 1,
              child: TextField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: tr.amount,
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  _debounceUpdate(() {
                    final amount =
                        double.tryParse(value.replaceAll(',', '')) ?? 0;
                    _updateExpense(amount: amount);
                  });
                },
                onSubmitted: (_) => _onAmountSubmitted(),
              ),
            ),

            /// Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () {
                context.read<PurchaseInvoiceBloc>().add(
                  RemovePaymentEvent(widget.index, wasExpense: true),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}