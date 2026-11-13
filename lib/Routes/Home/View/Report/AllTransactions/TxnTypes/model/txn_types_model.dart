

import 'dart:convert';

List<TxnTypeModel> txnTypeModelFromMap(String str) => List<TxnTypeModel>.from(json.decode(str).map((x) => TxnTypeModel.fromMap(x)));

String txnTypeModelToMap(List<TxnTypeModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class TxnTypeModel {
  final String? trntCode;
  final String? trntName;
  final String? trntDetails;

  TxnTypeModel({
    this.trntCode,
    this.trntName,
    this.trntDetails,
  });

  TxnTypeModel copyWith({
    String? trntCode,
    String? trntName,
    String? trntDetails,
  }) =>
      TxnTypeModel(
        trntCode: trntCode ?? this.trntCode,
        trntName: trntName ?? this.trntName,
        trntDetails: trntDetails ?? this.trntDetails,
      );

  factory TxnTypeModel.fromMap(Map<String, dynamic> json) => TxnTypeModel(
    trntCode: json["trntCode"],
    trntName: json["trntName"],
    trntDetails: json["trntDetails"],
  );

  Map<String, dynamic> toMap() => {
    "trntCode": trntCode,
    "trntName": trntName,
    "trntDetails": trntDetails,
  };
}
