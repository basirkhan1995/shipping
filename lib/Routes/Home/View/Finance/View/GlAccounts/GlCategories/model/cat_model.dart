
import 'dart:convert';

List<GlCategoriesModel> glCategoriesModelFromMap(String str) => List<GlCategoriesModel>.from(json.decode(str).map((x) => GlCategoriesModel.fromMap(x)));

String glCategoriesModelToMap(List<GlCategoriesModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class GlCategoriesModel {
  final int? acgId;
  final String? acgName;
  final int? acgCategory;

  GlCategoriesModel({
    this.acgId,
    this.acgName,
    this.acgCategory,
  });

  GlCategoriesModel copyWith({
    int? acgId,
    String? acgName,
    int? acgCategory,
  }) =>
      GlCategoriesModel(
        acgId: acgId ?? this.acgId,
        acgName: acgName ?? this.acgName,
        acgCategory: acgCategory ?? this.acgCategory,
      );

  factory GlCategoriesModel.fromMap(Map<String, dynamic> json) => GlCategoriesModel(
    acgId: json["acgID"],
    acgName: json["acgName"],
    acgCategory: json["acgCategory"],
  );

  Map<String, dynamic> toMap() => {
    "acgID": acgId,
    "acgName": acgName,
    "acgCategory": acgCategory,
  };
}
