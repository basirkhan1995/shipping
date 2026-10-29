import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import 'bloc/user_role_bloc.dart';
import 'model/role_model.dart';

class AddEditUserRoleSettingsView extends StatelessWidget {
  final UserRoleModel? model;
  const AddEditUserRoleSettingsView({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(model: model),
      tablet: _Tablet(model: model),
      desktop: _Desktop(model),
    );
  }
}

class _Mobile extends StatelessWidget {
  final UserRoleModel? model;
  const _Mobile({this.model});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        child: _AddEditForm(model: model),
      ),
    );
  }
}

class _Tablet extends StatelessWidget {
  final UserRoleModel? model;
  const _Tablet({this.model});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(width: 500, child: _AddEditForm(model: model)),
    );
  }
}

class _Desktop extends StatelessWidget {
  final UserRoleModel? model;
  const _Desktop(this.model);

  @override
  Widget build(BuildContext context) {
    return _AddEditForm(model: model, isDesktop: true);
  }
}

class _AddEditForm extends StatefulWidget {
  final UserRoleModel? model;
  final bool isDesktop;

  const _AddEditForm({this.model, this.isDesktop = false});

  @override
  State<_AddEditForm> createState() => _AddEditFormState();
}

class _AddEditFormState extends State<_AddEditForm> {
  final formKey = GlobalKey<FormState>();
  final roleNameController = TextEditingController();
  final _roleNameFocus = FocusNode();

  bool isActive = true;
  String? usrName;

  bool get _isEdit => widget.model != null;

  @override
  void initState() {
    super.initState();

    // Load actor + reset any stale bloc state left by a previous attempt.
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserRoleBloc>().add(ClearUserRoleMessagesEvent());
    });

    if (widget.model != null) {
      roleNameController.text = widget.model?.rolName ?? '';
      isActive = widget.model?.rolStatus == 1;
    }
  }

  Future<void> _loadUserData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      setState(() => usrName = authState.loginData.usrName);
    }
  }

  @override
  void dispose() {
    roleNameController.dispose();
    _roleNameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // Listen for success → close. Errors stay visible via builder.
    return BlocConsumer<UserRoleBloc, UserRoleState>(
      listenWhen: (p, c) =>
      c is UserRoleSuccessState || c is UserRoleErrorState,
      listener: (context, state) {
        if (state is UserRoleSuccessState) {
          final nav = Navigator.of(context);
          if (nav.canPop()) nav.pop();
          // Note: the bloc reloads roles for the parent list; the dialog's
          // success triggers only a pop here.
        }
      },
      builder: (context, roleState) {
        final isLoading = roleState is UserRoleLoadingState;

        if (widget.isDesktop) {
          return ZFormDialog(
            onAction: isLoading ? null : _onSubmit,
            padding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            actionLabel: isLoading
                ? SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                color: colorScheme.surface,
                strokeWidth: 2,
              ),
            )
                : Text(_isEdit ? tr.update : tr.create),
            title: _isEdit ? tr.editRole : tr.addRole,
            child: _buildFormContent(context, roleState),
          );
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? tr.editRole : tr.addRole,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildFormContent(context, roleState),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: .3),
                          ),
                        ),
                      ),
                      child: Text(
                        tr.cancel,
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _onSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: colorScheme.surface,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(_isEdit ? tr.update : tr.create),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormContent(BuildContext context, UserRoleState roleState) {
    final tr = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ZTextFieldEntitled(
            title: tr.roleName,
            controller: roleNameController,
            focusNode: _roleNameFocus,
            isRequired: true,
            autoFocus: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              _roleNameFocus.unfocus();
              _onSubmit();
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr.required(tr.roleName);
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => isActive = !isActive),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: .1)
                        : Colors.red.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.check_circle : Icons.cancel,
                        color: isActive ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? tr.active : tr.inactive,
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Error banner — only rendered for the current attempt because
          // the bloc state was cleared before submitting.
          if (roleState is UserRoleErrorState) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: .3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      roleState.message,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onSubmit() {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not authenticated'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final userName = authState.loginData.usrName ?? '';
    if (userName.isEmpty) return;

    final bloc = context.read<UserRoleBloc>();

    // Clear any stale error from a previous attempt before dispatching.
    bloc.add(ClearUserRoleMessagesEvent());

    if (_isEdit) {
      bloc.add(
        UpdateUserRoleEvent(
          newRole: UserRoleModel(
            usrName: userName,
            rolId: widget.model?.rolId,
            rolName: roleNameController.text.trim(),
            rolStatus: isActive ? 1 : 0,
          ),
        ),
      );
    } else {
      bloc.add(
        AddUserRoleEvent(
          usrName: userName,
          roleName: roleNameController.text.trim(),
        ),
      );
    }
  }
}