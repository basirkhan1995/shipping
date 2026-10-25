part of 'branch_limit_bloc.dart';

sealed class BranchLimitState extends Equatable {
  const BranchLimitState();
}

final class BranchLimitInitial extends BranchLimitState {
  @override
  List<Object> get props => [];
}

final class BranchLimitLoadingState extends BranchLimitState {
  @override
  List<Object> get props => [];
}

final class BranchLimitSuccessState extends BranchLimitState {
  @override
  List<Object> get props => [];
}

final class BranchLimitErrorState extends BranchLimitState {
  final String message;
  const BranchLimitErrorState(this.message);

  @override
  List<Object> get props => [message];
}

final class BranchLimitLoadedState extends BranchLimitState {
  final List<BranchLimitModel> limits;
  const BranchLimitLoadedState(this.limits);
  @override
  List<Object> get props => [limits];
}
