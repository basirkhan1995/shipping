import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/l10n/app_localizations.dart';

import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Widgets/extensions.dart';
import '../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../../Stakeholder/model/stk_model.dart';

/// Opens the expense dialog. Returns true if the user clicked Done.
Future<bool?> showShpExpenseDialog(
    BuildContext context, {
      required int shpId,
      required String usrName,
    }) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ShpExpenseForm(
      shpId: shpId,
      usrName: usrName,
    ),
  );
}

class ShpExpenseForm extends StatefulWidget {
  final int shpId;
  final String usrName;

  const ShpExpenseForm({
    super.key,
    required this.shpId,
    required this.usrName,
  });

  @override
  State<ShpExpenseForm> createState() => _ShpExpenseFormState();
}

class _ShpExpenseFormState extends State<ShpExpenseForm> {
  final _accountNo = TextEditingController();
  final _amount = TextEditingController();
  final _narration = TextEditingController();

  final _accountFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _narrationFocus = FocusNode();

  StkAccountModel? _acc;
  int? _editingIndex;      // null = Add mode
  String? _error;
  bool _submitting = false;

  static const int _kCashCategory    = 1;
  static const int _kExpenseCategory = 8;

  bool get _isEditing => _editingIndex != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _accountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _accountNo.dispose();
    _amount.dispose();
    _narration.dispose();
    _accountFocus.dispose();
    _amountFocus.dispose();
    _narrationFocus.dispose();
    super.dispose();
  }

  double _d(TextEditingController c) => c.text.toDoubleAmount();

  String? get _effectiveAccountNo {
    final fromPicker = _acc?.accNumber?.toString();
    if (fromPicker != null && fromPicker.isNotEmpty) return fromPicker;
    final typed = _accountNo.text.trim();
    if (typed.isEmpty) return null;
    final m = RegExp(r'^\d+').firstMatch(typed);
    return m?.group(0);
  }

  void _clearForm() {
    setState(() {
      _acc = null;
      _accountNo.clear();
      _amount.clear();
      _narration.clear();
      _editingIndex = null;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _accountFocus.requestFocus();
    });
  }

  // ─────────────────────────────────────────────────────────
  // ADD / UPDATE — for now only validates; the list is empty.
  // When you plug the model in, store the created object here
  // and rebuild the list below.
  // ─────────────────────────────────────────────────────────
  void _onAddPressed() {
    final tr = AppLocalizations.of(context)!;

    if (_effectiveAccountNo == null) {
      setState(() => _error = tr.accountRequired);
      return;
    }
    if (_d(_amount) <= 0) {
      setState(() => _error = tr.amountGreaterZero);
      return;
    }
    if (_narration.text.trim().isEmpty) {
      setState(() => _error = tr.required(tr.narration));
      return;
    }

    // TODO: build ShipmentExpenseModel here and add to the list.
    // For now just clear the form so the flow is visible.
    _clearForm();
  }

  Future<void> _onDone() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    // TODO: persist via bloc/repo. For now just close.
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return ZFormDialog(
      title: _isEditing ? tr.edit : tr.addExpense,
      icon: _isEditing ? Icons.edit_outlined : Icons.trending_down_rounded,
      width: MediaQuery.of(context).size.width *.7,
      padding: const EdgeInsets.all(8),
      isLoading: _submitting,
      errorMessage: _error,
      isActionTrue: false,
      onAction: null,
      child: SizedBox(
        height: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Form row ───────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 4, child: _buildAccountPicker()),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ZTextFieldEntitled(
                    title: tr.amount,
                    isRequired: true,
                    controller: _amount,
                    focusNode: _amountFocus,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormat: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _narrationFocus.requestFocus(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: ZTextFieldEntitled(
                    title: tr.narration,
                    isRequired: true,
                    controller: _narration,
                    focusNode: _narrationFocus,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _onAddPressed(),
                  ),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  height: 47,
                  isActive: true,
                  icon: _isEditing ? Icons.check : Icons.add,
                  label: Text(_isEditing ? tr.update : tr.addExpense),
                  onPressed: _onAddPressed,
                ),
                if (_isEditing) ...[
                  const SizedBox(width: 6),
                  ZOutlineButton(
                    height: 47,
                    icon: Icons.close,
                    label: Text(tr.cancel),
                    backgroundHover: color.error,
                    onPressed: _clearForm,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // ── List area ────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: color.outlineVariant.withValues(alpha: .4),
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 44, color: color.outline),
                        const SizedBox(height: 10),
                        Text(
                          tr.noData,
                          style: TextStyle(
                            fontSize: 13,
                            color: color.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr.addExpense,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: color.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Footer ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(),
                Row(
                  spacing: 8,
                  children: [
                    ZOutlineButton(
                      height: 38,
                      width: 120,
                      label: Text(tr.cancel),
                      backgroundHover: color.error,
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                    ZOutlineButton(
                      height: 38,
                      width: 120,
                      isActive: true,
                      label: _submitting
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(tr.done),
                      onPressed: _submitting ? null : _onDone,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountPicker() {
    final tr = AppLocalizations.of(context)!;
    return GenericTextField<StkAccountModel, StkAccountsBloc, StkAccountsState>(
      controller: _accountNo,
      title: tr.account,
      hintText: tr.accNameOrNumber,
      isRequired: true,
      bloc: context.read<StkAccountsBloc>(),
      focusNode: _accountFocus,
      textInputAction: TextInputAction.next,
      showAllOnFocus: false,
      fetchAllFunction: null,
      isEnabled: !_submitting,
      searchFunction: (bloc, q) {
        if (q.trim().isEmpty) return;
        bloc.add(LoadStkAccountsEvent(query: q));
      },
      itemBuilder: (context, a) {
        final c = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${a.accNumber} | ${a.accName}',
                style: TextStyle(color: c.onSurface),
              ),
              Text(
                '${a.accBalance.toAmount()} ${a.accCurrency ?? ''}',
                style: TextStyle(color: c.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
      itemToString: (a) => '${a.accNumber} | ${a.accName}',

      stateToItems: (s) {
        if (s is! StkAccountsLoadedState) return const <StkAccountModel>[];

        final filtered = s.accounts.where((a) {
          // Cash: only the exact account 10101010
          if (a.accCategory == _kCashCategory) {
            return a.accNumber?.toString() == '10101010';
          }
          // Expense: all of them
          if (a.accCategory == _kExpenseCategory) return true;
          return false;
        }).toList();

        return filtered;
      },

      stateToLoading: (s) => s is StkAccountsLoadingState,
      onSelected: (a) {
        setState(() {
          _acc = a;
          _accountNo.text = '${a.accNumber} | ${a.accName}';
          _error = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _amountFocus.requestFocus();
        });
      },
      validator: (_) => _effectiveAccountNo == null ? 'Required' : null,
    );
  }
}