part of 'password_bloc.dart';

sealed class PasswordEvent extends Equatable {
  const PasswordEvent();
}

class ForceChangePasswordEvent extends PasswordEvent {
  final String credential;
  final String newPassword;

  const ForceChangePasswordEvent({
    required this.credential,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [credential, newPassword];
}

class ChangePasswordEvent extends PasswordEvent {
  final String usrName;
  final String oldPassword;
  final String newPassword;

  const ChangePasswordEvent({
    required this.usrName,
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [usrName, oldPassword, newPassword];
}

class ResetPasswordEvent extends PasswordEvent {
  final String credential;
  final String newPassword;

  const ResetPasswordEvent({
    required this.credential,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [credential, newPassword];
}