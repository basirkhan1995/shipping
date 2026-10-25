import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../Services/api_exception.dart';
import '../../../Services/localization_services.dart';
import '../../../Services/repository.dart';
import '../model/user_model.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Repositories _repo;
  AuthBloc(this._repo) : super(AuthInitial()) {

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

        // Success
        final loginData = LoginData.fromMap(response);
        emit(AuthenticatedState(loginData));

      } on ApiException catch (e) {
        emit(AuthErrorState(e.toString()));
      }
    });

    on<OnLogoutEvent>((event, emit){
      emit(UnAuthenticatedState());
    });

    on<OnResetAuthState>((event, emit){
      emit(AuthInitial());
    });
  }
}
