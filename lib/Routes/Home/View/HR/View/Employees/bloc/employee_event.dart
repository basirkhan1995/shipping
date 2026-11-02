part of 'employee_bloc.dart';

sealed class EmployeeEvent extends Equatable {
  const EmployeeEvent();
}

class LoadEmployeeEvent extends EmployeeEvent {
  final String? cat;
  const LoadEmployeeEvent({this.cat});
  @override
  List<Object?> get props => [cat];
}

class AddEmployeeEvent extends EmployeeEvent {
  final EmployeeModel newEmployee;
  const AddEmployeeEvent(this.newEmployee);
  @override
  List<Object?> get props => [newEmployee];
}

class UpdateEmployeeEvent extends EmployeeEvent {
  final EmployeeModel newEmployee;
  const UpdateEmployeeEvent(this.newEmployee);
  @override
  List<Object?> get props => [newEmployee];
}

class SearchEmployeesEvent extends EmployeeEvent {
  final String query;
  const SearchEmployeesEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class ClearEmployeeMessagesEvent extends EmployeeEvent {
  const ClearEmployeeMessagesEvent();
  @override
  List<Object?> get props => [];
}