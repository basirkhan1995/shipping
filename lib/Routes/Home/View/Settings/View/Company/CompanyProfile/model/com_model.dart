// To parse this JSON data, do
//
//     final companySettingsModel = companySettingsModelFromMap(jsonString);

import 'dart:convert';

List<CompanySettingsModel> companySettingsModelFromMap(String str) => List<CompanySettingsModel>.from(json.decode(str).map((x) => CompanySettingsModel.fromMap(x)));

String companySettingsModelToMap(List<CompanySettingsModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class CompanySettingsModel {
  final int? comId;
  final String? comName;
  final String? comLicenseNo;
  final String? comSlogan;
  final String? comDetails;
  final String? comPhone;
  final String? comEmail;
  final String? comWebsite;
  final String? comLogo;
  final String? comOwner;
  final int? comAddress;
  final String? comFb;
  final String? comInsta;
  final String? comWhatsapp;
  final int? comVerify;
  final String? comLocalCcy;
  final String? comTimeZone;
  final DateTime? comEntryDate;
  final String? addName;
  final String? addCity;
  final String? addProvince;
  final String? addCountry;
  final String? addZipCode;

  CompanySettingsModel({
    this.comId,
    this.comName,
    this.comLicenseNo,
    this.comSlogan,
    this.comDetails,
    this.comPhone,
    this.comEmail,
    this.comWebsite,
    this.comLogo,
    this.comOwner,
    this.comAddress,
    this.comFb,
    this.comInsta,
    this.comWhatsapp,
    this.comVerify,
    this.comLocalCcy,
    this.comTimeZone,
    this.comEntryDate,
    this.addName,
    this.addCity,
    this.addProvince,
    this.addCountry,
    this.addZipCode,
  });

  CompanySettingsModel copyWith({
    int? comId,
    String? comName,
    String? comLicenseNo,
    String? comSlogan,
    String? comDetails,
    String? comPhone,
    String? comEmail,
    String? comWebsite,
    String? comLogo,
    String? comOwner,
    int? comAddress,
    String? comFb,
    String? comInsta,
    String? comWhatsapp,
    int? comVerify,
    String? comLocalCcy,
    String? comTimeZone,
    DateTime? comEntryDate,
    String? addName,
    String? addCity,
    String? addProvince,
    String? addCountry,
    String? addZipCode,
  }) =>
      CompanySettingsModel(
        comId: comId ?? this.comId,
        comName: comName ?? this.comName,
        comLicenseNo: comLicenseNo ?? this.comLicenseNo,
        comSlogan: comSlogan ?? this.comSlogan,
        comDetails: comDetails ?? this.comDetails,
        comPhone: comPhone ?? this.comPhone,
        comEmail: comEmail ?? this.comEmail,
        comWebsite: comWebsite ?? this.comWebsite,
        comLogo: comLogo ?? this.comLogo,
        comOwner: comOwner ?? this.comOwner,
        comAddress: comAddress ?? this.comAddress,
        comFb: comFb ?? this.comFb,
        comInsta: comInsta ?? this.comInsta,
        comWhatsapp: comWhatsapp ?? this.comWhatsapp,
        comVerify: comVerify ?? this.comVerify,
        comLocalCcy: comLocalCcy ?? this.comLocalCcy,
        comTimeZone: comTimeZone ?? this.comTimeZone,
        comEntryDate: comEntryDate ?? this.comEntryDate,
        addName: addName ?? this.addName,
        addCity: addCity ?? this.addCity,
        addProvince: addProvince ?? this.addProvince,
        addCountry: addCountry ?? this.addCountry,
        addZipCode: addZipCode ?? this.addZipCode,
      );

  factory CompanySettingsModel.fromMap(Map<String, dynamic> json) => CompanySettingsModel(
    comId: json["comID"],
    comName: json["comName"],
    comLicenseNo: json["comLicenseNo"],
    comSlogan: json["comSlogan"],
    comDetails: json["comDetails"],
    comPhone: json["comPhone"],
    comEmail: json["comEmail"],
    comWebsite: json["comWebsite"],
    comLogo: json["comLogo"],
    comOwner: json["comOwner"],
    comAddress: json["comAddress"],
    comFb: json["comFB"],
    comInsta: json["comInsta"],
    comWhatsapp: json["comWhatsapp"],
    comVerify: json["comVerify"],
    comLocalCcy: json["comLocalCcy"],
    comTimeZone: json["comTimeZone"],
    comEntryDate: json["comEntryDate"] == null ? null : DateTime.parse(json["comEntryDate"]),
    addName: json["addName"],
    addCity: json["addCity"],
    addProvince: json["addProvince"],
    addCountry: json["addCountry"],
    addZipCode: json["addZipCode"],
  );

  Map<String, dynamic> toMap() => {
    "comID": comId,
    "comName": comName,
    "comLicenseNo": comLicenseNo,
    "comSlogan": comSlogan,
    "comDetails": comDetails,
    "comPhone": comPhone,
    "comEmail": comEmail,
    "comWebsite": comWebsite,
    "comLogo": comLogo,
    "comOwner": comOwner,
    "comAddress": comAddress,
    "comFB": comFb,
    "comInsta": comInsta,
    "comWhatsapp": comWhatsapp,
    "comVerify": comVerify,
    "comLocalCcy": comLocalCcy,
    "comTimeZone": comTimeZone,
    "comEntryDate": comEntryDate?.toIso8601String(),
    "addName": addName,
    "addCity": addCity,
    "addProvince": addProvince,
    "addCountry": addCountry,
    "addZipCode": addZipCode,
  };
}
