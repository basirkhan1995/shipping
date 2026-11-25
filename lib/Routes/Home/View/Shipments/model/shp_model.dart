

class ShipmentModel {
  final int shpId;
  final String portName;
  final String containerNo;
  final String? sequenceNo;
  final String loadingDate;      // "YYYY-MM-DD"
  final String? unloadingDate;   // "YYYY-MM-DD" or null
  final String? description;
  final String entryDate;        // "YYYY-MM-DD HH:mm:ss"
  final String? updatedAt;
  final int createdBy;
  final String status;           // "pending" | "shipped" | "delivered"
  final String? createdByName;
  final String? totalItems;
  final String? totalWeight;
  final String? totalCbm;
  final int totalReferences;
  final String totalRent;        // DECIMAL as string

  const ShipmentModel({
    required this.shpId,
    required this.portName,
    required this.containerNo,
    this.sequenceNo,
    required this.loadingDate,
    this.unloadingDate,
    this.description,
    required this.entryDate,
    this.updatedAt,
    required this.createdBy,
    required this.status,
    this.createdByName,
     this.totalItems,
    required this.totalReferences,
    this.totalWeight,
    this.totalCbm,
    required this.totalRent,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) =>
      ShipmentModel(
        shpId: json['shpId'] as int,
        portName: json['portName'] as String,
        containerNo: json['containerNo'] as String,
        sequenceNo: json['sequenceNo'] as String?,
        loadingDate: json['loadingDate'] as String,
        unloadingDate: json['unloadingDate'] as String?,
        description: json['description'] as String?,
        entryDate: json['entryDate'] as String,
        updatedAt: json['updatedAt'] as String?,
        createdBy: json['createdBy'] as int,
        status: json['status'] as String,
        createdByName: json['createdByName'] as String?,
        totalItems: json['totalItems'] as String?,
        totalReferences: json['totalReferences'] as int? ?? 0,
        totalRent: json['totalRent']?.toString() ?? '0',
        totalCbm: json['totalCbm']?.toString() ?? '0',
        totalWeight: json['totalWeight']?.toString() ?? '0',
      );

  Map<String, dynamic> toJson() => {
    'shpId': shpId,
    'portName': portName,
    'containerNo': containerNo,
    'sequenceNo': sequenceNo,
    'loadingDate': loadingDate,
    'unloadingDate': unloadingDate,
    'description': description,
    'entryDate': entryDate,
    'updatedAt': updatedAt,
    'createdBy': createdBy,
    'status': status,
    'createdByName': createdByName,
    'totalItems': totalItems,
    'totalReferences': totalReferences,
    'totalRent': totalRent,
  };
}

// -------------------------
// ERROR (all non-200 responses)
// -------------------------
class ApiError {
  final String msg;
  final String? error;
  final String? detail;
  final int? line;
  final String? file;
  final int? items;

  const ApiError({
    required this.msg,
    this.error,
    this.detail,
    this.line,
    this.file,
    this.items,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
    msg: json['msg']?.toString() ?? 'failed',
    error: json['error']?.toString(),
    detail: json['detail']?.toString(),
    line: json['line'] as int?,
    file: json['file'] as String?,
    items: json['items'] as int?,
  );
}

// -------------------------
// MUTATION RESULT (POST / PUT)
// -------------------------
class ShipmentMutationResult {
  final String msg;
  final int shpId;

  const ShipmentMutationResult({required this.msg, required this.shpId});

  factory ShipmentMutationResult.fromJson(Map<String, dynamic> json) =>
      ShipmentMutationResult(
        msg: json['msg'] as String,
        shpId: json['shpId'] as int,
      );
}

// -------------------------
// DELETE RESULT
// -------------------------
class ShipmentDeleteResult {
  final String msg;
  final int shpId;
  final bool forced;
  final int itemsDeleted;

  const ShipmentDeleteResult({
    required this.msg,
    required this.shpId,
    required this.forced,
    required this.itemsDeleted,
  });

  factory ShipmentDeleteResult.fromJson(Map<String, dynamic> json) =>
      ShipmentDeleteResult(
        msg: json['msg'] as String,
        shpId: json['shpId'] as int,
        forced: json['forced'] as bool? ?? false,
        itemsDeleted: json['itemsDeleted'] as int? ?? 0,
      );
}

// ============================================================
// shipment_models.dart (add these below the existing classes)
// ============================================================

// -------------------------
// ADD CONTAINER REQUEST
// -------------------------
class AddContainerRequest {
  final String user;
  final String portName;
  final String containerNo;
  final String loadingDate;      // "YYYY-MM-DD"
  final String? sequenceNo;
  final String? unloadingDate;   // "YYYY-MM-DD" or null
  final String? description;
  final String status;           // "pending" | "shipped" | "delivered"

  const AddContainerRequest({
    required this.user,
    required this.portName,
    required this.containerNo,
    required this.loadingDate,
    this.sequenceNo,
    this.unloadingDate,
    this.description,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
    'user': user,
    'portName': portName,
    'containerNo': containerNo,
    'sequenceNo': sequenceNo,
    'loadingDate': loadingDate,
    'unloadingDate': unloadingDate,
    'description': description,
    'status': status,
  };
}

// -------------------------
// UPDATE CONTAINER REQUEST (partial)
//   Only non-null fields are sent, matching the backend's
//   dynamic SET clause in updateContainer().
// -------------------------
class UpdateContainerRequest {
  final int shpId;
  final String user;
  final String? portName;
  final String? containerNo;
  final String? sequenceNo;
  final String? loadingDate;
  final String? unloadingDate;
  final String? description;
  final String? status;

  const UpdateContainerRequest({
    required this.shpId,
    required this.user,
    this.portName,
    this.containerNo,
    this.sequenceNo,
    this.loadingDate,
    this.unloadingDate,
    this.description,
    this.status,
  });

  Map<String, dynamic> toJson() => {
    'shpId': shpId,
    'user': user,
    if (portName != null) 'portName': portName,
    if (containerNo != null) 'containerNo': containerNo,
    if (sequenceNo != null) 'sequenceNo': sequenceNo,
    if (loadingDate != null) 'loadingDate': loadingDate,
    if (unloadingDate != null) 'unloadingDate': unloadingDate,
    if (description != null) 'description': description,
    if (status != null) 'status': status,
  };
}

// -------------------------
// DELETE CONTAINER REQUEST
// -------------------------
class DeleteContainerRequest {
  final int shpId;
  final String user;
  final bool force;

  const DeleteContainerRequest({
    required this.shpId,
    required this.user,
    this.force = false,
  });

  Map<String, dynamic> toJson() => {
    'shpId': shpId,
    'user': user,
    'force': force,
  };
}