// To parse this JSON data, do
//
//     final currenciesModel = currenciesModelFromMap(jsonString);

import 'dart:convert';

List<CurrenciesModel> currenciesModelFromMap(String str) => List<CurrenciesModel>.from(json.decode(str).map((x) => CurrenciesModel.fromMap(x)));

String currenciesModelToMap(List<CurrenciesModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class CurrenciesModel {
  final String? ccyCode;
  final String? ccyName;
  final String? ccySymbol;
  final String? ccyCountry;
  final String? ccyCountryCode;
  final String? ccyLocalName;
  final int? ccyStatus;

  CurrenciesModel({
    this.ccyCode,
    this.ccyCountryCode,
    this.ccyName,
    this.ccySymbol,
    this.ccyLocalName,
    this.ccyCountry,
    this.ccyStatus,
  });

  CurrenciesModel copyWith({
    String? ccyCode,
    String? ccyName,
    String? ccySymbol,
    String? ccyCountry,
    String? ccyCountryCode,
    int? ccyStatus,
    String? ccyLocalName,
  }) =>
      CurrenciesModel(
        ccyLocalName: ccyLocalName ?? this.ccyLocalName,
        ccyCountryCode: ccyCountryCode ?? this.ccyCountryCode,
        ccyCode: ccyCode ?? this.ccyCode,
        ccyName: ccyName ?? this.ccyName,
        ccySymbol: ccySymbol ?? this.ccySymbol,
        ccyCountry: ccyCountry ?? this.ccyCountry,
        ccyStatus: ccyStatus ?? this.ccyStatus,
      );

  factory CurrenciesModel.fromMap(Map<String, dynamic> json) => CurrenciesModel(
    ccyCode: json["ccyCode"],
    ccyName: json["ccyName"],
    ccySymbol: json["ccySymbol"],
    ccyCountry: json["ccyCountry"],
    ccyStatus: json["ccyStatus"],
    ccyCountryCode: json["ccyCountryCode"],
    ccyLocalName: json["ccyLocalName"],
  );

  Map<String, dynamic> toMap() => {
    "ccyLocalName":ccyLocalName,
    "ccyCode": ccyCode,
    "ccyName": ccyName,
    "ccySymbol": ccySymbol,
    "ccyCountry": ccyCountry,
    "ccyStatus": ccyStatus,
    "ccyCountryCode": ccyCountryCode
  };
}
