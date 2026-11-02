import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shipping/Services/repository.dart';
import '../../../../../../../Services/api_exception.dart';
import '../model/emp_model.dart';

part 'employee_event.dart';
part 'employee_state.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final Repositories _repo;
  String _search = '';
  String? _cat;

  /// Last known good list — survives write-state transitions and errors.
  List<EmployeeModel> _lastList = const [];

  EmployeeBloc(this._repo) : super(EmployeeInitial()) {
    on<LoadEmployeeEvent>(_onLoad);
    on<SearchEmployeesEvent>(_onSearch);
    on<AddEmployeeEvent>(_onAdd);
    on<UpdateEmployeeEvent>(_onUpdate);
    on<DeleteEmployeeEvent>(_onDelete);
    on<ClearEmployeeMessagesEvent>(_onClearMessages);
  }

  // ── Helpers ─────────────────────────────────────────────────────
  List<EmployeeModel> get _currentList {
    final s = state;
    if (s is EmployeeLoadedState) return s.employees;
    return _lastList;
  }

  Future<List<EmployeeModel>> _reload() async {
    final list = await _repo.getEmployees(cat: _cat);
    _lastList = list;
    return list;
  }

  // ── LOAD ────────────────────────────────────────────────────────
  Future<void> _onLoad(
      LoadEmployeeEvent event,
      Emitter<EmployeeState> emit,
      ) async {
    if (event.cat != null) _cat = event.cat;
    emit(EmployeeLoadingState());
    try {
      final employees = await _repo.getEmployees(cat: _cat);
      _lastList = employees;
      emit(EmployeeLoadedState(_applySearch(employees), search: _search));
    } on ApiException catch (e) {
      emit(EmployeeErrorState(e.message));
    } catch (e) {
      emit(EmployeeErrorState(e.toString()));
    }
  }

  // ── SEARCH (local) ──────────────────────────────────────────────
  void _onSearch(
      SearchEmployeesEvent event,
      Emitter<EmployeeState> emit,
      ) {
    _search = event.query;
    emit(EmployeeLoadedState(_applySearch(_lastList), search: _search));
  }

  List<EmployeeModel> _applySearch(List<EmployeeModel> source) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((e) {
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
  }

  // ── ADD ─────────────────────────────────────────────────────────
  Future<void> _onAdd(
      AddEmployeeEvent event,
      Emitter<EmployeeState> emit,
      ) async {
    emit(EmployeeLoadingState());
    try {
      final response = await _repo.addEmployee(newEmployee: event.newEmployee);
      final msg = response['msg']?.toString().toLowerCase();

      if (msg == 'success') {
        final employees = await _reload();
        emit(EmployeeSavedState(
          message: 'Employee added successfully',
          isEdit: false,
        ));
        // Restore the visible list so the screen behind the dialog is
        // in sync when the dialog closes.
        emit(EmployeeLoadedState(_applySearch(employees), search: _search));
      } else if (msg == 'exist') {
        emit(const EmployeeErrorState('alreadyEmployed'));
      } else if (msg == 'empty') {
        emit(const EmployeeErrorState('fieldRequired'));
      } else {
        emit(EmployeeErrorState(
          response['error']?.toString() ??
              response['message']?.toString() ??
              msg ??
              'Failed to add employee',
        ));
      }
    } on ApiException catch (e) {
      emit(EmployeeErrorState(e.message));
    } catch (e) {
      emit(EmployeeErrorState(e.toString()));
    }
  }

  // ── UPDATE ──────────────────────────────────────────────────────
  Future<void> _onUpdate(
      UpdateEmployeeEvent event,
      Emitter<EmployeeState> emit,
      ) async {
    emit(EmployeeLoadingState());
    try {
      final response =
      await _repo.updateEmployee(newEmployee: event.newEmployee);
      final msg = response['msg']?.toString().toLowerCase();

      if (msg == 'success') {
        final employees = await _reload();
        emit(EmployeeSavedState(
          message: 'Employee updated successfully',
          isEdit: true,
        ));
        emit(EmployeeLoadedState(_applySearch(employees), search: _search));
      } else if (msg == 'empty') {
        emit(const EmployeeErrorState('fieldRequired'));
      } else {
        emit(EmployeeErrorState(
          response['error']?.toString() ??
              response['message']?.toString() ??
              msg ??
              'Failed to update employee',
        ));
      }
    } on ApiException catch (e) {
      emit(EmployeeErrorState(e.message));
    } catch (e) {
      emit(EmployeeErrorState(e.toString()));
    }
  }

  // ── DELETE ──────────────────────────────────────────────────────
  Future<void> _onDelete(
      DeleteEmployeeEvent event,
      Emitter<EmployeeState> emit,
      ) async {
    // Keep the list visible while the delete runs.
    emit(EmployeeLoadedState(_currentList, search: _search));
    try {
      await _repo.deleteEmployee(empId: event.empId);
      final employees = await _reload();
      emit(EmployeeSavedState(
        message: 'Employee deleted successfully',
        isEdit: true,
      ));
      emit(EmployeeLoadedState(_applySearch(employees), search: _search));
    } on ApiException catch (e) {
      // This carries the friendly `Cannot delete...` string built by
      // Repositories.deleteEmployee for `inuse` / `notfound` / `empty`.
      emit(EmployeeErrorState(e.message));
    } catch (e) {
      emit(EmployeeErrorState(e.toString()));
    }
  }

  // ── CLEAR MESSAGES ──────────────────────────────────────────────
  void _onClearMessages(
      ClearEmployeeMessagesEvent event,
      Emitter<EmployeeState> emit,
      ) {
    emit(EmployeeLoadedState(_currentList, search: _search));
  }
}