part of 'user_log_bloc.dart';

sealed class UserLogEvent extends Equatable {
  const UserLogEvent();
}

class LoadUserLogEvent extends UserLogEvent{
  final String? usrName;
  final String? fromDate;
  final String? toDate;
  const LoadUserLogEvent({this.usrName, this.fromDate, this.toDate});

  @override
  List<Object?> get props => [usrName, fromDate, toDate];
}

class ResetUserLogEvent extends UserLogEvent{
  @override
  List<Object?> get props => [];
}