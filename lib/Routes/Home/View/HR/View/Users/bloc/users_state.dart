part of 'users_bloc.dart';

sealed class UsersState extends Equatable {
  const UsersState();
}

final class UsersInitial extends UsersState {
  @override
  List<Object> get props => [];
}

final class UsersErrorState extends UsersState {
  final String message;
  const UsersErrorState(this.message);
  @override
  List<Object> get props => [message];
}

final class UsersLoadingState extends UsersState {
  @override
  List<Object> get props => [];
}

final class UserSuccessState extends UsersState {
  @override
  List<Object> get props => [];
}

final class UsersLoadedState extends UsersState {
  final List<UsersModel> users;
  const UsersLoadedState(this.users);
  @override
  List<Object> get props => [users];
}

final class UsersReportLoadedState extends UsersState {
  final List<UsersReportModel> users;
  const UsersReportLoadedState(this.users);
  @override
  List<Object> get props => [users];
}

final class UserUpdatedState extends UsersState {
  final UsersModel user;
  const UserUpdatedState(this.user);
  @override
  List<Object> get props => [user];
}

final class UserStatusToggledState extends UsersState {
  final UsersModel user;
  const UserStatusToggledState(this.user);
  @override
  List<Object> get props => [user];
}