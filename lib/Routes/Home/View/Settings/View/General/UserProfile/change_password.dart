import 'package:flutter/material.dart';
import '../../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../../l10n/app_localizations.dart';

class ChangePasswordResult {
  final String oldPassword;
  final String newPassword;
  const ChangePasswordResult({
    required this.oldPassword,
    required this.newPassword,
  });
}

class PasswordChangeDialog extends StatefulWidget {
  final String usrName;
  const PasswordChangeDialog({super.key, required this.usrName});

  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      ChangePasswordResult(
        oldPassword: _old.text,
        newPassword: _new.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return ZFormDialog(
      title: 'Change password',
      icon: Icons.lock_outline_rounded,
      width: 480,
      isButtonEnabled: true,
      actionLabel: Text(tr.save),
      onAction: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ZTextFieldEntitled(
              title: 'Current password',
              isRequired: true,
              controller: _old,
              securePassword: _obscure,
              trailing: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) =>
              (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ZTextFieldEntitled(
              title: 'New password',
              isRequired: true,
              controller: _new,
              securePassword: _obscure,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            ZTextFieldEntitled(
              title: 'Confirm new password',
              isRequired: true,
              controller: _confirm,
              securePassword: _obscure,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v != _new.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}