import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../bloc/stakeholder_bloc.dart';
import 'bloc/stk_security_bloc.dart';

enum LockVerifyMode {
  verifyOnly,
  lock,
  unlock,
}

/// Verifies the currently-logged-in admin's password and (optionally)
/// toggles the stakeholder's lock state.
///
/// Returns `true` on success, `false` / `null` on cancel or failure.
class LockVerifyDialog extends StatefulWidget {
  final int perID;
  final String stakeholderName;
  final LockVerifyMode mode;

  const LockVerifyDialog({
    super.key,
    required this.perID,
    required this.stakeholderName,
    required this.mode,
  });

  static Future<bool> show(
      BuildContext context, {
        required int perID,
        required String stakeholderName,
        required LockVerifyMode mode,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LockVerifyDialog(
        perID: perID,
        stakeholderName: stakeholderName,
        mode: mode,
      ),
    );
    return result == true;
  }

  @override
  State<LockVerifyDialog> createState() => _LockVerifyDialogState();
}

enum _Phase { form, busy, verified }

class _LockVerifyDialogState extends State<LockVerifyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();

  bool _obscure = true;
  _Phase _phase = _Phase.form;
  String? _error;

  Timer? _ticker;
  Duration _remaining = Duration.zero;
  static const Duration _closeAfter = Duration(seconds: 3);

  @override
  void dispose() {
    _ticker?.cancel();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  String? get _currentUsername {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthenticatedState) return auth.loginData.usrName;
    return null;
  }

  bool get _isLocking => widget.mode == LockVerifyMode.lock;
  bool get _isUnlocking => widget.mode == LockVerifyMode.unlock;

  String _title(AppLocalizations tr) {
    if (_isLocking) return tr.lockVerifyLockTitle;
    if (_isUnlocking) return tr.lockVerifyUnlockTitle;
    return tr.lockVerifyTitle;
  }

  IconData get _icon {
    if (_isLocking) return Icons.lock_outline_rounded;
    if (_isUnlocking) return Icons.lock_open_rounded;
    return Icons.verified_user_outlined;
  }

  Color _accent(ColorScheme scheme) =>
      _isLocking ? scheme.error : scheme.primary;

  String _explanation(AppLocalizations tr) {
    if (_isLocking) return tr.lockVerifyLockExplanation;
    if (_isUnlocking) return tr.lockVerifyUnlockExplanation;
    return tr.lockVerifyVerifyExplanation;
  }

  String _actionLabel(AppLocalizations tr) {
    if (_isLocking) return tr.lockVerifyLockAction;
    if (_isUnlocking) return tr.lockVerifyUnlockAction;
    return tr.lockVerifyContinueAction;
  }

  Future<void> _submit() async {
    if (_phase == _Phase.busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final username = _currentUsername;
    if (username == null) {
      setState(() => _error = AppLocalizations.of(context)!.lockVerifyFailed);
      return;
    }

    final security = context.read<StkSecurityBloc>();
    final listBloc = context.read<StakeholderBloc>();

    setState(() {
      _phase = _Phase.busy;
      _error = null;
    });

    final ok = await security.verify(
      perID: widget.perID,
      username: username,
      password: _passCtrl.text,
    );

    if (!mounted) return;

    if (!ok) {
      final s = security.state;
      setState(() {
        _phase = _Phase.form;
        _error = s is StkSecurityDenied
            ? s.message
            : AppLocalizations.of(context)!.lockVerifyFailed;
      });
      return;
    }

    switch (widget.mode) {
      case LockVerifyMode.verifyOnly:
        _markVerified();
        break;

      case LockVerifyMode.lock:
      case LockVerifyMode.unlock:
        listBloc.add(SetStakeholderLockEvent(
          perID: widget.perID,
          locked: widget.mode == LockVerifyMode.lock,
        ));

        final result = await listBloc.stream.firstWhere(
              (st) =>
          st is SetStakeholderLockSuccessState ||
              st is SetStakeholderLockFailureState,
        );

        if (!mounted) return;

        if (result is SetStakeholderLockFailureState) {
          setState(() {
            _phase = _Phase.form;
            _error = result.message;
          });
          return;
        }

        if (result is SetStakeholderLockSuccessState) {
          _markVerified();
        }
        break;
    }
  }

  void _markVerified() {
    setState(() {
      _phase = _Phase.verified;
      _remaining = _closeAfter;
    });

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _remaining -= const Duration(milliseconds: 100);
        if (_remaining <= Duration.zero) {
          t.cancel();
          if (mounted) Navigator.pop(context, true);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final accent = _accent(scheme);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: .8),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // ── Soft top accent wash ──
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent.withValues(alpha: .06),
                            accent.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Content ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: _phase == _Phase.verified
                      ? _VerifiedBody(
                    key: const ValueKey('verified'),
                    remaining: _remaining,
                    total: _closeAfter,
                    accent: accent,
                    title: tr.lockVerifyVerifiedTitle,
                    subtitle: tr.lockVerifyVerifiedSubtitle,
                    relockLabel: tr.lockVerifyRelockingIn,
                  )
                      : _FormBody(
                    key: const ValueKey('form'),
                    formKey: _formKey,
                    passCtrl: _passCtrl,
                    passFocus: _passFocus,
                    obscure: _obscure,
                    onToggleObscure: () =>
                        setState(() => _obscure = !_obscure),
                    busy: _phase == _Phase.busy,
                    error: _error,
                    icon: _icon,
                    accent: accent,
                    title: _title(tr),
                    stakeholderName: widget.stakeholderName,
                    explanation: _explanation(tr),
                    username: _currentUsername ?? '—',
                    signedInAsLabel: tr.lockVerifySignedInAs,
                    passwordLabel: tr.lockVerifyPasswordLabel,
                    passwordHint: tr.lockVerifyPasswordHint,
                    requiredMsg: tr.lockVerifyRequired,
                    onSubmit: _submit,
                    onCancel: () => Navigator.pop(context, false),
                    actionLabel: _actionLabel(tr),
                    cancelLabel: tr.lockVerifyCancel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Form body — redesigned
// ═══════════════════════════════════════════════════════════════════
class _FormBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passCtrl;
  final FocusNode passFocus;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool busy;
  final String? error;
  final IconData icon;
  final Color accent;
  final String title;
  final String stakeholderName;
  final String explanation;
  final String username;
  final String signedInAsLabel;
  final String passwordLabel;
  final String passwordHint;
  final String requiredMsg;
  final Future<void> Function() onSubmit;
  final VoidCallback onCancel;
  final String actionLabel;
  final String cancelLabel;

  const _FormBody({
    super.key,
    required this.formKey,
    required this.passCtrl,
    required this.passFocus,
    required this.obscure,
    required this.onToggleObscure,
    required this.busy,
    required this.error,
    required this.icon,
    required this.accent,
    required this.title,
    required this.stakeholderName,
    required this.explanation,
    required this.username,
    required this.signedInAsLabel,
    required this.passwordLabel,
    required this.passwordHint,
    required this.requiredMsg,
    required this.onSubmit,
    required this.onCancel,
    required this.actionLabel,
    required this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: .12),
                  ),
                  child: Icon(icon, size: 22, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stakeholderName,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Explanation ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              explanation,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),

          // ── Divider ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: .5),
            ),
          ),

          // ── Password field ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: _PasswordField(
              controller: passCtrl,
              focusNode: passFocus,
              obscure: obscure,
              onToggleObscure: onToggleObscure,
              enabled: !busy,
              accent: accent,
              label: passwordLabel,
              hint: passwordHint,
              requiredMsg: requiredMsg,
              onSubmitted: onSubmit,
            ),
          ),

          // ── Signed in as ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '$signedInAsLabel: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    username,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // ── Error ──
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: scheme.error.withValues(alpha: .3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline,
                        size: 18, color: scheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: scheme.error,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Actions ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: busy ? null : onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    cancelLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 38,
                  child: ZOutlineButton(
                    isActive: true,
                    onPressed: busy ? null : onSubmit,
                    label: busy
                        ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                        : Text(
                      actionLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Password field — custom, elevated, professional
// ═══════════════════════════════════════════════════════════════════
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool enabled;
  final Color accent;
  final String label;
  final String hint;
  final String requiredMsg;
  final Future<void> Function() onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.obscure,
    required this.onToggleObscure,
    required this.enabled,
    required this.accent,
    required this.label,
    required this.hint,
    required this.requiredMsg,
    required this.onSubmitted,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = _focused
        ? widget.accent
        : scheme.outlineVariant.withValues(alpha: .6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above the field, muted
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: .2,
              color: _focused
                  ? widget.accent
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: .35),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1 : 0.5,
            ),
            boxShadow: _focused
                ? [
              BoxShadow(
                color: widget.accent.withValues(alpha: .12),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            obscureText: widget.obscure,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => widget.onSubmitted(),
            style: const TextStyle(
              fontSize: 15,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 13,
                letterSpacing: 0,
                color: scheme.onSurfaceVariant.withValues(alpha: .7),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 4),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: _focused
                      ? widget.accent
                      : scheme.onSurfaceVariant,
                ),
              ),
              prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
              suffixIcon: IconButton(
                onPressed: widget.onToggleObscure,
                icon: Icon(
                  widget.obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                splashRadius: 20,
                tooltip: widget.obscure ? 'Show' : 'Hide',
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorStyle: TextStyle(
                fontSize: 11,
                color: scheme.error,
                height: 1.4,
              ),
            ),
            validator: (v) =>
            (v == null || v.isEmpty) ? widget.requiredMsg : null,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Verified body — with progress arc
// ═══════════════════════════════════════════════════════════════════
class _VerifiedBody extends StatelessWidget {
  final Duration remaining;
  final Duration total;
  final Color accent;
  final String title;
  final String subtitle;
  final String relockLabel;

  const _VerifiedBody({
    super.key,
    required this.remaining,
    required this.total,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.relockLabel,
  });

  double get _progress {
    if (total.inMilliseconds <= 0) return 0;
    final ratio = 1 - (remaining.inMilliseconds / total.inMilliseconds);
    return ratio.clamp(0.0, 1.0);
  }

  String get _mmss {
    final s = remaining.inSeconds.clamp(0, 999);
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 4,
                    backgroundColor: accent.withValues(alpha: .12),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: .14),
                  ),
                  child: Icon(Icons.check_rounded,
                      size: 32, color: accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$relockLabel  ',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                _mmss,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}