
import 'dart:convert';

ProductsModel productsModelFromMap(String str) =>
    ProductsModel.fromMap(json.decode(str));

String productsModelToMap(ProductsModel data) =>
    json.encode(data.toMap());

List<RecentPurchase> _parseRecentTxn(dynamic value) {
  if (value == null) return const [];

  if (value is List) {
    return value
        .whereType<Map>()
        .map((x) => RecentPurchase.fromMap(
      Map<String, dynamic>.from(x),
    ))
        .toList();
  }

  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((x) => RecentPurchase.fromMap(
          Map<String, dynamic>.from(x),
        ))
            .toList();
      }
    } catch (_) {
      return const [];
    }
  }

  return const [];
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _toStringValue(dynamic value) =>
    value == null ? null : value.toString();

class ProductsModel {
  final int? proId;
  final String? proName;
  final String? proCode;
  final String? proUnit;
  final String? proBrand;
  final String? proMadeIn;
  final String? proModel;
  final String? proGrade;
  final int? proCategory;
  final String? proDetails;
  final int? proLsNqty;
  final String? proColor;
  final int? proStatus;
  final String? proWidth;
  final String? proWeight;
  final String? proBreadth;
  final String? proSpp;
  final String? proLength;
  final int? pcId;
  final String? pcName;
  final String? pcDescription;
  final int? pcStatus;
  final String? totalQty;
  final String? totalItems;

  final List<Batch>? batches;

  // Recent purchase history
  final List<RecentPurchase>? recentTxn;

  ProductsModel({
    this.proId,
    this.totalQty,
    this.totalItems,
    this.proName,
    this.proCode,
    this.proUnit,
    this.proBrand,
    this.proMadeIn,
    this.proModel,
    this.proGrade,
    this.proCategory,
    this.proDetails,
    this.proLsNqty,
    this.proColor,
    this.proStatus,
    this.proWidth,
    this.proWeight,
    this.proBreadth,
    this.proSpp,
    this.proLength,
    this.pcId,
    this.pcName,
    this.pcDescription,
    this.pcStatus,
    this.batches,
    this.recentTxn,
  });

  ProductsModel copyWith({
    int? proId,
    String? proName,
    String? proCode,
    String? proUnit,
    String? proBrand,
    String? proMadeIn,
    String? proModel,
    String? proGrade,
    int? proCategory,
    String? proDetails,
    int? proLsNqty,
    String? proColor,
    int? proStatus,
    String? proWidth,
    String? proWeight,
    String? proBreadth,
    String? proSpp,
    String? proLength,
    int? pcId,
    String? pcName,
    String? pcDescription,
    int? pcStatus,
    List<Batch>? batches,
    String? totalQty,
    String? totalItems,
    List<RecentPurchase>? recentTxn,
  }) =>
      ProductsModel(
        proId: proId ?? this.proId,
        proName: proName ?? this.proName,
        proCode: proCode ?? this.proCode,
        proUnit: proUnit ?? this.proUnit,
        totalItems: totalItems ?? this.totalItems,
        totalQty: totalQty ?? this.totalQty,
        proBrand: proBrand ?? this.proBrand,
        proMadeIn: proMadeIn ?? this.proMadeIn,
        proModel: proModel ?? this.proModel,
        proGrade: proGrade ?? this.proGrade,
        proCategory: proCategory ?? this.proCategory,
        proDetails: proDetails ?? this.proDetails,
        proLsNqty: proLsNqty ?? this.proLsNqty,
        proColor: proColor ?? this.proColor,
        proStatus: proStatus ?? this.proStatus,
        proWidth: proWidth ?? this.proWidth,
        proWeight: proWeight ?? this.proWeight,
        proBreadth: proBreadth ?? this.proBreadth,
        proSpp: proSpp ?? this.proSpp,
        proLength: proLength ?? this.proLength,
        pcId: pcId ?? this.pcId,
        pcName: pcName ?? this.pcName,
        pcDescription: pcDescription ?? this.pcDescription,
        pcStatus: pcStatus ?? this.pcStatus,
        batches: batches ?? this.batches,
        recentTxn: recentTxn ?? this.recentTxn,
      );

  factory ProductsModel.fromMap(Map<String, dynamic> json) =>
      ProductsModel(
        proId: _toInt(json["proID"]),
        proName: _toStringValue(json["proName"]),
        proCode: _toStringValue(json["proCode"]),
        proUnit: _toStringValue(json["proUnit"]),
        proBrand: _toStringValue(json["proBrand"]),
        proMadeIn: _toStringValue(json["proMadeIn"]),
        proModel: _toStringValue(json["proModel"]),
        proGrade: _toStringValue(json["proGrade"]),
        proCategory: _toInt(json["proCategory"]),
        totalQty: _toStringValue(json["total_quantity"]),
        totalItems: _toStringValue(json["total_items"]),
        proDetails: _toStringValue(json["proDetails"]),
        proLsNqty: _toInt(json["proLSNQty"] ?? json["proLSNqty"]),
        proColor: _toStringValue(json["proColor"]),
        proStatus: _toInt(json["proStatus"]),
        proWidth: _toStringValue(json["proWidth"]),
        proWeight: _toStringValue(json["proWeight"]),
        proBreadth: _toStringValue(json["proBreadth"]),
        proSpp: _toStringValue(json["proSPP"]),
        proLength: _toStringValue(json["proLength"]),
        pcId: _toInt(json["pcID"]),
        pcName: _toStringValue(json["pcName"]),
        pcDescription: _toStringValue(json["pcDescription"]),
        pcStatus: _toInt(json["pcStatus"]),

        batches: json["batches"] == null
            ? []
            : List<Batch>.from(
          json["batches"].map(
                (x) => Batch.fromMap(x),
          ),
        ),

        recentTxn: _parseRecentTxn(json["recent_txn"]),
      );

  Map<String, dynamic> toMap() => {
    "proID": proId,
    "proName": proName,
    "proCode": proCode,
    "proUnit": proUnit,
    "proBrand": proBrand,
    "proMadeIn": proMadeIn,
    "proModel": proModel,
    "proGrade": proGrade,
    "proCategory": proCategory,
    "proDetails": proDetails,
    "proLSNQty": proLsNqty,
    "proColor": proColor,
    "proStatus": proStatus,
    "proWidth": proWidth,
    "proWeight": proWeight,
    "proBreadth": proBreadth,
    "proSPP": proSpp,
    "proLength": proLength,
    "pcID": pcId,
    "pcName": pcName,
    "pcDescription": pcDescription,
    "pcStatus": pcStatus,
    "total_quantity": totalQty,
    "total_items": totalItems,

    "batches": batches == null
        ? []
        : batches!.map((x) => x.toMap()).toList(),

    "recent_txn": recentTxn == null
        ? []
        : recentTxn!.map((x) => x.toMap()).toList(),
  };
}

// ─────────────────────────────────────────────
// Batch model
// ─────────────────────────────────────────────

class Batch {
  final int? storageId;
  final String? storageName;
  final int? batch;
  final String? availableQuantity;

  Batch({
    this.storageId,
    this.storageName,
    this.batch,
    this.availableQuantity,
  });

  Batch copyWith({
    int? storageId,
    String? storageName,
    int? batch,
    String? availableQuantity,
  }) =>
      Batch(
        storageId: storageId ?? this.storageId,
        storageName: storageName ?? this.storageName,
        batch: batch ?? this.batch,
        availableQuantity: availableQuantity ?? this.availableQuantity,
      );

  factory Batch.fromMap(Map<String, dynamic> json) => Batch(
    storageId: _toInt(json["storage_id"]),
    storageName: _toStringValue(json["storage_name"]),
    batch: _toInt(json["batch"]),
    availableQuantity: _toStringValue(json["available_Quantity"]),
  );

  Map<String, dynamic> toMap() => {
    "storage_id": storageId,
    "storage_name": storageName,
    "batch": batch,
    "available_Quantity": availableQuantity,
  };
}

// ─────────────────────────────────────────────
// Recent purchase transaction model
// ─────────────────────────────────────────────

class RecentPurchase {
  final String? date;
  final String? customer;
  final String? currency;
  final int? orderId;
  final int? quantity;
  final int? batchQty;
  final String? orderType;
  final num? unitPrice;

  const RecentPurchase({
    this.date,
    this.customer,
    this.currency,
    this.orderId,
    this.quantity,
    this.batchQty,
    this.orderType,
    this.unitPrice,
  });

  // Number of boxes = total items / items per box.
  double? get noBox {
    final q = quantity;
    final b = batchQty;

    if (q == null || b == null || b == 0) {
      return null;
    }

    return q / b;
  }

  factory RecentPurchase.fromMap(Map<String, dynamic> json) =>
      RecentPurchase(
        date: _toStringValue(json["date"]),
        customer: _toStringValue(json["customer"]),
        currency: _toStringValue(json["currency"]),
        orderId: _toInt(json["order_id"]),
        quantity: _toInt(json["quantity"]),
        batchQty: _toInt(json["batch_qty"]),
        orderType: _toStringValue(json["order_type"]),
        unitPrice: json["unit_price"] is num
            ? json["unit_price"] as num
            : num.tryParse(
          json["unit_price"]?.toString() ?? '',
        ),
      );

  Map<String, dynamic> toMap() => {
    "date": date,
    "customer": customer,
    "currency": currency,
    "order_id": orderId,
    "quantity": quantity,
    "batch_qty": batchQty,
    "order_type": orderType,
    "unit_price": unitPrice,
  };
}
