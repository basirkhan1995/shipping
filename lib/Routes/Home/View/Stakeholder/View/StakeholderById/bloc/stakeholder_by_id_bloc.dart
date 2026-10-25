// stakeholder_by_id_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Services/repository.dart';
import 'stakeholder_by_id_event.dart';
import 'stakeholder_by_id_state.dart';

class StakeholderByIdBloc
    extends Bloc<StakeholderByIdEvent, StakeholderByIdState> {
  final Repositories _repo;

  StakeholderByIdBloc(this._repo) : super(const StakeholderByIdInitialState()) {
    on<LoadStakeholderByIdEvent>(_onLoad);
    on<RefreshStakeholderByIdEvent>(_onRefresh);
    on<ClearStakeholderByIdEvent>((_, emit) => emit(const StakeholderByIdInitialState()));
  }

  Future<void> _onLoad(
      LoadStakeholderByIdEvent event,
      Emitter<StakeholderByIdState> emit,
      ) async {
    emit(const StakeholderByIdLoadingState());
    try {
      final stk = await _repo.getStakeholderById(event.stkId);
      emit(StakeholderByIdLoadedState(stk));
    } catch (e) {
      emit(StakeholderByIdFailureState(e.toString()));
    }
  }

  Future<void> _onRefresh(
      RefreshStakeholderByIdEvent event,
      Emitter<StakeholderByIdState> emit,
      ) async {
    // Refresh without showing loading (keep current data on screen)
    try {
      final stk = await _repo.getStakeholderById(event.stkId);
      emit(StakeholderByIdLoadedState(stk));
    } catch (e) {
      // Keep existing data; optionally add a non-fatal error state
      addError(e);
    }
  }
}