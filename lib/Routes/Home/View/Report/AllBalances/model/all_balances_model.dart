
import 'dart:convert';

List<AllBalancesModel> allBalancesModelFromMap(String str) => List<AllBalancesModel>.from(json.decode(str).map((x) => AllBalancesModel.fromMap(x)));

String allBalancesModelToMap(List<AllBalancesModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class AllBalancesModel {
  final int? trdAccount;
  final String? accName;
  final String? trdCcy;
  final int? trdBranch;
  final String? acgName;
  final int? acgId;
  final String? balance;

  AllBalancesModel({
    this.trdAccount,
    this.accName,
    this.trdCcy,
    this.trdBranch,
    this.acgName,
    this.acgId,
    this.balance,
  });

  AllBalancesModel copyWith({
    int? trdAccount,
    String? accName,
    String? trdCcy,
    int? trdBranch,
    String? acgName,
    int? acgId,
    String? balance,
  }) =>
      AllBalancesModel(
        trdAccount: trdAccount ?? this.trdAccount,
        accName: accName ?? this.accName,
        trdCcy: trdCcy ?? this.trdCcy,
        trdBranch: trdBranch ?? this.trdBranch,
        acgName: acgName ?? this.acgName,
        acgId: acgId ?? this.acgId,
        balance: balance ?? this.balance,
      );

  factory AllBalancesModel.fromMap(Map<String, dynamic> json) => AllBalancesModel(
    trdAccount: json["trdAccount"],
    accName: json["accName"],
    trdCcy: json["trdCcy"],
    trdBranch: json["trdBranch"],
    acgName: json["acgName"],
    acgId: json["acgID"],
    balance: json["balance"],
  );

  Map<String, dynamic> toMap() => {
    "trdAccount": trdAccount,
    "accName": accName,
    "trdCcy": trdCcy,
    "trdBranch": trdBranch,
    "acgName": acgName,
    "acgID": acgId,
    "balance": balance,
  };
}
