

part of 'stakeholder_bloc.dart';

sealed class StakeholderEvent extends Equatable {
  const StakeholderEvent();
  @override
  List<Object?> get props => [];
}

// ── Read ──────────────────────────────────────────────
class GetStakeholdersEvent extends StakeholderEvent {
  final String? search;
  const GetStakeholdersEvent({this.search});
  @override
  List<Object?> get props => [search];
}

class GetStakeholderByIdEvent extends StakeholderEvent {
  final int perId;
  const GetStakeholderByIdEvent(this.perId);
  @override
  List<Object?> get props => [perId];
}

// ── Search ────────────────────────────────────────────
class SearchStakeholdersEvent extends StakeholderEvent {
  final String query;
  const SearchStakeholdersEvent(this.query);
  @override
  List<Object?> get props => [query];
}

// ── Write ─────────────────────────────────────────────
class AddStakeholderEvent extends StakeholderEvent {
  final IndividualsModel model;
  const AddStakeholderEvent(this.model);
  @override
  List<Object?> get props => [model];
}

class UpdateStakeholderEvent extends StakeholderEvent {
  final IndividualsModel model;
  const UpdateStakeholderEvent(this.model);
  @override
  List<Object?> get props => [model];
}

class DeleteStakeholderEvent extends StakeholderEvent {
  final int perId;
  const DeleteStakeholderEvent(this.perId);
  @override
  List<Object?> get props => [perId];
}

// ── Utility ───────────────────────────────────────────
class ClearStakeholderMessagesEvent extends StakeholderEvent {
  const ClearStakeholderMessagesEvent();
}

class UploadStkProfileImageEvent extends StakeholderEvent {
  final int perId;
  final Uint8List image;
  const UploadStkProfileImageEvent({
    required this.perId,
    required this.image,
  });
  @override
  List<Object?> get props => [perId, image];
}