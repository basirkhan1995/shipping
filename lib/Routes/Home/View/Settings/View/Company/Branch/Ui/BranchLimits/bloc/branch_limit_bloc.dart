import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../../../../Services/api_exception.dart';
import '../../../../../../../../../../Services/repository.dart';
import '../model/limit_model.dart';

part 'branch_limit_event.dart';
part 'branch_limit_state.dart';

class BranchLimitBloc extends Bloc<BranchLimitEvent, BranchLimitState> {
  final Repositories _repo;

  BranchLimitBloc(this._repo) : super(BranchLimitInitial()) {
    // ── LOAD ────────────────────────────────────────────────────────
    on<LoadBranchLimitEvent>((event, emit) async {
      emit(BranchLimitLoadingState());
      try {
        final limits = await _repo.getBranchLimits(brcCode: event.brcId);
        emit(BranchLimitLoadedState(limits));
      } on ApiException catch (e) {
        emit(BranchLimitErrorState(e.message));
      } catch (e) {
        emit(BranchLimitErrorState(e.toString()));
      }
    });

    // ── ADD ────────────────────────────────────────────────────────
    on<AddBranchLimitEvent>((event, emit) async {
      emit(BranchLimitLoadingState());
      try {
        await _repo.addEditBranchLimit(newLimit: event.newLimit);
        emit(BranchLimitSuccessState());
        add(LoadBranchLimitEvent(event.newLimit.balBranch));
      } on ApiException catch (e) {
        emit(BranchLimitErrorState(e.message));
      } catch (e) {
        emit(BranchLimitErrorState(e.toString()));
      }
    });

    // ── EDIT ────────────────────────────────────────────────────────
    on<EditBranchLimitEvent>((event, emit) async {
      emit(BranchLimitLoadingState());
      try {
        await _repo.addEditBranchLimit(newLimit: event.newLimit);
        emit(BranchLimitSuccessState());
        add(LoadBranchLimitEvent(event.newLimit.balBranch));
      } on ApiException catch (e) {
        emit(BranchLimitErrorState(e.message));
      } catch (e) {
        emit(BranchLimitErrorState(e.toString()));
      }
    });
  }
}