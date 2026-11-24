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
        final rows = await _repo.getExchangeTxn(
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
        await _repo.getExchangeTxnByRef(reference: event.reference);
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
        final body = await _repo.addExchangeTxn(
          usrName: event.usrName,
          debit: event.debit,
          credit: event.credit,
        );

        final errorText = _exchangeMsgError(body);
        if (errorText != null) {
          emit(ExchangeError(errorText));
          return;
        }

        final ref = body['reference']?.toString() ?? '';
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
        final body = await _repo.editExchangeTxn(
          reference: event.reference,
          usrName: event.usrName,
          debit: event.debit,
          credit: event.credit,
        );

        final errorText = _exchangeMsgError(body);
        if (errorText != null) {
          emit(ExchangeError(errorText));
          return;
        }

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
        final body = await _repo.deleteExchangeTxn(
          reference: event.reference,
          usrName: event.usrName,
        );

        final errorText = _exchangeMsgError(body);
        if (errorText != null) {
          _rowError(emit, errorText);
          return;
        }

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

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

  /// Returns null if `msg` is empty or 'success' (i.e. no error).
  /// Otherwise returns a user-friendly message derived from the body.
  String? _exchangeMsgError(Map<String, dynamic> body) {
    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg.isEmpty || msg == 'success') return null;

    // Prefer an explicit server-provided error text if present.
    final serverErr = body['error']?.toString();
    if (serverErr != null && serverErr.isNotEmpty) return serverErr;

    return switch (msg) {
      'empty' => 'Please fill in all fields.',
      'same_account' => 'Debit and credit accounts must be different.',
      'same_ccy' => 'Exchange requires two different currencies.',
      'ccy_mismatch' => 'Leg currency does not match the account currency.',
      'blocked' => 'One of the accounts is blocked.',
      'no_limit' => 'The account has exceeded its credit limit.',
      'not_found' => 'Exchange transfer not found.',
      'invalid_type' => 'This reference is not an exchange transfer.',
      'invalid_action' => 'Only Pending exchange transfers can be modified.',
      'invalid' => 'Only the maker can perform this action.',
      'invalid_legs' =>
      'An exchange needs exactly one debit and one credit leg.',
      'invalid_user' => 'Invalid user.',
      'failed' => 'The exchange transfer could not be processed.',
      _ => 'Exchange transfer failed.',
    };
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
      emit(after.copyWith(clearActionInProgress: true, actionError: message));
    } else {
      emit(ExchangeError(message));
    }
  }
}