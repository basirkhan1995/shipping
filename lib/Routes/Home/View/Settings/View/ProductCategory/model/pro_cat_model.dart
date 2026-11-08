

import 'dart:convert';

List<ProCategoryModel> proCategoryModelFromMap(String str) => List<ProCategoryModel>.from(json.decode(str).map((x) => ProCategoryModel.fromMap(x)));

String proCategoryModelToMap(List<ProCategoryModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ProCategoryModel {
  final int? pcId;
  final String? pcName;
  final String? pcDescription;
  final int? pcStatus;

  ProCategoryModel({
    this.pcId,
    this.pcName,
    this.pcDescription,
    this.pcStatus,
  });

  ProCategoryModel copyWith({
    int? pcId,
    String? pcName,
    String? pcDescription,
    int? pcStatus,
  }) =>
      ProCategoryModel(
        pcId: pcId ?? this.pcId,
        pcName: pcName ?? this.pcName,
        pcDescription: pcDescription ?? this.pcDescription,
        pcStatus: pcStatus ?? this.pcStatus,
      );

  factory ProCategoryModel.fromMap(Map<String, dynamic> json) => ProCategoryModel(
    pcId: json["pcID"],
    pcName: json["pcName"],
    pcDescription: json["pcDescription"],
    pcStatus: json["pcStatus"],
  );

  Map<String, dynamic> toMap() => {
    "pcID": pcId,
    "pcName": pcName,
    "pcDescription": pcDescription,
    "pcStatus": pcStatus,
  };
}
