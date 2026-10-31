part of 'all_balances_bloc.dart';

sealed class AllBalancesEvent extends Equatable {
  const AllBalancesEvent();
}

class LoadAllBalancesEvent extends AllBalancesEvent{
  final int? catId;
  const LoadAllBalancesEvent({this.catId});
  @override
  List<Object?> get props => [catId];
}

class ResetAllBalancesEvent extends AllBalancesEvent{
  @override
  List<Object?> get props => [];
}