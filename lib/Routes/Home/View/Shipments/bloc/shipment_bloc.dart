import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Services/repository.dart';

import '../model/shp_model.dart';
import 'shipment_event.dart';
import 'shipment_state.dart';

class ShipmentBloc extends Bloc<ShipmentEvent, ShipmentState> {
  final Repositories _repository;

  // Remember last filter so RefreshShipments can replay it.
  String _status = 'pending';
  String? _search;
  String? _containerNo;
  String? _sequenceNo;
  String? _from;
  String? _to;

  // Kept so ResolveShipmentByInput can restore the list after emitting
  // a one-shot ShipmentResolved / ShipmentResolveNotFound.
  List<ShipmentModel> _lastShipments = const [];
  String _lastStatusFilter = 'pending';

  ShipmentBloc(this._repository) : super(const ShipmentInitial()) {
    on<LoadShipments>(_onLoadShipments);
    on<RefreshShipments>(_onRefreshShipments);

    on<CreateShipment>(_onCreateShipment);
    on<UpdateShipment>(_onUpdateShipment);
    on<DeleteShipment>(_onDeleteShipment);

    on<ResolveShipmentByInput>(_onResolveByInput);
  }

  // ─────────────────────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────────────────────
  Future<void> _onLoadShipments(
      LoadShipments event,
      Emitter<ShipmentState> emit,
      ) async {
    _status = event.status;
    _search = event.search;
    _containerNo = event.containerNo;
    _sequenceNo = event.sequenceNo;
    _from = event.from;
    _to = event.to;

    emit(const ShipmentLoading());

    try {
      final shipments = await _repository.getContainers(
        status: _status,
        search: _search,
        containerNo: _containerNo,
        sequenceNo: _sequenceNo,
        from: _from,
        to: _to,
      );

      _lastShipments = shipments;
      _lastStatusFilter = _status;

      emit(ShipmentLoaded(
        shipments: shipments,
        statusFilter: _status,
      ));
    } catch (e) {
      emit(ShipmentError(e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REFRESH
  // ─────────────────────────────────────────────────────────────
  Future<void> _onRefreshShipments(
      RefreshShipments event,
      Emitter<ShipmentState> emit,
      ) async {
    add(LoadShipments(
      status: _status,
      search: _search,
      containerNo: _containerNo,
      sequenceNo: _sequenceNo,
      from: _from,
      to: _to,
    ));
  }

  // ─────────────────────────────────────────────────────────────
  // RESOLVE INPUT → shpId (search-Enter)
  // ─────────────────────────────────────────────────────────────
  Future<void> _onResolveByInput(
      ResolveShipmentByInput event,
      Emitter<ShipmentState> emit,
      ) async {
    final query = event.input.trim();

    if (query.isEmpty) {
      // Nothing to resolve — restore the list.
      emit(ShipmentLoaded(
        shipments: _lastShipments,
        statusFilter: _lastStatusFilter,
      ));
      return;
    }

    try {
      // Search across ALL statuses so a shipped/delivered
      // container can still be opened by its number.
      final results = await _repository.getContainers(
        status: 'all',
        search: query,
      );

      if (results.isEmpty) {
        emit(ShipmentResolveNotFound(query));
        // Restore the list so the UI isn't blank behind the toast.
        emit(ShipmentLoaded(
          shipments: _lastShipments,
          statusFilter: _lastStatusFilter,
        ));
        return;
      }

      // Prefer an exact containerNo / sequenceNo match; otherwise first hit.
      final normalized = query.toLowerCase();
      final exact = results.firstWhere(
            (c) =>
        c.containerNo.toLowerCase() == normalized ||
            (c.sequenceNo ?? '').toLowerCase() == normalized,
        orElse: () => results.first,
      );

      emit(ShipmentResolved(exact.shpId));
      // Restore the list so when the user pops the detail screen,
      // they land on the same list they were viewing.
      emit(ShipmentLoaded(
        shipments: _lastShipments,
        statusFilter: _lastStatusFilter,
      ));
    } catch (e) {
      emit(ShipmentOperationError('Lookup failed: $e'));
      emit(ShipmentLoaded(
        shipments: _lastShipments,
        statusFilter: _lastStatusFilter,
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────
  Future<void> _onCreateShipment(
      CreateShipment event,
      Emitter<ShipmentState> emit,
      ) async {
    emit(const ShipmentOperationLoading('create'));

    try {
      final shpId = await _repository.addContainer(
        AddContainerRequest(
          user: event.usrName,
          portName: event.portName,
          containerNo: event.containerNo,
          loadingDate: event.loadingDate,
          sequenceNo: event.sequenceNo,
          unloadingDate: event.unloadingDate,
          description: event.description,
          status: event.status,
        ),
      );

      emit(ShipmentOperationSuccess(
        message: 'Container created successfully.',
        shpId: shpId,
      ));

      add(const RefreshShipments());
    } catch (e) {
      emit(ShipmentOperationError(e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────
  Future<void> _onUpdateShipment(
      UpdateShipment event,
      Emitter<ShipmentState> emit,
      ) async {
    emit(const ShipmentOperationLoading('update'));

    try {
      await _repository.updateContainer(
        UpdateContainerRequest(
          shpId: event.shpId,
          user: event.usrName,
          portName: event.portName,
          containerNo: event.containerNo,
          sequenceNo: event.sequenceNo,
          loadingDate: event.loadingDate,
          unloadingDate: event.unloadingDate,
          description: event.description,
          status: event.status,
        ),
      );

      emit(ShipmentOperationSuccess(
        message: 'Container updated successfully.',
        shpId: event.shpId,
      ));

      add(const RefreshShipments());
    } catch (e) {
      emit(ShipmentOperationError(e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────
  Future<void> _onDeleteShipment(
      DeleteShipment event,
      Emitter<ShipmentState> emit,
      ) async {
    emit(const ShipmentOperationLoading('delete'));

    try {
      await _repository.deleteContainer(
        DeleteContainerRequest(
          shpId: event.shpId,
          user: event.usrName,
          force: event.force,
        ),
      );

      emit(ShipmentOperationSuccess(
        message: 'Container deleted successfully.',
        shpId: event.shpId,
      ));

      add(const RefreshShipments());
    } catch (e) {
      emit(ShipmentOperationError(e.toString()));
    }
  }
}