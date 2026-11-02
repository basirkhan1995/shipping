import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/repository.dart';
import '../../../../../../../Services/api_exception.dart';
import '../model/attendance_model.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final Repositories _repo;
  String? _date;
  String? _month;
  List<AttendanceModel> _lastList = const [];

  AttendanceBloc(this._repo) : super(AttendanceInitial()) {
    on<LoadAttendanceEvent>(_onLoad);
    on<AddAttendanceEvent>(_onAdd);
    on<UpdateAttendanceEvent>(_onUpdate);
    on<DeleteAttendanceEvent>(_onDelete);
    on<ClearAttendanceMessagesEvent>(_onClear);
  }

  Future<List<AttendanceModel>> _reload() async {
    final list = await _repo.getAttendance(date: _date, month: _month);
    _lastList = list;
    return list;
  }

  Future<void> _onLoad(
      LoadAttendanceEvent e, Emitter<AttendanceState> emit) async {
    if (e.date != null) _date = e.date;
    if (e.month != null) _month = e.month;
    emit(AttendanceLoadingState());
    try {
      final list = await _reload();
      emit(AttendanceLoadedState(list, date: _date, month: _month));
    } on ApiException catch (err) {
      emit(AttendanceErrorState(err.message));
    } catch (err) {
      emit(AttendanceErrorState(err.toString()));
    }
  }

  Future<void> _onAdd(
      AddAttendanceEvent e, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoadedState(_lastList, date: _date, month: _month));
    try {
      final res = await _repo.addAttendance(
        mode: e.mode,
        usrName: e.usrName,
        emaDate: e.emaDate,
        emaEmployee: e.emaEmployee,
        emaCheckedIn: e.emaCheckedIn,
        emaCheckedOut: e.emaCheckedOut,
        emaStatus: e.emaStatus,
        records: e.records,
      );
      final skipped = (res['skipped'] as num?)?.toInt() ?? 0;
      final inserted = (res['inserted'] as num?)?.toInt() ?? 0;
      final list = await _reload();
      emit(AttendanceSavedState(
        skipped > 0
            ? 'Inserted $inserted, skipped $skipped already-present.'
            : 'Inserted $inserted.',
      ));
      emit(AttendanceLoadedState(list, date: _date, month: _month));
    } on ApiException catch (err) {
      emit(AttendanceErrorState(err.message));
    } catch (err) {
      emit(AttendanceErrorState(err.toString()));
    }
  }

  Future<void> _onUpdate(
      UpdateAttendanceEvent e, Emitter<AttendanceState> emit) async {
    try {
      await _repo.updateAttendance(usrName: e.usrName, records: e.records);
      final list = await _reload();
      emit(const AttendanceSavedState('Attendance updated.'));
      emit(AttendanceLoadedState(list, date: _date, month: _month));
    } on ApiException catch (err) {
      emit(AttendanceErrorState(err.message));
    } catch (err) {
      emit(AttendanceErrorState(err.toString()));
    }
  }

  Future<void> _onDelete(
      DeleteAttendanceEvent e, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoadedState(_lastList, date: _date, month: _month));
    try {
      await _repo.deleteAttendance(emaID: e.emaID, usrName: e.usrName);
      final list = await _reload();
      emit(const AttendanceSavedState('Attendance deleted.'));
      emit(AttendanceLoadedState(list, date: _date, month: _month));
    } on ApiException catch (err) {
      emit(AttendanceErrorState(err.message));
    } catch (err) {
      emit(AttendanceErrorState(err.toString()));
    }
  }

  void _onClear(
      ClearAttendanceMessagesEvent e, Emitter<AttendanceState> emit) {
    emit(AttendanceLoadedState(_lastList, date: _date, month: _month));
  }
}