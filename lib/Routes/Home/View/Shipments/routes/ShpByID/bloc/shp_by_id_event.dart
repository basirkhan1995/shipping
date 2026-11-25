part of 'shp_by_id_bloc.dart';

sealed class ShpByIdEvent extends Equatable {
  const ShpByIdEvent();

  @override
  List<Object?> get props => [];
}

/// Load shipment details (initial load).
final class ShpByIdLoadRequested extends ShpByIdEvent {
  final int shpId;
  const ShpByIdLoadRequested(this.shpId);

  @override
  List<Object?> get props => [shpId];
}

/// Pull-to-refresh.
final class ShpByIdRefreshed extends ShpByIdEvent {
  final int shpId;
  const ShpByIdRefreshed(this.shpId);

  @override
  List<Object?> get props => [shpId];
}

/// ── ADD ITEM ────────────────────────────────────────────────
final class ShpByIdAddItemRequested extends ShpByIdEvent {
  final int shpId;
  final String usrName;
  final String accountNo;
  final String itemDescription;
  final double qty;
  final double cbm;
  final double weight;
  final double ratePerCbm;
  final double ratePerWeight;
  final double extraCharges;

  const ShpByIdAddItemRequested({
    required this.shpId,
    required this.usrName,
    required this.accountNo,
    required this.itemDescription,
    required this.qty,
    this.cbm = 0,
    this.weight = 0,
    this.ratePerCbm = 0,
    this.ratePerWeight = 0,
    this.extraCharges = 0,
  });

  @override
  List<Object?> get props => [
    shpId,
    usrName,
    accountNo,
    itemDescription,
    qty,
    cbm,
    weight,
    ratePerCbm,
    ratePerWeight,
    extraCharges,
  ];
}

/// ── UPDATE ITEM ─────────────────────────────────────────────
final class ShpByIdUpdateItemRequested extends ShpByIdEvent {
  final int shpId;
  final int shpItmId;
  final String usrName;
  final String? accountNo;
  final String? itemDescription;
  final double? qty;
  final double? cbm;
  final double? weight;
  final double? ratePerCbm;
  final double? ratePerWeight;
  final double? extraCharges;

  const ShpByIdUpdateItemRequested({
    required this.shpId,
    required this.shpItmId,
    required this.usrName,
    this.accountNo,
    this.itemDescription,
    this.qty,
    this.cbm,
    this.weight,
    this.ratePerCbm,
    this.ratePerWeight,
    this.extraCharges,
  });

  @override
  List<Object?> get props => [
    shpId,
    shpItmId,
    usrName,
    accountNo,
    itemDescription,
    qty,
    cbm,
    weight,
    ratePerCbm,
    ratePerWeight,
    extraCharges,
  ];
}

/// ── DELETE ITEM ─────────────────────────────────────────────
final class ShpByIdDeleteItemRequested extends ShpByIdEvent {
  final int shpId;
  final int shpItmId;
  final String usrName;

  const ShpByIdDeleteItemRequested({
    required this.shpId,
    required this.shpItmId,
    required this.usrName,
  });

  @override
  List<Object?> get props => [shpId, shpItmId, usrName];
}

/// Clear the one-shot action error (e.g. after showing a snackbar).
final class ShpByIdActionErrorCleared extends ShpByIdEvent {
  const ShpByIdActionErrorCleared();
}


class ShpByIdUpdateItemStatusRequested extends ShpByIdEvent {
  final String usrName;
  final int shpId;
  final int shpItmId;
  final String status;

  const ShpByIdUpdateItemStatusRequested({
    required this.usrName,
    required this.shpId,
    required this.shpItmId,
    required this.status,
  });

  @override
  List<Object?> get props => [
    usrName,
    shpId,
    shpItmId,
    status,
  ];
}
/// ── EXPORT ITEMS ─────────────────────────────────────────────
final class ShpByIdExportRequested extends ShpByIdEvent {
  final int shpId;

  const ShpByIdExportRequested({
    required this.shpId,
  });

  @override
  List<Object?> get props => [shpId];
}

