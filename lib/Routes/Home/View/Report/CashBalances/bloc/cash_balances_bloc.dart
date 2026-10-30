import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../Services/repository.dart';
import '../model/cash_balance_model.dart';

part 'cash_balances_event.dart';
part 'cash_balances_state.dart';

class CashBalancesBloc extends Bloc<CashBalancesEvent, CashBalancesState> {
  final Repositories _repo;
  CashBalancesBloc(this._repo) : super(CashBalancesInitial()) {

    on<LoadCashBalanceBranchWiseEvent>((event, emit) async {
      emit( CashBalancesLoadingState());

      try {
        final result = await _repo.cashBalances(
          branchId: event.branchId,
          from: event.from,
          to: event.to,
        );

        if (result == null) {
          emit(const CashBalancesErrorState(
            "No cash balance data found for this branch and date range.",
          ));
          return;
        }

        emit(CashBalancesLoadedState(result));
      } catch (e) {
        emit(CashBalancesErrorState("Failed to load cash balances: $e"));
      }
    });

    on<LoadAllCashBalancesEvent>((event, emit) async {
      emit(CashBalancesLoadingState());
      try {
        final cashList = await _repo.allCashBalances();
        emit(AllCashBalancesLoadedState(cashList));
      } catch (e) {
        emit(CashBalancesErrorState(e.toString()));
      }
    });
  }
}