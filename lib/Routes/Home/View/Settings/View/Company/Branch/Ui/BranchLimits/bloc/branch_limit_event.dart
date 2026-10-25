part of 'branch_limit_bloc.dart';

sealed class BranchLimitEvent extends Equatable {
  const BranchLimitEvent();
}

class LoadBranchLimitEvent extends BranchLimitEvent{
  final int? brcId;
  const LoadBranchLimitEvent(this.brcId);

  @override
  List<Object?> get props => [brcId];
}

class AddBranchLimitEvent extends BranchLimitEvent{
  final BranchLimitModel newLimit;
  const AddBranchLimitEvent(this.newLimit);
  @override
  List<Object?> get props => [newLimit];
}

class EditBranchLimitEvent extends BranchLimitEvent{
  final BranchLimitModel newLimit;
  const EditBranchLimitEvent(this.newLimit);
  @override
  List<Object?> get props => [newLimit];
}