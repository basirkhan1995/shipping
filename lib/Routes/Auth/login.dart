import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/utils.dart';
import 'package:shipping/Routes/Auth/bloc/auth_bloc.dart';
import 'package:shipping/Routes/Home/home.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../Features/Widgets/ztextfield.dart';
import '../../../../Themes/Ui/theme_selector.dart';
import '../../../../l10n/locale_selector.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure = true;
  String? _error;

  /// "Remember me" state — defaults to true so users stay signed in
  /// unless they explicitly opt out.
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }

    context.read<AuthBloc>().add(
      LoginEvent(
        usrName: _emailCtrl.text,
        usrPassword: _passwordCtrl.text,
        rememberMe: _rememberMe,
      ),
    );
  }

  // ─────────────── Brand block: logo + company name ───────────────
  Widget _brandBlock(ColorScheme scheme) {
    final tr = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo — falls back to an icon if the asset is missing.
        SizedBox(
          width: 50,
          height: 50,
          child: Image.asset(
            'assets/images/zaitoonLogo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.business_outlined,
                size: 30,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Wordmark
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            Text(
              tr.zaitoonTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: 0.4,
                color: scheme.onSurface,
                height: 1.1,
              ),
            ),
            Text(
              tr.softwareCompany,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.sizeOf(context).width < 900;
    final tr = AppLocalizations.of(context)!;

    // Drive the loading state from the bloc instead of a frozen local flag.
    final isLoading = context.watch<AuthBloc>().state is AuthLoadingState;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
      current is AuthenticatedState ||
          current is AuthErrorState ||
          current is ForceChangePasswordState ||
          current is NoSubscriptionState ||
          current is EmailVerificationState,
      listener: (context, state) {
        if (state is AuthenticatedState) {
          // ✅ Login succeeded → navigate to Home.
          Utils.goto(context, const HomeView());
        } else if (state is AuthErrorState) {
          setState(() => _error = state.message);
        } else if (state is ForceChangePasswordState) {
          // TODO: navigate to force-change-password page.
        } else if (state is NoSubscriptionState) {
          // TODO: navigate to no-subscription page.
        } else if (state is EmailVerificationState) {
          // TODO: navigate to email verification page.
        }
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Stack(
            children: [
              // ───────────────────────── Main layout ──────────────────────
              Row(
                children: [
                  // Left: image panel
                  if (!isNarrow)
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.primaryContainer.withValues(alpha: .55),
                              scheme.surfaceContainerHighest,
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 420,
                                height: 420,
                                child: Image.asset(
                                  'assets/images/shipping.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.local_shipping_outlined,
                                    size: 180,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                tr.shippingManagement.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tr.shipping_subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Right: form panel
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Extra top room on narrow layouts so the
                                // selectors don't overlap the brand block.
                                SizedBox(height: isNarrow ? 44 : 0),
                                _brandBlock(scheme),
                                const SizedBox(height: 32),

                                // Email
                                ZTextFieldEntitled(
                                  title: tr.emailOrUsername,
                                  hint: 'you@example.com',
                                  isRequired: true,
                                  controller: _emailCtrl,
                                  focusNode: _emailFocus,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _passwordFocus.requestFocus(),
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty) {
                                      return tr.required(tr.emailOrUsername);
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Password
                                ZTextFieldEntitled(
                                  title: tr.usrPass,
                                  hint: '••••••••',
                                  isRequired: true,
                                  controller: _passwordCtrl,
                                  focusNode: _passwordFocus,
                                  securePassword: _obscure,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty) {
                                      return tr.required(tr.usrPass);
                                    }
                                    return null;
                                  },
                                  trailing: IconButton(
                                    tooltip: _obscure
                                        ? tr.show_password
                                        : tr.hide_password,
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // ── Remember me ──
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (v) => setState(
                                                () => _rememberMe = v ?? false),
                                        materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setState(
                                              () => _rememberMe = !_rememberMe),
                                      child: Text(
                                        tr.rememberMe,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Error banner
                                if (_error != null)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: scheme.errorContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline,
                                            size: 16, color: scheme.error),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: TextStyle(
                                              color: scheme.onErrorContainer,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Sign in
                                SizedBox(
                                  height: 44,
                                  child: FilledButton(
                                    onPressed: isLoading ? null : _submit,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : Text(tr.signIn),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Footer
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      tr.dont_have_account,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      child: Text(tr.contact_admin),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Small copyright line
                                Center(
                                  child: Text(
                                    tr.copyright(2026),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurfaceVariant
                                          .withValues(alpha: .7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ───────────────── Theme + Locale selectors (top-right) ─────────────────
              Positioned(
                top: 8,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocaleSelector(width: 130),
                    const SizedBox(width: 8),
                    ThemeSelector(width: 130),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}