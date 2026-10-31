// lib/features/fund_transfer/bloc/fund_transfer_bloc.dart
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
        final detail = await _repo.getFundTransferByReference(
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
        final ref = await _repo.addFundTransfer(
          usrName: event.usrName,
          fromAccount: event.fromAccount,
          fromAccCcy: event.fromAccCcy,
          toAccount: event.toAccount,
          toAccCcy: event.toAccCcy,
          amount: event.amount,
          narration: event.narration,
        );
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
        await _repo.editFundTransfer(
          reference: event.reference,
          usrName: event.usrName,
          fromAccount: event.fromAccount,
          fromAccCcy: event.fromAccCcy,
          toAccount: event.toAccount,
          toAccCcy: event.toAccCcy,
          amount: event.amount,
          narration: event.narration,
        );
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
        await _repo.deleteFundTransfer(
          reference: event.reference,
          usrName: event.usrName,
        );

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