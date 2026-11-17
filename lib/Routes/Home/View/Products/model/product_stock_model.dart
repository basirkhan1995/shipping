// To parse this JSON data, do
//
//     final productsStockModel = productsStockModelFromMap(jsonString);

import 'dart:convert';

ProductsStockModel productsStockModelFromMap(String str) => ProductsStockModel.fromMap(json.decode(str));

String productsStockModelToMap(ProductsStockModel data) => json.encode(data.toMap());

List<RecentTxn> _parseRecentTxn(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value.whereType<Map>().map((x) => RecentTxn.fromMap(Map<String, dynamic>.from(x))).toList();
  }
  if (value is String) {
    if (value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((x) => RecentTxn.fromMap(Map<String, dynamic>.from(x)))
            .toList();
      }
    } catch (_) {
      // malformed JSON string — treat as empty rather than crashing the list
    }
    return const [];
  }

  return const [];
}

class ProductsStockModel {
  final int? proId;
  final String? proName;
  final String? proCode;
  final String? proGrade;
  final String? proUnit;
  final String? proBrand;
  final int? proCategory;
  final String? proModel;
  final String? proMadeIn;
  final String? proColor;
  final String? proDetails;
  final dynamic proLsNqty;
  final int? proStatus;
  final int? stkStorage;
  final String? stgName;
  final int? stkQtyInBatch;
  final String? available;
  final String? availableItem;
  final String? recentPurPrice;
  final String? recentLandedPurPrice;
  final String? averagePrice;
  final String? averageLandedPrice;

  // ── New FIFO fields ──────────────────────────────────────────────
  final String? fifoNextBatchRef;
  final String? fifoNextBatchRemaining;
  final String? fifoNextBatchEntry;
  final String? fifoNextUnitCost;
  final String? fifoNextUnitLanded;
  final String? fifoCogsTotal;

  final String? sellPrice;
  final List<RecentTxn>? recentTxn;

  ProductsStockModel({
    this.proId,
    this.proName,
    this.proCode,
    this.proGrade,
    this.proUnit,
    this.proBrand,
    this.proCategory,
    this.proModel,
    this.proMadeIn,
    this.proColor,
    this.proDetails,
    this.proLsNqty,
    this.proStatus,
    this.stkStorage,
    this.stgName,
    this.stkQtyInBatch,
    this.available,
    this.availableItem,
    this.recentPurPrice,
    this.recentLandedPurPrice,
    this.averagePrice,
    this.averageLandedPrice,
    this.fifoNextBatchRef,
    this.fifoNextBatchRemaining,
    this.fifoNextBatchEntry,
    this.fifoNextUnitCost,
    this.fifoNextUnitLanded,
    this.fifoCogsTotal,
    this.sellPrice,
    this.recentTxn,
  });

  ProductsStockModel copyWith({
    int? proId,
    String? proName,
    String? proCode,
    String? proGrade,
    String? proUnit,
    String? proBrand,
    int? proCategory,
    String? proModel,
    String? proMadeIn,
    String? proColor,
    String? proDetails,
    dynamic proLsNqty,
    int? proStatus,
    int? stkStorage,
    String? stgName,
    int? stkQtyInBatch,
    String? available,
    String? availableItem,
    String? recentPurPrice,
    String? recentLandedPurPrice,
    String? averagePrice,
    String? averageLandedPrice,
    String? fifoNextBatchRef,
    String? fifoNextBatchRemaining,
    String? fifoNextBatchEntry,
    String? fifoNextUnitCost,
    String? fifoNextUnitLanded,
    String? fifoCogsTotal,
    String? sellPrice,
    List<RecentTxn>? recentTxn,
  }) =>
      ProductsStockModel(
        proId: proId ?? this.proId,
        proName: proName ?? this.proName,
        proCode: proCode ?? this.proCode,
        proGrade: proGrade ?? this.proGrade,
        proUnit: proUnit ?? this.proUnit,
        proBrand: proBrand ?? this.proBrand,
        proCategory: proCategory ?? this.proCategory,
        proModel: proModel ?? this.proModel,
        proMadeIn: proMadeIn ?? this.proMadeIn,
        proColor: proColor ?? this.proColor,
        proDetails: proDetails ?? this.proDetails,
        proLsNqty: proLsNqty ?? this.proLsNqty,
        proStatus: proStatus ?? this.proStatus,
        stkStorage: stkStorage ?? this.stkStorage,
        stgName: stgName ?? this.stgName,
        stkQtyInBatch: stkQtyInBatch ?? this.stkQtyInBatch,
        available: available ?? this.available,
        availableItem: availableItem ?? this.availableItem,
        recentPurPrice: recentPurPrice ?? this.recentPurPrice,
        recentLandedPurPrice:
        recentLandedPurPrice ?? this.recentLandedPurPrice,
        averagePrice: averagePrice ?? this.averagePrice,
        averageLandedPrice: averageLandedPrice ?? this.averageLandedPrice,
        fifoNextBatchRef: fifoNextBatchRef ?? this.fifoNextBatchRef,
        fifoNextBatchRemaining:
        fifoNextBatchRemaining ?? this.fifoNextBatchRemaining,
        fifoNextBatchEntry: fifoNextBatchEntry ?? this.fifoNextBatchEntry,
        fifoNextUnitCost: fifoNextUnitCost ?? this.fifoNextUnitCost,
        fifoNextUnitLanded: fifoNextUnitLanded ?? this.fifoNextUnitLanded,
        fifoCogsTotal: fifoCogsTotal ?? this.fifoCogsTotal,
        sellPrice: sellPrice ?? this.sellPrice,
        recentTxn: recentTxn ?? this.recentTxn,
      );

  factory ProductsStockModel.fromMap(Map<String, dynamic> json) =>
      ProductsStockModel(
        proId: json["proID"],
        proName: json["proName"],
        proCode: json["proCode"],
        proGrade: json["proGrade"],
        proUnit: json["proUnit"],
        proBrand: json["proBrand"],
        proCategory: json["proCategory"],
        proModel: json["proModel"],
        proMadeIn: json["proMadeIn"],
        proColor: json["proColor"],
        proDetails: json["proDetails"],
        proLsNqty: json["proLSNqty"],
        proStatus: json["proStatus"],
        stkStorage: json["stkStorage"],
        stgName: json["stgName"],
        stkQtyInBatch: json["stkQtyInBatch"],
        available: json["available"],
        availableItem: json["available_Item"],
        recentPurPrice: json["recent_PurPrice"],
        recentLandedPurPrice: json["recent_landedPurPrice"],
        averagePrice: json["average_price"],
        averageLandedPrice: json["average_landed_price"],
        fifoNextBatchRef: json["fifo_next_batch_ref"],
        fifoNextBatchRemaining: json["fifo_next_batch_remaining"],
        fifoNextBatchEntry: json["fifo_next_batch_entry"],
        fifoNextUnitCost: json["fifo_next_unit_cost"],
        fifoNextUnitLanded: json["fifo_next_unit_landed"],
        fifoCogsTotal: json["fifo_cogs_total"],
        sellPrice: json["sell_price"],
        recentTxn: _parseRecentTxn(json["recent_txn"]),
      );

  Map<String, dynamic> toMap() => {
    "proID": proId,
    "proName": proName,
    "proCode": proCode,
    "proGrade": proGrade,
    "proUnit": proUnit,
    "proBrand": proBrand,
    "proCategory": proCategory,
    "proModel": proModel,
    "proMadeIn": proMadeIn,
    "proColor": proColor,
    "proDetails": proDetails,
    "proLSNqty": proLsNqty,
    "proStatus": proStatus,
    "stkStorage": stkStorage,
    "stgName": stgName,
    "stkQtyInBatch": stkQtyInBatch,
    "available": available,
    "available_Item": availableItem,
    "recent_PurPrice": recentPurPrice,
    "recent_landedPurPrice": recentLandedPurPrice,
    "average_price": averagePrice,
    "average_landed_price": averageLandedPrice,
    "fifo_next_batch_ref": fifoNextBatchRef,
    "fifo_next_batch_remaining": fifoNextBatchRemaining,
    "fifo_next_batch_entry": fifoNextBatchEntry,
    "fifo_next_unit_cost": fifoNextUnitCost,
    "fifo_next_unit_landed": fifoNextUnitLanded,
    "fifo_cogs_total": fifoCogsTotal,
    "sell_price": sellPrice,
    "recent_txn": recentTxn == null
        ? []
        : List<dynamic>.from(recentTxn!.map((x) => x.toMap())),
  };
}

class RecentTxn {
  final String? date;
  final String? customer;
  final String? currency;
  final int? orderId;
  final int? quantity;         // total units sold
  final int? batchQty;         // items per box
  final String? orderType;
  final num? unitPrice;        // per-unit sale price (base ccy)

  const RecentTxn({
    this.date,
    this.customer,
    this.currency,
    this.orderId,
    this.quantity,
    this.batchQty,
    this.orderType,
    this.unitPrice,
  });

  /// Number of boxes = total units / items per box.
  /// Returns null when either value is missing or batchQty is 0,
  /// otherwise returns a double (e.g. 20 / 10 = 2.0).
  double? get noBox {
    final q = quantity;
    final b = batchQty;
    if (q == null || b == null || b == 0) return null;
    return q / b;
  }

  factory RecentTxn.fromMap(Map<String, dynamic> json) => RecentTxn(
    date: json["date"],
    customer: json["customer"],
    currency: json["currency"],
    orderId: json["order_id"],
    quantity: json["quantity"],
    batchQty: json["batch_qty"],
    orderType: json["order_type"],
    unitPrice: json["unit_price"] as num?,
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

class ProductFieldData {
  final String? id;
  final String? name;
  final String? code;
  final int? storageId;
  final String? storageName;
  final String? available;
  final int? batch;
  final String? landedPrice;
  final String? averagePrice;
  final String? recentPrice;
  final String? sellPrice;
  final String? unit;

  final String? fifoNextBatchRef;
  final String? fifoNextBatchRemaining;
  final String? fifoNextBatchEntry;
  final String? fifoNextUnitCost;
  final String? fifoNextUnitLanded;
  final String? fifoCogsTotal;

  final List<dynamic> recentSales;

  const ProductFieldData({
    this.id,
    this.name,
    this.code,
    this.storageId,
    this.storageName,
    this.available,
    this.batch,
    this.landedPrice,
    this.averagePrice,
    this.recentPrice,
    this.sellPrice,
    this.unit,
    this.fifoNextBatchRef,
    this.fifoNextBatchRemaining,
    this.fifoNextBatchEntry,
    this.fifoNextUnitCost,
    this.fifoNextUnitLanded,
    this.fifoCogsTotal,
    this.recentSales = const [],
  });
}

extension ProductsStockModelFieldData on ProductsStockModel {
  ProductFieldData toFieldData() => ProductFieldData(
    id: proId?.toString(),
    name: proName,
    code: proCode,
    storageId: stkStorage,
    storageName: stgName,
    available: available,
    batch: stkQtyInBatch,
    landedPrice: averageLandedPrice,
    averagePrice: averagePrice,
    recentPrice: recentPurPrice,
    sellPrice: sellPrice,
    unit: proUnit,
    fifoNextBatchRef: fifoNextBatchRef,
    fifoNextBatchRemaining: fifoNextBatchRemaining,
    fifoNextBatchEntry: fifoNextBatchEntry,
    fifoNextUnitCost: fifoNextUnitCost,
    fifoNextUnitLanded: fifoNextUnitLanded,
    fifoCogsTotal: fifoCogsTotal,
    recentSales: recentTxn ?? const [],
  );
}