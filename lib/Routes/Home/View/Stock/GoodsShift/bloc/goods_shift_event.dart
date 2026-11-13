part of 'goods_shift_bloc.dart';

abstract class GoodsShiftEvent extends Equatable {
  const GoodsShiftEvent();
  @override
  List<Object?> get props => [];
}

/// Loads shifts with optional filters.
/// - If `status` is null → backend default (Pending).
/// - If `from`/`to` are null → no date bounds.
/// - Pass `status: 'All'` to include Pending + Authorized + Deleted.
class LoadGoodsShiftsEvent extends GoodsShiftEvent {
  final String? status; // 'Pending' | 'Authorized' | 'Deleted' | 'All' | null
  final DateTime? from;
  final DateTime? to;

  const LoadGoodsShiftsEvent({
    this.status,
    this.from,
    this.to,
  });

  @override
  List<Object?> get props => [status, from, to];
}

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

/// Bulk status change. Backend `change_orders_status` receives:
///   [{ "ordID": 5, "ordStatus": "Authorized" | "Pending" }, ...]
///
/// `targetStatus` is used only on the Flutter side to know what to
/// toast after success — the actual status change is carried inside
/// `ordersData`.
class AuthorizeGoodsShiftsEvent extends GoodsShiftEvent {
  final List<Map<String, dynamic>> ordersData;
  final String targetStatus; // 'Authorized' | 'Pending'

  const AuthorizeGoodsShiftsEvent(
      this.ordersData, {
        this.targetStatus = 'Authorized',
      });

  @override
  List<Object?> get props => [ordersData, targetStatus];
}

class ReturnToShiftsListEvent extends GoodsShiftEvent {}