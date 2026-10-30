// cash_balances_event.dart
part of 'cash_balances_bloc.dart';

sealed class CashBalancesEvent extends Equatable {
  const CashBalancesEvent();
}

class LoadCashBalanceBranchWiseEvent extends CashBalancesEvent {
  final int? branchId;
  final String? from;   // YYYY-MM-DD
  final String? to;     // YYYY-MM-DD

  const LoadCashBalanceBranchWiseEvent({
    this.branchId,
    this.from,
    this.to,
  });
  @override
  List<Object> get props => [];
}

class LoadAllCashBalancesEvent extends CashBalancesEvent {
  const LoadAllCashBalancesEvent();
  @override
  List<Object> get props => [];
}