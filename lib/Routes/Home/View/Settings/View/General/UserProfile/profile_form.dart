import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../../l10n/app_localizations.dart';
import 'model/user_profile_model.dart';

class UserProfileFormDialog extends StatefulWidget {
  final UserProfile profile;
  const UserProfileFormDialog({super.key, required this.profile});

  @override
  State<UserProfileFormDialog> createState() => _UserProfileFormDialogState();
}

class _UserProfileFormDialogState extends State<UserProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _enid;
  late final TextEditingController _addName;
  late final TextEditingController _addCity;
  late final TextEditingController _addProvince;
  late final TextEditingController _addCountry;
  late final TextEditingController _addZip;

  String? _gender;
  String? _dobIso;

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile.personal;
    _name       = TextEditingController(text: p.perName ?? '');
    _lastName   = TextEditingController(text: p.perLastName ?? '');
    _phone      = TextEditingController(text: p.perPhone ?? '');
    _email      = TextEditingController(text: p.perEmail ?? '');
    _enid       = TextEditingController(text: p.perENIDNo ?? '');
    _gender     = p.perGender;
    _dobIso     = p.perDoB == null ? null : _toIso(p.perDoB!);

    final a = widget.profile.address;
    _addName     = TextEditingController(text: a?.addName ?? '');
    _addCity     = TextEditingController(text: a?.addCity ?? '');
    _addProvince = TextEditingController(text: a?.addProvince ?? '');
    _addCountry  = TextEditingController(text: a?.addCountry ?? '');
    _addZip      = TextEditingController(text: a?.addZipCode ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _enid.dispose();
    _addName.dispose();
    _addCity.dispose();
    _addProvince.dispose();
    _addCountry.dispose();
    _addZip.dispose();
    super.dispose();
  }

  String _toIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  DateTime? _parseIso(String? s) =>
      (s == null || s.isEmpty) ? null : DateTime.tryParse(s);

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final profile = widget.profile;
    final address = UserAddress(
      addID: profile.address?.addID ?? 0,
      addName:     _addName.text.trim().isEmpty     ? null : _addName.text.trim(),
      addCity:     _addCity.text.trim().isEmpty     ? null : _addCity.text.trim(),
      addProvince: _addProvince.text.trim().isEmpty ? null : _addProvince.text.trim(),
      addCountry:  _addCountry.text.trim().isEmpty  ? null : _addCountry.text.trim(),
      addZipCode:  _addZip.text.trim().isEmpty      ? null : _addZip.text.trim(),
      addMailing:  profile.address?.addMailing ?? 0,
    );

    Navigator.pop(
      context,
      UpdateUserProfileRequest(
        usrName:     profile.user.usrName,
        perName:     _name.text.trim(),
        perLastName: _lastName.text.trim(),
        perGender:   _gender,
        perDoB:      _parseIso(_dobIso),
        perENIDNo:   _enid.text.trim().isEmpty ? null : _enid.text.trim(),
        perPhone:    _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        perEmail:    _email.text.trim().isEmpty ? null : _email.text.trim(),
        address:     profile.address != null ? address : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return ZFormDialog(
      title: 'Edit profile',
      icon: Icons.edit_outlined,
      width: 750,
      isButtonEnabled: true,
      actionLabel: Text(tr.save),
      onAction: _submit,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section('Personal'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'First name',
                      isRequired: true,
                      controller: _name,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Last name',
                      controller: _lastName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Phone',
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Email',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'National ID',
                      controller: _enid,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _genderDropdown(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Date of birth',
                      controller: TextEditingController(text: _dobIso ?? ''),
                      hint: 'YYYY-MM-DD',
                      onChanged: (v) => _dobIso = v.trim(),
                      inputFormat: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _section('Address'),
              const SizedBox(height: 8),
              ZTextFieldEntitled(
                title: 'Address label',
                controller: _addName,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ZTextFieldEntitled(
                      title: 'City',
                      controller: _addCity,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ZTextFieldEntitled(
                      title: 'Province',
                      controller: _addProvince,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ZTextFieldEntitled(
                      title: 'Country',
                      controller: _addCountry,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Zip',
                      controller: _addZip,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      decoration: const InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(),
      ),
      items: _genders
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (v) => setState(() => _gender = v),
    );
  }

  Widget _section(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );
}