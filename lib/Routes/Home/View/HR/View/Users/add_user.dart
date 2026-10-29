import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/HR/View/Users/features/permission_section.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/bloc/stakeholder_bloc.dart';

import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../Features/Widgets/utils.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Settings/View/Company/Branches/features/branch_drop.dart';
import '../../../Settings/View/Company/Branches/model/branch_model.dart';
import '../../../Settings/View/General/UserRole/features/role_drop.dart';
import '../../../Stakeholder/model/stk_model.dart';
import 'bloc/users_bloc.dart';
import 'model/user_model.dart';

class AddUserView extends StatelessWidget {
  final int? indId;
  final UsersModel? existing;

  const AddUserView({super.key, this.indId, this.existing});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(indId: indId, existing: existing),
      tablet: _Desktop(indId: indId, existing: existing),
      desktop: _Desktop(indId: indId, existing: existing),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _Mobile extends StatefulWidget {
  final int? indId;
  final UsersModel? existing;
  const _Mobile({this.indId, this.existing});

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  final usrName = TextEditingController();
  final usrEmail = TextEditingController();
  final usrPas = TextEditingController();
  final passConfirm = TextEditingController();
  final usrOwner = TextEditingController();

  final _usrNameFocus = FocusNode();
  final _ownerFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _usrPassFocus = FocusNode();
  final _passConfirmFocus = FocusNode();

  int? _selectedRole = 2;
  bool isPasswordSecure = true;
  bool fcpValue = true;
  bool fevValue = true;
  int? usrOwnerId;
  BranchModel? selectedBranch;
  IndividualsModel? selectedIndividual;

  final Map<int, bool> _permissions = {};
  final Map<int, bool> _roleCeiling = {};
  final Map<int, bool> _pendingChanges = {};

  final formKey = GlobalKey<FormState>();
  String? errorMessage;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.indId != null) usrOwnerId = widget.indId!;

    final e = widget.existing;
    if (e != null) {
      usrName.text = e.usrName ?? '';
      usrEmail.text = e.usrEmail ?? '';
      usrOwner.text = e.usrOwner?.toString() ?? '';
      _selectedRole = e.rolID ?? _selectedRole;
      fcpValue = (e.usrFcp ?? 1) == 1;
      fevValue = e.usrFev ?? true;
      usrOwnerId = e.usrOwner ?? usrOwnerId;
      if (e.usrBranch != null) {
        selectedBranch = BranchModel(brcId: e.usrBranch!);
      }

      _roleCeiling.addAll(e.roleCeilingAsBool);
      for (final rsgID in _roleCeiling.keys) {
        _permissions[rsgID] = false;
      }
      _permissions.addAll(e.permissionsAsBool);
    }
  }

  String? currentUser() {
    try {
      final auth = context.read<AuthBloc>().state;
      return auth is AuthenticatedState ? auth.loginData.usrName : '';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    usrName.dispose();
    usrEmail.dispose();
    usrPas.dispose();
    passConfirm.dispose();
    usrOwner.dispose();

    _usrNameFocus.dispose();
    _ownerFocus.dispose();
    _emailFocus.dispose();
    _usrPassFocus.dispose();
    _passConfirmFocus.dispose();
    super.dispose();
  }

  void _moveFocus(FocusNode target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (target.context != null) target.requestFocus();
    });
  }

  void _onLastFieldSubmit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _passConfirmFocus.unfocus();
      onSubmit();
    });
  }

  void _onPermissionChanged(int rsgID, bool enabled) {
    final original = widget.existing?.permissionsAsBool[rsgID] ?? false;
    setState(() {
      _permissions[rsgID] = enabled;
      if (enabled == original) {
        _pendingChanges.remove(rsgID);
      } else {
        _pendingChanges[rsgID] = enabled;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final isLoading = context.watch<UsersBloc>().state is UsersLoadingState;

    return Scaffold(
      body: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.outline.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isEdit
                            ? Icons.edit_rounded
                            : Icons.person_add_rounded,
                        color: color.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEdit ? locale.editUser : locale.addUser,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocListener<UsersBloc, UsersState>(
                    listenWhen: (p, c) =>
                    c is UserSuccessState || c is UsersErrorState,
                    listener: (context, state) {
                      if (state is UserSuccessState) {
                        final nav = Navigator.of(context);
                        if (nav.canPop()) nav.pop();
                        return;
                      }
                      if (state is UsersErrorState) {
                        setState(() => errorMessage = state.message);
                      }
                    },
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ZTextFieldEntitled(
                              isRequired: true,
                              controller: usrName,
                              focusNode: _usrNameFocus,
                              autoFocus: !_isEdit,
                              readOnly: _isEdit,
                              textInputAction: TextInputAction.next,
                              hint: 'e.g zaitoon',
                              onFieldSubmitted: (_) {
                                if (widget.indId != null) {
                                  _moveFocus(_emailFocus);
                                }
                              },
                              validator: (e) {
                                if (e == null || e.isEmpty) {
                                  return locale.required(locale.usrName);
                                }
                                return Utils.validateUsername(
                                    value: e, context: context);
                              },
                              title: locale.usrName,
                            ),
                            const SizedBox(height: 12),

                            UserRoleDropdown(
                              selectedId: _selectedRole,
                              onRoleSelected: (e) {
                                setState(() => _selectedRole = e?.rolId);
                                if (widget.indId == null && !_isEdit) {
                                  _moveFocus(_ownerFocus);
                                } else {
                                  _moveFocus(_emailFocus);
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            if (widget.indId == null && !_isEdit) ...[
                              GenericTextField<IndividualsModel,
                                  StakeholderBloc, StakeholderState>(
                                showAllOnFocus: true,
                                controller: usrOwner,
                                focusNode: _ownerFocus,
                                textInputAction: TextInputAction.next,
                                title: locale.stakeholders,
                                hintText: locale.userOwner,
                                isRequired: true,
                                bloc: context.read<StakeholderBloc>(),
                                fetchAllFunction: (bloc) =>
                                    bloc.add(GetStakeholdersEvent()),
                                searchFunction: (bloc, q) => bloc
                                    .add(GetStakeholdersEvent(search: q)),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? locale.required(locale.stakeholders)
                                    : null,
                                itemBuilder: (context, account) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 5),
                                  child: Text(
                                    '${account.perName} ${account.perLastName}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge,
                                  ),
                                ),
                                itemToString: (ind) =>
                                '${ind.perName} ${ind.perLastName}',
                                stateToLoading: (s) =>
                                s is GetStakeholdersLoadingState,
                                loadingBuilder: (_) => const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                stateToItems: (s) =>
                                s is GetStakeholdersSuccessState
                                    ? s.stakeholders
                                    : [],
                                onSelected: (v) {
                                  setState(() {
                                    selectedIndividual = v;
                                    usrOwnerId = v.perId!;
                                  });
                                },
                                noResultsText: locale.noDataFound,
                                showClearButton: true,
                              ),
                              const SizedBox(height: 12),
                            ],

                            BranchDropdown(
                              title: locale.branch,
                              selectedId: selectedBranch?.brcId,
                              onBranchSelected: (b) {
                                selectedBranch = b;
                                _moveFocus(_emailFocus);
                              },
                            ),
                            const SizedBox(height: 12),

                            ZTextFieldEntitled(
                              isRequired: true,
                              controller: usrEmail,
                              focusNode: _emailFocus,
                              autoFocus: false,
                              textInputAction: TextInputAction.next,
                              hint: 'example@zaitoonsoft.com',
                              onFieldSubmitted: (_) =>
                                  _moveFocus(_usrPassFocus),
                              validator: (e) {
                                if (e == null || e.isEmpty) {
                                  return locale.required(locale.email);
                                }
                                return Utils.validateEmail(
                                    email: e, context: context);
                              },
                              title: locale.email,
                            ),
                            const SizedBox(height: 12),

                            ZTextFieldEntitled(
                              isRequired: !_isEdit,
                              securePassword: isPasswordSecure,
                              controller: usrPas,
                              focusNode: _usrPassFocus,
                              autoFocus: false,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _moveFocus(_passConfirmFocus),
                              validator: (e) {
                                if (_isEdit && (e == null || e.isEmpty)) {
                                  return null;
                                }
                                if (e == null || e.isEmpty) {
                                  return locale.required(locale.usrPass);
                                }
                                return null;
                              },
                              title: _isEdit
                                  ? '${locale.usrPass} (optional)'
                                  : locale.usrPass,
                              trailing: IconButton(
                                onPressed: () => setState(() =>
                                isPasswordSecure = !isPasswordSecure),
                                icon: Icon(isPasswordSecure
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                              ),
                            ),
                            const SizedBox(height: 12),

                            ZTextFieldEntitled(
                              isRequired: !_isEdit,
                              securePassword: isPasswordSecure,
                              controller: passConfirm,
                              focusNode: _passConfirmFocus,
                              autoFocus: false,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _onLastFieldSubmit(),
                              validator: (e) {
                                if (_isEdit && (e == null || e.isEmpty)) {
                                  return null;
                                }
                                if (e == null || e.isEmpty) {
                                  return locale
                                      .required(locale.confirmPassword);
                                }
                                if (usrPas.text != passConfirm.text) {
                                  return locale.passwordNotMatch;
                                }
                                return null;
                              },
                              title: _isEdit
                                  ? '${locale.confirmPassword} (optional)'
                                  : locale.confirmPassword,
                              trailing: IconButton(
                                onPressed: () => setState(() =>
                                isPasswordSecure = !isPasswordSecure),
                                icon: Icon(isPasswordSecure
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Switches in a row ──────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: _SwitchTile(
                                    label: locale.forceChangePassword,
                                    value: fcpValue,
                                    onChanged: (v) =>
                                        setState(() => fcpValue = v),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SwitchTile(
                                    label: locale.forceEmailVerification,
                                    value: fevValue,
                                    onChanged: (v) =>
                                        setState(() => fevValue = v),
                                  ),
                                ),
                              ],
                            ),

                            // ── Permissions section (edit only) ──
                            if (_isEdit) ...[
                              const SizedBox(height: 12),
                              PermissionsSection(
                                permissions: _permissions,
                                roleCeiling: _roleCeiling,
                                pendingChanges: _pendingChanges,
                                onChanged: _onPermissionChanged,
                              ),
                            ],

                            if (errorMessage != null &&
                                errorMessage!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.error.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded,
                                        color: color.error),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: TextStyle(
                                            color: color.error, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      side: BorderSide(
                                        color: color.outline
                                            .withValues(alpha: .2),
                                      ),
                                    ),
                                    child: Text(locale.cancel),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: isLoading ? null : onSubmit,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      backgroundColor: color.primary,
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                        : Text(_isEdit
                                        ? locale.save
                                        : locale.create),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void onSubmit() {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final model = UsersModel(
      usrId: widget.existing?.usrId,
      usrName: usrName.text.trim(),
      usrPass: usrPas.text,
      usrBranch: selectedBranch?.brcId
          ?? widget.existing?.usrBranch
          ?? 1000,
      rolID: _selectedRole,
      usrEmail: usrEmail.text,
      usrFcp: fcpValue ? 1 : 0,
      usrFev: fevValue,
      usrOwner: widget.indId ?? usrOwnerId,
      usrStatus: widget.existing?.usrStatus ?? 1,
      loggedInUser: currentUser(),
      usrPermissions: _isEdit
          ? _permissions.map((k, v) => MapEntry(k, v ? 1 : 0))
          : null,
    );

    context.read<UsersBloc>().add(
      _isEdit ? UpdateUserEvent(model) : AddUserEvent(model),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _Desktop extends StatefulWidget {
  final int? indId;
  final UsersModel? existing;
  const _Desktop({this.indId, this.existing});

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final usrName = TextEditingController();
  final usrEmail = TextEditingController();
  final usrPas = TextEditingController();
  final passConfirm = TextEditingController();
  final usrOwner = TextEditingController();

  final _usrNameFocus = FocusNode();
  final _ownerFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _usrPassFocus = FocusNode();
  final _passConfirmFocus = FocusNode();

  int? _selectedRole = 2;
  bool isPasswordSecure = true;
  bool fcpValue = true;
  bool fevValue = true;
  int? usrOwnerId;
  BranchModel? selectedBranch;
  IndividualsModel? selectedIndividual;

  final Map<int, bool> _permissions = {};
  final Map<int, bool> _roleCeiling = {};
  final Map<int, bool> _pendingChanges = {};

  final formKey = GlobalKey<FormState>();
  String? errorMessage;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.indId != null) usrOwnerId = widget.indId!;

    final e = widget.existing;
    if (e != null) {
      usrName.text = e.usrName ?? '';
      usrEmail.text = e.usrEmail ?? '';
      usrOwner.text = e.usrOwner?.toString() ?? '';
      _selectedRole = e.rolID ?? _selectedRole;
      fcpValue = (e.usrFcp ?? 1) == 1;
      fevValue = e.usrFev ?? true;
      usrOwnerId = e.usrOwner ?? usrOwnerId;
      if (e.usrBranch != null) {
        selectedBranch = BranchModel(brcId: e.usrBranch!);
      }

      _roleCeiling.addAll(e.roleCeilingAsBool);
      for (final rsgID in _roleCeiling.keys) {
        _permissions[rsgID] = false;
      }
      _permissions.addAll(e.permissionsAsBool);
    }
  }

  String? currentUser() {
    try {
      final auth = context.read<AuthBloc>().state;
      return auth is AuthenticatedState ? auth.loginData.usrName : '';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    usrName.dispose();
    usrEmail.dispose();
    usrPas.dispose();
    passConfirm.dispose();
    usrOwner.dispose();

    _usrNameFocus.dispose();
    _ownerFocus.dispose();
    _emailFocus.dispose();
    _usrPassFocus.dispose();
    _passConfirmFocus.dispose();
    super.dispose();
  }

  void _moveFocus(FocusNode target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (target.context != null) target.requestFocus();
    });
  }

  void _onLastFieldSubmit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _passConfirmFocus.unfocus();
      onSubmit();
    });
  }

  void _onPermissionChanged(int rsgID, bool enabled) {
    final original = widget.existing?.permissionsAsBool[rsgID] ?? false;
    setState(() {
      _permissions[rsgID] = enabled;
      if (enabled == original) {
        _pendingChanges.remove(rsgID);
      } else {
        _pendingChanges[rsgID] = enabled;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final isLoading = context.watch<UsersBloc>().state is UsersLoadingState;

    return ZFormDialog(
      width: 780,
      icon: _isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
      onAction: onSubmit,
      actionLabel: isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          color: Theme.of(context).colorScheme.surface,
        ),
      )
          : Text(_isEdit ? locale.save : locale.create),
      title: _isEdit ? locale.editUser : locale.addUser,
      child: BlocListener<UsersBloc, UsersState>(
        listenWhen: (p, c) =>
        c is UserSuccessState || c is UsersErrorState,
        listener: (context, state) {
          if (state is UserSuccessState) {
            final nav = Navigator.of(context);
            if (nav.canPop()) nav.pop();
            return;
          }
          if (state is UsersErrorState) {
            setState(() => errorMessage = state.message);
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 5,
                    children: [
                      Expanded(
                        flex: 4,
                        child: ZTextFieldEntitled(
                          isRequired: true,
                          controller: usrName,
                          focusNode: _usrNameFocus,
                          autoFocus: !_isEdit,
                          readOnly: _isEdit,
                          textInputAction: TextInputAction.next,
                          hint: 'e.g zaitoon',
                          onFieldSubmitted: (_) {
                            if (widget.indId != null) {
                              _moveFocus(_emailFocus);
                            }
                          },
                          validator: (e) {
                            if (e == null || e.isEmpty) {
                              return locale.required(locale.usrName);
                            }
                            return Utils.validateUsername(
                                value: e, context: context);
                          },
                          title: locale.usrName,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: UserRoleDropdown(
                          selectedId: _selectedRole,
                          onRoleSelected: (e) {
                            setState(() => _selectedRole = e?.rolId);
                            if (widget.indId == null && !_isEdit) {
                              _moveFocus(_ownerFocus);
                            } else {
                              _moveFocus(_emailFocus);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  if (widget.indId == null && !_isEdit) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 8,
                      children: [
                        Expanded(
                          flex: 4,
                          child: GenericTextField<IndividualsModel,
                              StakeholderBloc, StakeholderState>(
                            showAllOnFocus: true,
                            controller: usrOwner,
                            focusNode: _ownerFocus,
                            textInputAction: TextInputAction.next,
                            title: locale.stakeholders,
                            hintText: locale.userOwner,
                            isRequired: true,
                            bloc: context.read<StakeholderBloc>(),
                            fetchAllFunction: (bloc) =>
                                bloc.add(GetStakeholdersEvent()),
                            searchFunction: (bloc, q) =>
                                bloc.add(GetStakeholdersEvent(search: q)),
                            validator: (v) => (v == null || v.isEmpty)
                                ? locale.required(locale.stakeholders)
                                : null,
                            itemBuilder: (context, account) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 5),
                              child: Text(
                                '${account.perName} ${account.perLastName}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            itemToString: (ind) =>
                            '${ind.perName} ${ind.perLastName}',
                            stateToLoading: (s) =>
                            s is GetStakeholdersLoadingState,
                            loadingBuilder: (_) => const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                              CircularProgressIndicator(strokeWidth: 2),
                            ),
                            stateToItems: (s) =>
                            s is GetStakeholdersSuccessState
                                ? s.stakeholders
                                : [],
                            onSelected: (v) {
                              setState(() {
                                selectedIndividual = v;
                                usrOwnerId = v.perId!;
                              });
                            },
                            noResultsText: locale.noDataFound,
                            showClearButton: true,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: BranchDropdown(
                            title: locale.branch,
                            selectedId: selectedBranch?.brcId,
                            onBranchSelected: (b) {
                              selectedBranch = b;
                              _moveFocus(_emailFocus);
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: BranchDropdown(
                            title: locale.branch,
                            selectedId: selectedBranch?.brcId,
                            onBranchSelected: (b) {
                              selectedBranch = b;
                              _moveFocus(_emailFocus);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],

                  ZTextFieldEntitled(
                    isRequired: true,
                    controller: usrEmail,
                    focusNode: _emailFocus,
                    autoFocus: false,
                    textInputAction: TextInputAction.next,
                    hint: 'example@zaitoonsoft.com',
                    onFieldSubmitted: (_) => _moveFocus(_usrPassFocus),
                    validator: (e) {
                      if (e == null || e.isEmpty) {
                        return locale.required(locale.email);
                      }
                      return Utils.validateEmail(email: e, context: context);
                    },
                    title: locale.email,
                  ),

                  Row(
                    spacing: 3,
                    children: [
                      Expanded(
                        child: ZTextFieldEntitled(
                          isRequired: !_isEdit,
                          securePassword: isPasswordSecure,
                          controller: usrPas,
                          focusNode: _usrPassFocus,
                          autoFocus: false,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _moveFocus(_passConfirmFocus),
                          validator: (e) {
                            if (_isEdit && (e == null || e.isEmpty)) {
                              return null;
                            }
                            if (e == null || e.isEmpty) {
                              return locale.required(locale.usrPass);
                            }
                            return null;
                          },
                          title: _isEdit
                              ? '${locale.usrPass} (optional)'
                              : locale.usrPass,
                          trailing: IconButton(
                            onPressed: () => setState(() =>
                            isPasswordSecure = !isPasswordSecure),
                            icon: Icon(isPasswordSecure
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ZTextFieldEntitled(
                          isRequired: !_isEdit,
                          securePassword: isPasswordSecure,
                          controller: passConfirm,
                          focusNode: _passConfirmFocus,
                          autoFocus: false,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _onLastFieldSubmit(),
                          validator: (e) {
                            if (_isEdit && (e == null || e.isEmpty)) {
                              return null;
                            }
                            if (e == null || e.isEmpty) {
                              return locale
                                  .required(locale.confirmPassword);
                            }
                            if (usrPas.text != passConfirm.text) {
                              return locale.passwordNotMatch;
                            }
                            return null;
                          },
                          title: _isEdit
                              ? '${locale.confirmPassword} (optional)'
                              : locale.confirmPassword,
                          trailing: IconButton(
                            onPressed: () => setState(() =>
                            isPasswordSecure = !isPasswordSecure),
                            icon: Icon(isPasswordSecure
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Switches in a row ────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _SwitchTile(
                          label: locale.forceChangePassword,
                          value: fcpValue,
                          onChanged: (v) =>
                              setState(() => fcpValue = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SwitchTile(
                          label: locale.forceEmailVerification,
                          value: fevValue,
                          onChanged: (v) =>
                              setState(() => fevValue = v),
                        ),
                      ),
                    ],
                  ),

                  // ── Permissions section (edit only) ─────
                  if (_isEdit)
                    PermissionsSection(
                      permissions: _permissions,
                      roleCeiling: _roleCeiling,
                      pendingChanges: _pendingChanges,
                      onChanged: _onPermissionChanged,
                    ),

                  if (errorMessage != null && errorMessage!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        spacing: 5,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: Theme.of(context).colorScheme.error),
                          Expanded(
                            child: Text(
                              errorMessage ?? '',
                              style: TextStyle(
                                  color:
                                  Theme.of(context).colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onSubmit() {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final model = UsersModel(
      usrId: widget.existing?.usrId,
      usrName: usrName.text.trim(),
      usrPass: usrPas.text,
      usrBranch: selectedBranch?.brcId
          ?? widget.existing?.usrBranch
          ?? 1000,
      rolID: _selectedRole,
      usrEmail: usrEmail.text,
      usrFcp: fcpValue ? 1 : 0,
      usrFev: fevValue,
      usrOwner: widget.indId ?? usrOwnerId,
      usrStatus: widget.existing?.usrStatus ?? 1,
      loggedInUser: currentUser(),
      usrPermissions: _isEdit
          ? _permissions.map((k, v) => MapEntry(k, v ? 1 : 0))
          : null,
    );

    context.read<UsersBloc>().add(
      _isEdit ? UpdateUserEvent(model) : AddUserEvent(model),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Small shared widgets
// ═══════════════════════════════════════════════════════════════════

/// Compact switch + label tile used for FCP and FE Verification.
class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: .4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}