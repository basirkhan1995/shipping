import '../../../model/shp_model.dart';

class ShipmentDetailsModel {
  final ShipmentModel shipment;
  final List<ShipmentItemModel> items;

  const ShipmentDetailsModel({
    required this.shipment,
    required this.items,
  });

  /// Parses the flat response:
  /// {
  ///   "shpId": 1, "portName": "...", "containerNo": "...", ...,
  ///   "items": [ {...}, {...} ]
  /// }
  factory ShipmentDetailsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> shipmentJson =
    Map<String, dynamic>.from(json)..remove('items'); // root IS the shipment

    return ShipmentDetailsModel(
      shipment: ShipmentModel.fromJson(shipmentJson),
      items: (json['items'] as List? ?? const [])
          .map((e) => ShipmentItemModel.fromJson(
        Map<String, dynamic>.from(e as Map),
      ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    ...shipment.toJson(),
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class ShipmentItemModel {
  final int shpItmId;
  final int shpId;
  final String? itemDescription;
  final String accountNo;       // API sends number, model keeps it as String
  final double qty;
  final double cbm;
  final double weight;
  final double ratePerCbm;
  final double ratePerWeight;
  final double extraCharges;
  final String? status;
  final int? payReference;      // API sends int
  final String? entryDate;
  final String? updatedAt;
  final double weightAvg;       // JSON key: weightAVG
  final double itemRent;
  final int? perID;
  final String? perCode;
  final String? perName;
  final String? perLastName;
  final String? perPhone;

  const ShipmentItemModel({
    required this.shpItmId,
    required this.shpId,
    this.itemDescription,
    required this.accountNo,
    required this.qty,
    required this.cbm,
    required this.weight,
    required this.ratePerCbm,
    required this.ratePerWeight,
    required this.extraCharges,
    this.status,
    this.payReference,
    this.entryDate,
    this.updatedAt,
    required this.weightAvg,
    required this.itemRent,
    this.perID,
    this.perCode,
    this.perName,
    this.perLastName,
    this.perPhone,
  });

  factory ShipmentItemModel.fromJson(Map<String, dynamic> json) {
    return ShipmentItemModel(
      shpItmId: _toInt(json['shpItmId']),
      shpId: _toInt(json['shpId']),
      itemDescription: json['itemDescription']?.toString(),

      // ✅ API key is `accountNo` (camelCase). Kept as String for the UI.
      accountNo: json['accountNo']?.toString() ?? '',

      qty: _toDouble(json['qty']),
      cbm: _toDouble(json['cbm']),
      weight: _toDouble(json['weight']),
      ratePerCbm: _toDouble(json['ratePerCbm']),
      ratePerWeight: _toDouble(json['ratePerWeight']),
      extraCharges: _toDouble(json['extraCharges']),

      status: json['status']?.toString(),

      // ✅ API sends `payReference` as int.
      payReference: _toNullableInt(json['payReference']),

      entryDate: json['entryDate']?.toString(),
      updatedAt: json['updatedAt']?.toString(),

      // ✅ API key is `weightAVG` (uppercase AVG).
      weightAvg: _toDouble(json['weightAVG']),
      itemRent: _toDouble(json['itemRent']),

      perID: _toNullableInt(json['perID']),
      perCode: json['perCode']?.toString(),
      perName: json['perName']?.toString(),
      perLastName: json['perLastName']?.toString(),
      perPhone: json['perPhone']?.toString(),
    );
  }

  /// Convenience getter (not in JSON, computed) — use in the table.
  String get fullName {
    final first = (perName ?? '').trim();
    final last = (perLastName ?? '').trim();
    return [if (first.isNotEmpty) first, if (last.isNotEmpty) last].join(' ');
  }

  Map<String, dynamic> toJson() => {
    'shpItmId': shpItmId,
    'shpId': shpId,
    'itemDescription': itemDescription,
    'accountNo': accountNo,
    'qty': qty,
    'cbm': cbm,
    'weight': weight,
    'ratePerCbm': ratePerCbm,
    'ratePerWeight': ratePerWeight,
    'extraCharges': extraCharges,
    'status': status,
    'payReference': payReference,
    'entryDate': entryDate,
    'updatedAt': updatedAt,
    'weightAVG': weightAvg,
    'itemRent': itemRent,
    'perID': perID,
    'perCode': perCode,
    'perName': perName,
    'perLastName': perLastName,
    'perPhone': perPhone,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Safe numeric parsers (tolerate null, int, double, "1.5000", "1,500")
// ─────────────────────────────────────────────────────────────────────────────
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();

  final s = value.toString().trim().replaceAll(',', '');
  return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  final s = value.toString().trim().replaceAll(',', '');
  return int.tryParse(s) ?? double.tryParse(s)?.toInt();
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is num) return value.toDouble();

  final s = value.toString().trim().replaceAll(',', '');
  return double.tryParse(s) ?? 0.0;
}