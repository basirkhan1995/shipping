// To parse this JSON data, do
//
//     final branchLimitModel = branchLimitModelFromMap(jsonString);

import 'dart:convert';

List<BranchLimitModel> branchLimitModelFromMap(String str) => List<BranchLimitModel>.from(json.decode(str).map((x) => BranchLimitModel.fromMap(x)));

String branchLimitModelToMap(List<BranchLimitModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class BranchLimitModel {
  final int? balId;
  final int? balBranch;
  final String? balCurrency;
  final String? balLimitAmount;

  BranchLimitModel({
    this.balId,
    this.balBranch,
    this.balCurrency,
    this.balLimitAmount,
  });

  BranchLimitModel copyWith({
    int? balId,
    int? balBranch,
    String? balCurrency,
    String? balLimitAmount,
  }) =>
      BranchLimitModel(
        balId: balId ?? this.balId,
        balBranch: balBranch ?? this.balBranch,
        balCurrency: balCurrency ?? this.balCurrency,
        balLimitAmount: balLimitAmount ?? this.balLimitAmount,
      );

  factory BranchLimitModel.fromMap(Map<String, dynamic> json) => BranchLimitModel(
    balId: json["balID"],
    balBranch: json["balBranch"],
    balCurrency: json["balCurrency"],
    balLimitAmount: json["balLimitAmount"],
  );

  Map<String, dynamic> toMap() => {
    "balID": balId,
    "balBranch": balBranch,
    "balCurrency": balCurrency,
    "balLimitAmount": balLimitAmount,
  };
}
