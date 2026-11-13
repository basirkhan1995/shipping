part of 'goods_shift_bloc.dart';

abstract class GoodsShiftEvent extends Equatable {
  const GoodsShiftEvent();
  @override
  List<Object?> get props => [];
}

class LoadGoodsShiftsEvent extends GoodsShiftEvent {}

class LoadGoodsShiftByIdEvent extends GoodsShiftEvent {
  final int orderId;
  const LoadGoodsShiftByIdEvent(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

class AddGoodsShiftEvent extends GoodsShiftEvent {
  final String usrName;
  final List<ShiftRecord> records;
  const AddGoodsShiftEvent({
    required this.usrName,
    required this.records,
  });
  @override
  List<Object?> get props => [usrName, records];
}

class UpdateGoodsShiftEvent extends GoodsShiftEvent {
  final int ordID;
  final String usrName;
  final List<ShiftRecord> records;
  const UpdateGoodsShiftEvent({
    required this.ordID,
    required this.usrName,
    required this.records,
  });
  @override
  List<Object?> get props => [ordID, usrName, records];
}

class DeleteGoodsShiftEvent extends GoodsShiftEvent {
  final int orderId;
  final String usrName;
  const DeleteGoodsShiftEvent({
    required this.orderId,
    required this.usrName,
  });
  @override
  List<Object?> get props => [orderId, usrName];
}

/// NEW — bulk authorize one or more goods shifts.
/// Payload shape matches the backend `change_orders_status`:
///   [{ "ordID": 5, "ordStatus": "Authorized" }, ...]
class AuthorizeGoodsShiftsEvent extends GoodsShiftEvent {
  final List<Map<String, dynamic>> ordersData;
  const AuthorizeGoodsShiftsEvent(this.ordersData);
  @override
  List<Object?> get props => [ordersData];
}

class ReturnToShiftsListEvent extends GoodsShiftEvent {}