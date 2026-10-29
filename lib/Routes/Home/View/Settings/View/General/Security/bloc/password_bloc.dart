import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../../Services/api_exception.dart';
import '../../../../../../../../Services/repository.dart';

part 'password_event.dart';
part 'password_state.dart';

class PasswordBloc extends Bloc<PasswordEvent, PasswordState> {
  final Repositories _repo;

  PasswordBloc(this._repo) : super(PasswordInitial()) {
    on<ForceChangePasswordEvent>(_onForceChangePassword);
    on<ChangePasswordEvent>(_onChangePassword);
    on<ResetPasswordEvent>(_onResetPassword);
  }

  // ── FORCE CHANGE (no old password) ───────────────────

  Future<void> _onForceChangePassword(
      ForceChangePasswordEvent event,
      Emitter<PasswordState> emit,
      ) async {
    emit(PasswordLoadingState());
    try {
      await _repo.forceChangePassword(
        credential: event.credential,
        newPassword: event.newPassword,
      );
      emit(PasswordChangedSuccessState());
    } on ApiException catch (e) {
      emit(PasswordErrorState(e.message));
    } catch (e) {
      emit(PasswordErrorState(e.toString()));
    }
  }

  // ── CHANGE (old + new) ───────────────────────────────

  Future<void> _onChangePassword(
      ChangePasswordEvent event,
      Emitter<PasswordState> emit,
      ) async {
    // final locale = localizationService.loc;
    emit(PasswordLoadingState());
    try {
      await _repo.changePassword(
        credential: event.usrName,
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );
      emit(PasswordChangedSuccessState());
    } on ApiException catch (e) {
      // The repository throws ApiException('incorrect') when the
      // backend replies with {"msg":"incorrect"}. Localize it.
      if (e.message.toLowerCase() == 'incorrect') {
        emit(PasswordErrorState("oldPasswordIncorrect"));
        return;
      }
      emit(PasswordErrorState(e.message));
    } catch (e) {
      emit(PasswordErrorState(e.toString()));
    }
  }

  // ── RESET (admin-forced new password) ────────────────

  Future<void> _onResetPassword(
      ResetPasswordEvent event,
      Emitter<PasswordState> emit,
      ) async {
    emit(PasswordLoadingState());
    try {
      await _repo.resetPassword(
        credential: event.credential,
        newPassword: event.newPassword,
      );
      emit(PasswordChangedSuccessState());
    } on ApiException catch (e) {
      emit(PasswordErrorState(e.message));
    } catch (e) {
      emit(PasswordErrorState(e.toString()));
    }
  }
}