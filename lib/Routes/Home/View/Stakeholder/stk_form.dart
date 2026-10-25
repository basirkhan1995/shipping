import 'package:flutter/material.dart';
import '../../../../Features/Date/zdate_picker.dart';
import '../../../../Features/Other/form_dialog.dart';
import '../../../../Features/Other/image_crop.dart';
import '../../../../Features/Other/image_helper.dart';
import '../../../../Features/Widgets/utils.dart';
import '../../../../Features/Widgets/ztextfield.dart';
import '../../../../Features/zdropdown.dart';
import 'bloc/stakeholder_bloc.dart';
import 'model/stk_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StakeholderFormDialog extends StatefulWidget {
  final IndividualsModel? existing;
  const StakeholderFormDialog({super.key, this.existing});

  @override
  State<StakeholderFormDialog> createState() =>
      _StakeholderFormDialogState();
}

class _StakeholderFormDialogState extends State<StakeholderFormDialog> {
  final _formKey = GlobalKey<FormState>();

  static const _genders = ['Male', 'Female', 'Other'];

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _enidNo;
  late final TextEditingController _addName;
  late final TextEditingController _addCity;
  late final TextEditingController _addProvince;
  late final TextEditingController _addCountry;
  late final TextEditingController _addZip;

  late final FocusNode _firstNameFocus;
  late final FocusNode _lastNameFocus;
  late final FocusNode _phoneFocus;
  late final FocusNode _emailFocus;
  late final FocusNode _enidNoFocus;
  late final FocusNode _addNameFocus;
  late final FocusNode _addCityFocus;
  late final FocusNode _addProvinceFocus;
  late final FocusNode _addCountryFocus;
  late final FocusNode _addZipFocus;

  Uint8List? _selectedImageBytes;

  Future<void> _pickAndCropImage() async {
    // Capture context-dependent things BEFORE any await.
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<StakeholderBloc>();
    final perId = widget.existing?.perId;

    final imageBytes = await Utils.pickImage();
    if (!mounted || imageBytes == null || imageBytes.isEmpty) return;

    try {
      final cropped = await showImageCropper(
        context: context,
        imageBytes: imageBytes,
      );
      if (!mounted || cropped == null || cropped.isEmpty) return;

      setState(() => _selectedImageBytes = cropped);

      if (perId != null) {
        bloc.add(
          UploadStkProfileImageEvent(
            perId: perId,
            image: cropped,
          ),
        );
      }
    } catch (e) {
      debugPrint('Image crop failed: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Image crop failed: $e')),
        );
      }
    }
  }
  static Widget _buildHeroShuttle(
      BuildContext flightContext,
      Animation<double> animation,
      HeroFlightDirection direction,
      BuildContext fromHeroContext,
      BuildContext toHeroContext,
      ) {
    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: (toHeroContext.widget as Hero).child,
      ),
    );
  }
  String? _dobIso;
  String? _gender;
  bool _isMailing = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _firstName = TextEditingController(text: e?.perName ?? '');
    _lastName = TextEditingController(text: e?.perLastName ?? '');
    _phone = TextEditingController(text: e?.perPhone ?? '');
    _email = TextEditingController(text: e?.perEmail ?? '');
    _enidNo = TextEditingController(text: e?.perEnidNo ?? '');
    _addName = TextEditingController(text: e?.addName ?? '');
    _addCity = TextEditingController(text: e?.addCity ?? '');
    _addProvince = TextEditingController(text: e?.addProvince ?? '');
    _addCountry = TextEditingController(text: e?.addCountry ?? '');
    _addZip = TextEditingController(text: e?.addZipCode ?? '');
    _gender = e?.perGender;
    _isMailing = (e?.addMailing ?? 0) == 1;

    _firstNameFocus = FocusNode();
    _lastNameFocus = FocusNode();
    _phoneFocus = FocusNode();
    _emailFocus = FocusNode();
    _enidNoFocus = FocusNode();
    _addNameFocus = FocusNode();
    _addCityFocus = FocusNode();
    _addProvinceFocus = FocusNode();
    _addCountryFocus = FocusNode();
    _addZipFocus = FocusNode();

    final dob = e?.perDoB;
    if (dob != null) {
      _dobIso = '${dob.year.toString().padLeft(4, '0')}-'
          '${dob.month.toString().padLeft(2, '0')}-'
          '${dob.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _enidNo.dispose();
    _addName.dispose();
    _addCity.dispose();
    _addProvince.dispose();
    _addCountry.dispose();
    _addZip.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _enidNoFocus.dispose();
    _addNameFocus.dispose();
    _addCityFocus.dispose();
    _addProvinceFocus.dispose();
    _addCountryFocus.dispose();
    _addZipFocus.dispose();

    super.dispose();
  }

  DateTime? _parseIso(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final model = IndividualsModel(
      perId: widget.existing?.perId,
      perName: _firstName.text.trim(),
      perLastName: _lastName.text.trim(),
      perGender: _gender,
      perDoB: _parseIso(_dobIso),
      perEnidNo: _enidNo.text.trim().isEmpty ? null : _enidNo.text.trim(),
      perPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      perEmail: _email.text.trim().isEmpty ? null : _email.text.trim(),
      addId: widget.existing?.addId,
      addName: _addName.text.trim().isEmpty ? null : _addName.text.trim(),
      addCity: _addCity.text.trim().isEmpty ? null : _addCity.text.trim(),
      addProvince:
      _addProvince.text.trim().isEmpty ? null : _addProvince.text.trim(),
      addCountry:
      _addCountry.text.trim().isEmpty ? null : _addCountry.text.trim(),
      addZipCode: _addZip.text.trim().isEmpty ? null : _addZip.text.trim(),
      addMailing: _isMailing ? 1 : 0,
    );

    Navigator.pop(context, model);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return ZFormDialog(
      title: _isEdit ? 'Edit stakeholder' : 'New stakeholder',
      icon: _isEdit ? Icons.edit_outlined : Icons.person_add_alt_1_outlined,
      width: 750,
      isButtonEnabled: true,
      actionLabel: Text(_isEdit ? 'Save' : 'Create'),
      onAction: _submit,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isEdit) ...[
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Hero(
                          tag: 'stakeholder_viewer_${widget.existing?.perId}',
                          flightShuttleBuilder: _buildHeroShuttle,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  color: color.primary.withValues(alpha: .15),
                                ),
                              ],
                            ),
                            child: ImageHelper.stakeholderProfile(
                              imageName: widget.existing?.imageProfile,
                              localImageBytes: _selectedImageBytes,
                              size: 120,
                              border: Border.all(
                                color: color.outline.withValues(alpha: .3),
                                width: 2,
                              ),
                              shapeStyle: ShapeStyle.circle,
                              onImageTap: () => ImageHelper.showImageViewer(
                                context: context,
                                imageName: widget.existing?.imageProfile,
                                localImageBytes: _selectedImageBytes,
                                heroTag: 'stakeholder_viewer_${widget.existing?.perId}',
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _pickAndCropImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: color.surface, width: 2),
                            ),
                            child: const Icon(Icons.edit, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              _section('Personal'),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'First name',
                      hint: 'John',
                      isRequired: true,
                      controller: _firstName,
                      focusNode: _firstNameFocus,
                      autoFocus: true,                  // ← only this one
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          _lastNameFocus.requestFocus(),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Last name',
                      hint: 'Doe',
                      controller: _lastName,
                      focusNode: _lastNameFocus,
                      autoFocus: false,                 // ← all others
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
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
                      hint: '+93…',
                      controller: _phone,
                      focusNode: _phoneFocus,
                      autoFocus: false,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Email',
                      hint: 'you@example.com',
                      controller: _email,
                      focusNode: _emailFocus,
                      autoFocus: false,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      onFieldSubmitted: (_) => _enidNoFocus.requestFocus(),
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
                      hint: 'Tazkira',
                      controller: _enidNo,
                      focusNode: _enidNoFocus,
                      autoFocus: false,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          _addNameFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZDropdown<String>(
                      title: 'Gender',
                      items: _genders,
                      itemLabel: (g) => g,
                      initialValue: 'Select gender',
                      selectedItem: _gender,
                      onItemSelected: (v) => setState(() => _gender = v),
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GenericDatePicker(
                      label: 'Date of birth',
                      initialGregorianDate: _dobIso,
                      onDateChanged: (iso) =>
                          setState(() => _dobIso = iso),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _section('Address'),
              const SizedBox(height: 8),

              ZTextFieldEntitled(
                title: 'Address label',
                hint: 'Home / Office',
                controller: _addName,
                focusNode: _addNameFocus,
                autoFocus: false,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _addCityFocus.requestFocus(),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ZTextFieldEntitled(
                      title: 'City',
                      hint: 'Mazar-e Sharif',
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
                      title: 'Province',
                      hint: 'Balkh',
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
                      title: 'Country',
                      hint: 'Afghanistan',
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
                      title: 'Zip code',
                      hint: '1701',
                      controller: _addZip,
                      focusNode: _addZipFocus,
                      autoFocus: false,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // CheckboxListTile(
              //   dense: true,
              //   shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(3)),
              //   value: _isMailing,
              //   onChanged: (v) => setState(() => _isMailing = v ?? false),
              //   title: const Text('Use as mailing address'),
              //   contentPadding: EdgeInsets.zero,
              //   controlAffinity: ListTileControlAffinity.leading,
              // ),

            ],
          ),
        ),
      ),
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