
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Services/repository.dart';

import 'shipment_event.dart';
import 'shipment_state.dart';

class ShipmentBloc extends Bloc<ShipmentEvent, ShipmentState> {
  final Repositories _repository;

  String _status = 'pending';
  String? _shpReference;
  String? _containerNo;
  String? _sequenceNo;
  String? _from;
  String? _to;

  int _currentPage = 1;
  final int _pageSize = 50;

  ShipmentBloc(this._repository) : super(const ShipmentInitial()) {
    on<LoadShipments>(_onLoadShipments);
    on<LoadMoreShipments>(_onLoadMoreShipments);
    on<RefreshShipments>(_onRefreshShipments);

    on<CreateShipment>(_onCreateShipment);
    on<UpdateShipment>(_onUpdateShipment);
    on<DeleteShipment>(_onDeleteShipment);
  }

  // ─────────────────────────────────────────────────────────────
  // LOAD CONTAINERS
  // ─────────────────────────────────────────────────────────────

  Future<void> _onLoadShipments(
      LoadShipments event,
      Emitter<ShipmentState> emit,
      ) async {
    _status = event.status;
    _shpReference = event.shpReference;
    _containerNo = event.containerNo;
    _sequenceNo = event.sequenceNo;
    _from = event.from;
    _to = event.to;

    _currentPage = 1;

    emit(const ShipmentLoading());

    try {
      final result = await _repository.getContainers(
        status: _status,
        shpReference: _shpReference,
        containerNo: _containerNo,
        sequenceNo: _sequenceNo,
        from: _from,
        to: _to,
        page: _currentPage,
        size: _pageSize,
      );

      emit(
        ShipmentLoaded(
          shipments: result.data,
          page: result.page,
          size: result.size,
          statusFilter: result.statusFilter,
          hasMore: result.data.length == _pageSize,
        ),
      );
    } catch (e) {
      emit(ShipmentError(e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LOAD MORE
  // ─────────────────────────────────────────────────────────────

  Future<void> _onLoadMoreShipments(
      LoadMoreShipments event,
      Emitter<ShipmentState> emit,
      ) async {
    final currentState = state;

    if (currentState is! ShipmentLoaded ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = _currentPage + 1;

      final result = await _repository.getContainers(
        status: _status,
        shpReference: _shpReference,
        containerNo: _containerNo,
        sequenceNo: _sequenceNo,
        from: _from,
        to: _to,
        page: nextPage,
        size: _pageSize,
      );

      _currentPage = nextPage;

      emit(
        currentState.copyWith(
          shipments: [...currentState.shipments, ...result.data],
          page: result.page,
          hasMore: result.data.length == _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REFRESH
  // ─────────────────────────────────────────────────────────────

  Future<void> _onRefreshShipments(
      RefreshShipments event,
      Emitter<ShipmentState> emit,
      ) async {
    add(
      LoadShipments(
        status: _status,
        shpReference: _shpReference,
        containerNo: _containerNo,
        sequenceNo: _sequenceNo,
        from: _from,
        to: _to,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CREATE CONTAINER
  // ─────────────────────────────────────────────────────────────

  Future<void> _onCreateShipment(CreateShipment event, Emitter<ShipmentState> emit) async {
    emit(const ShipmentOperationLoading('create'));

    try {
      final shpId = await _repository.createContainer(
        usrName: event.usrName,
        portName: event.portName,
        containerNo: event.containerNo,
        loadingDate: event.loadingDate,
        sequenceNo: event.sequenceNo,
        unloadingDate: event.unloadingDate,
        description: event.description,
      );

      emit(
        ShipmentOperationSuccess(
          message: 'Container created successfully.',
          shpId: shpId,
        ),
      );

      add(RefreshShipments());
    } catch (e) {
      emit(ShipmentOperationError(e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE CONTAINER
  // ─────────────────────────────────────────────────────────────

  Future<void> _onUpdateShipment(
      UpdateShipment event,
      Emitter<ShipmentState> emit,
      ) async {
    emit(const ShipmentOperationLoading('update'));

    try {
      await _repository.updateContainer(
        usrName: event.usrName,
        shpId: event.shpId,
        portName: event.portName,
        containerNo: event.containerNo,
        sequenceNo: event.sequenceNo,
        loadingDate: event.loadingDate,
        unloadingDate: event.unloadingDate,
        description: event.description,
        status: event.status,
      );

      emit(
        ShipmentOperationSuccess(
          message: 'Container updated successfully.',
          shpId: event.shpId,
        ),
      );

      add(RefreshShipments());
    } catch (e) {
      emit(ShipmentOperationError(e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE CONTAINER
  // ─────────────────────────────────────────────────────────────

  Future<void> _onDeleteShipment(
      DeleteShipment event,
      Emitter<ShipmentState> emit,
      ) async {
    emit(const ShipmentOperationLoading('delete'));

    try {
      await _repository.deleteContainer(
        usrName: event.usrName,
        shpId: event.shpId,
      );

      emit(
        ShipmentOperationSuccess(
          message: 'Container deleted successfully.',
          shpId: event.shpId,
        ),
      );

      add(RefreshShipments());
    } catch (e) {
      emit(ShipmentOperationError(e.toString()));
    }
  }
}
