
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/ex_model.dart';

part 'exchange_event.dart';
part 'exchange_state.dart';

class ExchangeBloc extends Bloc<ExchangeEvent, ExchangeState> {
  final Repositories _repo;

  /// Replayed after a successful delete so filters survive.
  LoadExchangesEvent? _lastLoad;

  ExchangeBloc(this._repo) : super(ExchangeInitial()) {
    // ── Load list ─────────────────────────────────────────
    on<LoadExchangesEvent>((event, emit) async {
      _lastLoad = event;

      final before = state is ExchangeListLoaded
          ? (state as ExchangeListLoaded).rows
          : const <ExchangeListItem>[];

      emit(ExchangeLoading(previous: before));

      try {
        final rows = await _repo.getExchangeList(
          state: event.state,
          search: event.search,
        );
        emit(ExchangeListLoaded(rows));
      } on ApiException catch (e) {
        if (before.isNotEmpty) {
          emit(ExchangeListLoaded(before));
        }
        emit(ExchangeError(e.message));
      } catch (e) {
        if (before.isNotEmpty) {
          emit(ExchangeListLoaded(before));
        }
        emit(ExchangeError(e.toString()));
      }
    });

    // ── Load single ───────────────────────────────────────
    on<LoadExchangeDetailEvent>((event, emit) async {
      emit(const ExchangeLoading());
      try {
        final detail =
        await _repo.getExchangeByReference(reference: event.reference);
        emit(ExchangeDetailLoaded(detail));
      } on ApiException catch (e) {
        emit(ExchangeError(e.message));
      } catch (e) {
        emit(ExchangeError(e.toString()));
      }
    });

    // ── Add ───────────────────────────────────────────────
    on<AddExchangeEvent>((event, emit) async {
      emit(const ExchangeSubmitting());
      try {
        final ref = await _repo.addExchangeTransfer(
          usrName: event.usrName,
          debit: event.debit,
          credit: event.credit,
        );
        emit(ExchangeSubmitSuccess(
          'Exchange transfer created.',
          reference: ref,
        ));
      } on ApiException catch (e) {
        emit(ExchangeError(e.message));
      } catch (e) {
        emit(ExchangeError(e.toString()));
      }
    });

    // ── Edit ──────────────────────────────────────────────
    on<EditExchangeEvent>((event, emit) async {
      emit(const ExchangeSubmitting());
      try {
        await _repo.editExchangeTransfer(
          reference: event.reference,
          usrName: event.usrName,
          debit: event.debit,
          credit: event.credit,
        );
        emit(ExchangeSubmitSuccess(
          'Exchange transfer updated.',
          reference: event.reference,
        ));
      } on ApiException catch (e) {
        emit(ExchangeError(e.message));
      } catch (e) {
        emit(ExchangeError(e.toString()));
      }
    });

    // ── Delete (soft, row-level) ──────────────────────────
    on<DeleteExchangeEvent>((event, emit) async {
      final current = state;
      if (current is ExchangeListLoaded) {
        emit(current.copyWith(
          actionInProgress: event.reference,
          clearActionError: true,
          clearActionSuccess: true,
        ));
      } else {
        emit(const ExchangeSubmitting());
      }

      try {
        await _repo.deleteExchangeTransfer(
          reference: event.reference,
          usrName: event.usrName,
        );

        final after = state;
        if (after is ExchangeListLoaded) {
          emit(after.copyWith(
            clearActionInProgress: true,
            actionSuccess: 'Exchange transfer deleted.',
          ));
        } else {
          emit(const ExchangeSubmitSuccess('Exchange transfer deleted.'));
        }

        _reload();
      } on ApiException catch (e) {
        _rowError(emit, e.message);
      } catch (e) {
        _rowError(emit, e.toString());
      }
    });

    // ── Banner clearers ───────────────────────────────────
    on<ClearExchangeErrorEvent>((_, emit) {
      final s = state;
      if (s is ExchangeListLoaded && s.actionError != null) {
        emit(s.copyWith(clearActionError: true));
      }
    });

    on<ClearExchangeSuccessEvent>((_, emit) {
      final s = state;
      if (s is ExchangeListLoaded && s.actionSuccess != null) {
        emit(s.copyWith(clearActionSuccess: true));
      }
    });
  }

  void _reload() {
    final last = _lastLoad;
    if (last != null) {
      add(LoadExchangesEvent(
        state: last.state,
        search: last.search,
      ));
    }
  }

  void _rowError(Emitter<ExchangeState> emit, String message) {
    final after = state;
    if (after is ExchangeListLoaded) {
      emit(after.copyWith(
        clearActionInProgress: true,
        actionError: message,
      ));
    } else {
      emit(ExchangeError(message));
    }
  }
}