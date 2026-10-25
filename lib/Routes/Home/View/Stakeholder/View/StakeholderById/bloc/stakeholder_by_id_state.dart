import 'package:equatable/equatable.dart';

import '../../../model/stk_model.dart';

abstract class StakeholderByIdState extends Equatable {
  const StakeholderByIdState();
  @override
  List<Object?> get props => [];
}

class StakeholderByIdInitialState extends StakeholderByIdState {
  const StakeholderByIdInitialState();
}

class StakeholderByIdLoadingState extends StakeholderByIdState {
  const StakeholderByIdLoadingState();
}

class StakeholderByIdLoadedState extends StakeholderByIdState {
  final IndividualsModel stk;
  const StakeholderByIdLoadedState(this.stk);
  @override
  List<Object?> get props => [stk];
}

class StakeholderByIdFailureState extends StakeholderByIdState {
  final String message;
  const StakeholderByIdFailureState(this.message);
  @override
  List<Object?> get props => [message];
}