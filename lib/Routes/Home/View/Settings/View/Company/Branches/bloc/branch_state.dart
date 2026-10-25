part of 'branch_bloc.dart';

sealed class BranchState extends Equatable {
  const BranchState();
}

final class BranchInitial extends BranchState {
  @override
  List<Object> get props => [];
}


final class BranchLoadingState extends BranchState {
  @override
  List<Object> get props => [];
}

final class BranchSuccessState extends BranchState {
  @override
  List<Object> get props => [];
}

final class BranchErrorState extends BranchState {
  final String message;
  const BranchErrorState(this.message);
  @override
  List<Object> get props => [message];
}

final class BranchLoadedState extends BranchState {
  final List<BranchModel> branches;
  const BranchLoadedState(this.branches);
  @override
  List<Object> get props => [branches];
}
