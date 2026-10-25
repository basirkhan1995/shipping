import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/reminder_model.dart';

part 'reminder_event.dart';
part 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final Repositories _repo;
  int? _currentAlertFilter;

  ReminderBloc(this._repo) : super(ReminderInitial()) {
    // ── LOAD ────────────────────────────────────────────────────────
    on<LoadAlertReminders>((event, emit) async {
      emit(state.copyWith(loading: true, error: null, successMsg: null));
      try {
        final data = await _repo.getAlertReminders(alert: event.alert);
        _currentAlertFilter = event.alert;

        emit(state.copyWith(
          reminders: data,
          loading: false,
        ));
      } on ApiException catch (e) {
        emit(state.copyWith(loading: false, error: e.message));
      } catch (e) {
        emit(state.copyWith(loading: false, error: e.toString()));
      }
    });

    // ── ADD ────────────────────────────────────────────────────────
    on<AddReminderEvent>((event, emit) async {
      emit(state.copyWith(loading: true, error: null, successMsg: null));

      try {
        await _repo.addNewReminder(newData: event.model);

        // Reload with the current filter so the new reminder appears
        // in whichever tab is showing.
        final alertToLoad = _currentAlertFilter ?? 1;
        final data = await _repo.getAlertReminders(alert: alertToLoad);

        emit(state.copyWith(
          reminders: data,
          loading: false,
          successMsg: "Reminder Added",
        ));
      } on ApiException catch (e) {
        emit(state.copyWith(loading: false, error: e.message));
      } catch (e) {
        emit(state.copyWith(loading: false, error: e.toString()));
      }
    });

    // ── UPDATE (optimistic with rollback) ───────────────────────────
    on<UpdateReminderEvent>((event, emit) async {
      // Snapshot for rollback.
      final previous = List<ReminderModel>.from(state.reminders);

      // Step 1 — optimistic update.
      final updatedList = state.reminders
          .where((r) {
        if (r.rmdId == event.model.rmdId) {
          final isAlertFilter = (_currentAlertFilter ?? 1) == 1;
          if (isAlertFilter && event.model.rmdStatus == 1) {
            return false; // hide completed from active tab
          }
        }
        return true;
      })
          .map((r) => r.rmdId == event.model.rmdId ? event.model : r)
          .toList();

      emit(state.copyWith(
        reminders: updatedList,
        loading: true,
        error: null,
        successMsg: null,
      ));

      // Step 2 — call API.
      try {
        await _repo.updateReminder(newData: event.model);

        // Optional silent sync with the server for consistency.
        final data = await _repo.getAlertReminders(
          alert: _currentAlertFilter ?? 1,
        );

        emit(state.copyWith(reminders: data, loading: false));
      } on ApiException catch (e) {
        // Roll back the optimistic change on failure.
        emit(state.copyWith(
          reminders: previous,
          loading: false,
          error: e.message,
        ));
      } catch (e) {
        emit(state.copyWith(
          reminders: previous,
          loading: false,
          error: e.toString(),
        ));
      }
    });
  }
}