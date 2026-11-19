
class ShipmentDetailsModel {
  final bool ok;
  final ShipmentModel shipment;
  final List<ShipmentItemModel> items;

  const ShipmentDetailsModel({
    required this.ok,
    required this.shipment,
    required this.items,
  });

  factory ShipmentDetailsModel.fromJson(Map<String, dynamic> json) {
    return ShipmentDetailsModel(
      ok: json['ok'] == true,
      shipment: ShipmentModel.fromJson(
        Map<String, dynamic>.from(json['shipment'] ?? {}),
      ),
      items: (json['items'] as List? ?? [])
          .map((e) => ShipmentItemModel.fromJson(
        Map<String, dynamic>.from(e),
      ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'ok': ok,
    'shipment': shipment.toJson(),
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class ShipmentModel {
  final int shpId;
  final String shpReference;
  final String? entryDate;
  final String? updatedAt;
  final int? createdBy;
  final String? portName;
  final String? containerNo;
  final String? sequenceNo;
  final String? loadingDate;
  final String? unloadingDate;
  final String? description;
  final String? status;

  const ShipmentModel({
    required this.shpId,
    required this.shpReference,
    this.entryDate,
    this.updatedAt,
    this.createdBy,
    this.portName,
    this.containerNo,
    this.sequenceNo,
    this.loadingDate,
    this.unloadingDate,
    this.description,
    this.status,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      shpId: _toInt(json['shpId']),
      shpReference: json['shpReference']?.toString() ?? '',
      entryDate: json['entryDate']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      createdBy: _toNullableInt(json['createdBy']),
      portName: json['portName']?.toString(),
      containerNo: json['containerNo']?.toString(),
      sequenceNo: json['sequenceNo']?.toString(),
      loadingDate: json['loadingDate']?.toString(),
      unloadingDate: json['unloadingDate']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'shpId': shpId,
    'shpReference': shpReference,
    'entryDate': entryDate,
    'updatedAt': updatedAt,
    'createdBy': createdBy,
    'portName': portName,
    'containerNo': containerNo,
    'sequenceNo': sequenceNo,
    'loadingDate': loadingDate,
    'unloadingDate': unloadingDate,
    'description': description,
    'status': status,
  };
}

class ShipmentItemModel {
  final int shpItmId;
  final int shpId;
  final String accountNo;
  final String? itemDescription;
  final double qty;
  final double cbm;
  final double weight;
  final double ratePerCbm;
  final double ratePerWeight;
  final double extraCharges;
  final String? status;
  final String? entryDate;
  final String? updatedAt;

  final int? perID;
  final String? perCode;
  final String? perName;
  final String? perLastName;
  final String? fullName;

  final double weightAvg;
  final double itemRent;
  final double delivered;
  final double returned;
  final double unloaded;

  const ShipmentItemModel({
    required this.shpItmId,
    required this.shpId,
    required this.accountNo,
    this.itemDescription,
    required this.qty,
    required this.cbm,
    required this.weight,
    required this.ratePerCbm,
    required this.ratePerWeight,
    required this.extraCharges,
    this.status,
    this.entryDate,
    this.updatedAt,
    this.perID,
    this.perCode,
    this.perName,
    this.perLastName,
    this.fullName,
    required this.weightAvg,
    required this.itemRent,
    required this.delivered,
    required this.returned,
    required this.unloaded,
  });

  factory ShipmentItemModel.fromJson(Map<String, dynamic> json) {
    return ShipmentItemModel(
      shpItmId: _toInt(json['shpItmId']),
      shpId: _toInt(json['shpId']),
      accountNo: json['AccountNo']?.toString() ?? '',
      itemDescription: json['itemDescription']?.toString(),
      qty: _toDouble(json['qty']),
      cbm: _toDouble(json['cbm']),
      weight: _toDouble(json['weight']),
      ratePerCbm: _toDouble(json['ratePerCbm']),
      ratePerWeight: _toDouble(json['ratePerWeight']),
      extraCharges: _toDouble(json['extraCharges']),
      status: json['status']?.toString(),
      entryDate: json['entryDate']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      perID: _toNullableInt(json['perID']),
      perCode: json['perCode']?.toString(),
      perName: json['perName']?.toString(),
      perLastName: json['perLastName']?.toString(),
      fullName: json['fullName']?.toString(),
      weightAvg: _toDouble(json['weightAvg']),
      itemRent: _toDouble(json['itemRent']),
      delivered: _toDouble(json['delivered']),
      returned: _toDouble(json['returned']),
      unloaded: _toDouble(json['unloaded']),
    );
  }

  Map<String, dynamic> toJson() => {
    'shpItmId': shpItmId,
    'shpId': shpId,
    'AccountNo': accountNo,
    'itemDescription': itemDescription,
    'qty': qty,
    'cbm': cbm,
    'weight': weight,
    'ratePerCbm': ratePerCbm,
    'ratePerWeight': ratePerWeight,
    'extraCharges': extraCharges,
    'status': status,
    'entryDate': entryDate,
    'updatedAt': updatedAt,
    'perID': perID,
    'perCode': perCode,
    'perName': perName,
    'perLastName': perLastName,
    'fullName': fullName,
    'weightAvg': weightAvg,
    'itemRent': itemRent,
    'delivered': delivered,
    'returned': returned,
    'unloaded': unloaded,
  };
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  return int.tryParse(value.toString()) ??
      double.tryParse(value.toString())?.toInt() ??
      0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  return _toInt(value);
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  return double.tryParse(value.toString()) ?? 0.0;
}

