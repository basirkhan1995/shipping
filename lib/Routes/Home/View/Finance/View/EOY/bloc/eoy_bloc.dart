import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/eoy_model.dart';

part 'eoy_event.dart';
part 'eoy_state.dart';

class EoyBloc extends Bloc<EoyEvent, EoyState> {
  final Repositories _repo;

  EoyBloc(this._repo) : super(EoyInitial()) {
    // ── LOAD P&L ────────────────────────────────────────────────────
    on<LoadPLEvent>((event, emit) async {
      emit(EoyLoadingState());
      try {
        final eoy = await _repo.getProfitAndLoss();
        emit(EoyLoadedState(eoy));
      } on ApiException catch (e) {
        emit(EoyErrorState(e.message));
      } catch (e) {
        emit(EoyErrorState(e.toString()));
      }
    });

    // ── PROCESS EOY ─────────────────────────────────────────────────
    on<ProcessPLEvent>((event, emit) async {
      emit(EoyLoadingState());

      try {
        await _repo.eoyOperationProcess(
          usrName: event.usrName,
          remark: event.remark,
          branchCode: event.branchCode,
        );

        // Success: refresh the P&L list, then let the UI react to success.
        add(LoadPLEvent());
        emit(EoySuccessState());
      } on ApiException catch (e) {
        emit(EoyErrorState(_messageFor(e)));
      } catch (e) {
        emit(EoyErrorState(e.toString()));
      }
    });
  }

  /// Maps the server's domain `code` (preferred) or `message` into a
  /// user-facing error. With Option A, the PHP returns:
  ///
  ///   { "msg": "failed", "code": "pending",  "error": "..." }
  ///   { "msg": "failed", "code": "no_record", "error": "..." }
  ///   { "msg": "failed", "error": "..." }        // unknown
  ///
  /// `ApiException.code` is populated by `ApiServices._handleError` from
  /// the response body's `code` field. If it isn't set, we fall through
  /// to `e.message`, then to the raw server message.
  String _messageFor(ApiException e) {
    switch (e.code) {
      case 'pending':
        return 'P&L closing failed. Please check pending transactions.';
      case 'no_record':
      case 'no record':
        return 'No Profit & Loss record found to proceed.';
      case 'failed':
        return 'Operation failed, try again later.';
      default:
      // Either no code, or an unexpected one — show the server's own
      // message if present, otherwise a generic fallback.
        return e.message;
    }
  }
}