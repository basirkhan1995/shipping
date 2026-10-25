// To parse this JSON data, do
//
//     final branchModel = branchModelFromMap(jsonString);

import 'dart:convert';

List<BranchModel> branchModelFromMap(String str) => List<BranchModel>.from(json.decode(str).map((x) => BranchModel.fromMap(x)));

String branchModelToMap(List<BranchModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class BranchModel {
  final int? brcId;
  final int? brcCompany;
  final String? brcName;
  final int? brcAddress;
  final String? brcPhone;
  final int? brcStatus;
  final DateTime? brcEntryDate;
  final int? addId;
  final String? addName;
  final String? addCity;
  final String? addProvince;
  final String? addCountry;
  final String? addZipCode;
  final int? addMailing;

  BranchModel({
    this.brcId,
    this.brcCompany,
    this.brcName,
    this.brcAddress,
    this.brcPhone,
    this.brcStatus,
    this.brcEntryDate,
    this.addId,
    this.addName,
    this.addCity,
    this.addProvince,
    this.addCountry,
    this.addZipCode,
    this.addMailing,
  });

  BranchModel copyWith({
    int? brcId,
    int? brcCompany,
    String? brcName,
    int? brcAddress,
    String? brcPhone,
    int? brcStatus,
    DateTime? brcEntryDate,
    int? addId,
    String? addName,
    String? addCity,
    String? addProvince,
    String? addCountry,
    String? addZipCode,
    int? addMailing,
  }) =>
      BranchModel(
        brcId: brcId ?? this.brcId,
        brcCompany: brcCompany ?? this.brcCompany,
        brcName: brcName ?? this.brcName,
        brcAddress: brcAddress ?? this.brcAddress,
        brcPhone: brcPhone ?? this.brcPhone,
        brcStatus: brcStatus ?? this.brcStatus,
        brcEntryDate: brcEntryDate ?? this.brcEntryDate,
        addId: addId ?? this.addId,
        addName: addName ?? this.addName,
        addCity: addCity ?? this.addCity,
        addProvince: addProvince ?? this.addProvince,
        addCountry: addCountry ?? this.addCountry,
        addZipCode: addZipCode ?? this.addZipCode,
        addMailing: addMailing ?? this.addMailing,
      );

  factory BranchModel.fromMap(Map<String, dynamic> json) => BranchModel(
    brcId: json["brcID"],
    brcCompany: json["brcCompany"],
    brcName: json["brcName"],
    brcAddress: json["brcAddress"],
    brcPhone: json["brcPhone"],
    brcStatus: json["brcStatus"],
    brcEntryDate: json["brcEntryDate"] == null ? null : DateTime.parse(json["brcEntryDate"]),
    addId: json["addID"],
    addName: json["addName"],
    addCity: json["addCity"],
    addProvince: json["addProvince"],
    addCountry: json["addCountry"],
    addZipCode: json["addZipCode"],
    addMailing: json["addMailing"],
  );

  Map<String, dynamic> toMap() => {
    "brcID": brcId,
    "brcCompany": brcCompany,
    "brcName": brcName,
    "brcAddress": brcAddress,
    "brcPhone": brcPhone,
    "brcStatus": brcStatus,
    "brcEntryDate": brcEntryDate?.toIso8601String(),
    "addID": addId,
    "addName": addName,
    "addCity": addCity,
    "addProvince": addProvince,
    "addCountry": addCountry,
    "addZipCode": addZipCode,
    "addMailing": addMailing,
  };
}
