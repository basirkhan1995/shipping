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
    // ❌ NO pre-emit — the list is already on screen.
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

      final serverMsg = (res['message'] as String?)?.trim();
      final inserted  = _toInt(res['inserted']) ?? 0;
      final skipped   = _toInt(res['skipped'])  ?? 0;

      final msg = (serverMsg != null && serverMsg.isNotEmpty)
          ? serverMsg
          : (skipped > 0
          ? 'Inserted $inserted, skipped $skipped already-present.'
          : 'Inserted $inserted.');

      // ✅ Emit success FIRST so the dialog pops.
      emit(AttendanceSavedState(msg));

      // ✅ Refresh — silence any refresh failure so success isn't lost.
      try {
        final list = await _reload();
        emit(AttendanceLoadedState(list, date: _date, month: _month));
      } catch (_) {
        emit(AttendanceLoadedState(_lastList, date: _date, month: _month));
      }
    } on ApiException catch (err) {
      emit(AttendanceErrorState(err.message));
    } catch (err) {
      emit(AttendanceErrorState(err.toString()));
    }
  }

  Future<void> _onUpdate(
      UpdateAttendanceEvent e, Emitter<AttendanceState> emit) async {
    try {
      final res = await _repo.updateAttendance(
        usrName: e.usrName,
        records: e.records,
      );

      final serverMsg = (res['message'] as String?)?.trim();
      emit(AttendanceSavedState(
        (serverMsg != null && serverMsg.isNotEmpty)
            ? serverMsg
            : 'Attendance updated.',
      ));

      try {
        final list = await _reload();
        emit(AttendanceLoadedState(list, date: _date, month: _month));
      } catch (_) {
        emit(AttendanceLoadedState(_lastList, date: _date, month: _month));
      }
    } on ApiException catch (err) {
      emit(AttendanceErrorState(err.message));
    } catch (err) {
      emit(AttendanceErrorState(err.toString()));
    }
  }

  Future<void> _onDelete(
      DeleteAttendanceEvent e, Emitter<AttendanceState> emit) async {
    // ❌ NO pre-emit here either.
    try {
      final res = await _repo.deleteAttendance(
        emaID: e.emaID,
        usrName: e.usrName,
      );

      final serverMsg = (res['message'] as String?)?.trim();
      emit(AttendanceSavedState(
        (serverMsg != null && serverMsg.isNotEmpty)
            ? serverMsg
            : 'Attendance deleted.',
      ));

      try {
        final list = await _reload();
        emit(AttendanceLoadedState(list, date: _date, month: _month));
      } catch (_) {
        emit(AttendanceLoadedState(_lastList, date: _date, month: _month));
      }
    } on ApiException catch (err) {
      emit(AttendanceErrorState(err.message));
    } catch (err) {
      emit(AttendanceErrorState(err.toString()));
    }
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  void _onClear(
      ClearAttendanceMessagesEvent e, Emitter<AttendanceState> emit) {
    emit(AttendanceLoadedState(_lastList, date: _date, month: _month));
  }
}