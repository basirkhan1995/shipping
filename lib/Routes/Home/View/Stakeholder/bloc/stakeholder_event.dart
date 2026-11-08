

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
  final StakeholdersModel model;
  const AddStakeholderEvent(this.model);
  @override
  List<Object?> get props => [model];
}

class UpdateStakeholderEvent extends StakeholderEvent {
  final StakeholdersModel model;
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

class ClearStakeholderSearchEvent extends StakeholderEvent {
  const ClearStakeholderSearchEvent();
  @override
  List<Object?> get props => [];
}

// ── Lock / Unlock (write only — verification is done by StkSecurityBloc) ──
class SetStakeholderLockEvent extends StakeholderEvent {
  final int perID;
  final bool locked; // true = lock, false = unlock
  const SetStakeholderLockEvent({
    required this.perID,
    required this.locked,
  });
  @override
  List<Object?> get props => [perID, locked];
}