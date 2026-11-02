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
  final String search;
  const EmployeeLoadedState(this.employees, {this.search = ''});
  @override
  List<Object> get props => [employees, search];
}

/// Emitted after a successful add / update / delete.
/// Used by the dialog to close and by the view listener to toast + refresh.
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