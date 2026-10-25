part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
}

class LoginEvent extends AuthEvent{
  final String usrName;
  final String usrPassword;
  final bool rememberMe;
  const LoginEvent({required this.usrName, required this.usrPassword, required this.rememberMe});

  @override
  List<Object?> get props => [usrName, usrPassword];
}

// class OnProfileUpdateEvent extends AuthEvent{
//   final CompanySettingsModel newProfile;
//   const OnProfileUpdateEvent(this.newProfile);
//   @override
//   List<Object?> get props => [newProfile];
// }

class OnLogoChangeEvent extends AuthEvent{
  @override
  List<Object?> get props => [];
}

class OnLogoutEvent extends AuthEvent{
  @override
  List<Object?> get props => [];
}


class OnResetAuthState extends AuthEvent{
  @override
  List<Object?> get props => [];
}

