import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import '../model/user_profile_model.dart';

sealed class UserProfileEvent extends Equatable {
  const UserProfileEvent();
  @override
  List<Object?> get props => const [];
}

/// GET /users/profile.php?usrName=…
class LoadUserProfile extends UserProfileEvent {
  final String usrName;
  const LoadUserProfile(this.usrName);
  @override
  List<Object?> get props => [usrName];
}

/// POST /users/profile.php?action=update
class UpdateUserProfile extends UserProfileEvent {
  final UpdateUserProfileRequest request;
  const UpdateUserProfile(this.request);
  @override
  List<Object?> get props => [request];
}

/// POST /users/profile.php?action=password
class ChangeProfilePassword extends UserProfileEvent {
  final String usrName;
  final String oldPassword;
  final String newPassword;
  const ChangeProfilePassword({
    required this.usrName,
    required this.oldPassword,
    required this.newPassword,
  });
  @override
  List<Object?> get props => [usrName, oldPassword, newPassword];
}

/// POST /users/profile.php?action=photo
class UploadProfilePhoto extends UserProfileEvent {
  final String usrName;
  final Uint8List image;
  const UploadProfilePhoto({
    required this.usrName,
    required this.image,
  });
  @override
  List<Object?> get props => [usrName, image];
}

/// Clears any transient message (snackbar was shown).
class ClearProfileMessage extends UserProfileEvent {
  const ClearProfileMessage();
}

// ═════════════════════════════════════════════════════════════════
// Internal events — must live in the same library as the sealed base
// ═════════════════════════════════════════════════════════════════

/// Emitted by [UserProfileBloc] internally — never dispatched from UI.
/// Carries a photo-upload progress tick that the emitter cannot emit
/// directly from inside Dio's `onSendProgress` callback.
class PhotoProgressTick extends UserProfileEvent {
  final double progress;
  const PhotoProgressTick(this.progress);
  @override
  List<Object?> get props => [progress];
}