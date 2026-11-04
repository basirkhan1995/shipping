part of 'user_profile_bloc.dart';

sealed class UserProfileState extends Equatable {
  /// The loaded profile (survives message-only state transitions).
  final UserProfile? profile;

  /// Last message to show once (success or error).
  final String? message;
  final bool isError;

  /// Upload progress for photo (0.0 – 1.0), null when not uploading.
  final double? uploadProgress;

  const UserProfileState({
    this.profile,
    this.message,
    this.isError = false,
    this.uploadProgress,
  });

  @override
  List<Object?> get props => [profile, message, isError, uploadProgress];
}

// ── Initial ──────────────────────────────────────────────

class UserProfileInitial extends UserProfileState {
  const UserProfileInitial() : super();
}

// ── Loading the whole profile ────────────────────────────

class UserProfileLoading extends UserProfileState {
  const UserProfileLoading({super.profile});
}

class UserProfileLoaded extends UserProfileState {
  const UserProfileLoaded(UserProfile profile)
      : super(profile: profile);
}

class UserProfileFailure extends UserProfileState {
  const UserProfileFailure(String message, {super.profile})
      : super(message: message, isError: true);
}

// ── Updating details ─────────────────────────────────────

class UserProfileSaving extends UserProfileState {
  const UserProfileSaving({super.profile});
}

class UserProfileSaved extends UserProfileState {
  const UserProfileSaved(UserProfile profile, String message)
      : super(profile: profile, message: message);
}

// ── Changing password ────────────────────────────────────

class ProfilePasswordChanging extends UserProfileState {
  const ProfilePasswordChanging({super.profile});
}

class ProfilePasswordChanged extends UserProfileState {
  const ProfilePasswordChanged({super.profile})
      : super(
    message: 'Password changed successfully.',
  );
}

class ProfilePasswordFailure extends UserProfileState {
  const ProfilePasswordFailure(String message, {super.profile})
      : super(message: message, isError: true);
}

// ── Uploading photo ──────────────────────────────────────

class ProfilePhotoUploading extends UserProfileState {
  const ProfilePhotoUploading(
      double progress, {
        super.profile,
      }) : super(uploadProgress: progress);
}

class ProfilePhotoUploaded extends UserProfileState {
  const ProfilePhotoUploaded(
      UserProfile profile,
      String message,
      ) : super(profile: profile, message: message);
}

class ProfilePhotoFailure extends UserProfileState {
  const ProfilePhotoFailure(String message, {super.profile})
      : super(message: message, isError: true);
}