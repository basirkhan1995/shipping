import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/trn_model.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final Repositories _repo;

  /// The last load the caller dispatched. Replayed after a successful
  /// row action so the current filters (status/date/type/search) survive
  /// the reload. Without this, authorizing a row would silently reset
  /// the list to "all".
  LoadTransactionsEvent? _lastLoad;

  TransactionsBloc(this._repo) : super(TransactionsInitial()) {
    // ── Load ────────────────────────────────────────────────────
    on<LoadTransactionsEvent>((event, emit) async {
      _lastLoad = event;

      final before = state is TransactionsLoadedState
          ? (state as TransactionsLoadedState).rows
          : const <TransactionListItem>[];

      emit(TransactionsLoadingState(previous: before));

      try {
        final body = await _repo.getTransactions(
          status: event.status ?? 'all',
          from: event.from,
          to: event.to,
          type: event.type,
          branch: event.branch,
          search: event.search,
        );

        final list = (body['data'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TransactionListItem.fromMap)
            .toList();
        final total = body['total'] is num
            ? (body['total'] as num).toInt()
            : list.length;

        emit(TransactionsLoadedState(list, total: total));
      } on ApiException catch (e) {
        if (before.isNotEmpty) {
          emit(TransactionsLoadedState(before, total: before.length));
        }
        emit(TransactionsErrorState(e.message));
      } catch (e) {
        if (before.isNotEmpty) {
          emit(TransactionsLoadedState(before, total: before.length));
        }
        emit(TransactionsErrorState(e.toString()));
      }
    });

    // ── Row actions ─────────────────────────────────────────────
    on<AuthorizeTransactionEvent>(_onAuthorize);
    on<UnauthorizeTransactionEvent>(_onUnauthorize);
    on<ReverseTransactionEvent>(_onReverse);
    on<DeleteTransactionEvent>(_onDelete);
    on<ClearRowActionErrorEvent>(_onClearError);
    on<ClearRowActionSuccessEvent>(_onClearSuccess);
  }

  // ══════════════════════════════════════════════════════════════
  // Row action handlers — each just delegates to _runRowAction.
  // ══════════════════════════════════════════════════════════════

  Future<void> _onAuthorize(
      AuthorizeTransactionEvent e,
      Emitter<TransactionsState> emit,
      ) =>
      _runRowAction(
        emit: emit,
        reference: e.reference,
        action: () => _repo.authorizeTxn(
          reference: e.reference,
          usrName: e.userName,
        ),
        successMessage: 'Transaction authorized.',
      );

  Future<void> _onUnauthorize(
      UnauthorizeTransactionEvent e,
      Emitter<TransactionsState> emit,
      ) =>
      _runRowAction(
        emit: emit,
        reference: e.reference,
        action: () => _repo.unAuthorizeTxn(
          reference: e.reference,
          usrName: e.userName,
        ),
        successMessage: 'Transaction unauthorized.',
      );

  Future<void> _onReverse(
      ReverseTransactionEvent e,
      Emitter<TransactionsState> emit,
      ) =>
      _runRowAction(
        emit: emit,
        reference: e.reference,
        action: () => _repo.reverseTxn(
          reference: e.reference,
          usrName: e.userName,
        ),
        successMessage: 'Transaction reversed.',
      );

  Future<void> _onDelete(
      DeleteTransactionEvent e,
      Emitter<TransactionsState> emit,
      ) =>
      _runRowAction(
        emit: emit,
        reference: e.reference,
        action: () => _repo.deleteBulkTransfer(
          reference: e.reference,
          userName: e.userName ?? '',
        ),
        successMessage: 'Transaction deleted.',
      );

  void _onClearError(
      ClearRowActionErrorEvent _,
      Emitter<TransactionsState> emit,
      ) {
    final s = state;
    if (s is TransactionsLoadedState && s.actionError != null) {
      emit(s.copyWith(clearActionError: true));
    }
  }

  void _onClearSuccess(
      ClearRowActionSuccessEvent _,
      Emitter<TransactionsState> emit,
      ) {
    final s = state;
    if (s is TransactionsLoadedState && s.actionSuccess != null) {
      emit(s.copyWith(clearActionSuccess: true));
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Shared helper: drives the busy flag, the reload, the error
  // banner, and the success toast for all four actions.
  // ══════════════════════════════════════════════════════════════

  Future<void> _runRowAction({
    required Emitter<TransactionsState> emit,
    required String reference,
    required Future<Map<String, dynamic>> Function() action,
    required String successMessage,
  }) async {
    final s = state;
    if (s is! TransactionsLoadedState) return;

    // 1. Mark this row as busy, clear any previous banner / toast.
    emit(s.copyWith(
      actionInProgress: reference,
      clearActionError: true,
      clearActionSuccess: true,
    ));

    try {
      await action();

      // 2. Success. Clear the busy flag and surface a success message.
      final after = state;
      if (after is TransactionsLoadedState) {
        emit(after.copyWith(
          clearActionInProgress: true,
          actionSuccess: successMessage,
        ));
      }

      // 3. Reload the list — replay the last load so filters survive.
      final last = _lastLoad;
      if (last != null) {
        add(LoadTransactionsEvent(
          status: last.status,
          from: last.from,
          to: last.to,
          type: last.type,
          branch: last.branch,
          search: last.search,
        ));
      }
    } on ApiException catch (x) {
      final after = state;
      if (after is TransactionsLoadedState) {
        emit(after.copyWith(
          clearActionInProgress: true,
          actionError: x.message,
        ));
      }
    } catch (x) {
      final after = state;
      if (after is TransactionsLoadedState) {
        emit(after.copyWith(
          clearActionInProgress: true,
          actionError: x.toString(),
        ));
      }
    }
  }
}