import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shipping/Services/repository.dart';

import '../../../../../../../Services/localization_services.dart';
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
    on<ShpByIdUpdateItemStatusRequested>(_onUpdateItemStatus);
    on<ShpByIdExportRequested>(_onExportItems);
  }

  // ─────────────────────────────────────────────────────────
  // EXPORT ITEMS
  // ─────────────────────────────────────────────────────────
  Future<void> _onExportItems(
      ShpByIdExportRequested event,
      Emitter<ShpByIdState> emit,
      ) async {
    final current = state;
    if (current is! ShpByIdLoaded) return;

    final tr = localizationService.loc;

    emit(current.copyWith(
      clearActionError: true,
      clearSuccessMessage: true,
    ));

    try {
      final filePath = await _repo.exportContainerItems(shpId: event.shpId);
      final fileName = filePath.split('/').last;

      emit(current.copyWith(
        successMessage: tr.fileSaved(fileName),
      ));
    } catch (e) {
      emit(current.copyWith(
        actionError: tr.exportFailed(_msg(e)),
      ));
    }
  }

  /// Pulls a plain, lower-cased server message out of whatever the repo returned.
  /// Works whether the repo returned a String, a Map, or threw an ApiException.
  String _normalizeMsg(Object? result) {
    if (result == null) return 'failed';
    if (result is String) return result.trim().toLowerCase();
    if (result is Map) {
      final m = result['msg'];
      return m?.toString().trim().toLowerCase() ?? 'failed';
    }
    return result.toString().trim().toLowerCase();
  }

  Future<void> _onUpdateItemStatus(
      ShpByIdUpdateItemStatusRequested event,
      Emitter<ShpByIdState> emit,
      ) async {
    final current = state;
    if (current is! ShpByIdLoaded) return;

    final tr = localizationService.loc;

    emit(current.copyWith(
      pendingAction: ShpByIdAction.updateItemStatus,
      clearActionError: true,
      clearSuccessMessage: true,
    ));

    try {
      // Recalculate status using server-side delivery movements.
      final status = await _repo.updateShpItemStatus(
        usrName: event.usrName,
        shpItmId: event.shpItmId,
        status: event.status,
      );

      // Fetch fresh shipment details.
      final fresh = await _repo.getShippingDetails(
        shpId: event.shpId,
      );

      emit(ShpByIdLoaded(
        fresh,
        successMessage: tr.itemStatusUpdated(status),
      ));
    } catch (e) {
      emit(current.copyWith(
        clearPendingAction: true,
        actionError: tr.failedUpdateItemStatus(_msg(e)),
      ));
    }
  }

  // ─────────────────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────────────────
  Future<void> _onLoadRequested(ShpByIdLoadRequested event, Emitter<ShpByIdState> emit) async {
    final previous =
    state is ShpByIdLoaded ? (state as ShpByIdLoaded).details : null;
    emit(ShpByIdLoading(previous: previous));
    await _fetch(emit, event.shpId, previous: previous);
  }

  Future<void> _onRefreshed(ShpByIdRefreshed event, Emitter<ShpByIdState> emit) async {
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

    final tr = localizationService.loc;

    emit(current.copyWith(
      pendingAction: ShpByIdAction.addItem,
      clearActionError: true,
      clearSuccessMessage: true,
    ));

    try {
      final result = await _repo.addShpItem(
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

      switch (_normalizeMsg(result)) {
        case 'success':
          try {
            final fresh = await _repo.getShippingDetails(shpId: event.shpId);
            emit(ShpByIdLoaded(fresh, successMessage: tr.itemAdded));
          } catch (e) {
            // Server committed; refresh failed — still report success.
            emit(current.copyWith(
              clearPendingAction: true,
              successMessage: tr.itemAdded,
              actionError: tr.reloadFailed(_msg(e)),
            ));
          }
          return;

        case 'over limit':
          emit(current.copyWith(
            clearPendingAction: true,
            actionError: tr.overLimitAdd,
          ));
          return;

        case 'blocked':
          emit(current.copyWith(
            clearPendingAction: true,
            actionError: tr.blockedAdd,
          ));
          return;

        default:
          emit(current.copyWith(
            clearPendingAction: true,
            actionError: tr.operationFailed(_normalizeMsg(result)),
          ));
          return;
      }
    } catch (e) {
      emit(current.copyWith(
        clearPendingAction: true,
        actionError: tr.failedAddItem(_msg(e)),
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

    final tr = localizationService.loc;

    emit(current.copyWith(
      pendingAction: ShpByIdAction.updateItem,
      clearActionError: true,
      clearSuccessMessage: true,
    ));

    try {
      final result = await _repo.updateShpItem(
        user: event.usrName,
        shpItmId: event.shpItmId,
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

      switch (_normalizeMsg(result)) {
        case 'success':
          try {
            final fresh = await _repo.getShippingDetails(shpId: event.shpId);
            emit(ShpByIdLoaded(fresh, successMessage: tr.itemUpdated));
          } catch (e) {
            emit(current.copyWith(
              clearPendingAction: true,
              successMessage: tr.itemUpdated,
              actionError: tr.reloadFailed(_msg(e)),
            ));
          }
          return;

        case 'over limit':
          emit(current.copyWith(
            clearPendingAction: true,
            actionError: tr.overLimitUpdate,
          ));
          return;

        case 'blocked':
          emit(current.copyWith(
            clearPendingAction: true,
            actionError: tr.blockedUpdate,
          ));
          return;

        default:
          emit(current.copyWith(
            clearPendingAction: true,
            actionError: tr.operationFailed(_normalizeMsg(result)),
          ));
          return;
      }
    } catch (e) {
      emit(current.copyWith(
        clearPendingAction: true,
        actionError: tr.failedUpdateItem(_msg(e)),
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

    final tr = localizationService.loc;

    emit(current.copyWith(
      pendingAction: ShpByIdAction.deleteItem,
      clearActionError: true,
      clearSuccessMessage: true,
    ));

    try {
      await _repo.deleteShpItem(
        usrName: event.usrName,
        shpItmId: event.shpItmId,
        shpId: event.shpId,
      );

      final fresh = await _repo.getShippingDetails(shpId: event.shpId);
      emit(ShpByIdLoaded(
        fresh,
        successMessage: tr.itemDeleted,
      ));
    } catch (e) {
      emit(current.copyWith(
        clearPendingAction: true,
        actionError: tr.failedDeleteItem(_msg(e)),
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
      final details = await _repo.getShippingDetails(shpId: shpId);
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