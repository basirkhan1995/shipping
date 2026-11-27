import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Date/shamsi_converter.dart';
import 'package:shipping/Features/Widgets/ztextfield.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Widgets/extensions.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../../Stakeholder/model/stk_model.dart';
import 'bloc/shp_by_id_bloc.dart';
import 'model/shp_details_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Account category filter — stakeholders only (matches CashTxnForm)
// ─────────────────────────────────────────────────────────────────────────────
const int _kStakeholderCategory = 8;

// ─────────────────────────────────────────────────────────────────────────────
// Numeric input formatters
// ─────────────────────────────────────────────────────────────────────────────
final List<TextInputFormatter> _intFormatters = [
  FilteringTextInputFormatter.digitsOnly,
];

final List<TextInputFormatter> _decimalFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
];

// ─────────────────────────────────────────────────────────────────────────────
// Result
// ─────────────────────────────────────────────────────────────────────────────
class ShpItemFormResult {
  final String accountNo;
  final String itemDescription;
  final double qty;
  final double cbm;
  final double weight;
  final double ratePerCbm;
  final double ratePerWeight;
  final double extraCharges;

  const ShpItemFormResult({
    required this.accountNo,
    required this.itemDescription,
    required this.qty,
    required this.cbm,
    required this.weight,
    required this.ratePerCbm,
    required this.ratePerWeight,
    required this.extraCharges,
  });
}

Future<ShpItemFormResult?> showShpItemForm(
    BuildContext context, {
      ShipmentItemModel? existing,
      required int shpId,
      required String usrName,
    }) {
  // Capture the bloc from the CALLER's context (which IS under the provider),
  // then re-expose it to the dialog route via BlocProvider.value.
  final bloc = context.read<ShpByIdBloc>();

  return showDialog<ShpItemFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider<ShpByIdBloc>.value(
      value: bloc,
      child: ShpItemForm(
        existing: existing,
        shpId: shpId,
        usrName: usrName,
      ),
    ),
  );
}

class ShpItemForm extends StatefulWidget {
  final ShipmentItemModel? existing;
  final int shpId;
  final String usrName;

  const ShpItemForm({
    super.key,
    this.existing,
    required this.shpId,
    required this.usrName,
  });

  @override
  State<ShpItemForm> createState() => _ShpItemFormState();
}

class _ShpItemFormState extends State<ShpItemForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _accountNo;
  late final TextEditingController _description;
  late final TextEditingController _qty;
  late final TextEditingController _cbm;
  late final TextEditingController _weight;
  late final TextEditingController _ratePerCbm;
  late final TextEditingController _ratePerWeight;
  late final TextEditingController _extraCharges;

  // Focus nodes
  late final FocusNode _accountFocus;
  late final FocusNode _descFocus;
  late final FocusNode _qtyFocus;
  late final FocusNode _cbmFocus;
  late final FocusNode _weightFocus;
  late final FocusNode _rateCbmFocus;
  late final FocusNode _rateWeightFocus;
  late final FocusNode _extraFocus;

  StkAccountModel? _acc;
  String? _error;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    // Controllers — all 8 assigned
    _accountNo    = TextEditingController(text: e?.accountNo ?? '');
    _description  = TextEditingController(text: e?.itemDescription ?? '');
    _qty           = TextEditingController(text: e?.qty.toAmountInt() ?? '');
    _cbm           = TextEditingController(text: e?.cbm.toAmount(decimal: 4) ?? '');
    _weight        = TextEditingController(text: e?.weight.toAmount(decimal: 3) ?? '');
    _ratePerCbm    = TextEditingController(text: e?.ratePerCbm.toAmount(decimal: 4) ?? '');
    _ratePerWeight = TextEditingController(text: e?.ratePerWeight.toAmount(decimal: 4) ?? '');
    _extraCharges  = TextEditingController(text: e?.extraCharges.toAmount(decimal: 2) ?? '');

    // Focus nodes — all 8 assigned
    _accountFocus = FocusNode();
    _descFocus = FocusNode();
    _qtyFocus = FocusNode();
    _cbmFocus = FocusNode();
    _weightFocus = FocusNode();
    _rateCbmFocus = FocusNode();
    _rateWeightFocus = FocusNode();
    _extraFocus = FocusNode();

    // Mutual exclusion on rates
    _ratePerCbm.addListener(_onRateChanged);
    _ratePerWeight.addListener(_onRateChanged);

    // Re-render on any numeric change so the grand total updates live
    _cbm.addListener(_rebuild);
    _weight.addListener(_rebuild);
    _extraCharges.addListener(_rebuild);
    _rateCbmFocus.addListener(_rebuild);
    _rateWeightFocus.addListener(_rebuild);

    // Autofocus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _accountFocus.requestFocus();
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ratePerCbm.removeListener(_onRateChanged);
    _ratePerWeight.removeListener(_onRateChanged);
    _accountNo.dispose();
    _description.dispose();
    _qty.dispose();
    _cbm.dispose();
    _weight.dispose();
    _ratePerCbm.dispose();
    _ratePerWeight.dispose();
    _extraCharges.dispose();
    _accountFocus.dispose();
    _descFocus.dispose();
    _qtyFocus.dispose();
    _cbmFocus.dispose();
    _weightFocus.dispose();
    _rateCbmFocus.dispose();
    _rateWeightFocus.dispose();
    _extraFocus.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────
  // Rate lock: only one may be non-zero.
  // ───────────────────────────────────────────────────────────────────────
  void _onRateChanged() {
    final cbmRate = _d(_ratePerCbm);
    final kgRate = _d(_ratePerWeight);

    if (cbmRate > 0 && kgRate > 0) {
      final clearCbm = !_rateCbmFocus.hasFocus; // the one NOT focused gets cleared
      // Defer so we don't mutate the field mid key-event / caret movement.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ratePerCbm.removeListener(_onRateChanged);
        _ratePerWeight.removeListener(_onRateChanged);
        if (clearCbm) {
          _ratePerCbm.clear();
        } else {
          _ratePerWeight.clear();
        }
        _ratePerCbm.addListener(_onRateChanged);
        _ratePerWeight.addListener(_onRateChanged);
        _rebuild();
      });
    } else {
      _rebuild();
    }
  }

  bool get _lockRateCbm => _d(_ratePerWeight) > 0;
  bool get _lockRateWeight => _d(_ratePerCbm) > 0;

  // ✅ FIX: use the extension so comma-grouped prefills parse correctly.
  double _d(TextEditingController c) => c.text.toDoubleAmount();

  double get _grandTotal {
    final cbm = _d(_cbm);
    final rc = _d(_ratePerCbm);
    final wt = _d(_weight);
    final rw = _d(_ratePerWeight);
    final extra = _d(_extraCharges);
    return (cbm * rc) + (wt * rw) + extra;
  }

// ───────────────────────────────────────────────────────────────────────
// SUBMIT — dispatches to BLoC and awaits success/failure.
// Success → toast + close dialog. Failure → inline error in dialog.
// ───────────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);

    final tr = AppLocalizations.of(context)!;

    if (_effectiveAccountNo == null) {
      setState(() => _error = tr.accountRequired);
      return;
    }
    if (_description.text.trim().isEmpty) {
      setState(() => _error = tr.itemDescriptionRequired);
      return;
    }
    if (_qty.text.trim().isEmpty || _d(_qty) <= 0) {
      setState(() => _error = tr.qtyMustBeGreaterThanZero);
      return;
    }
    if (_d(_ratePerCbm) > 0 && _d(_ratePerWeight) > 0) {
      setState(() => _error = tr.onlyOneRateAllowed);
      return;
    }

    setState(() => _submitting = true);

    final bloc = context.read<ShpByIdBloc>();

    // ✅ Capture the message string directly from the stream event.
    //    null  → success
    //    non-null → error message (e.g. tr.overLimitAdd)
    final completer = Completer<String?>();
    late final StreamSubscription<ShpByIdState> sub;
    sub = bloc.stream.listen((s) {
      if (s is! ShpByIdLoaded) return;
      if (!completer.isCompleted) {
        if (s.actionError != null) {
          completer.complete(s.actionError); // capture exact error
        } else if (s.successMessage != null) {
          completer.complete(null); // success
        }
      }
    });

    try {
      if (_isEdit) {
        bloc.add(ShpByIdUpdateItemRequested(
          shpId: widget.shpId,
          shpItmId: widget.existing!.shpItmId,
          usrName: widget.usrName,
          accountNo: _effectiveAccountNo!,
          itemDescription: _description.text.trim(),
          qty: _d(_qty),
          cbm: _d(_cbm),
          weight: _d(_weight),
          ratePerCbm: _d(_ratePerCbm),
          ratePerWeight: _d(_ratePerWeight),
          extraCharges: _d(_extraCharges),
        ));
      } else {
        bloc.add(ShpByIdAddItemRequested(
          shpId: widget.shpId,
          usrName: widget.usrName,
          accountNo: _effectiveAccountNo!,
          itemDescription: _description.text.trim(),
          qty: _d(_qty),
          cbm: _d(_cbm),
          weight: _d(_weight),
          ratePerCbm: _d(_ratePerCbm),
          ratePerWeight: _d(_ratePerWeight),
          extraCharges: _d(_extraCharges),
        ));
      }

      final errMsg = await completer.future;

      if (!mounted) return;

      if (errMsg == null) {
        // ── SUCCESS ───────────────────────────────────────────────────
        final s = bloc.state;
        final successMsg = (s is ShpByIdLoaded && s.successMessage != null)
            ? s.successMessage!
            : (_isEdit ? tr.itemUpdated : tr.itemAdded);

        // Capture messenger BEFORE pop (context is defunct after pop).
        final messenger = ScaffoldMessenger.of(context);

        final result = ShpItemFormResult(
          accountNo: _effectiveAccountNo!,
          itemDescription: _description.text.trim(),
          qty: _d(_qty),
          cbm: _d(_cbm),
          weight: _d(_weight),
          ratePerCbm: _d(_ratePerCbm),
          ratePerWeight: _d(_ratePerWeight),
          extraCharges: _d(_extraCharges),
        );

        Navigator.of(context).pop(result);

        messenger.showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // ── FAILURE — dialog stays open, shows exact error inline ─────
      setState(() {
        _error = errMsg;
        _submitting = false;
      });
      // Clear so a retry can proceed.
      bloc.add(const ShpByIdActionErrorCleared());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = tr.unexpectedError(e.toString());
        _submitting = false;
      });
    } finally {
      await sub.cancel();
    }
  }

  String? get _effectiveAccountNo {
    final fromPicker = _acc?.accNumber?.toString();
    if (fromPicker != null && fromPicker.isNotEmpty) return fromPicker;
    final typed = _accountNo.text.trim();
    if (typed.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(typed)) return null;
    return typed;
  }

  // ───────────────────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    return ZFormDialog(
      title: _isEdit ? "${tr.editItem} | ${widget.existing?.itemDescription}" : tr.addItem,
      icon: _isEdit ? Icons.edit_outlined : Icons.add_box_outlined,
      padding: EdgeInsets.all(8),
      width: 620,
      errorMessage: _error,
      onAction: _submitting ? null : _submit,
      actionLabel: _submitting
          ? const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : Text(_isEdit ? tr.update : tr.create),
      child: AbsorbPointer(
        absorbing: _submitting,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if(widget.existing !=null)...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 5,
                    children: [
                      Text(tr.entryUpdated,style: TextStyle(color: Theme.of(context).colorScheme.outline),),
                      Text("${widget.existing?.entryDate?.toFormattedDateTime()??"_"} - ${widget.existing?.updatedAt?.toFormattedDateTime()??"_"}"),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                _buildAccountPicker(),
                const SizedBox(height: 10),

                ZTextFieldEntitled(
                  title: tr.itemDescription,
                  keyboardType: TextInputType.multiline,
                  isRequired: true,
                  controller: _description,
                  focusNode: _descFocus,
                  hint: '',
                  showClearButton: true,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _qtyFocus.requestFocus(),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ZTextFieldEntitled(
                        title: tr.qty,
                        isRequired: true,
                        controller: _qty,
                        focusNode: _qtyFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormat: _intFormatters,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _cbmFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ZTextFieldEntitled(
                        title: tr.extraCharges,
                        controller: _extraCharges,
                        focusNode: _extraFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormat: _decimalFormatters,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _focusFirstEnabledRate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ZTextFieldEntitled(
                        title: tr.cbm,
                        controller: _cbm,
                        focusNode: _cbmFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormat: _decimalFormatters,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _weightFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ZTextFieldEntitled(
                        title: '${tr.weight.toUpperCase()} (kg)',
                        controller: _weight,
                        focusNode: _weightFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormat: _decimalFormatters,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _focusFirstEnabledRate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ZTextFieldEntitled(
                        title: tr.cbmRate.toUpperCase(),
                        controller: _ratePerCbm,
                        focusNode: _rateCbmFocus,
                        isEnabled: !_lockRateCbm,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormat: _decimalFormatters,
                        textInputAction: TextInputAction.done,
                        hint: _lockRateCbm
                            ? 'Disabled (Rate/kg is set)'
                            : null,
                        onFieldSubmitted: (_) => _onLastRateFieldSubmitted(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ZTextFieldEntitled(
                        title: tr.weightRate.toUpperCase(),
                        controller: _ratePerWeight,
                        focusNode: _rateWeightFocus,
                        isEnabled: !_lockRateWeight,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormat: _decimalFormatters,
                        textInputAction: TextInputAction.done,
                        hint: _lockRateWeight
                            ? 'Disabled (Rate/CBM is set)'
                            : null,
                        onFieldSubmitted: (_) => _onLastRateFieldSubmitted(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _GrandTotalBar(
                  cbm: _d(_cbm),
                  rateCbm: _d(_ratePerCbm),
                  weight: _d(_weight),
                  rateKg: _d(_ratePerWeight),
                  extra: _d(_extraCharges),
                  total: _grandTotal,
                  color: color,
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onLastRateFieldSubmitted() {
    if (_submitting) return;
    _submit();
  }

  void _focusFirstEnabledRate() {
    if (!_lockRateCbm) {
      _rateCbmFocus.requestFocus();
    } else if (!_lockRateWeight) {
      _rateWeightFocus.requestFocus();
    } else {
      _onLastRateFieldSubmitted();
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // ACCOUNT PICKER — filtered to stakeholders, same pattern as CashTxnForm
  // ───────────────────────────────────────────────────────────────────────
  Widget _buildAccountPicker() {
    return GenericTextField<StkAccountModel, StkAccountsBloc, StkAccountsState>(
      controller: _accountNo,
      title: AppLocalizations.of(context)!.customerAndAccount,
      hintText: AppLocalizations.of(context)!.accNameOrNumber,
      isRequired: true,
      bloc: context.read<StkAccountsBloc>(),
      focusNode: _accountFocus,
      textInputAction: TextInputAction.none,
      showAllOnFocus: false,
      fetchAllFunction: null,
      readOnly: false,
      isEnabled: !_submitting,
      searchFunction: (bloc, q) {
        if (q.trim().isEmpty) return;
        bloc.add(LoadStkAccountsEvent(query: q));
      },
      itemBuilder: (context, account) {
        final c = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${account.accNumber} | ${account.accName}',
                style: TextStyle(color: c.onSurface),
              ),
              Text(
                '${account.accBalance.toAmount()} '
                    '${account.accCurrency ?? ''}',
                style: TextStyle(color: c.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
      itemToString: (a) => '${a.accNumber} | ${a.accName}',
      stateToItems: (s) {
        if (s is! StkAccountsLoadedState) {
          return const <StkAccountModel>[];
        }
        return _filterAccounts(s.accounts);
      },
      stateToLoading: (s) => s is StkAccountsLoadingState,
      onSelected: (a) {
        setState(() {
          _acc = a;
          _accountNo.text = '${a.accNumber} | ${a.accName}';
          _error = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _descFocus.requestFocus();
        });
      },
      validator: (_) => _effectiveAccountNo == null ? 'Required' : null,
    );
  }

  List<StkAccountModel> _filterAccounts(List<StkAccountModel> all) {
    return all
        .where((a) => a.accCategory == _kStakeholderCategory)
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grand-total bar
// ─────────────────────────────────────────────────────────────────────────────
class _GrandTotalBar extends StatelessWidget {
  final double cbm;
  final double rateCbm;
  final double weight;
  final double rateKg;
  final double extra;
  final double total;
  final ColorScheme color;

  const _GrandTotalBar({
    required this.cbm,
    required this.rateCbm,
    required this.weight,
    required this.rateKg,
    required this.extra,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    final cbmTotal = cbm * rateCbm;
    final weightTotal = weight * rateKg;
    final showCbmRow = cbmTotal > 0;
    final showWeightRow = weightTotal > 0;
    final showAvgRow = weight > 0 && cbm > 0;
    final showExtraRow = extra > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCbmRow) ...[
            _row(
              '${tr.cbm} × ${tr.cbmRate}',
              '${cbm.toAmount(decimal: 3)} × ${rateCbm.toAmount(decimal: 4)}',
              cbmTotal.toAmount(),
            ),
            const SizedBox(height: 4),
          ],
          if (showWeightRow) ...[
            _row(
              '${tr.weight} × ${tr.weightRate}',
              '${weight.toAmount(decimal: 2)} × ${rateKg.toAmount(decimal: 4)}',
              weightTotal.toAmount(),
            ),
            const SizedBox(height: 4),
          ],
          if (showAvgRow) ...[
            _row(
              tr.weightAvg,
              '${weight.toAmount(decimal: 2)} / ${cbm.toAmount(decimal: 2)}',
              (weight / cbm).toAmount(),
            ),
            const SizedBox(height: 4),
          ],
          if (showExtraRow) ...[
            _row(tr.extraCharges, '', extra.toAmount()),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 4),
          Divider(height: 1, color: color.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  tr.grandTotal.toUpperCase(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                total.toAmount(),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String detail, String amount) {
    return Row(
      children: [
        // Label — takes the left share
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color.onPrimaryContainer.withValues(alpha: 0.85),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Detail — fixed-ish middle share, right-aligned
        if (detail.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              detail,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                color: color.onPrimaryContainer.withValues(alpha: 0.6),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        // Amount — right share, right-aligned to the very end
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            amount,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.onPrimaryContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}