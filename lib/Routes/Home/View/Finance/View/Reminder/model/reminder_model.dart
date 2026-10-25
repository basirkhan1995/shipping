// To parse this JSON data, do
//
//     final reminderModel = reminderModelFromMap(jsonString);

import 'dart:convert';

List<ReminderModel> reminderModelFromMap(String str) => List<ReminderModel>.from(json.decode(str).map((x) => ReminderModel.fromMap(x)));

String reminderModelToMap(List<ReminderModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ReminderModel {
  final int? rmdId;
  final String? usrName;
  final String? rmdName;
  final int? rmdAccount;
  final String? rmdAmount;
  final String? rmdDetails;
  final DateTime? rmdAlertDate;
  final int? rmdStatus;
  final int? rmdBranch;
  final String? brcName;
  final String? fullName;
  final String? perPhone;
  final String? perEmail;
  final String? currency;

  ReminderModel({
    this.rmdId,
    this.rmdName,
    this.usrName,
    this.rmdAccount,
    this.rmdAmount,
    this.rmdDetails,
    this.rmdAlertDate,
    this.rmdStatus,
    this.rmdBranch,
    this.brcName,
    this.fullName,
    this.perPhone,
    this.perEmail,
    this.currency,
  });

  ReminderModel copyWith({
    int? rmdId,
    String? rmdName,
    String? usrName,
    int? rmdAccount,
    String? rmdAmount,
    String? rmdDetails,
    DateTime? rmdAlertDate,
    int? rmdStatus,
    int? rmdBranch,
    String? currency,
    String? brcName,
    String? fullName,
    String? perPhone,
    String? perEmail,
  }) =>
      ReminderModel(
        rmdId: rmdId ?? this.rmdId,
        rmdName: rmdName ?? this.rmdName,
        usrName: usrName ?? this.usrName,
        rmdAccount: rmdAccount ?? this.rmdAccount,
        rmdAmount: rmdAmount ?? this.rmdAmount,
        rmdDetails: rmdDetails ?? this.rmdDetails,
        rmdAlertDate: rmdAlertDate ?? this.rmdAlertDate,
        rmdStatus: rmdStatus ?? this.rmdStatus,
        rmdBranch: rmdBranch ?? this.rmdBranch,
        brcName: brcName ?? this.brcName,
        fullName: fullName ?? this.fullName,
        perPhone: perPhone ?? this.perPhone,
        perEmail: perEmail ?? this.perEmail,
        currency: currency ?? this.currency,
      );

  factory ReminderModel.fromMap(Map<String, dynamic> json) => ReminderModel(
    rmdId: json["rmdID"],
    rmdName: json["rmdName"],
    usrName: json["user"],
    rmdAccount: json["rmdAccount"],
    rmdAmount: json["rmdAmount"],
    rmdDetails: json["rmdDetails"],
    rmdAlertDate: json["rmdAlertDate"] == null ? null : DateTime.parse(json["rmdAlertDate"]),
    rmdStatus: json["rmdStatus"],
    rmdBranch: json["rmdBranch"],
    brcName: json["brcName"],
    currency: json["currency"],
    fullName: json["fullName"],
    perPhone: json["perPhone"],
    perEmail: json["perEmail"],
  );

  Map<String, dynamic> toMap() => {
    "user": usrName,
    "rmdID": rmdId,
    "rmdName": rmdName,
    "rmdAccount": rmdAccount,
    "rmdAmount": rmdAmount,
    "currency":currency,
    "rmdDetails": rmdDetails,
    "rmdAlertDate": "${rmdAlertDate!.year.toString().padLeft(4, '0')}-${rmdAlertDate!.month.toString().padLeft(2, '0')}-${rmdAlertDate!.day.toString().padLeft(2, '0')}",
    "rmdStatus": rmdStatus,
    "rmdBranch": rmdBranch,
    "brcName": brcName,
    "fullName": fullName,
    "perPhone": perPhone,
    "perEmail": perEmail,
  };
}
