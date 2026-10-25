// To parse this JSON data, do
//
//     final storageModel = storageModelFromMap(jsonString);

import 'dart:convert';

StorageModel storageModelFromMap(String str) => StorageModel.fromMap(json.decode(str));

String storageModelToMap(StorageModel data) => json.encode(data.toMap());

class StorageModel {
  final int? stgId;
  final String? stgName;
  final String? stgDetails;
  final String? stgLocation;
  final int? stgStatus;

  StorageModel({
    this.stgId,
    this.stgName,
    this.stgDetails,
    this.stgLocation,
    this.stgStatus,
  });

  StorageModel copyWith({
    int? stgId,
    String? stgName,
    String? stgDetails,
    String? stgLocation,
    int? stgStatus,
  }) =>
      StorageModel(
        stgId: stgId ?? this.stgId,
        stgName: stgName ?? this.stgName,
        stgDetails: stgDetails ?? this.stgDetails,
        stgLocation: stgLocation ?? this.stgLocation,
        stgStatus: stgStatus ?? this.stgStatus,
      );

  factory StorageModel.fromMap(Map<String, dynamic> json) => StorageModel(
    stgId: json["stgID"],
    stgName: json["stgName"],
    stgDetails: json["stgDetails"],
    stgLocation: json["stgLocation"],
    stgStatus: json["stgStatus"],
  );

  Map<String, dynamic> toMap() => {
    "stgID": stgId,
    "stgName": stgName,
    "stgDetails": stgDetails,
    "stgLocation": stgLocation,
    "stgStatus": stgStatus
  };
}
