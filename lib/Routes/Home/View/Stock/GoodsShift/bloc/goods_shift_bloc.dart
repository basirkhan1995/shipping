import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../Services/repository.dart';
import '../model/shift_model.dart';

part 'goods_shift_event.dart';
part 'goods_shift_state.dart';

class GoodsShiftBloc extends Bloc<GoodsShiftEvent, GoodsShiftState> {
  final Repositories _repo;
  List<GoodShiftModel> _cachedShifts = [];

  /// Remember the last filter so reloads (after add/edit/delete) keep
  /// the same view the user is looking at.
  String? _lastStatus;
  DateTime? _lastFrom;
  DateTime? _lastTo;

  GoodsShiftBloc(this._repo) : super(GoodsShiftInitial()) {
    on<LoadGoodsShiftsEvent>(_onLoadGoodsShifts);
    on<LoadGoodsShiftByIdEvent>(_onLoadGoodsShiftById);
    on<AddGoodsShiftEvent>(_onAddGoodsShift);
    on<UpdateGoodsShiftEvent>(_onUpdateGoodsShift);
    on<DeleteGoodsShiftEvent>(_onDeleteGoodsShift);
    on<AuthorizeGoodsShiftsEvent>(_onAuthorizeGoodsShifts);
    on<ReturnToShiftsListEvent>(_onReturnToList);
  }

  Future<void> _reloadWithFilters(Emitter<GoodsShiftState> emit) async {
    final shifts = await _repo.getShifts(
      status: _lastStatus,
      from: _lastFrom,
      to: _lastTo,
    );
    _cachedShifts = shifts;
    emit(GoodsShiftLoadedState(shifts));
  }

  Future<void> _onLoadGoodsShifts(
      LoadGoodsShiftsEvent event, Emitter<GoodsShiftState> emit) async {
    _lastStatus = event.status;
    _lastFrom = event.from;
    _lastTo = event.to;

    emit(GoodsShiftLoadingState());
    try {
      final shifts = await _repo.getShifts(
        status: event.status,
        from: event.from,
        to: event.to,
      );
      _cachedShifts = shifts;
      emit(GoodsShiftLoadedState(shifts));
    } catch (e) {
      emit(GoodsShiftErrorState(e.toString()));
    }
  }

  Future<void> _onLoadGoodsShiftById(
      LoadGoodsShiftByIdEvent event, Emitter<GoodsShiftState> emit) async {
    try {
      emit(GoodsShiftDetailLoadingState());
      // Fetch with 'All' so we can open authorized shifts in read-only/edit
      // correctly. (Update still rejects non-Pending on the server.)
      final shifts = await _repo.getShifts(
        orderId: event.orderId,
        status: 'All',
      );
      if (shifts.isEmpty) {
        emit(GoodsShiftErrorState('Shift not found'));
        if (_cachedShifts.isNotEmpty) {
          emit(GoodsShiftLoadedState(_cachedShifts));
        }
        return;
      }
      emit(GoodsShiftDetailLoadedState(shifts.first));
    } catch (e) {
      emit(GoodsShiftErrorState(e.toString()));
      if (_cachedShifts.isNotEmpty) {
        emit(GoodsShiftLoadedState(_cachedShifts));
      }
    }
  }

  Future<void> _onAddGoodsShift(
      AddGoodsShiftEvent event, Emitter<GoodsShiftState> emit) async {
    emit(GoodsShiftSavingState());
    try {
      final response = await _repo.addShift(
        usrName: event.usrName,
        records: event.records,
      );
      final msg = response['msg']?.toString() ?? '';
      if (msg.toLowerCase().contains('success')) {
        emit(GoodsShiftSavedState(
            message: 'Goods shift created successfully'));
        await _reloadWithFilters(emit);
      } else {
        emit(GoodsShiftErrorState(msg));
        if (_cachedShifts.isNotEmpty) {
          emit(GoodsShiftLoadedState(_cachedShifts));
        }
      }
    } catch (e) {
      emit(GoodsShiftErrorState(e.toString()));
      if (_cachedShifts.isNotEmpty) {
        emit(GoodsShiftLoadedState(_cachedShifts));
      }
    }
  }

  Future<void> _onUpdateGoodsShift(
      UpdateGoodsShiftEvent event, Emitter<GoodsShiftState> emit) async {
    emit(GoodsShiftUpdatingState());
    try {
      final response = await _repo.updateShift(
        ordID: event.ordID,
        usrName: event.usrName,
        records: event.records,
      );
      final msg = response['msg']?.toString() ?? '';
      if (msg.toLowerCase().contains('success')) {
        emit(GoodsShiftUpdatedState(
            message: 'Goods shift updated successfully'));
        await _reloadWithFilters(emit);
      } else {
        emit(GoodsShiftErrorState(msg));
        if (_cachedShifts.isNotEmpty) {
          emit(GoodsShiftLoadedState(_cachedShifts));
        }
      }
    } catch (e) {
      emit(GoodsShiftErrorState(e.toString()));
      if (_cachedShifts.isNotEmpty) {
        emit(GoodsShiftLoadedState(_cachedShifts));
      }
    }
  }

  Future<void> _onDeleteGoodsShift(
      DeleteGoodsShiftEvent event, Emitter<GoodsShiftState> emit) async {
    emit(GoodsShiftDeletingState());
    try {
      final response = await _repo.deleteShift(
        orderId: event.orderId,
        usrName: event.usrName,
      );
      final msg = response['msg']?.toString() ?? '';
      if (msg.toLowerCase().contains('success')) {
        emit(GoodsShiftDeletedState(
            message: 'Goods shift deleted successfully'));
        // Refresh list immediately so the deleted row vanishes.
        await _reloadWithFilters(emit);
      } else {
        emit(GoodsShiftErrorState(msg));
        if (_cachedShifts.isNotEmpty) {
          emit(GoodsShiftLoadedState(_cachedShifts));
        }
      }
    } catch (e) {
      emit(GoodsShiftErrorState(e.toString()));
      if (_cachedShifts.isNotEmpty) {
        emit(GoodsShiftLoadedState(_cachedShifts));
      }
    }
  }

  /// Works for both directions:
  ///   - targetStatus: 'Authorized'  (authorize)
  ///   - targetStatus: 'Pending'     (revert / un-authorize)
  Future<void> _onAuthorizeGoodsShifts(
      AuthorizeGoodsShiftsEvent event, Emitter<GoodsShiftState> emit) async {
    emit(GoodsShiftAuthorizingState());
    try {
      final response = await _repo.postOrderStatus(event.ordersData);

      final isSuccess =
          response['msg']?.toString().toLowerCase() == 'success';
      final fallback = event.targetStatus == 'Pending'
          ? 'Goods shift(s) reverted to Pending'
          : 'Goods shift(s) authorized successfully';
      final message = response['message']?.toString() ?? fallback;

      if (isSuccess) {
        emit(GoodsShiftAuthorizedState(
          message: message,
          count: event.ordersData.length,
          targetStatus: event.targetStatus,
        ));
        await _reloadWithFilters(emit);
      } else {
        emit(GoodsShiftErrorState(message));
        if (_cachedShifts.isNotEmpty) {
          emit(GoodsShiftLoadedState(_cachedShifts));
        }
      }
    } catch (e) {
      emit(GoodsShiftErrorState(e.toString()));
      if (_cachedShifts.isNotEmpty) {
        emit(GoodsShiftLoadedState(_cachedShifts));
      }
    }
  }

  void _onReturnToList(
      ReturnToShiftsListEvent event, Emitter<GoodsShiftState> emit) {
    if (_cachedShifts.isNotEmpty) {
      emit(GoodsShiftLoadedState(_cachedShifts));
    } else {
      add(LoadGoodsShiftsEvent(
        status: _lastStatus,
        from: _lastFrom,
        to: _lastTo,
      ));
    }
  }
}