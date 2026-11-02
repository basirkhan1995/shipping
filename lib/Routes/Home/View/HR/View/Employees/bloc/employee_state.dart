part of 'employee_bloc.dart';

sealed class EmployeeState extends Equatable {
  const EmployeeState();
}

final class EmployeeInitial extends EmployeeState {
  @override
  List<Object> get props => [];
}

final class EmployeeLoadingState extends EmployeeState {
  @override
  List<Object> get props => [];
}

final class EmployeeLoadedState extends EmployeeState {
  final List<EmployeeModel> employees;
  const EmployeeLoadedState(this.employees);
  @override
  List<Object> get props => [employees];
}

/// Emitted when add/update succeeds — dialog closes, view refreshes.
final class EmployeeSavedState extends EmployeeState {
  final String message;
  final bool isEdit;
  const EmployeeSavedState({required this.message, required this.isEdit});
  @override
  List<Object> get props => [message, isEdit];
}

final class EmployeeErrorState extends EmployeeState {
  final String message;
  const EmployeeErrorState(this.message);
  @override
  List<Object> get props => [message];
}