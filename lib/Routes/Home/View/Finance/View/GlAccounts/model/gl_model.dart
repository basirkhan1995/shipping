// To parse this JSON data, do
//
//     final glAccountsModel = glAccountsModelFromMap(jsonString);

import 'dart:convert';

List<GlAccountsModel> glAccountsModelFromMap(String str) => List<GlAccountsModel>.from(json.decode(str).map((x) => GlAccountsModel.fromMap(x)));

String glAccountsModelToMap(List<GlAccountsModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class GlAccountsModel {
  final int? accNumber;
  final String? accName;
  final int? accCategory;
  final String? acgName;
  final String? usrName;

  GlAccountsModel({
    this.accNumber,
    this.accName,
    this.accCategory,
    this.acgName,
    this.usrName,
  });

  GlAccountsModel copyWith({
    int? accNumber,
    String? accName,
    int? accCategory,
    String? acgName,
    String? usrName,
  }) =>
      GlAccountsModel(
        accNumber: accNumber ?? this.accNumber,
        accName: accName ?? this.accName,
        accCategory: accCategory ?? this.accCategory,
        acgName: acgName ?? this.acgName,
        usrName: usrName ?? this.usrName,
      );

  factory GlAccountsModel.fromMap(Map<String, dynamic> json) => GlAccountsModel(
    accNumber: json["accNumber"],
    accName: json["accName"],
    accCategory: json["accCategory"],
    acgName: json["acgName"],
    usrName: json["usrName"],
  );

  Map<String, dynamic> toMap() => {
    "accNumber": accNumber,
    "accName": accName,
    "accCategory": accCategory,
    "acgName": acgName,
    "usrName": usrName,
  };
}
