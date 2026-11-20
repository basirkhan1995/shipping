class ShipmentModel {
  final int shpId;
  final String? containerNo;
  final String? entryDate;
  final String? sequenceNo;
  final String? loadingDate;
  final String? unloadingDate;
  final String? portName;
  final String? description;
  final String status;
  final int? createdBy;
  final String? createdByName;
  final int totalItems;
  final double totalRent;

  const ShipmentModel({
    required this.shpId,
    this.containerNo,
    this.entryDate,
    this.sequenceNo,
    this.loadingDate,
    this.unloadingDate,
    this.portName,
    this.description,
    required this.status,
    this.createdBy,
    this.createdByName,
    required this.totalItems,
    required this.totalRent,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      shpId: _toInt(json['shpId']),
      containerNo: _toString(json['containerNo']),
      entryDate: _toString(json['entryDate']),
      sequenceNo: _toString(json['sequenceNo']),
      loadingDate: _toString(json['loadingDate']),
      unloadingDate: _toString(json['unloadingDate']),
      portName: _toString(json['portName']),
      description: _toString(json['description']),
      status: _toString(json['status']) ?? 'pending',
      createdBy:
      json['createdBy'] == null ? null : _toInt(json['createdBy']),
      createdByName: _toString(json['createdByName']),
      totalItems: _toInt(json['totalItems']),
      totalRent: _toDouble(json['totalRent']),
    );
  }

  Map<String, dynamic> toJson() => {
    'shpId': shpId,
    'containerNo': containerNo,
    'entryDate': entryDate,
    'sequenceNo': sequenceNo,
    'loadingDate': loadingDate,
    'unloadingDate': unloadingDate,
    'portName': portName,
    'description': description,
    'status': status,
    'createdBy': createdBy,
    'createdByName': createdByName,
    'totalItems': totalItems,
    'totalRent': totalRent,
  };

  static String? _toString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}

class ShipmentListResponse {
  final bool ok;
  final List<ShipmentModel> data;
  final int page;
  final int size;
  final String statusFilter;

  const ShipmentListResponse({
    required this.ok,
    required this.data,
    required this.page,
    required this.size,
    required this.statusFilter,
  });

  factory ShipmentListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    final List<ShipmentModel> shipments = [];

    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map) {
          shipments.add(
            ShipmentModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return ShipmentListResponse(
      ok: json['ok'] == true,
      data: shipments,
      page: ShipmentModel._toInt(json['page']),
      size: ShipmentModel._toInt(json['size']),
      statusFilter: json['statusFilter']?.toString() ?? 'pending',
    );
  }
}
