import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/ft_model.dart';

part 'fund_transfer_event.dart';
part 'fund_transfer_state.dart';

class FundTransferBloc extends Bloc<FundTransferEvent, FundTransferState> {
  final Repositories _repo;

  /// Replayed after a successful delete so filters/search survive.
  LoadFundTransfersEvent? _lastLoad;

  FundTransferBloc(this._repo) : super(FundTransferInitial()) {
    // ── Load list ─────────────────────────────────────────
    on<LoadFundTransfersEvent>((event, emit) async {
      _lastLoad = event;

      final before = state is FundTransferListLoaded
          ? (state as FundTransferListLoaded).rows
          : const <FundTransferListItem>[];

      emit(FundTransferLoading(previous: before));

      try {
        final rows = await _repo.getFundTransfers(
          state: event.state,
          search: event.search,
        );
        emit(FundTransferListLoaded(rows));
      } on ApiException catch (e) {
        if (before.isNotEmpty) {
          emit(FundTransferListLoaded(before));
        }
        emit(FundTransferError(e.message));
      } catch (e) {
        if (before.isNotEmpty) {
          emit(FundTransferListLoaded(before));
        }
        emit(FundTransferError(e.toString()));
      }
    });

    // ── Load single ───────────────────────────────────────
    on<LoadFundTransferDetailEvent>((event, emit) async {
      emit(const FundTransferLoading());
      try {
        final detail = await _repo.getFundTransferByRef(
          reference: event.reference,
        );
        emit(FundTransferDetailLoaded(detail));
      } on ApiException catch (e) {
        emit(FundTransferError(e.message));
      } catch (e) {
        emit(FundTransferError(e.toString()));
      }
    });

    // ── Add ───────────────────────────────────────────────
    on<AddFundTransferEvent>((event, emit) async {
      emit(const FundTransferSubmitting());
      try {
        final body = await _repo.addFundTransfer(
          usrName: event.usrName,
          fromAccount: event.fromAccount,
          fromAccCcy: event.fromAccCcy,
          toAccount: event.toAccount,
          toAccCcy: event.toAccCcy,
          amount: event.amount,
          narration: event.narration,
        );

        final errorText = _ftMsgError(body);
        if (errorText != null) {
          emit(FundTransferError(errorText));
          return;
        }

        final ref = body['reference']?.toString() ?? '';
        emit(FundTransferSubmitSuccess(
          'Fund transfer created.',
          reference: ref,
        ));
      } on ApiException catch (e) {
        emit(FundTransferError(e.message));
      } catch (e) {
        emit(FundTransferError(e.toString()));
      }
    });

    // ── Edit ──────────────────────────────────────────────
    on<EditFundTransferEvent>((event, emit) async {
      emit(const FundTransferSubmitting());
      try {
        final body = await _repo.editFundTransfer(
          reference: event.reference,
          usrName: event.usrName,
          fromAccount: event.fromAccount,
          fromAccCcy: event.fromAccCcy,
          toAccount: event.toAccount,
          toAccCcy: event.toAccCcy,
          amount: event.amount,
          narration: event.narration,
        );

        final errorText = _ftMsgError(body);
        if (errorText != null) {
          emit(FundTransferError(errorText));
          return;
        }

        emit(FundTransferSubmitSuccess(
          'Fund transfer updated.',
          reference: event.reference,
        ));
      } on ApiException catch (e) {
        emit(FundTransferError(e.message));
      } catch (e) {
        emit(FundTransferError(e.toString()));
      }
    });

    // ── Delete (soft, row-level) ──────────────────────────
    on<DeleteFundTransferEvent>((event, emit) async {
      final current = state;
      if (current is FundTransferListLoaded) {
        emit(current.copyWith(
          actionInProgress: event.reference,
          clearActionError: true,
          clearActionSuccess: true,
        ));
      } else {
        emit(const FundTransferSubmitting());
      }

      try {
        final body = await _repo.deleteFundTransfer(
          reference: event.reference,
          usrName: event.usrName,
        );

        final errorText = _ftMsgError(body);
        if (errorText != null) {
          _rowError(emit, errorText);
          return;
        }

        final after = state;
        if (after is FundTransferListLoaded) {
          emit(after.copyWith(
            clearActionInProgress: true,
            actionSuccess: 'Fund transfer deleted.',
          ));
        } else {
          emit(const FundTransferSubmitSuccess('Fund transfer deleted.'));
        }

        _reload();
      } on ApiException catch (e) {
        _rowError(emit, e.message);
      } catch (e) {
        _rowError(emit, e.toString());
      }
    });

    // ── Banner clearers ───────────────────────────────────
    on<ClearFundTransferErrorEvent>((_, emit) {
      final s = state;
      if (s is FundTransferListLoaded && s.actionError != null) {
        emit(s.copyWith(clearActionError: true));
      }
    });

    on<ClearFundTransferSuccessEvent>((_, emit) {
      final s = state;
      if (s is FundTransferListLoaded && s.actionSuccess != null) {
        emit(s.copyWith(clearActionSuccess: true));
      }
    });
  }

  // ══════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════

  /// Returns null if `msg` is empty or 'success' (no error).
  /// Otherwise returns a user-friendly message.
  ///
  /// Codes are the union of add/edit/delete responses; unknown codes fall
  /// back to the server's `error` field, then a generic message.
  String? _ftMsgError(Map<String, dynamic> body) {
    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg.isEmpty || msg == 'success') return null;

    final serverErr = body['error']?.toString();
    if (serverErr != null && serverErr.isNotEmpty) return serverErr;

    return switch (msg) {
      'empty' => 'Please fill in all fields.',
      'same_account' => 'From and To accounts must be different.',
      'currency_unmatch' =>
      'From and To accounts must share the same currency.',
      'blocked' => 'One of the accounts is blocked.',
      'no_limit' => 'The account has exceeded its credit limit.',
      'invalid_user' => 'Invalid user.',
      'not_found' => 'Fund transfer not found.',
      'invalid_type' => 'This reference is not a fund transfer.',
      'invalid_action' => 'This action is not allowed for this transfer.',
      'invalid' => 'Only the maker can perform this action.',
      'missing_ref' => 'Missing reference.',
      'failed' => 'The fund transfer operation could not be completed.',
      _ => 'Fund transfer operation failed.',
    };
  }

  void _reload() {
    final last = _lastLoad;
    if (last != null) {
      add(LoadFundTransfersEvent(
        state: last.state,
        search: last.search,
      ));
    }
  }

  void _rowError(Emitter<FundTransferState> emit, String message) {
    final after = state;
    if (after is FundTransferListLoaded) {
      emit(after.copyWith(
        clearActionInProgress: true,
        actionError: message,
      ));
    } else {
      emit(FundTransferError(message));
    }
  }
}