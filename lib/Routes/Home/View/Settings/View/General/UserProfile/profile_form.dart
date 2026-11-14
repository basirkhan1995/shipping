import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../Features/Date/zdate_picker.dart';
import '../../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../../Features/Other/zdropdown.dart';
import '../../../../../../../l10n/app_localizations.dart';
import 'bloc/user_profile_bloc.dart';
import 'bloc/user_profile_event.dart';
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

  late final FocusNode _nameFocus;
  late final FocusNode _lastNameFocus;
  late final FocusNode _phoneFocus;
  late final FocusNode _emailFocus;
  late final FocusNode _enidFocus;
  late final FocusNode _addNameFocus;
  late final FocusNode _addCityFocus;
  late final FocusNode _addProvinceFocus;
  late final FocusNode _addCountryFocus;
  late final FocusNode _addZipFocus;

  String? _gender;
  String? _dobIso;
  String? _error;

  /// Guards against a double `Navigator.pop` if the bloc emits
  /// `UserProfileSaved` more than once while the pop animation is
  /// still in flight.
  bool _closed = false;

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile.personal;
    _name = TextEditingController(text: p.perName ?? '');
    _lastName = TextEditingController(text: p.perLastName ?? '');
    _phone = TextEditingController(text: p.perPhone ?? '');
    _email = TextEditingController(text: p.perEmail ?? '');
    _enid = TextEditingController(text: p.perENIDNo ?? '');
    _gender = p.perGender;
    _dobIso = p.perDoB == null ? null : _toIso(p.perDoB!);

    final a = widget.profile.address;
    _addName = TextEditingController(text: a?.addName ?? '');
    _addCity = TextEditingController(text: a?.addCity ?? '');
    _addProvince = TextEditingController(text: a?.addProvince ?? '');
    _addCountry = TextEditingController(text: a?.addCountry ?? '');
    _addZip = TextEditingController(text: a?.addZipCode ?? '');

    _nameFocus = FocusNode();
    _lastNameFocus = FocusNode();
    _phoneFocus = FocusNode();
    _emailFocus = FocusNode();
    _enidFocus = FocusNode();
    _addNameFocus = FocusNode();
    _addCityFocus = FocusNode();
    _addProvinceFocus = FocusNode();
    _addCountryFocus = FocusNode();
    _addZipFocus = FocusNode();
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

    _nameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _enidFocus.dispose();
    _addNameFocus.dispose();
    _addCityFocus.dispose();
    _addProvinceFocus.dispose();
    _addCountryFocus.dispose();
    _addZipFocus.dispose();

    super.dispose();
  }

  String _toIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  DateTime? _parseIso(String? s) =>
      (s == null || s.isEmpty) ? null : DateTime.tryParse(s);

  void _submit() {
    if (_error != null) setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final profile = widget.profile;
    final address = UserAddress(
      addID: profile.address?.addID ?? 0,
      addName: _addName.text.trim().isEmpty ? null : _addName.text.trim(),
      addCity: _addCity.text.trim().isEmpty ? null : _addCity.text.trim(),
      addProvince: _addProvince.text.trim().isEmpty
          ? null
          : _addProvince.text.trim(),
      addCountry: _addCountry.text.trim().isEmpty
          ? null
          : _addCountry.text.trim(),
      addZipCode: _addZip.text.trim().isEmpty ? null : _addZip.text.trim(),
      addMailing: profile.address?.addMailing ?? 0,
    );

    context.read<UserProfileBloc>().add(
      UpdateUserProfile(
        UpdateUserProfileRequest(
          usrName: profile.user.usrName,
          perName: _name.text.trim(),
          perLastName: _lastName.text.trim(),
          perGender: _gender,
          perDoB: _parseIso(_dobIso),
          perENIDNo:
          _enid.text.trim().isEmpty ? null : _enid.text.trim(),
          perPhone:
          _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          perEmail:
          _email.text.trim().isEmpty ? null : _email.text.trim(),
          address: profile.address != null ? address : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return BlocConsumer<UserProfileBloc, UserProfileState>(
      listenWhen: (p, c) =>
      c is UserProfileSaved || c is UserProfileFailure,
      listener: (context, state) {
        if (state is UserProfileSaved) {
          // Pop with NO value — the parent opens this dialog with
          // `showDialog<void>`. Popping `true` triggers:
          //   "A request was made to pop a route with a result of
          //    type bool, but the route expected a value of type
          //    UpdateUserProfileRequest."
          if (mounted && !_closed) {
            _closed = true;
            Navigator.of(context).pop();
          }
        } else if (state is UserProfileFailure) {
          if (mounted) setState(() => _error = state.message);
        }
      },
      builder: (context, state) {
        final busy = state is UserProfileSaving;

        return ZFormDialog(
          title: tr.editProfile.toUpperCase(),
          icon: Icons.edit_outlined,
          width: 750,
          isButtonEnabled: true,
          isLoading: busy,
          errorMessage: _error,
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
                  Row(
                    children: [
                      Expanded(
                        child: ZTextFieldEntitled(
                          title: tr.firstName,
                          isRequired: true,
                          controller: _name,
                          focusNode: _nameFocus,
                          autoFocus: true,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _lastNameFocus.requestFocus(),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ZTextFieldEntitled(
                          title: tr.lastName,
                          controller: _lastName,
                          focusNode: _lastNameFocus,
                          autoFocus: false,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _phoneFocus.requestFocus(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ZTextFieldEntitled(
                          title: tr.phone,
                          controller: _phone,
                          focusNode: _phoneFocus,
                          autoFocus: false,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.phone,
                          onFieldSubmitted: (_) =>
                              _emailFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ZTextFieldEntitled(
                          title: tr.email,
                          controller: _email,
                          focusNode: _emailFocus,
                          autoFocus: false,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          onFieldSubmitted: (_) =>
                              _enidFocus.requestFocus(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ZTextFieldEntitled(
                          title: tr.nationalId,
                          controller: _enid,
                          focusNode: _enidFocus,
                          autoFocus: false,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _addNameFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ZDropdown<String>(
                          title: tr.gender,
                          items: _genders,
                          itemLabel: (g) => g,
                          initialValue: tr.gender,
                          selectedItem: _gender,
                          onItemSelected: (v) =>
                              setState(() => _gender = v),
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GenericDatePicker(
                          label: tr.dob,
                          initialGregorianDate: _dobIso,
                          onDateChanged: (iso) =>
                              setState(() => _dobIso = iso),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ZTextFieldEntitled(
                    title: tr.address,
                    controller: _addName,
                    focusNode: _addNameFocus,
                    autoFocus: false,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        _addCityFocus.requestFocus(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ZTextFieldEntitled(
                          title: tr.city,
                          controller: _addCity,
                          focusNode: _addCityFocus,
                          autoFocus: false,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _addProvinceFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ZTextFieldEntitled(
                          title: tr.province,
                          controller: _addProvince,
                          focusNode: _addProvinceFocus,
                          autoFocus: false,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _addCountryFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ZTextFieldEntitled(
                          title: tr.country,
                          controller: _addCountry,
                          focusNode: _addCountryFocus,
                          autoFocus: false,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _addZipFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ZTextFieldEntitled(
                          title: tr.zipCode,
                          controller: _addZip,
                          focusNode: _addZipFocus,
                          autoFocus: false,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}