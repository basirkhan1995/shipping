import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Services/repository.dart';
import 'shipment_event.dart';
import 'shipment_state.dart';

class ShipmentBloc extends Bloc<ShipmentEvent, ShipmentState> {
  final Repositories _repository;

  String? _usrName;
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
  }

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

  Future<void> _onLoadMoreShipments(
      LoadMoreShipments event,
      Emitter<ShipmentState> emit,
      ) async {
    final currentState = state;

    if (currentState is! ShipmentLoaded ||
        currentState.isLoadingMore ||
        !currentState.hasMore ||
        _usrName == null) {
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
      emit(
        currentState.copyWith(isLoadingMore: false),
      );
    }
  }

  Future<void> _onRefreshShipments(
      RefreshShipments event,
      Emitter<ShipmentState> emit,
      ) async {
    if (_usrName == null) return;

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
}