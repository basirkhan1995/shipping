import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/repository.dart';
import '../model/emp_model.dart';

part 'employee_event.dart';
part 'employee_state.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final Repositories _repo;
  EmployeeBloc(this._repo) : super(EmployeeInitial()) {
    on<LoadEmployeeEvent>((event, emit) async {
      emit(EmployeeLoadingState());
      try {
        final emp = await _repo.getEmployees(cat: event.cat);
        emit(EmployeeLoadedState(emp));
      } catch (e) {
        emit(EmployeeErrorState(e.toString()));
      }
    });

    on<AddEmployeeEvent>((event, emit) async {
      try {
        final response =
        await _repo.addEmployee(newEmployee: event.newEmployee);
        final msg = response['msg'];
        if (msg == "success") {
          emit(const EmployeeSavedState(message: 'success', isEdit: false));
        } else if (msg == "exist") {
          emit(const EmployeeErrorState("alreadyEmployed"));
        } else {
          emit(EmployeeErrorState(msg.toString()));
        }
      } catch (e) {
        emit(EmployeeErrorState(e.toString()));
      }
    });

    on<UpdateEmployeeEvent>((event, emit) async {
      try {
        final response =
        await _repo.updateEmployee(newEmployee: event.newEmployee);
        final msg = response['msg'];
        if (msg == "success") {
          emit(const EmployeeSavedState(message: 'success', isEdit: true));
        } else {
          emit(EmployeeErrorState(msg.toString()));
        }
      } catch (e) {
        emit(EmployeeErrorState(e.toString()));
      }
    });

    on<SearchEmployeesEvent>((event, emit) {
      final current = _currentList(state);
      final q = event.query.trim().toLowerCase();
      if (q.isEmpty) {
        emit(EmployeeLoadedState(current));
        return;
      }
      final filtered = current.where((e) {
        final haystack = [
          e.perName,
          e.perLastName,
          e.empEmail,
          e.perEmail,
          e.empPosition,
          e.empDepartment,
          e.perPhone,
        ].whereType<String>().join(' ').toLowerCase();
        return haystack.contains(q);
      }).toList();
      emit(EmployeeLoadedState(filtered));
    });

    on<ClearEmployeeMessagesEvent>((event, emit) {
      emit(EmployeeLoadedState(_currentList(state)));
    });
  }

  List<EmployeeModel> _currentList(EmployeeState s) {
    if (s is EmployeeLoadedState) return s.employees;
    return const [];
  }
}