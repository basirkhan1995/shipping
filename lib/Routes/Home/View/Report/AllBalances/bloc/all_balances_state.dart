part of 'all_balances_bloc.dart';

sealed class AllBalancesState extends Equatable {
  const AllBalancesState();
}

final class AllBalancesInitial extends AllBalancesState {
  @override
  List<Object> get props => [];
}

final class AllBalancesErrorState extends AllBalancesState {
  final String message;
  const AllBalancesErrorState(this.message);
  @override
  List<Object> get props => [message];
}

final class AllBalancesLoadedState extends AllBalancesState {
  final List<AllBalancesModel> balances;
  const AllBalancesLoadedState(this.balances);
  @override
  List<Object> get props => [balances];
}

final class AllBalancesLoadingState extends AllBalancesState {
  @override
  List<Object> get props => [];
}