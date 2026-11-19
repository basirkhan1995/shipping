import 'package:flutter/material.dart';
import 'package:shipping/Features/Widgets/ztextfield.dart';
import '../../../../../../Features/Other/form_dialog.dart';
import 'model/shp_details_model.dart';

/// Result of the add/edit dialog.
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

/// Shows the add/edit item dialog and returns the result (null if cancelled).
Future<ShpItemFormResult?> showShpItemForm(
    BuildContext context, {
      ShipmentItemModel? existing,
    }) {
  return showDialog<ShpItemFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ShpItemForm(existing: existing),
  );
}

class ShpItemForm extends StatefulWidget {
  final ShipmentItemModel? existing;
  const ShpItemForm({super.key, this.existing});

  @override
  State<ShpItemForm> createState() => _ShpItemFormState();
}

class _ShpItemFormState extends State<ShpItemForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _accountNo;
  late final TextEditingController _description;
  late final TextEditingController _qty;
  late final TextEditingController _cbm;
  late final TextEditingController _weight;
  late final TextEditingController _ratePerCbm;
  late final TextEditingController _ratePerWeight;
  late final TextEditingController _extraCharges;

  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _accountNo = TextEditingController(text: e?.accountNo ?? '');
    _description = TextEditingController(text: e?.itemDescription ?? '');
    _qty = TextEditingController(text: e == null ? '' : _fmt(e.qty));
    _cbm =
        TextEditingController(text: e == null ? '' : _fmt(e.cbm, decimals: 4));
    _weight = TextEditingController(
        text: e == null ? '' : _fmt(e.weight, decimals: 3));
    _ratePerCbm = TextEditingController(
        text: e == null ? '' : _fmt(e.ratePerCbm, decimals: 4));
    _ratePerWeight = TextEditingController(
        text: e == null ? '' : _fmt(e.ratePerWeight, decimals: 4));
    _extraCharges = TextEditingController(
        text: e == null ? '' : _fmt(e.extraCharges, decimals: 2));
  }

  @override
  void dispose() {
    _accountNo.dispose();
    _description.dispose();
    _qty.dispose();
    _cbm.dispose();
    _weight.dispose();
    _ratePerCbm.dispose();
    _ratePerWeight.dispose();
    _extraCharges.dispose();
    super.dispose();
  }

  double _d(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0.0;

  void _submit() {
    setState(() => _error = null);

    if (_accountNo.text.trim().isEmpty) {
      setState(() => _error = 'Account No is required');
      return;
    }
    if (_description.text.trim().isEmpty) {
      setState(() => _error = 'Item description is required');
      return;
    }
    if (_qty.text.trim().isEmpty || _d(_qty) <= 0) {
      setState(() => _error = 'Qty must be greater than 0');
      return;
    }

    Navigator.of(context).pop(ShpItemFormResult(
      accountNo: _accountNo.text.trim(),
      itemDescription: _description.text.trim(),
      qty: _d(_qty),
      cbm: _d(_cbm),
      weight: _d(_weight),
      ratePerCbm: _d(_ratePerCbm),
      ratePerWeight: _d(_ratePerWeight),
      extraCharges: _d(_extraCharges),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ZFormDialog(
      title: _isEdit ? 'Edit item' : 'Add item',
      icon: _isEdit ? Icons.edit_outlined : Icons.add_box_outlined,
      width: 560,
      errorMessage: _error,
      onAction: _submit,
      actionLabel: Text(_isEdit ? 'Save changes' : 'Add item'),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Account No',
                      isRequired: true,
                      controller: _accountNo,
                      hint: 'e.g. 500005',
                      showClearButton: true,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ZTextFieldEntitled(
                      title: 'Item description',
                      isRequired: true,
                      controller: _description,
                      hint: 'e.g. Car spare parts',
                      showClearButton: true,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Qty',
                      isRequired: true,
                      controller: _qty,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Extra charges',
                      controller: _extraCharges,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'CBM',
                      controller: _cbm,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Weight (kg)',
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Rate / CBM',
                      controller: _ratePerCbm,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Rate / kg',
                      controller: _ratePerWeight,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmt(double v, {int decimals = 0}) {
  final s = v.toStringAsFixed(decimals);
  final parts = s.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return parts.length > 1 ? '${buf.toString()}.${parts[1]}' : buf.toString();
}