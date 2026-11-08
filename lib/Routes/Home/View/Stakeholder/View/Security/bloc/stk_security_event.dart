part of 'stk_security_bloc.dart';

sealed class StkSecurityEvent extends Equatable {
  const StkSecurityEvent();
  @override
  List<Object?> get props => [];
}

class VerifyAdminPasswordEvent extends StkSecurityEvent {
  final int perID;
  final String username;
  final String password;

  const VerifyAdminPasswordEvent({
    required this.perID,
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [perID, username, password];
}

class RelockEvent extends StkSecurityEvent {
  final int perID;
  const RelockEvent(this.perID);
  @override
  List<Object?> get props => [perID];
}

class ClearStkSecurityErrorEvent extends StkSecurityEvent {
  const ClearStkSecurityErrorEvent();
  @override
  List<Object?> get props => [];
}