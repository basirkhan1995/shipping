import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/trn_model.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final Repositories _repo;

  TransactionsBloc(this._repo) : super(TransactionsInitial()) {
    on<LoadTransactionsEvent>((event, emit) async {
      final before = state is TransactionsLoadedState
          ? (state as TransactionsLoadedState).rows
          : const <TransactionListItem>[];

      emit(TransactionsLoadingState(previous: before));

      try {
        final body = await _repo.getTransactions(
          status: event.status!,
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
  }
}