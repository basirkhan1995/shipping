part of 'attendance_bloc.dart';

sealed class AttendanceEvent extends Equatable {
  const AttendanceEvent();
}

class LoadAttendanceEvent extends AttendanceEvent {
  final String? date;
  final String? month;
  const LoadAttendanceEvent({this.date, this.month});
  @override
  List<Object?> get props => [date, month];
}

class AddAttendanceEvent extends AttendanceEvent {
  final String mode;               // 'single' | 'multiple' | 'all'
  final String usrName;
  final String emaDate;
  final int? emaEmployee;
  final String? emaCheckedIn;
  final String? emaCheckedOut;
  final String? emaStatus;
  final List<Map<String, dynamic>>? records;

  const AddAttendanceEvent({
    required this.mode,
    required this.usrName,
    required this.emaDate,
    this.emaEmployee,
    this.emaCheckedIn,
    this.emaCheckedOut,
    this.emaStatus,
    this.records,
  });

  @override
  List<Object?> get props => [
    mode,
    usrName,
    emaDate,
    emaEmployee,
    emaCheckedIn,
    emaCheckedOut,
    emaStatus,
    records,
  ];
}

class UpdateAttendanceEvent extends AttendanceEvent {
  final String usrName;
  final List<Map<String, dynamic>> records;
  const UpdateAttendanceEvent({required this.usrName, required this.records});
  @override
  List<Object?> get props => [usrName, records];
}

class DeleteAttendanceEvent extends AttendanceEvent {
  final int emaID;
  final String? usrName;
  const DeleteAttendanceEvent(this.emaID, {this.usrName});
  @override
  List<Object?> get props => [emaID, usrName];
}

class ClearAttendanceMessagesEvent extends AttendanceEvent {
  const ClearAttendanceMessagesEvent();
  @override
  List<Object?> get props => [];
}