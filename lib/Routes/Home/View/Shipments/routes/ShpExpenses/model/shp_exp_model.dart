// Routes/Home/View/Shipments/routes/ShpByID/model/shipment_expense_model.dart

class ShipmentExpenseModel {
  final int expId;
  final int shpId;
  final String shpReference;
  final String? containerNo;
  final String? sequenceNo;
  final double amount;
  final String ccy;
  final int drAccount;
  final int crAccount;
  final String? crAccountName;
  final String narration;
  final String? entryDate;

  const ShipmentExpenseModel({
    required this.expId,
    required this.shpId,
    required this.shpReference,
    this.containerNo,
    this.sequenceNo,
    required this.amount,
    required this.ccy,
    required this.drAccount,
    required this.crAccount,
    this.crAccountName,
    required this.narration,
    this.entryDate,
  });

  factory ShipmentExpenseModel.fromMap(Map<String, dynamic> json) {
    return ShipmentExpenseModel(
      expId: _toInt(json['expId']),
      shpId: _toInt(json['shpId']),
      shpReference: json['shpReference']?.toString() ?? '',
      containerNo: json['containerNo']?.toString(),
      sequenceNo: json['sequenceNo']?.toString(),
      amount: _toDouble(json['amount']),
      ccy: json['ccy']?.toString() ?? '',
      drAccount: _toInt(json['drAccount']),
      crAccount: _toInt(json['crAccount']),
      crAccountName: json['crAccountName']?.toString(),
      narration: json['narration']?.toString() ?? '',
      entryDate: json['entryDate']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'expId': expId,
    'shpId': shpId,
    'shpReference': shpReference,
    'containerNo': containerNo,
    'sequenceNo': sequenceNo,
    'amount': amount,
    'ccy': ccy,
    'drAccount': drAccount,
    'crAccount': crAccount,
    'crAccountName': crAccountName,
    'narration': narration,
    'entryDate': entryDate,
  };
}

// Write result (add + update) — the API returns the resolved record
class ShipmentExpenseWriteResult {
  final int expId;
  final int shpId;
  final String shpReference;
  final double amount;
  final String ccy;
  final int drAccount;
  final int crAccount;
  final String narration;

  const ShipmentExpenseWriteResult({
    required this.expId,
    required this.shpId,
    required this.shpReference,
    required this.amount,
    required this.ccy,
    required this.drAccount,
    required this.crAccount,
    required this.narration,
  });

  factory ShipmentExpenseWriteResult.fromMap(Map<String, dynamic> json) {
    return ShipmentExpenseWriteResult(
      expId: _toInt(json['expId']),
      shpId: _toInt(json['shpId']),
      shpReference: json['shpReference']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      ccy: json['ccy']?.toString() ?? '',
      drAccount: _toInt(json['drAccount']),
      crAccount: _toInt(json['crAccount']),
      narration: json['narration']?.toString() ?? '',
    );
  }
}

// List result — mirrors the `{ ok, shpId, shpReference, count, data }` envelope
class ShipmentExpenseListResult {
  final int shpId;
  final String shpReference;
  final int count;
  final List<ShipmentExpenseModel> items;

  const ShipmentExpenseListResult({
    required this.shpId,
    required this.shpReference,
    required this.count,
    required this.items,
  });

  factory ShipmentExpenseListResult.fromMap(Map<String, dynamic> json) {
    final raw = json['data'];
    return ShipmentExpenseListResult(
      shpId: _toInt(json['shpId']),
      shpReference: json['shpReference']?.toString() ?? '',
      count: _toInt(json['count']),
      items: raw is List
          ? raw
          .whereType<Map>()
          .map((e) => ShipmentExpenseModel.fromMap(
        Map<String, dynamic>.from(e),
      ))
          .toList()
          : const [],
    );
  }
}

// Delete result
class ShipmentExpenseDeleteResult {
  final int expId;
  final String shpReference;

  const ShipmentExpenseDeleteResult({
    required this.expId,
    required this.shpReference,
  });

  factory ShipmentExpenseDeleteResult.fromMap(Map<String, dynamic> json) {
    return ShipmentExpenseDeleteResult(
      expId: _toInt(json['expId']),
      shpReference: json['shpReference']?.toString() ?? '',
    );
  }
}

// Tiny tolerant helpers (mirror shp_details_model.dart)
int _toInt(dynamic v) {
  if (v == null) return 0;
  return int.tryParse(v.toString()) ??
      double.tryParse(v.toString())?.toInt() ??
      0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  return double.tryParse(v.toString()) ?? 0.0;
}