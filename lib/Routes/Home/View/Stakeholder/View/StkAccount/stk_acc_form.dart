import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/ztextfield.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../Features/Widgets/z_generic_field.dart';
import '../../model/stk_model.dart';
import 'bloc/stk_accounts_bloc.dart';
import 'bloc/stk_accounts_event.dart';

class StkAccountFormDialog extends StatefulWidget {
  /// Required so add can set actSignatory.
  final int perId;

  /// null = add mode, non-null = edit mode.
  final StakeholderAccount? account;

  const StkAccountFormDialog({
    super.key,
    required this.perId,
    this.account,
  });

  @override
  State<StkAccountFormDialog> createState() => _StkAccountFormDialogState();
}

class _StkAccountFormDialogState extends State<StkAccountFormDialog> {
  static const _unlimited = '100000000';
  String defaultCcy = "USD";
  late final TextEditingController _nameCtrl;
  late final TextEditingController _limitCtrl;
  late String _currency;
  late bool _active;

  // ── Focus nodes ────────────────────────────────────────────────
  late final FocusNode _nameFocus;
  late final FocusNode _limitFocus;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameCtrl = TextEditingController(text: a?.accName ?? '');
    _limitCtrl = TextEditingController(
      text: (a == null || a.isUnlimited)
          ? ''
          : (a.limitValue?.toStringAsFixed(2) ?? ''),
    );
    _currency = a?.accCurrency ?? 'USD';
    _active = a?.accStatus == 1;

    _nameFocus = FocusNode(debugLabel: 'stk_acc_name');
    _limitFocus = FocusNode(debugLabel: 'stk_acc_limit');

    _nameCtrl.addListener(_refresh);
    _limitCtrl.addListener(_refresh);

    _active = true;

    // Auto-focus the first field when the dialog opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_refresh);
    _limitCtrl.removeListener(_refresh);
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    _nameFocus.dispose();
    _limitFocus.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _isValid {
    if (_nameCtrl.text.trim().isEmpty) return false;
    final limitText = _limitCtrl.text.trim();
    if (limitText.isNotEmpty) {
      final parsed = double.tryParse(limitText);
      if (parsed == null || parsed < 0) return false;
    }
    return true;
  }

  void _submit() {
    if (!_isValid) return;

    final bloc = context.read<StkAccountsBloc>();
    final limitText = _limitCtrl.text.trim();
    final dynamic limit =
    limitText.isEmpty ? _unlimited : double.parse(limitText);

    if (_isEdit) {
      bloc.add(EditStkAccountEvent(
        perId: widget.perId,
        accNumber: widget.account!.accNumber!,
        accName: _nameCtrl.text.trim(),
        actCurrency: _currency,
        actCreditLimit: limit,
        actStatus: _active ? 1 : 0,
      ));
    } else {
      bloc.add(AddStkAccountEvent(
        perId: widget.perId,
        accName: _nameCtrl.text.trim(),
        actCurrency: _currency,
        actCreditLimit: limit,
      ));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ZFormDialog(
      title: _isEdit ? 'Edit Account' : 'New Account',
      icon: _isEdit ? Icons.edit_outlined : Icons.add_card_outlined,
      width: 480,
      isButtonEnabled: _isValid,
      actionLabel: Text(_isEdit ? 'Save' : 'Add'),
      onAction: _submit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ZGenericTextField(
              controller: _nameCtrl,
              focusNode: _nameFocus,                    // <-- wire focus
              title: AppLocalizations.of(context)!.accountName,
              hint: "e.g Ahmad",
              defaultCurrencyCode: _currency,
              fieldType: ZTextFieldType.currency,
              onCurrencyChanged: (currency) {
                _currency = currency!.ccyCode!;
              },
              showFlag: true,
              showClearButton: true,
              showSymbol: false,
              isRequired: true,
              inputAction: TextInputAction.next,
              onSubmit: (_) => _limitFocus.requestFocus(), // <-- go to limit
            ),

            const SizedBox(height: 12),

            ZTextFieldEntitled(
              controller: _limitCtrl,
              focusNode: _limitFocus,
              title: AppLocalizations.of(context)!.accountLimit,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                // After limit, submit if valid.
                if (_isValid) _submit();
              },
            ),
            const SizedBox(height: 4),

            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: Text(AppLocalizations.of(context)!.accountStatus),
              subtitle: Text(
                _active
                    ? AppLocalizations.of(context)!.accountActiveMsg
                    : AppLocalizations.of(context)!.accountBlockMsg,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),

            if (_isEdit) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.ccyChangeWarnings,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}