// To parse this JSON data, do
//
//     final txnReportByRefModel = txnReportByRefModelFromMap(jsonString);

import 'dart:convert';

TxnReportByRefModel txnReportByRefModelFromMap(String str) => TxnReportByRefModel.fromMap(json.decode(str));

String txnReportByRefModelToMap(TxnReportByRefModel data) => json.encode(data.toMap());

class TxnReportByRefModel {
  final int? trnId;
  final String? trnReference;
  final String? trnType;
  final String? trntName;
  final String? maker;
  final String? checker;
  final String? trnStateText;
  final DateTime? trnEntryDate;
  final List<Record>? records;

  TxnReportByRefModel({
    this.trnId,
    this.trnReference,
    this.trnType,
    this.trntName,
    this.maker,
    this.checker,
    this.trnStateText,
    this.trnEntryDate,
    this.records,
  });

  TxnReportByRefModel copyWith({
    int? trnId,
    String? trnReference,
    String? trnType,
    String? trntName,
    String? maker,
    String? checker,
    String? trnStateText,
    DateTime? trnEntryDate,
    List<Record>? records,
  }) =>
      TxnReportByRefModel(
        trnId: trnId ?? this.trnId,
        trnReference: trnReference ?? this.trnReference,
        trnType: trnType ?? this.trnType,
        trntName: trntName ?? this.trntName,
        maker: maker ?? this.maker,
        checker: checker ?? this.checker,
        trnStateText: trnStateText ?? this.trnStateText,
        trnEntryDate: trnEntryDate ?? this.trnEntryDate,
        records: records ?? this.records,
      );

  factory TxnReportByRefModel.fromMap(Map<String, dynamic> json) => TxnReportByRefModel(
    trnId: json["trnID"],
    trnReference: json["trnReference"],
    trnType: json["trnType"],
    trntName: json["trntName"],
    maker: json["maker"],
    checker: json["checker"],
    trnStateText: json["trnStateText"],
    trnEntryDate: json["trnEntryDate"] == null ? null : DateTime.parse(json["trnEntryDate"]),
    records: json["records"] == null ? [] : List<Record>.from(json["records"]!.map((x) => Record.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "trnID": trnId,
    "trnReference": trnReference,
    "trnType": trnType,
    "trntName": trntName,
    "maker": maker,
    "checker": checker,
    "trnStateText": trnStateText,
    "trnEntryDate": trnEntryDate?.toIso8601String(),
    "records": records == null ? [] : List<dynamic>.from(records!.map((x) => x.toMap())),
  };
}

class Record {
  final int? trdId;
  final String? debitCredit;
  final int? trdAccount;
  final String? accName;
  final String? trdAmount;
  final String? trdCcy;
  final String? trdNarration;
  final DateTime? trdEntryDate;

  Record({
    this.trdId,
    this.debitCredit,
    this.trdAccount,
    this.accName,
    this.trdAmount,
    this.trdCcy,
    this.trdNarration,
    this.trdEntryDate,
  });

  Record copyWith({
    int? trdId,
    String? debitCredit,
    int? trdAccount,
    String? accName,
    String? trdAmount,
    String? trdCcy,
    String? trdNarration,
    DateTime? trdEntryDate,
  }) =>
      Record(
        trdId: trdId ?? this.trdId,
        debitCredit: debitCredit ?? this.debitCredit,
        trdAccount: trdAccount ?? this.trdAccount,
        accName: accName ?? this.accName,
        trdAmount: trdAmount ?? this.trdAmount,
        trdCcy: trdCcy ?? this.trdCcy,
        trdNarration: trdNarration ?? this.trdNarration,
        trdEntryDate: trdEntryDate ?? this.trdEntryDate,
      );

  factory Record.fromMap(Map<String, dynamic> json) => Record(
    trdId: json["trdID"],
    debitCredit: json["Debit_Credit"],
    trdAccount: json["trdAccount"],
    accName: json["accName"],
    trdAmount: json["trdAmount"],
    trdCcy: json["trdCcy"],
    trdNarration: json["trdNarration"],
    trdEntryDate: json["trdEntryDate"] == null ? null : DateTime.parse(json["trdEntryDate"]),
  );

  Map<String, dynamic> toMap() => {
    "trdID": trdId,
    "Debit_Credit": debitCredit,
    "trdAccount": trdAccount,
    "accName": accName,
    "trdAmount": trdAmount,
    "trdCcy": trdCcy,
    "trdNarration": trdNarration,
    "trdEntryDate": trdEntryDate?.toIso8601String(),
  };
}
