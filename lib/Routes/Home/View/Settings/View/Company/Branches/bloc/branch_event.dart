part of 'branch_bloc.dart';

sealed class BranchEvent extends Equatable {
  const BranchEvent();
}

class LoadBranchesEvent extends BranchEvent{
  final int? brcId;
  const LoadBranchesEvent({this.brcId});
  @override
  List<Object?> get props => [brcId];
}

class AddBranchEvent extends BranchEvent{
  final BranchModel newBranch;
  const AddBranchEvent(this.newBranch);
  @override
  List<Object?> get props => [newBranch];
}

class EditBranchEvent extends BranchEvent{
  final BranchModel newBranch;
  const EditBranchEvent(this.newBranch);
  @override
  List<Object?> get props => [newBranch];
}