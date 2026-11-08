part of 'stk_security_bloc.dart';

sealed class StkSecurityState extends Equatable {
  const StkSecurityState();
  @override
  List<Object?> get props => [];
}

class StkSecurityInitial extends StkSecurityState {
  const StkSecurityInitial();
  @override
  List<Object?> get props => [];
}

class StkSecurityVerifying extends StkSecurityState {
  final int perID;
  const StkSecurityVerifying(this.perID);
  @override
  List<Object?> get props => [perID];
}

class StkSecurityVerified extends StkSecurityState {
  final int perID;
  final String username;
  final DateTime expiresAt;

  const StkSecurityVerified({
    required this.perID,
    required this.username,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [perID, username, expiresAt];
}

class StkSecurityDenied extends StkSecurityState {
  final int perID;
  final String message;

  const StkSecurityDenied({
    required this.perID,
    required this.message,
  });

  @override
  List<Object?> get props => [perID, message];
}