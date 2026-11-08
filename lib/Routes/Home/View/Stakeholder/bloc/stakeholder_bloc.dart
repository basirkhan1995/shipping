import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:shipping/Services/repository.dart';
import '../../../../../Services/api_exception.dart';
import '../model/stk_model.dart';
part 'stakeholder_event.dart';
part 'stakeholder_state.dart';

class StakeholderBloc extends Bloc<StakeholderEvent, StakeholderState> {
  final Repositories _stakeholderRepo;

  /// Currently active search term. Empty string means "no filter".
  /// This is the **single source of truth** for the filter, and it is
  /// mirrored on `GetStakeholdersSuccessState.search` so the UI can show
  /// the active filter if it wants to.
  String _search = '';

  /// Most recent successful list — survives write-state transitions.
  List<StakeholdersModel> _lastList = const [];

  /// Most recent by-id load — survives write-state transitions.
  StakeholdersModel? _lastById;

  StakeholderBloc(this._stakeholderRepo) : super(StakeholderInitialState()) {
    on<GetStakeholdersEvent>(_onGetStakeholders);
    on<GetStakeholderByIdEvent>(_onGetStakeholderById);
    on<SearchStakeholdersEvent>(_onSearchStakeholders);
    on<ClearStakeholderSearchEvent>(_onClearSearch);
    on<AddStakeholderEvent>(_onAddStakeholder);
    on<UpdateStakeholderEvent>(_onUpdateStakeholder);
    on<DeleteStakeholderEvent>(_onDeleteStakeholder);
    on<ClearStakeholderMessagesEvent>(_onClearMessages);
    on<UploadStkProfileImageEvent>(_onUploadImage);
    on<SetStakeholderLockEvent>(_onSetLock);
  }

  Future<void> _onSetLock(SetStakeholderLockEvent event, Emitter<StakeholderState> emit) async {
    emit(SetStakeholderLockLoadingState(_currentList));

    // Find the model we're toggling. Prefer _lastList (freshest), fall
    // back to the current UI list, then to a bare-bones model as a last
    // resort (extremely unlikely).
    final current = _findById(event.perID);

    if (current == null) {
      emit(const SetStakeholderLockFailureState(
        'Stakeholder not found in the current list.',
      ));
      return;
    }

    // Build the updated model by flipping only perLock. Every other
    // field is preserved, so the PUT cannot blank the name.
    final updated = current.copyWith(
      perLock: event.locked ? 1 : 0,
    );

    try {
      final res = await _stakeholderRepo.setStakeholderLock(updated);

      if (res['msg'] != 'success') {
        emit(SetStakeholderLockFailureState(
          res['message']?.toString() ??
              res['error']?.toString() ??
              'Failed to update lock state',
        ));
        return;
      }

      final stakeholders = await _reload();

      emit(SetStakeholderLockSuccessState(
        stakeholders: stakeholders,
        message: event.locked
            ? 'Stakeholder locked'
            : 'Stakeholder unlocked',
        perID: event.perID,
        isLocked: event.locked,
      ));
    } on ApiException catch (e) {
      emit(SetStakeholderLockFailureState(e.message));
    } catch (e) {
      emit(SetStakeholderLockFailureState(e.toString()));
    }
  }

  /// Look up the current model by perID, preferring the freshest source.
  StakeholdersModel? _findById(int perID) {
    for (final s in _lastList) {
      if (s.perId == perID) return s;
    }
    for (final s in _currentList) {
      if (s.perId == perID) return s;
    }
    return _lastById?.perId == perID ? _lastById : null;
  }

  // ── Helpers ─────────────────────────────────────────

  /// Best-effort current list from state, or the cached list.
  List<StakeholdersModel> get _currentList {
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

  /// Reloads using the **current** `_search`, caches the result, and returns
  /// it. This is the ONLY method that should hit `getStakeholders` on the
  /// repository — so search and refresh cannot diverge.
  Future<List<StakeholdersModel>> _reload() async {
    final list = await _stakeholderRepo.getStakeholders(search: _search);
    _lastList = list;
    return list;
  }

  // ── GET list ────────────────────────────────────────

  Future<void> _onGetStakeholders(
      GetStakeholdersEvent event,
      Emitter<StakeholderState> emit,
      ) async {
    // Contract:
    //   event.search == null → refresh using current _search
    //   event.search == ''   → clear filter and load everything
    //   event.search == 'x'  → filter by 'x'
    if (event.search != null) {
      _search = event.search!.trim();
    }

    emit(GetStakeholdersLoadingState());

    try {
      final stakeholders = await _reload();
      emit(GetStakeholdersSuccessState(stakeholders, search: _search));
    } on ApiException catch (e) {
      emit(GetStakeholdersFailureState(e.message));
    } catch (e) {
      emit(GetStakeholdersFailureState(e.toString()));
    }
  }

  // ── Search ──────────────────────────────────────────

  Future<void> _onSearchStakeholders(
      SearchStakeholdersEvent event,
      Emitter<StakeholderState> emit,
      ) async {
    final query = event.query.trim();

    // Empty query → treat as "clear filter", NOT as "filter by ''".
    if (query.isEmpty) {
      if (_search.isEmpty) return; // already unfiltered, no-op
      _search = '';
      add(const GetStakeholdersEvent(search: ''));
      return;
    }

    // No-op if the query hasn't actually changed.
    if (query == _search) return;

    // Debounce so typing doesn't fire one request per keystroke.
    await Future.delayed(const Duration(milliseconds: 250));
    if (emit.isDone) return;

    _search = query;
    add(GetStakeholdersEvent(search: _search));
  }

  Future<void> _onClearSearch(
      ClearStakeholderSearchEvent event,
      Emitter<StakeholderState> emit,
      ) async {
    if (_search.isEmpty) return;
    _search = '';
    add(const GetStakeholdersEvent(search: ''));
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

  // ── IMAGE UPLOAD ────────────────────────────────────

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

    // Otherwise reset the list back to its last known good state,
    // preserving the active search string.
    emit(GetStakeholdersSuccessState(_lastList, search: _search));
  }
}