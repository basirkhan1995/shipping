import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../Services/api_exception.dart';
import '../../../Services/api_services.dart';
import '../../../Services/localization_services.dart';
import '../../../Services/repository.dart';
import '../model/user_model.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Repositories _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    // ── Startup restore ─────────────────────────────────────────
    on<RestoreSessionEvent>((event, emit) async {
      final session = await _repo.readSession();
      if (session == null) return; // stay AuthInitial

      try {
        ApiServices.setAuthToken(session.token);
        final loginData = LoginData.fromMap(session.loginData);
        emit(AuthenticatedState(loginData));

        // ── Fetch the full profile immediately so `comLogo` (which was
        //    trimmed from the session blob) comes back as a `data:` URL.
        //    The widget renders the cached image from there.
        if (loginData.usrName != null) {
          add(RefreshProfileEvent(loginData.usrName!));
        }
      } catch (_) {
        ApiServices.setAuthToken(null);
        await _repo.clearSession();
      }
    });

    // ── Login ───────────────────────────────────────────────────
    on<LoginEvent>((event, emit) async {
      final tr = localizationService.loc;
      emit(AuthLoadingState());

      try {
        final response = await _repo.login(
          username: event.usrName,
          password: event.usrPassword,
        );

        if (response.containsKey("msg") && response["msg"] != null) {
          final String result = response["msg"];

          switch (result) {
            case "incorrect":
              emit(AuthErrorState(tr.incorrectCredential));
              return;
            case "blocked":
              emit(AuthErrorState("blockedMessage"));
              return;
            case "unverified":
              emit(AuthErrorState("unverified"));
              return;
            case "fcp":
              emit(ForceChangePasswordState());
              return;
            case "nosub":
              emit(NoSubscriptionState());
              return;
            case "fev":
              emit(EmailVerificationState());
              return;
            default:
              emit(AuthErrorState(result));
              return;
          }
        }

        final loginData = LoginData.fromMap(response);
        ApiServices.setAuthToken(loginData.token);

        if (event.rememberMe) {
          await _repo.saveSession(loginData: response);
        } else {
          await _repo.clearSession();
        }

        // Emit the ORIGINAL response — includes the `data:` URL logo.
        emit(AuthenticatedState(loginData));
      } on ApiException catch (e) {
        emit(AuthErrorState(e.toString()));
      }
    });

    // ── Profile refresh ─────────────────────────────────────────
    on<RefreshProfileEvent>((event, emit) async {
      final current = state;
      if (current is! AuthenticatedState) return;

      try {
        final response = await _repo.fetchProfile(username: event.username);

        final msg = response['msg']?.toString().toLowerCase() ?? '';
        if (msg.isNotEmpty && msg != 'success') {
          switch (msg) {
            case 'incorrect':
            case 'username required':
            case 'unauthenticated':
              ApiServices.setAuthToken(null);
              await _repo.clearSession();
              emit(UnAuthenticatedState());
              return;
            default:
              return;
          }
        }

        final refreshed = LoginData.fromMap(response);
        emit(AuthenticatedState(refreshed));

        // Preserve the stored token — profile endpoint doesn't echo it.
        final stored = await _repo.readSession();
        if (stored != null) {
          final merged = Map<String, dynamic>.from(response);
          merged['token'] = stored.token;
          await _repo.saveSession(loginData: merged);
        }
      } on ApiException {
        return;
      }
    });

    // ── Logout ─────────────────────────────────────────────────
    on<OnLogoutEvent>((event, emit) async {
      ApiServices.setAuthToken(null);
      await _repo.clearSession();
      emit(UnAuthenticatedState());
    });

    on<OnResetAuthState>((event, emit) async {
      ApiServices.setAuthToken(null);
      await _repo.clearSession();
      emit(AuthInitial());
    });
  }
}