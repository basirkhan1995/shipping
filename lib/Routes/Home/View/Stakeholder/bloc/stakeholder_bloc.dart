import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shipping/Services/repository.dart';
import '../../../../../Services/api_exception.dart';
import '../model/stk_model.dart';
import 'package:flutter/services.dart';
part 'stakeholder_event.dart';
part 'stakeholder_state.dart';

class StakeholderBloc extends Bloc<StakeholderEvent, StakeholderState> {
  final Repositories _stakeholderRepo;
  String _search = '';

  /// Keeps the most recent successful list — survives write-state transitions.
  List<IndividualsModel> _lastList = const [];

  /// Keeps the most recent by-id load — survives write-state transitions.
  IndividualsModel? _lastById;

  StakeholderBloc(this._stakeholderRepo) : super(StakeholderInitialState()) {
    on<GetStakeholdersEvent>(_onGetStakeholders);
    on<GetStakeholderByIdEvent>(_onGetStakeholderById);
    on<SearchStakeholdersEvent>(_onSearchStakeholders);
    on<AddStakeholderEvent>(_onAddStakeholder);
    on<UpdateStakeholderEvent>(_onUpdateStakeholder);
    on<DeleteStakeholderEvent>(_onDeleteStakeholder);
    on<ClearStakeholderMessagesEvent>(_onClearMessages);
    on<UploadStkProfileImageEvent>(_onUploadImage);
  }




  Future<void> _onUploadImage(
      UploadStkProfileImageEvent event,
      Emitter<StakeholderState> emit,
      ) async {
    emit(UploadStakeholderImageLoadingState(_currentList));
    try {
      final res = await _stakeholderRepo.uploadStakeholderPhoto(
        perID: event.perId,
        image: event.image,
      );
      if (res['msg'] == 'success') {
        final stakeholders = await _reload();
        emit(UploadStakeholderImageSuccessState(
          stakeholders,
          'Photo updated successfully',
        ));
      } else {
        emit(UploadStakeholderImageFailureState(
          res['error']?.toString() ??
              res['msg']?.toString() ??
              'Upload failed',
        ));
      }
    } catch (e) {
      emit(UploadStakeholderImageFailureState(e.toString()));
    }
  }
  // ── Helpers ─────────────────────────────────────────

  /// Best-effort current list from state, or the cached list.
  List<IndividualsModel> get _currentList {
    final s = state;
    if (s is GetStakeholdersSuccessState) return s.stakeholders;
    if (s is AddStakeholderLoadingState) return s.stakeholders;
    if (s is AddStakeholderSuccessState) return s.stakeholders;
    if (s is UpdateStakeholderLoadingState) return s.stakeholders;
    if (s is UpdateStakeholderSuccessState) return s.stakeholders;
    if (s is DeleteStakeholderLoadingState) return s.stakeholders;
    if (s is DeleteStakeholderSuccessState) return s.stakeholders;
    return _lastList;
  }

  Future<List<IndividualsModel>> _reload() async {
    final list = await _stakeholderRepo.getStakeholders(search: _search);
    _lastList = list;
    return list;
  }

  // ── GET list ────────────────────────────────────────

  Future<void> _onGetStakeholders(
      GetStakeholdersEvent event,
      Emitter<StakeholderState> emit,
      ) async {
    if (event.search != null) _search = event.search!;
    emit(GetStakeholdersLoadingState());
    try {
      final stakeholders =
      await _stakeholderRepo.getStakeholders(search: _search);
      _lastList = stakeholders;
      emit(GetStakeholdersSuccessState(stakeholders, search: _search));
    } on ApiException catch (e) {
      emit(GetStakeholdersFailureState(e.message));
    } catch (e) {
      emit(GetStakeholdersFailureState(e.toString()));
    }
  }

  // ── GET by id ───────────────────────────────────────

  Future<void> _onGetStakeholderById(
      GetStakeholderByIdEvent event,
      Emitter<StakeholderState> emit,
      ) async {
    emit(GetStakeholderByIdLoadingState());
    try {
      final stakeholder =
      await _stakeholderRepo.getStakeholderById(event.perId);
      _lastById = stakeholder;
      emit(GetStakeholderByIdSuccessState(stakeholder));
    } on ApiException catch (e) {
      emit(GetStakeholderByIdFailureState(e.message));
    } catch (e) {
      emit(GetStakeholderByIdFailureState(e.toString()));
    }
  }

  // ── Search ──────────────────────────────────────────

  Future<void> _onSearchStakeholders(
      SearchStakeholdersEvent event,
      Emitter<StakeholderState> emit,
      ) async {
    _search = event.query;
    add(GetStakeholdersEvent(search: _search));
  }

  // ── ADD ─────────────────────────────────────────────

  Future<void> _onAddStakeholder(
      AddStakeholderEvent event,
      Emitter<StakeholderState> emit,
      ) async {
    emit(AddStakeholderLoadingState(_currentList));
    try {
      await _stakeholderRepo.addStakeholder(event.model);
      final stakeholders = await _reload();
      emit(AddStakeholderSuccessState(
        stakeholders,
        'Stakeholder added successfully',
      ));
    } on ApiException catch (e) {
      emit(AddStakeholderFailureState(e.message));
    } catch (e) {
      emit(AddStakeholderFailureState(e.toString()));
    }
  }

  // ── UPDATE ──────────────────────────────────────────

  Future<void> _onUpdateStakeholder(
      UpdateStakeholderEvent event,
      Emitter<StakeholderState> emit,
      ) async {
    emit(UpdateStakeholderLoadingState(_currentList));
    try {
      await _stakeholderRepo.updateStakeholder(event.model);
      final stakeholders = await _reload();
      emit(UpdateStakeholderSuccessState(
        stakeholders,
        'Stakeholder updated successfully',
      ));
    } on ApiException catch (e) {
      emit(UpdateStakeholderFailureState(e.message));
    } catch (e) {
      emit(UpdateStakeholderFailureState(e.toString()));
    }
  }

  // ── DELETE ──────────────────────────────────────────

  Future<void> _onDeleteStakeholder(
      DeleteStakeholderEvent event,
      Emitter<StakeholderState> emit,
      ) async {
    emit(DeleteStakeholderLoadingState(_currentList));
    try {
      await _stakeholderRepo.deleteStakeholder(event.perId);
      final stakeholders = await _reload();
      emit(DeleteStakeholderSuccessState(
        stakeholders,
        'Stakeholder deleted successfully',
      ));
    } on ApiException catch (e) {
      emit(DeleteStakeholderFailureState(e.message));
    } catch (e) {
      emit(DeleteStakeholderFailureState(e.toString()));
    }
  }

  // ── CLEAR MESSAGES (after snackbar shown) ───────────

  Future<void> _onClearMessages(
      ClearStakeholderMessagesEvent event,
      Emitter<StakeholderState> emit,
      ) async {
    // Do NOT wipe by-id state. Restore it if that's what was showing.
    final s = state;
    if (s is GetStakeholderByIdSuccessState ||
        s is GetStakeholderByIdFailureState ||
        s is GetStakeholderByIdLoadingState) {
      if (_lastById != null) {
        emit(GetStakeholderByIdSuccessState(_lastById!));
        return;
      }
    }

    // Otherwise reset the list back to its last known good list state.
    emit(GetStakeholdersSuccessState(_lastList, search: _search));
  }
}