import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Features/Other/image_helper.dart';
import 'package:shipping/Features/Other/responsive_widget.dart';
import 'package:shipping/Features/Other/image_crop.dart';
import 'package:shipping/Features/Widgets/utils.dart';
import 'package:shipping/Routes/Home/View/Settings/View/General/UserProfile/profile_form.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../../../Services/repository.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import 'bloc/user_profile_bloc.dart';
import 'bloc/user_profile_event.dart';
import 'change_password.dart';
import 'model/user_profile_model.dart';

// ═══════════════════════════════════════════════════════════════════
// Entry point
// ═══════════════════════════════════════════════════════════════════
class UserProfileView extends StatelessWidget {
  final String? usrName;

  const UserProfileView({super.key, this.usrName});

  @override
  Widget build(BuildContext context) {
    final resolvedName = usrName ?? _loginName(context);
    if (resolvedName == null || resolvedName.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    // ✅ Provide the bloc at the top so every descendant can find it,
    //    and dispatch the initial load immediately.
    return BlocProvider(
      create: (_) => UserProfileBloc(context.read<Repositories>())
        ..add(LoadUserProfile(resolvedName)),
      child: ResponsiveLayout(
        mobile: _UserProfileMobile(usrName: resolvedName),
        tablet: _UserProfileDesktop(usrName: resolvedName),
        desktop: _UserProfileDesktop(usrName: resolvedName),
      ),
    );
  }

  static String? _loginName(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthenticatedState ? auth.loginData.usrName : null;
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _UserProfileMobile extends StatelessWidget {
  final String usrName;
  const _UserProfileMobile({required this.usrName});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.userProfile),
        actions: const [_ProfileRefreshButton()],
      ),
      body: _ProfileBody(
        usrName: usrName,
        layout: _ProfileLayout.compact,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP / TABLET
// ═══════════════════════════════════════════════════════════════════
class _UserProfileDesktop extends StatelessWidget {
  final String usrName;
  const _UserProfileDesktop({required this.usrName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _ProfileBody(
        usrName: usrName,
        layout: _ProfileLayout.wide,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Refresh button
// ═══════════════════════════════════════════════════════════════════
class _ProfileRefreshButton extends StatelessWidget {
  const _ProfileRefreshButton();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UserProfileBloc>().state;
    final busy = state is UserProfileLoading;

    return IconButton(
      tooltip: 'Refresh',
      icon: busy
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.refresh_rounded),
      onPressed: busy
          ? null
          : () {
        final profile = state.profile;
        if (profile != null) {
          context.read<UserProfileBloc>().add(
            LoadUserProfile(profile.user.usrName),
          );
        }
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared body — loading / error / loaded
// ═══════════════════════════════════════════════════════════════════
enum _ProfileLayout { compact, wide }

class _ProfileBody extends StatelessWidget {
  final String usrName;
  final _ProfileLayout layout;

  const _ProfileBody({required this.usrName, required this.layout});

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserProfileBloc, UserProfileState>(
      listenWhen: (p, c) => c.message != null,
      listener: (context, state) {
        // 1) Show the toast (existing behaviour)
        ToastManager.show(
          context: context,
          title: state.isError ? 'Error' : 'Success',
          message: state.message!,
          type: state.isError ? ToastType.error : ToastType.success,
        );

        // 2) If the write succeeded, refresh the auth loginData
        //    so header / sidebar / permissions re-read the latest profile.
        if (!state.isError && _needsAuthRefresh(state)) {
          context.read<AuthBloc>().add(RefreshProfileEvent(usrName));
        }

        // 3) Clear the one-shot message
        context.read<UserProfileBloc>().add(const ClearProfileMessage());
      },
      child: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          final profile = state.profile;

          if (profile == null) {
            if (state is UserProfileFailure) {
              return _ErrorPanel(
                message: state.message ?? 'Failed to load profile',
                onRetry: () => context.read<UserProfileBloc>().add(
                  LoadUserProfile(usrName),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          return _ProfileContent(
            profile: profile,
            state: state,
            layout: layout,
          );
        },
      ),
    );
  }

  /// Which success states should trigger a full auth refresh?
  bool _needsAuthRefresh(UserProfileState s) =>
      s is UserProfileSaved ||       // details update
          s is ProfilePasswordChanged || // password change
          s is ProfilePhotoUploaded;     // photo upload
}

// ═══════════════════════════════════════════════════════════════════
// Loaded content
// ═══════════════════════════════════════════════════════════════════
class _ProfileContent extends StatelessWidget {
  final UserProfile profile;
  final UserProfileState state;
  final _ProfileLayout layout;

  const _ProfileContent({
    required this.profile,
    required this.state,
    required this.layout,
  });

  bool get _isWide => layout == _ProfileLayout.wide;

  bool get _passwordBusy => state is ProfilePasswordChanging;
  bool get _photoBusy => state is ProfilePhotoUploading;
  bool get _saving => state is UserProfileSaving;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final padding = EdgeInsets.all(_isWide ? 5 : 12);

    if (!_isWide) {
      return SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileCard(profile: profile),
            const SizedBox(height: 16),
            _ActionPanel(
              profile: profile,
              passwordBusy: _passwordBusy,
              photoBusy: _photoBusy,
              saving: _saving,
              progress: state.uploadProgress,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _ProfileCard(profile: profile),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 1,
            color: color.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _ActionPanel(
                profile: profile,
                passwordBusy: _passwordBusy,
                photoBusy: _photoBusy,
                saving: _saving,
                progress: state.uploadProgress,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// LEFT — Profile card
// ═══════════════════════════════════════════════════════════════════
class _ProfileCard extends StatelessWidget {
  final UserProfile profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final state = context.watch<UserProfileBloc>().state;
    final photoBusy = state is ProfilePhotoUploading;
    final progress = state.uploadProgress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: color.shadow.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: AlignmentDirectional.bottomEnd,
            children: [
              _ProfileAvatar(
                photoUrl: profile.photoUrl,
                progress: photoBusy ? progress : null,
              ),
              if (!photoBusy)
                InkWell(
                  onTap: () => _pickAndUpload(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: color.surface, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.displayName.isEmpty ? '—' : profile.displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          if (profile.user.usrName.isNotEmpty) ...[
            Text(
              '@${profile.user.usrName}',
              style: TextStyle(
                fontSize: 13,
                color: color.onSurfaceVariant,
              ),
            ),
          ],
          if ((profile.personal.perEmail ?? '').isNotEmpty) ...[
            _chip(
              icon: Icons.email_outlined,
              label: profile.personal.perEmail!,
              fg: color.onSurfaceVariant,
              bg: color.surfaceContainerHighest.withValues(alpha: .5),
            ),
          ],
          if ((profile.personal.perPhone ?? '').isNotEmpty)
            _chip(
              icon: Icons.phone,
              label: profile.personal.perPhone!,
              fg: color.primary,
              bg: color.primary.withValues(alpha: .08),
            ),

          const SizedBox(height: 14),
          _sectionDivider(color, tr.profile.toUpperCase()),
          const SizedBox(height: 10),

              _info(
                context,
                icon: Icons.badge_outlined,
                title: tr.gender,
                value: profile.personal.perGender ?? '',
              ),
              if (profile.personal.perDoB != null)
                _info(
                  context,
                  icon: Icons.cake_outlined,
                  title: tr.dob,
                  value: _formatDate(profile.personal.perDoB!),
                ),
              if ((profile.personal.perENIDNo ?? '').isNotEmpty)
                _info(
                  context,
                  icon: Icons.credit_card_outlined,
                  title: tr.nationalId,
                  value: profile.personal.perENIDNo!,
                ),


          _sectionDivider(color, tr.address.toUpperCase()),
          const SizedBox(height: 10),

          if (profile.address != null) ...[
            if ((profile.address!.addName ?? '').isNotEmpty)...[
              _info(
                context,
                icon: Icons.location_on_outlined,
                title: tr.address,
                value: profile.address!.addName!,
              ),
              const SizedBox(height: 10),
            ],

            Row(
              spacing: 5,
              children: [
                if ((profile.address!.addCity ?? '').isNotEmpty)
                  Expanded(
                    child: _info(
                      context,
                      icon: Icons.location_city_outlined,
                      title: tr.city,
                      value: profile.address!.addCity!,
                    ),
                  ),
                if ((profile.address!.addProvince ?? '').isNotEmpty)
                  Expanded(
                    child: _info(
                      context,
                      icon: Icons.map_outlined,
                      title: tr.province,
                      value: profile.address!.addProvince!,
                    ),
                  ),
                if ((profile.address!.addCountry ?? '').isNotEmpty)
                  Expanded(
                    child: _info(
                      context,
                      icon: Icons.public_outlined,
                      title: tr.country,
                      value: profile.address!.addCountry!,
                    ),
                  ),
                if ((profile.address!.addZipCode ?? '').isNotEmpty)
                  Expanded(
                    child: _info(
                      context,
                      icon: Icons.markunread_mailbox_outlined,
                      title: tr.zipCode,
                      value: profile.address!.addZipCode!,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 5),
          _sectionDivider(color, tr.account.toUpperCase()),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                profile.user.isEnabled
                    ? Icons.check_circle_rounded
                    : Icons.block_rounded,
                size: 16,
                color: profile.user.isEnabled
                    ? const Color(0xFF16A34A)
                    : color.error,
              ),
              const SizedBox(width: 8),
              Text(
                profile.user.isEnabled ? tr.active : tr.blocked,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (profile.user.usrEntryDate != null)
                Text(
                  'Since ${_formatDate(profile.user.usrEntryDate!)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: color.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final bloc = context.read<UserProfileBloc>();
    final usrName = profile.user.usrName;

    final imageBytes = await Utils.pickImage();
    if (imageBytes == null || imageBytes.isEmpty) return;
    if (!context.mounted) return;

    try {
      final cropped = await showImageCropper(
        context: context,
        imageBytes: imageBytes,
      );
      if (cropped == null || cropped.isEmpty) return;

      bloc.add(UploadProfilePhoto(usrName: usrName, image: cropped));
    } catch (e) {
      debugPrint('Image crop failed: $e');
    }
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color fg,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionDivider(ColorScheme color, String label) {
    return Row(
      children: [
        Expanded(child: Divider(color: color.outline.withValues(alpha: .2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: color.outline.withValues(alpha: .7),
            ),
          ),
        ),
        Expanded(child: Divider(color: color.outline.withValues(alpha: .2))),
      ],
    );
  }

  Widget _info(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
      }) {
    final color = Theme.of(context).colorScheme;
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: color.outline.withValues(alpha: .7),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
// Avatar
// ═══════════════════════════════════════════════════════════════════
class _ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final double? progress;

  const _ProfileAvatar({this.photoUrl, this.progress});

  bool get _uploading => progress != null;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final fileName = _extractFileName(photoUrl);

    final inner = SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageHelper.stakeholderProfile(
            imageName: fileName,
            size: 120,
            shapeStyle: ShapeStyle.circle,
            placeholderColor: color.primary.withValues(alpha: .15),
            placeholderIcon: Icons.person_rounded,
            fit: BoxFit.cover,
          ),
          if (_uploading) ...[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: progress == 0 ? null : progress,
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.primary.withValues(alpha: .1),
        border: Border.all(
          color: color.primary.withValues(alpha: .25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            spreadRadius: 2,
            color: color.primary.withValues(alpha: .12),
          ),
        ],
      ),
      child: ClipOval(child: inner),
    );
  }

  String? _extractFileName(String? url) {
    if (url == null || url.isEmpty) return null;
    final idx = url.lastIndexOf('/');
    return idx == -1 ? url : url.substring(idx + 1);
  }
}

// ═══════════════════════════════════════════════════════════════════
// RIGHT — Action panel
// ═══════════════════════════════════════════════════════════════════
class _ActionPanel extends StatelessWidget {
  final UserProfile profile;
  final bool passwordBusy;
  final bool photoBusy;
  final bool saving;
  final double? progress;

  const _ActionPanel({
    required this.profile,
    required this.passwordBusy,
    required this.photoBusy,
    required this.saving,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionCard(
          icon: Icons.perm_identity_rounded,
          title: tr.editProfile.toUpperCase(),
          subtitle:
          tr.editProfileHint,
          busy: saving,
          onAction: () => _openEditDialog(context),
        ),
        const SizedBox(height: 14),
        _ActionCard(
          icon: Icons.lock_outline_rounded,
          title: tr.changePassowrd,
          subtitle: tr.changePasswordHint,
          busy: passwordBusy,
          onAction: () => _openPasswordDialog(context),
        ),
        const SizedBox(height: 14),
        _ActionCard(
          icon: Icons.photo_camera_outlined,
          title: tr.profilePhoto.toUpperCase(),
          subtitle: progress != null ? '${tr.uploading} ${(progress! * 100).toStringAsFixed(0)}%'
              : tr.profilePhotoHint,
          busy: photoBusy,
          onAction: () => _pickAndUpload(context),
        ),
      ],
    );
  }

  Future<void> _openEditDialog(BuildContext context) async {
    final bloc = context.read<UserProfileBloc>();
    final updated = await showDialog<UpdateUserProfileRequest>(
      context: context,
      builder: (_) => UserProfileFormDialog(profile: profile),
    );
    if (updated != null) {
      bloc.add(UpdateUserProfile(updated));
    }
  }

  Future<void> _openPasswordDialog(BuildContext context) async {
    final bloc = context.read<UserProfileBloc>();
    final result = await showDialog<ChangePasswordResult>(
      context: context,
      builder: (_) => PasswordChangeDialog(usrName: profile.user.usrName),
    );
    if (result != null) {
      bloc.add(ChangeProfilePassword(
        usrName: profile.user.usrName,
        oldPassword: result.oldPassword,
        newPassword: result.newPassword,
      ));
    }
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final bloc = context.read<UserProfileBloc>();
    final usrName = profile.user.usrName;

    final imageBytes = await Utils.pickImage();
    if (imageBytes == null || imageBytes.isEmpty) return;
    if (!context.mounted) return;

    try {
      final cropped = await showImageCropper(
        context: context,
        imageBytes: imageBytes,
      );
      if (cropped == null || cropped.isEmpty) return;

      bloc.add(UploadProfilePhoto(usrName: usrName, image: cropped));
    } catch (e) {
      debugPrint('Image crop failed: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Single action card
// ═══════════════════════════════════════════════════════════════════
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback onAction;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return InkWell(
      onTap: busy ? null : onAction,
      child: Container(
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: color.shadow.withValues(alpha: 0.04),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color.primary, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            busy ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ) : Icon(Icons.arrow_forward_ios_rounded,size: 18),

          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Error panel
// ═══════════════════════════════════════════════════════════════════
class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: color.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ZOutlineButton(
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}