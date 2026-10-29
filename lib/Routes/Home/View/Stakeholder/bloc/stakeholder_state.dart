// lib/Routes/Home/model/Stakeholder/bloc/stakeholder_state.dart

part of 'stakeholder_bloc.dart';

sealed class StakeholderState extends Equatable {
  const StakeholderState();
  @override
  List<Object?> get props => [];
}

class StakeholderInitialState extends StakeholderState {}

class GetStakeholdersLoadingState extends StakeholderState {}

class GetStakeholdersSuccessState extends StakeholderState {
  final List<IndividualsModel> stakeholders;
  final String search;
  const GetStakeholdersSuccessState(this.stakeholders, {this.search = ''});
  @override
  List<Object?> get props => [stakeholders, search];
}

class GetStakeholdersFailureState extends StakeholderState {
  final String message;
  const GetStakeholdersFailureState(this.message);
  @override
  List<Object?> get props => [message];
}

class GetStakeholderByIdLoadingState extends StakeholderState {}

class GetStakeholderByIdSuccessState extends StakeholderState {
  final IndividualsModel stakeholder;
  const GetStakeholderByIdSuccessState(this.stakeholder);
  @override
  List<Object?> get props => [stakeholder];
}

class GetStakeholderByIdFailureState extends StakeholderState {
  final String message;
  const GetStakeholderByIdFailureState(this.message);
  @override
  List<Object?> get props => [message];
}

class AddStakeholderLoadingState extends StakeholderState {
  final List<IndividualsModel> stakeholders;
  const AddStakeholderLoadingState(this.stakeholders);
  @override
  List<Object?> get props => [stakeholders];
}

class AddStakeholderSuccessState extends StakeholderState {
  final List<IndividualsModel> stakeholders;
  final String message;
  const AddStakeholderSuccessState(this.stakeholders, this.message);
  @override
  List<Object?> get props => [stakeholders, message];
}

class AddStakeholderFailureState extends StakeholderState {
  final String message;
  const AddStakeholderFailureState(this.message);
  @override
  List<Object?> get props => [message];
}

class UpdateStakeholderLoadingState extends StakeholderState {
  final List<IndividualsModel> stakeholders;
  const UpdateStakeholderLoadingState(this.stakeholders);
  @override
  List<Object?> get props => [stakeholders];
}

class UpdateStakeholderSuccessState extends StakeholderState {
  final List<IndividualsModel> stakeholders;
  final String message;
  const UpdateStakeholderSuccessState(this.stakeholders, this.message);
  @override
  List<Object?> get props => [stakeholders, message];
}

class UpdateStakeholderFailureState extends StakeholderState {
  final String message;
  const UpdateStakeholderFailureState(this.message);
  @override
  List<Object?> get props => [message];
}

class DeleteStakeholderLoadingState extends StakeholderState {
  final List<IndividualsModel> stakeholders;
  const DeleteStakeholderLoadingState(this.stakeholders);
  @override
  List<Object?> get props => [stakeholders];
}

class DeleteStakeholderSuccessState extends StakeholderState {
  final List<IndividualsModel> stakeholders;
  final String message;
  const DeleteStakeholderSuccessState(this.stakeholders, this.message);
  @override
  List<Object?> get props => [stakeholders, message];
}

class DeleteStakeholderFailureState extends StakeholderState {
  final String message;
  const DeleteStakeholderFailureState(this.message);
  @override
  List<Object?> get props => [message];
}

class UploadStakeholderImageLoadingState extends StakeholderState {
  final List<IndividualsModel> stakeholders;
  const UploadStakeholderImageLoadingState(this.stakeholders);
  @override
  List<Object?> get props => [stakeholders];
}

class UploadStakeholderImageSuccessState extends StakeholderState {
  final List<IndividualsModel> stakeholders;
  final String message;
  const UploadStakeholderImageSuccessState(
      this.stakeholders,
      this.message,
      );
  @override
  List<Object?> get props => [stakeholders, message];
}

class UploadStakeholderImageFailureState extends StakeholderState {
  final String message;
  const UploadStakeholderImageFailureState(this.message);
  @override
  List<Object?> get props => [message];
}