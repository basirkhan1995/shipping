import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shipping/Services/repository.dart';

import '../model/shp_details_model.dart';

part 'shp_by_id_event.dart';
part 'shp_by_id_state.dart';

class ShpByIdBloc extends Bloc<ShpByIdEvent, ShpByIdState> {
  final Repositories _repo;

  ShpByIdBloc(this._repo) : super(ShpByIdInitial()) {
    on<ShpByIdLoadRequested>(_onLoadRequested);
    on<ShpByIdRefreshed>(_onRefreshed);
    on<ShpByIdAddItemRequested>(_onAddItem);
    on<ShpByIdUpdateItemRequested>(_onUpdateItem);
    on<ShpByIdDeleteItemRequested>(_onDeleteItem);
    on<ShpByIdActionErrorCleared>(_onActionErrorCleared);
  }

  // ─────────────────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────────────────
  Future<void> _onLoadRequested(
      ShpByIdLoadRequested event,
      Emitter<ShpByIdState> emit,
      ) async {
    final previous =
    state is ShpByIdLoaded ? (state as ShpByIdLoaded).details : null;
    emit(ShpByIdLoading(previous: previous));
    await _fetch(emit, event.shpId, previous: previous);
  }

  Future<void> _onRefreshed(
      ShpByIdRefreshed event,
      Emitter<ShpByIdState> emit,
      ) async {
    final previous =
    state is ShpByIdLoaded ? (state as ShpByIdLoaded).details : null;
    emit(ShpByIdLoading(previous: previous));
    await _fetch(emit, event.shpId, previous: previous);
  }

  // ─────────────────────────────────────────────────────────
  // ADD ITEM
  // ─────────────────────────────────────────────────────────
  Future<void> _onAddItem(
      ShpByIdAddItemRequested event,
      Emitter<ShpByIdState> emit,
      ) async {
    final current = state;
    if (current is! ShpByIdLoaded) return;

    emit(current.copyWith(
      pendingAction: ShpByIdAction.addItem,
      clearActionError: true,
      clearSuccessMessage: true,
    ));

    try {
      await _repo.addShpItem(
        usrName: event.usrName,
        shpId: event.shpId,
        accountNo: event.accountNo,
        itemDescription: event.itemDescription,
        qty: event.qty,
        cbm: event.cbm,
        weight: event.weight,
        ratePerCbm: event.ratePerCbm,
        ratePerWeight: event.ratePerWeight,
        extraCharges: event.extraCharges,
      );

      // Re-fetch fresh details (server-computed totals etc.)
      final fresh = await _repo.getShipmentDetails(shpId: event.shpId);
      emit(ShpByIdLoaded(
        fresh,
        successMessage: 'Item added',
      ));
    } catch (e) {
      emit(current.copyWith(
        clearPendingAction: true,
        actionError: 'Failed to add item: ${_msg(e)}',
      ));
    }
  }

  // ─────────────────────────────────────────────────────────
  // UPDATE ITEM
  // ─────────────────────────────────────────────────────────
  Future<void> _onUpdateItem(
      ShpByIdUpdateItemRequested event,
      Emitter<ShpByIdState> emit,
      ) async {
    final current = state;
    if (current is! ShpByIdLoaded) return;

    emit(current.copyWith(
      pendingAction: ShpByIdAction.updateItem,
      clearActionError: true,
      clearSuccessMessage: true,
    ));

    try {
      await _repo.updateShpItem(
        usrName: event.usrName,
        shpItmId: event.shpItmId,
        accountNo: event.accountNo,
        itemDescription: event.itemDescription,
        qty: event.qty,
        cbm: event.cbm,
        weight: event.weight,
        ratePerCbm: event.ratePerCbm,
        ratePerWeight: event.ratePerWeight,
        extraCharges: event.extraCharges,
      );

      final fresh = await _repo.getShipmentDetails(shpId: event.shpId);
      emit(ShpByIdLoaded(
        fresh,
        successMessage: 'Item updated',
      ));
    } catch (e) {
      emit(current.copyWith(
        clearPendingAction: true,
        actionError: 'Failed to update item: ${_msg(e)}',
      ));
    }
  }

  // ─────────────────────────────────────────────────────────
  // DELETE ITEM
  // ─────────────────────────────────────────────────────────
  Future<void> _onDeleteItem(
      ShpByIdDeleteItemRequested event,
      Emitter<ShpByIdState> emit,
      ) async {
    final current = state;
    if (current is! ShpByIdLoaded) return;

    emit(current.copyWith(
      pendingAction: ShpByIdAction.deleteItem,
      clearActionError: true,
      clearSuccessMessage: true,
    ));

    try {
      await _repo.deleteShpItem(
        usrName: event.usrName,
        shpItmId: event.shpItmId,
      );

      final fresh = await _repo.getShipmentDetails(shpId: event.shpId);
      emit(ShpByIdLoaded(
        fresh,
        successMessage: 'Item deleted',
      ));
    } catch (e) {
      emit(current.copyWith(
        clearPendingAction: true,
        actionError: 'Failed to delete item: ${_msg(e)}',
      ));
    }
  }

  // ─────────────────────────────────────────────────────────
  // CLEAR ACTION ERROR
  // ─────────────────────────────────────────────────────────
  void _onActionErrorCleared(
      ShpByIdActionErrorCleared event,
      Emitter<ShpByIdState> emit,
      ) {
    final current = state;
    if (current is ShpByIdLoaded) {
      emit(current.copyWith(clearActionError: true));
    }
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────
  Future<void> _fetch(
      Emitter<ShpByIdState> emit,
      int shpId, {
        ShipmentDetailsModel? previous,
      }) async {
    try {
      final details = await _repo.getShipmentDetails(shpId: shpId);
      emit(ShpByIdLoaded(details));
    } catch (e) {
      if (previous != null) {
        emit(ShpByIdLoaded(previous));
      } else {
        emit(ShpByIdError(_msg(e)));
      }
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    return s.length > 300 ? s.substring(0, 300) : s;
  }
}