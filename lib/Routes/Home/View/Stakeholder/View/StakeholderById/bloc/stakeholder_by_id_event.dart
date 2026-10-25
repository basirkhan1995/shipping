// stakeholder_by_id_event.dart
import 'package:equatable/equatable.dart';

abstract class StakeholderByIdEvent extends Equatable {
  const StakeholderByIdEvent();
  @override
  List<Object?> get props => [];
}

class LoadStakeholderByIdEvent extends StakeholderByIdEvent {
  final int stkId;
  const LoadStakeholderByIdEvent({required this.stkId});
  @override
  List<Object?> get props => [stkId];
}

class RefreshStakeholderByIdEvent extends StakeholderByIdEvent {
  final int stkId;
  const RefreshStakeholderByIdEvent({required this.stkId});
  @override
  List<Object?> get props => [stkId];
}

class ClearStakeholderByIdEvent extends StakeholderByIdEvent {
  const ClearStakeholderByIdEvent();
}