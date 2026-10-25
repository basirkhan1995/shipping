import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../../Services/api_exception.dart';
import '../../../../../../../../Services/repository.dart';
import '../model/branch_model.dart';

part 'branch_event.dart';
part 'branch_state.dart';

class BranchBloc extends Bloc<BranchEvent, BranchState> {
  final Repositories _repo;

  BranchBloc(this._repo) : super(BranchInitial()) {
    // ── LOAD ────────────────────────────────────────────────────────
    on<LoadBranchesEvent>((event, emit) async {
      emit(BranchLoadingState());
      try {
        final brc = await _repo.getBranches(brcId: event.brcId);
        emit(BranchLoadedState(brc));
      } on ApiException catch (e) {
        emit(BranchErrorState(e.message));
      } catch (e) {
        emit(BranchErrorState(e.toString()));
      }
    });

    // ── ADD ────────────────────────────────────────────────────────
    on<AddBranchEvent>((event, emit) async {
      emit(BranchLoadingState());
      try {
        await _repo.addBranch(newBranch: event.newBranch);
        emit(BranchSuccessState());
        add(LoadBranchesEvent());
      } on ApiException catch (e) {
        emit(BranchErrorState(e.message));
      } catch (e) {
        emit(BranchErrorState(e.toString()));
      }
    });

    // ── EDIT ────────────────────────────────────────────────────────
    on<EditBranchEvent>((event, emit) async {
      emit(BranchLoadingState());
      try {
        await _repo.updateBranch(newBranch: event.newBranch);
        emit(BranchSuccessState());
        add(LoadBranchesEvent());
      } on ApiException catch (e) {
        emit(BranchErrorState(e.message));
      } catch (e) {
        emit(BranchErrorState(e.toString()));
      }
    });
  }
}