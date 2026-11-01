part of 'user_log_bloc.dart';

sealed class UserLogState extends Equatable {
  const UserLogState();
}

final class UserLogInitial extends UserLogState {
  @override
  List<Object> get props => [];
}
final class UserLogLoadingState extends UserLogState {
  @override
  List<Object> get props => [];
}
final class UserLogErrorState extends UserLogState {
  final String error;
  const UserLogErrorState(this.error);
  @override
  List<Object> get props => [error];
}
final class UserLogLoadedState extends UserLogState {
  final List<UserLogModel> log;
  const UserLogLoadedState(this.log);
  @override
  List<Object> get props => [log];
}

