
part of 'cash_balances_bloc.dart';

sealed class CashBalancesState extends Equatable {
  const CashBalancesState();
}

final class CashBalancesInitial extends CashBalancesState {
  @override
  List<Object> get props => [];
}

final class CashBalancesLoadingState extends CashBalancesState {
  @override
  List<Object> get props => [];
}

final class CashBalancesErrorState extends CashBalancesState {
  final String error;
  const CashBalancesErrorState(this.error);
  @override
  List<Object> get props => [error];
}

final class CashBalancesLoadedState extends CashBalancesState {
  final CashBalancesModel cash;
  const CashBalancesLoadedState(this.cash);
  @override
  List<Object> get props => [cash];
}

final class AllCashBalancesLoadedState extends CashBalancesState {
  final List<CashBalancesModel> cashList;
  const AllCashBalancesLoadedState(this.cashList);
  @override
  List<Object> get props => [cashList];
}