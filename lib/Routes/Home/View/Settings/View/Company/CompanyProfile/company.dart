import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import '../../../../../../../Features/Other/image_crop.dart';
import '../../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../../Features/Widgets/noData_widget.dart';
import '../../../../../../../Features/Widgets/shimmer.dart';
import '../../../../../../../Features/Widgets/toast.dart';
import '../../../../../../../Features/Widgets/utils.dart';
import '../../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../../Auth/model/user_model.dart';
import 'bloc/company_profile_bloc.dart';
import 'features/section.dart';
import 'model/com_model.dart';

class CompanySettingsView extends StatelessWidget {
  const CompanySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileCompanyForm(),
      tablet: _TabletCompanyForm(),
      desktop: _DesktopCompanyForm(),
    );
  }
}

// Base form widget that contains all the logic
class _BaseCompanyForm extends StatefulWidget {
  final bool isMobile;
  final bool isTablet;

  const _BaseCompanyForm({
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseCompanyForm> createState() => _BaseCompanyFormState();
}

class _BaseCompanyFormState extends State<_BaseCompanyForm>
    with SingleTickerProviderStateMixin {
  final TextEditingController businessName = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController comDetails = TextEditingController();
  final TextEditingController website = TextEditingController();
  final TextEditingController phone2 = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController province = TextEditingController();
  final TextEditingController baseCurrency = TextEditingController();
  final TextEditingController comFb = TextEditingController();
  final TextEditingController comInsta = TextEditingController();
  final TextEditingController comWhatsApp = TextEditingController();
  final TextEditingController comZipCode = TextEditingController();
  final TextEditingController comLocalCcy = TextEditingController();
  final TextEditingController country = TextEditingController();
  final TextEditingController comLicense = TextEditingController();

  CompanySettingsModel? loadedCompany;
  bool isUpdateMode = false;
  Uint8List _companyLogo = Uint8List(0);
  int? comId;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  // ── LIFECYCLE ─────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadCachedLogo();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    businessName.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    comDetails.dispose();
    website.dispose();
    phone2.dispose();
    city.dispose();
    province.dispose();
    baseCurrency.dispose();
    comFb.dispose();
    comInsta.dispose();
    comWhatsApp.dispose();
    comZipCode.dispose();
    comLocalCcy.dispose();
    country.dispose();
    comLicense.dispose();
    super.dispose();
  }

  // ── DATA INIT ─────────────────────────────────────────────────────

  void _initializeData() {
    final state = context.read<CompanyProfileBloc>().state;
    if (state is CompanyProfileLoadedState) {
      _updateControllers(state);
    }
  }

  void _loadCachedLogo() {
    final state = context.read<CompanyProfileBloc>().state;
    if (state is CompanyProfileLoadedState) {
      final base64Logo = state.company.comLogo;
      if (base64Logo != null && base64Logo.isNotEmpty) {
        try {
          _companyLogo = base64Decode(base64Logo);
        } catch (_) {
          _companyLogo = Uint8List(0);
        }
      }
    }
  }

  // ── LOGO PICK / UPLOAD ────────────────────────────────────────────

  Future<void> _pickLogoImage() async {
    final bloc = context.read<CompanyProfileBloc>();

    final imageBytes = await Utils.pickImage();
    if (imageBytes == null || imageBytes.isEmpty) return;

    try {
      if (!mounted) return;
      final croppedBytes = await showImageCropper(
        context: context,
        imageBytes: imageBytes,
      );

      if (!mounted || croppedBytes == null || croppedBytes.isEmpty) return;

      // Log magic bytes so we can tell if the cropper returned a real image
      debugPrint(
        'CROP bytes=${croppedBytes.length}, '
            'first8=${croppedBytes.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
      );

      setState(() => _companyLogo = croppedBytes);
      bloc.add(UploadCompanyLogoEvent(croppedBytes));
    } catch (e) {
      debugPrint('Image crop failed: $e');
    }
  }

  // ── IMAGE HELPERS ─────────────────────────────────────────────────

  /// Sniff common image magic numbers (JPEG / PNG / GIF / WebP / BMP).
  bool _isValidImageBytes(Uint8List bytes) {
    if (bytes.length < 12) return false;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // GIF: 'GIF8'
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }
    // WebP: 'RIFF' ....'WEBP'
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return true;
    return false;
  }

  /// Single guarded image widget used by BOTH mobile and desktop/tablet.
  Widget _buildLogoImage({double? width, double? height}) {
    // 1) No bytes → asset fallback
    if (_companyLogo.isEmpty) {
      return Image.asset(
        "assets/images/zaitoonLogo.png",
        fit: BoxFit.cover,
        width: width,
        height: height,
      );
    }

    // 2) Bytes present but not a real image → asset fallback, no decode
    if (!_isValidImageBytes(_companyLogo)) {
      debugPrint(
        '_buildLogoImage: rejected ${_companyLogo.length} non-image bytes '
            '(first8=${_companyLogo.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join()})',
      );
      return Image.asset(
        "assets/images/zaitoonLogo.png",
        fit: BoxFit.cover,
        width: width,
        height: height,
      );
    }

    // 3) Valid image → render with errorBuilder as last line of defense
    return Image.memory(
      _companyLogo,
      fit: BoxFit.cover,
      width: width,
      height: height,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
          '_buildLogoImage: decode failed (${_companyLogo.length} bytes): $error',
        );
        return Image.asset(
          "assets/images/zaitoonLogo.png",
          fit: BoxFit.cover,
          width: width,
          height: height,
        );
      },
    );
  }

  // ── CONTROLLER SYNC ───────────────────────────────────────────────

  void _updateControllers(CompanyProfileLoadedState state) {
    setState(() {
      businessName.text = state.company.comName ?? "";
      address.text = state.company.addName ?? "";
      email.text = state.company.comEmail ?? "";
      phone.text = state.company.comPhone ?? "";
      website.text = state.company.comWebsite ?? "";
      comDetails.text = state.company.comDetails ?? "";
      comWhatsApp.text = state.company.comWhatsapp ?? "";
      comInsta.text = state.company.comInsta ?? "";
      comFb.text = state.company.comFb ?? "";
      comLicense.text = state.company.comLicenseNo ?? "";
      comZipCode.text = state.company.addZipCode ?? "";
      city.text = state.company.addCity ?? "";
      province.text = state.company.addProvince ?? "";
      country.text = state.company.addCountry ?? "";
      loadedCompany = state.company;
      comLocalCcy.text = state.company.comLocalCcy ?? "";

      // Reset or refresh the logo bytes based on what the server returned.
      final base64Logo = state.company.comLogo;
      if (base64Logo != null && base64Logo.isNotEmpty) {
        try {
          _companyLogo = base64Decode(base64Logo);
        } catch (_) {
          _companyLogo = Uint8List(0);
        }
      } else {
        _companyLogo = Uint8List(0);
      }
    });
  }

  void _cancelUpdate() {
    final state = context.read<CompanyProfileBloc>().state;
    if (state is CompanyProfileLoadedState) {
      _updateControllers(state);
    }
    setState(() {
      isUpdateMode = false;
    });
  }

  void _updateCompanyProfile() {
    context.read<CompanyProfileBloc>().add(UpdateCompanyProfileEvent(
      CompanySettingsModel(
        comName: businessName.text,
        comWebsite: website.text,
        comEmail: email.text,
        comDetails: comDetails.text,
        comId: 1,
        addCity: city.text,
        addName: address.text,
        addProvince: province.text,
        comFb: comFb.text,
        comInsta: comInsta.text,
        comPhone: phone.text,
        comSlogan: comDetails.text,
        comWhatsapp: comWhatsApp.text,
        addCountry: country.text,
        addZipCode: comZipCode.text,
        comLicenseNo: comLicense.text,
        comAddress: loadedCompany?.comAddress,
      ),
    ));
  }

  // ── HEADER ────────────────────────────────────────────────────────

  Widget _buildHeader(
      LoginData login,
      AppLocalizations locale,
      CompanyProfileLoadedState state,
      ) {
    if (widget.isMobile) {
      // ── MOBILE: stacked layout ──
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .09),
                    ),
                  ),
                  child: _buildLogoImage(),
                ),
                if (isUpdateMode)
                  Positioned(
                    top: 60,
                    left: 60,
                    child: IconButton(
                      onPressed: _pickLogoImage,
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                state.company.comName ?? "",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (state.company.comEmail != null &&
                  state.company.comEmail!.isNotEmpty)
                Text(state.company.comEmail ?? ""),
              if (state.company.comPhone != null &&
                  state.company.comPhone!.isNotEmpty)
                Text(state.company.comPhone ?? ""),
            ],
          ),
          const SizedBox(height: 16),
          if (login.hasPermission(108) ?? false)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isUpdateMode)
                  ZOutlineButton(
                    icon: Icons.edit,
                    label: Text(locale.edit),
                    onPressed: () {
                      setState(() => isUpdateMode = true);
                    },
                  ),
                if (isUpdateMode) ...[
                  Expanded(
                    child: ZOutlineButton(
                      backgroundHover: Theme.of(context).colorScheme.error,
                      label: Text(locale.cancel),
                      onPressed: _cancelUpdate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ZOutlineButton(
                      isActive: true,
                      label: Text(locale.save),
                      onPressed: _updateCompanyProfile,
                    ),
                  ),
                ],
              ],
            ),
        ],
      );
    } else {
      // ── DESKTOP / TABLET: row layout ──
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    width: widget.isTablet ? 100 : 120,
                    height: widget.isTablet ? 100 : 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .09),
                      ),
                    ),
                    // ── FIX: was Image.memory(_companyLogo) ──
                    child: _buildLogoImage(),
                  ),
                  if (isUpdateMode)
                    Positioned(
                      top: widget.isTablet ? 70 : 82,
                      left: widget.isTablet ? 70 : 82,
                      child: IconButton(
                        onPressed: _pickLogoImage,
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.company.comName ?? "",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (state.company.comEmail != null &&
                      state.company.comEmail!.isNotEmpty)
                    Text(state.company.comEmail ?? ""),
                  if (state.company.comPhone != null &&
                      state.company.comPhone!.isNotEmpty)
                    Text(state.company.comPhone ?? ""),
                ],
              ),
            ],
          ),
          if (login.hasPermission(108) ?? false)
            Row(
              children: [
                if (!isUpdateMode)
                  ZOutlineButton(
                    icon: Icons.edit,
                    isActive: true,
                    label: Text(locale.editProfile),
                    onPressed: () {
                      setState(() => isUpdateMode = true);
                    },
                  ),
                if (isUpdateMode) ...[
                  ZOutlineButton(
                    icon: Icons.clear,
                    backgroundHover: Theme.of(context).colorScheme.error,
                    label: Text(locale.cancel),
                    onPressed: _cancelUpdate,
                  ),
                  const SizedBox(width: 8),
                  ZOutlineButton(
                    isActive: true,
                    label: Text(locale.save),
                    icon: Icons.save,
                    onPressed: _updateCompanyProfile,
                  ),
                ],
              ],
            ),
        ],
      );
    }
  }

  Widget _buildFormField(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: child,
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = authState.loginData;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<CompanyProfileBloc, CompanyProfileState>(
          listener: (context, state) {
            if (state is CompanyProfileLoadedState) {
              _updateControllers(state);

              if (isUpdateMode) {
                setState(() => isUpdateMode = false);
                ToastManager.show(
                  context: context,
                  message: locale.successMsg,
                  title: locale.successTitle,
                  type: ToastType.success,
                );
              }
            }
          },
          builder: (context, state) {
            if (state is CompanyProfileErrorState) {
              return NoDataWidget(
                message: state.message,
                onRefresh: () {
                  context
                      .read<CompanyProfileBloc>()
                      .add(LoadCompanyProfileEvent());
                },
              );
            }
            if (state is CompanyProfileLoadingState) {
              return UniversalShimmer.profileDetails(
                showImage: true,
                numberOfInfoSections: 9,
                showName: true,
                showInfoSections: true,
                showContact: false,
              );
            }

            if (state is CompanyProfileLoadedState) {
              loadedCompany = state.company;

              final double leftPanelWidth = widget.isMobile
                  ? 0
                  : (widget.isTablet ? 180 : 250);
              final bool isStacked = widget.isMobile;
              final EdgeInsets contentPadding = widget.isMobile
                  ? const EdgeInsets.all(12)
                  : const EdgeInsets.all(16);

              return SingleChildScrollView(
                controller: _scrollController,
                padding: contentPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(login, locale, state),
                    const SizedBox(height: 5),
                    Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: .3),
                    ),
                    const SizedBox(height: 5),

                    // Address Section
                    SectionFormLayout(
                      title: locale.address,
                      subtitle: locale.addressHint,
                      leftPanelWidth: leftPanelWidth,
                      isStacked: isStacked,
                      formFields: [
                        _buildFormField(
                          ZTextFieldEntitled(
                            readOnly: !isUpdateMode,
                            controller: address,
                            title: locale.address,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return locale.required(locale.address);
                              }
                              return null;
                            },
                          ),
                        ),
                        if (widget.isMobile) ...[
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: city,
                              title: locale.city,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: province,
                              title: locale.province,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: country,
                              title: locale.country,
                            ),
                          ),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: city,
                                  title: locale.city,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: province,
                                  title: locale.province,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: country,
                                  title: locale.country,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                        ],
                        if (widget.isMobile) ...[
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: phone,
                              title: locale.mobile1,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: comWhatsApp,
                              title: locale.whatsApp,
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: phone,
                                  title: locale.mobile1,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: comWhatsApp,
                                  title: locale.whatsApp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 5),
                    Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: .3),
                    ),
                    const SizedBox(height: 5),

                    // Social Media Section
                    SectionFormLayout(
                      title: locale.socialMedia,
                      subtitle: locale.socialMediaHint,
                      leftPanelWidth: leftPanelWidth,
                      isStacked: isStacked,
                      formFields: [
                        if (widget.isMobile) ...[
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: website,
                              title: locale.website,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: email,
                              title: locale.email,
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: website,
                                  title: locale.website,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: email,
                                  title: locale.email,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                        ],
                        if (widget.isMobile) ...[
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: comFb,
                              title: locale.facebook,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: comInsta,
                              title: locale.instagram,
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: comFb,
                                  title: locale.facebook,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: comInsta,
                                  title: locale.instagram,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 5),
                    Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: .3),
                    ),
                    const SizedBox(height: 5),

                    // Company Details Section
                    SectionFormLayout(
                      title: locale.comDetails,
                      subtitle: locale.companyDetailsHint,
                      leftPanelWidth: leftPanelWidth,
                      isStacked: isStacked,
                      formFields: [
                        if (widget.isMobile) ...[
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: true,
                              isEnabled: false,
                              controller: comLicense,
                              title: locale.companyLicence,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: comZipCode,
                              title: locale.zipCode,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: true,
                              isEnabled: false,
                              controller: comLocalCcy,
                              title: locale.baseCurrency,
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: true,
                                  isEnabled: false,
                                  controller: comLicense,
                                  title: locale.companyLicence,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: comZipCode,
                                  title: locale.zipCode,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: true,
                                  isEnabled: false,
                                  controller: comLocalCcy,
                                  title: locale.baseCurrency,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                        ],
                        _buildFormField(
                          ZTextFieldEntitled(
                            readOnly: !isUpdateMode,
                            controller: comDetails,
                            keyboardType: TextInputType.multiline,
                            title: AppLocalizations.of(context)!.comDetails,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}

// Mobile Form
class _MobileCompanyForm extends StatelessWidget {
  const _MobileCompanyForm();

  @override
  Widget build(BuildContext context) {
    return const _BaseCompanyForm(
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet Form
class _TabletCompanyForm extends StatelessWidget {
  const _TabletCompanyForm();

  @override
  Widget build(BuildContext context) {
    return const _BaseCompanyForm(
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop Form
class _DesktopCompanyForm extends StatelessWidget {
  const _DesktopCompanyForm();

  @override
  Widget build(BuildContext context) {
    return const _BaseCompanyForm(
      isMobile: false,
      isTablet: false,
    );
  }
}