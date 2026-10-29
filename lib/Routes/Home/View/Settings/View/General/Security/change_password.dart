import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';

import '../../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../../Features/Widgets/utils.dart';
import '../../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import 'bloc/password_bloc.dart';

class PasswordSettingsView extends StatelessWidget {
  const PasswordSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _Desktop(),
      tablet: _Desktop(),
      desktop: _Desktop(),
    );
  }
}

class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final formKey = GlobalKey<FormState>();

  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  final _oldFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool isVisible1 = true, isVisible2 = true, isVisible3 = true;

  @override
  void dispose() {
    oldPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();

    _oldFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  /// Post-frame focus move — wins over Flutter's built-in
  /// nextFocus()/unfocus() that fires after `onFieldSubmitted`.
  void _moveFocus(FocusNode target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (target.context != null) target.requestFocus();
    });
  }

  void _onLastFieldSubmit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _confirmFocus.unfocus();
      _submit();
    });
  }

  void _submit() {
    final state = context.read<AuthBloc>().state;
    if (state is! AuthenticatedState) return;

    final isLoading =
    context.read<PasswordBloc>().state is PasswordLoadingState;
    if (isLoading) return;

    if (!(formKey.currentState?.validate() ?? false)) return;

    context.read<PasswordBloc>().add(
      ChangePasswordEvent(
        usrName: state.loginData.usrName ?? '',
        oldPassword: oldPassword.text,
        newPassword: newPassword.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final auth = context.watch<AuthBloc>().state;

    if (auth is! AuthenticatedState) return const SizedBox();

    return BlocConsumer<PasswordBloc, PasswordState>(
      listener: (context, state) {
        if (state is PasswordChangedSuccessState) {
          // Clear fields so a re-open shows a clean form.
          oldPassword.clear();
          newPassword.clear();
          confirmPassword.clear();

          final nav = Navigator.of(context);
          if (nav.canPop()) nav.pop();
        }
      },
      builder: (context, state) {
        final isLoading = state is PasswordLoadingState;
        final error = state is PasswordErrorState ? state.message : '';

        return ZFormDialog(
          width: 400,
          isActionTrue: false,
          padding: const EdgeInsets.all(15),
          onAction: null,
          icon: Icons.lock_clock_sharp,
          title: locale.changePassowrd,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                const SizedBox(height: 5),

                // ── Old password ──────────────────────────────
                ZTextFieldEntitled(
                  controller: oldPassword,
                  focusNode: _oldFocus,
                  title: locale.oldPassword,
                  isRequired: true,
                  securePassword: isVisible1,
                  autoFocus: true,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _moveFocus(_newFocus),
                  trailing: _visibilityButton(
                    visible: isVisible1,
                    onTap: () =>
                        setState(() => isVisible1 = !isVisible1),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return locale.required(locale.usrPass);
                    }
                    return null;
                  },
                ),

                // ── New password ──────────────────────────────
                ZTextFieldEntitled(
                  controller: newPassword,
                  focusNode: _newFocus,
                  title: locale.newPassword,
                  isRequired: true,
                  securePassword: isVisible2,
                  autoFocus: false,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _moveFocus(_confirmFocus),
                  trailing: _visibilityButton(
                    visible: isVisible2,
                    onTap: () =>
                        setState(() => isVisible2 = !isVisible2),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return locale.required(locale.usrPass);
                    }
                    return Utils.validatePassword(
                      value: value,
                      context: context,
                    );
                  },
                ),

                // ── Confirm password ──────────────────────────
                ZTextFieldEntitled(
                  controller: confirmPassword,
                  focusNode: _confirmFocus,
                  title: locale.confirmPassword,
                  isRequired: true,
                  securePassword: isVisible3,
                  autoFocus: false,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onLastFieldSubmit(),
                  trailing: _visibilityButton(
                    visible: isVisible3,
                    onTap: () =>
                        setState(() => isVisible3 = !isVisible3),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return locale.required(locale.confirmPassword);
                    }
                    if (newPassword.text != confirmPassword.text) {
                      return locale.passwordNotMatch;
                    }
                    return null;
                  },
                ),

                // ── Error banner ──────────────────────────────
                if (error.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 5),

                ZOutlineButton(
                  height: 40,
                  isActive: true,
                  width: MediaQuery.sizeOf(context).width,
                  label: isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  )
                      : Text(locale.changePassowrd),
                  onPressed: isLoading ? null : _submit,
                ),

                const SizedBox(height: 5),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shared visibility toggle for the three password fields.
  Widget _visibilityButton({
    required bool visible,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        !visible ? Icons.visibility : Icons.visibility_off_rounded,
        size: 18,
      ),
    );
  }
}