import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../../Services/api_exception.dart';
import '../../../../../../../../Services/repository.dart';
import '../model/user_profile_model.dart';
import 'user_profile_event.dart';

part 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final Repositories _repo;

  /// Cache the last successful profile so message-only transitions
  /// don't drop the loaded data.
  UserProfile? _lastProfile;

  UserProfileBloc(this._repo) : super(const UserProfileInitial()) {
    on<LoadUserProfile>(_onLoad);
    on<UpdateUserProfile>(_onUpdate);
    on<ChangeProfilePassword>(_onChangePassword);
    on<UploadProfilePhoto>(_onUploadPhoto);
    on<PhotoProgressTick>(_onProgress);          // internal event
    on<ClearProfileMessage>(_onClearMessage);
  }

  // ── Helpers ────────────────────────────────────────────

  UserProfile? get _currentProfile {
    final s = state;
    return s.profile ?? _lastProfile;
  }

  // ── LOAD ───────────────────────────────────────────────

  Future<void> _onLoad(
      LoadUserProfile event,
      Emitter<UserProfileState> emit,
      ) async {
    emit(UserProfileLoading(profile: _currentProfile));
    try {
      final profile = await _repo.getUserProfile(usrName: event.usrName);
      _lastProfile = profile;
      emit(UserProfileLoaded(profile));
    } on ApiException catch (x) {
      emit(UserProfileFailure(x.message, profile: _currentProfile));
    } catch (x) {
      emit(UserProfileFailure(x.toString(), profile: _currentProfile));
    }
  }

  // ── UPDATE DETAILS ─────────────────────────────────────

  Future<void> _onUpdate(
      UpdateUserProfile event,
      Emitter<UserProfileState> emit,
      ) async {
    emit(UserProfileSaving(profile: _currentProfile));
    try {
      final updated = await _repo.updateUserProfile(request: event.request);
      _lastProfile = updated;
      emit(UserProfileSaved(updated, 'Profile updated successfully.'));
    } on ApiException catch (x) {
      emit(UserProfileFailure(
        _translateUpdateError(x.message),
        profile: _currentProfile,
      ));
    } catch (x) {
      emit(UserProfileFailure(x.toString(), profile: _currentProfile));
    }
  }

  String _translateUpdateError(String code) {
    return switch (code) {
      'not_found'       => 'User not found.',
      'missing_usrName' => 'Username is required.',
      'invalid_json'    => 'The request could not be processed.',
      _                 => code,
    };
  }

  // ── CHANGE PASSWORD ────────────────────────────────────

  Future<void> _onChangePassword(
      ChangeProfilePassword event,
      Emitter<UserProfileState> emit,
      ) async {
    emit(ProfilePasswordChanging(profile: _currentProfile));
    try {
      await _repo.changeProfilePassword(
        usrName: event.usrName,
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );
      emit(ProfilePasswordChanged(profile: _currentProfile));
    } on ApiException catch (x) {
      emit(ProfilePasswordFailure(
        _translatePasswordError(x.message),
        profile: _currentProfile,
      ));
    } catch (x) {
      emit(ProfilePasswordFailure(
        x.toString(),
        profile: _currentProfile,
      ));
    }
  }

  String _translatePasswordError(String code) {
    return switch (code) {
      'incorrect_old_password' => 'The current password is incorrect.',
      'password_too_short'     => 'New password must be at least 6 characters.',
      'missing_fields'         => 'All password fields are required.',
      'not_found'              => 'User not found.',
      _                        => code,
    };
  }

  // ── UPLOAD PHOTO ───────────────────────────────────────
  //
  // The repo uploads multipart to `POST ?action=photo` and returns
  // `{ msg, photo }` — same shape as `uploadStakeholderPhoto`.
  // After success we re-fetch the full profile so `perPhoto` carries
  // the fresh filename (e.g. "1700123456_2.jpg") and the avatar
  // updates without a manual refresh.

  Future<void> _onUploadPhoto(
      UploadProfilePhoto event,
      Emitter<UserProfileState> emit,
      ) async {
    emit(ProfilePhotoUploading(0, profile: _currentProfile));

    try {
      // 1) Upload the bytes — server saves file + filename.
      final res = await _repo.uploadProfilePhoto(
        usrName: event.usrName,
        image: event.image,
      );

      final msg = (res['msg'] ?? '').toString().toLowerCase();
      if (msg != 'success') {
        final rawError = res['error']?.toString() ?? 'Photo upload failed';
        emit(ProfilePhotoFailure(
          _translatePhotoError(rawError),
          profile: _currentProfile,
        ));
        return;
      }

      // 2) Reload the profile so perPhoto reflects the new filename.
      final profile = await _repo.getUserProfile(usrName: event.usrName);

      _lastProfile = profile;
      emit(ProfilePhotoUploaded(profile, 'Photo updated successfully.'));

    } on ApiException catch (x) {
      emit(ProfilePhotoFailure(
        _translatePhotoError(x.message),
        profile: _currentProfile,
      ));
    } catch (x) {
      emit(ProfilePhotoFailure(
        x.toString(),
        profile: _currentProfile,
      ));
    }
  }

  /// Handles the internally-dispatched progress tick.
  /// (Registered in the constructor with `on<PhotoProgressTick>(_onProgress)`.)
  void _onProgress(
      PhotoProgressTick event,
      Emitter<UserProfileState> emit,
      ) {
    emit(ProfilePhotoUploading(
      event.progress,
      profile: _currentProfile,
    ));
  }

  /// Maps server error codes to friendly English messages.
  String _translatePhotoError(String code) {
    return switch (code) {
    // server validation
      'usrName_or_file_missing' => 'Missing username or image.',
      'invalid_image_type'      => 'Only JPEG, PNG, WebP or GIF images are allowed.',
      'file_too_large'          => 'Image must be smaller than 4 MB.',
      'empty_file'              => 'The selected file is empty.',
      'upload_error'            => 'The upload failed. Please try again.',
    // server filesystem
      'move_failed'             => 'Could not save the image. Please try again.',
      'upload_dir_not_found'    => 'Image storage folder is missing on the server.',
      'upload_dir_not_writable' => 'Image storage folder is not writable.',
    // user
      'not_found'               => 'User not found.',
    // network / generic
      'Invalid server response' => 'Unexpected response from the server.',
      _                         => code,
    };
  }

  // ── Clear one-shot message ─────────────────────────────

  Future<void> _onClearMessage(
      ClearProfileMessage event,
      Emitter<UserProfileState> emit,
      ) async {
    // Preserve the loaded profile, drop the message.
    if (state.profile != null) {
      emit(UserProfileLoaded(state.profile!));
    } else if (_lastProfile != null) {
      emit(UserProfileLoaded(_lastProfile!));
    } else {
      emit(const UserProfileInitial());
    }
  }
}