import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/localization_services.dart';
import '../../../../../../../Services/repository.dart';
part 'stk_security_event.dart';
part 'stk_security_state.dart';

class StkSecurityBloc extends Bloc<StkSecurityEvent, StkSecurityState> {
  final Repositories _repo;

  static const Duration _defaultTtl = Duration(minutes: 5);

  Timer? _relockTimer;

  StkSecurityBloc(this._repo) : super(const StkSecurityInitial()) {
    on<VerifyAdminPasswordEvent>(_onVerify);
    on<RelockEvent>(_onRelock);
    on<ClearStkSecurityErrorEvent>(_onClearError);
  }

  // ── Public helpers (used by dialogs) ─────────────────────────

  Future<bool> verify({
    required int perID,
    required String username,
    required String password,
  }) async {
    add(VerifyAdminPasswordEvent(
      perID: perID,
      username: username,
      password: password,
    ));

    await stream.firstWhere((s) => s is StkSecurityVerifying);

    final result = await stream.firstWhere(
          (s) => s is StkSecurityVerified || s is StkSecurityDenied,
    );
    return result is StkSecurityVerified;
  }

  bool isUnlockedFor(int perID) {
    final s = state;
    return s is StkSecurityVerified &&
        s.perID == perID &&
        !s.isExpired;
  }

  // ── Handlers ─────────────────────────────────────────────────

  Future<void> _onVerify(
      VerifyAdminPasswordEvent event,
      Emitter<StkSecurityState> emit,
      ) async {
    // Capture the localization once — same pattern as AuthBloc.
    final tr = localizationService.loc;

    emit(StkSecurityVerifying(event.perID));

    try {
      final res = await _repo.unlockStakeholder(
        perID: event.perID,
        username: event.username,
        password: event.password,
      );

      if (res['ok'] != true) {
        final raw = (res['msg']?.toString() ?? '').toLowerCase();
        final err = (res['error']?.toString() ?? '').toLowerCase();

        String message;
        if (raw.contains('password') || raw.contains('invalid')) {
          message = tr.lockVerifyDeniedWrongPassword;
        } else if (raw.contains('role') || err.contains('role')) {
          message = tr.lockVerifyDeniedWrongRole;
        } else if (raw.contains('required')) {
          message = tr.lockVerifyDeniedPasswordRequired;
        } else if (raw.contains('server')) {
          message = tr.lockVerifyDeniedServerError;
        } else {
          message = tr.lockVerifyFailed;
        }

        emit(StkSecurityDenied(perID: event.perID, message: message));
        return;
      }

      final ttlSeconds = (res['unlockFor'] is int)
          ? res['unlockFor'] as int
          : _defaultTtl.inSeconds;

      final expiresAt = DateTime.now().add(Duration(seconds: ttlSeconds));

      _relockTimer?.cancel();
      if (ttlSeconds > 0) {
        _relockTimer = Timer(Duration(seconds: ttlSeconds), () {
          add(RelockEvent(event.perID));
        });
      }

      emit(StkSecurityVerified(
        perID: event.perID,
        username: event.username,
        expiresAt: expiresAt,
      ));
    } on ApiException {
      emit(StkSecurityDenied(
        perID: event.perID,
        message: tr.lockVerifyDeniedServerError,
      ));
    } catch (_) {
      emit(StkSecurityDenied(
        perID: event.perID,
        message: tr.lockVerifyDeniedNetwork,
      ));
    }
  }

  Future<void> _onRelock(
      RelockEvent event,
      Emitter<StkSecurityState> emit,
      ) async {
    _relockTimer?.cancel();
    _relockTimer = null;

    final s = state;
    if (s is StkSecurityVerified && s.perID == event.perID) {
      emit(const StkSecurityInitial());
    }
  }

  Future<void> _onClearError(
      ClearStkSecurityErrorEvent event,
      Emitter<StkSecurityState> emit,
      ) async {
    if (state is StkSecurityDenied) {
      emit(const StkSecurityInitial());
    }
  }

  @override
  Future<void> close() {
    _relockTimer?.cancel();
    _relockTimer = null;
    return super.close();
  }
}