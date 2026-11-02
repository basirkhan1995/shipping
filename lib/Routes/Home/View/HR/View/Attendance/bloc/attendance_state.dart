part of 'attendance_bloc.dart';

sealed class AttendanceState extends Equatable {
  const AttendanceState();
  @override
  List<Object?> get props => [];
}

final class AttendanceInitial extends AttendanceState {}

final class AttendanceLoadingState extends AttendanceState {}

final class AttendanceLoadedState extends AttendanceState {
  final List<AttendanceModel> records;
  final String? date;
  final String? month;
  const AttendanceLoadedState(this.records, {this.date, this.month});
  @override
  List<Object?> get props => [records, date, month];
}

final class AttendanceSavedState extends AttendanceState {
  final String message;
  const AttendanceSavedState(this.message);
  @override
  List<Object?> get props => [message];
}

final class AttendanceErrorState extends AttendanceState {
  final String message;
  const AttendanceErrorState(this.message);
  @override
  List<Object?> get props => [message];
}