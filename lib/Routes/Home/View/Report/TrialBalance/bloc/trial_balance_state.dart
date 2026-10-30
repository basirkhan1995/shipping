part of 'trial_balance_bloc.dart';

sealed class TrialBalanceState extends Equatable {
  const TrialBalanceState();
}

final class TrialBalanceInitial extends TrialBalanceState {
  @override
  List<Object> get props => [];
}

final class TrialBalanceLoadedState extends TrialBalanceState {
  final List<TrialBalanceModel> balance;
  const TrialBalanceLoadedState(this.balance);
  @override
  List<Object> get props => [balance];
}

final class TrialBalanceLoadingState extends TrialBalanceState {
  @override
  List<Object> get props => [];
}

final class TrialBalanceErrorState extends TrialBalanceState {
  final String message;
  const TrialBalanceErrorState(this.message);
  @override
  List<Object> get props => [message];
}

