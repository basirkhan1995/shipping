// To parse this JSON data, do
//
//     final productsStockModel = productsStockModelFromMap(jsonString);

import 'dart:convert';

ProductsStockModel productsStockModelFromMap(String str) => ProductsStockModel.fromMap(json.decode(str));

String productsStockModelToMap(ProductsStockModel data) => json.encode(data.toMap());

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
  final dynamic sellPrice;
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
    dynamic sellPrice,
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
        recentLandedPurPrice: recentLandedPurPrice ?? this.recentLandedPurPrice,
        averagePrice: averagePrice ?? this.averagePrice,
        averageLandedPrice: averageLandedPrice ?? this.averageLandedPrice,
        sellPrice: sellPrice ?? this.sellPrice,
        recentTxn: recentTxn ?? this.recentTxn,
      );

  factory ProductsStockModel.fromMap(Map<String, dynamic> json) => ProductsStockModel(
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
    sellPrice: json["sell_price"],
    recentTxn: json["recent_txn"] == null ? [] : List<RecentTxn>.from(json["recent_txn"]!.map((x) => RecentTxn.fromMap(x))),
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
    "sell_price": sellPrice,
    "recent_txn": recentTxn == null ? [] : List<dynamic>.from(recentTxn!.map((x) => x.toMap())),
  };
}

class RecentTxn {
  final String? date;
  final int? amount;
  final String? currency;
  final String? customer;
  final int? orderId;
  final int? quantity;
  final int? batchQty;
  final String? orderType;
  final double? basePurchasePrice;
  final int? originalSalePrice;

  RecentTxn({
    this.date,
    this.amount,
    this.currency,
    this.customer,
    this.orderId,
    this.quantity,
    this.batchQty,
    this.orderType,
    this.basePurchasePrice,
    this.originalSalePrice,
  });

  RecentTxn copyWith({
    String? date,
    int? amount,
    String? currency,
    String? customer,
    int? orderId,
    int? quantity,
    int? batchQty,
    String? orderType,
    double? basePurchasePrice,
    int? originalSalePrice,
  }) =>
      RecentTxn(
        date: date ?? this.date,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        customer: customer ?? this.customer,
        orderId: orderId ?? this.orderId,
        quantity: quantity ?? this.quantity,
        batchQty: batchQty ?? this.batchQty,
        orderType: orderType ?? this.orderType,
        basePurchasePrice: basePurchasePrice ?? this.basePurchasePrice,
        originalSalePrice: originalSalePrice ?? this.originalSalePrice,
      );

  factory RecentTxn.fromMap(Map<String, dynamic> json) => RecentTxn(
    date: json["date"],
    amount: json["amount"],
    currency: json["currency"],
    customer: json["customer"],
    orderId: json["order_id"],
    quantity: json["quantity"],
    batchQty: json["batch_qty"],
    orderType: json["order_type"],
    basePurchasePrice: json["basePurchasePrice"]?.toDouble(),
    originalSalePrice: json["originalSalePrice"],
  );

  Map<String, dynamic> toMap() => {
    "date": date,
    "amount": amount,
    "currency": currency,
    "customer": customer,
    "order_id": orderId,
    "quantity": quantity,
    "batch_qty": batchQty,
    "order_type": orderType,
    "basePurchasePrice": basePurchasePrice,
    "originalSalePrice": originalSalePrice,
  };
}
