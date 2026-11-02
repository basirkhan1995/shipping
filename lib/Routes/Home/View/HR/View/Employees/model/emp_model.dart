// To parse this JSON data, do
//
//     final employeeModel = employeeModelFromMap(jsonString);

import 'dart:convert';

List<EmployeeModel> employeeModelFromMap(String str) => List<EmployeeModel>.from(json.decode(str).map((x) => EmployeeModel.fromMap(x)));

String employeeModelToMap(List<EmployeeModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class EmployeeModel {
  final int? empId;
  final int? empPersonal;
  final int? empSalAccount;
  final String? empEmail;
  final DateTime? empHireDate;
  final String? empDepartment;
  final String? empPosition;
  final String? empSalCalcBase;
  final String? empPmntMethod;
  final String? empSalary;
  final String? empTaxInfo;
  final String? empFingerprint;
  final int? empStatus;
  final String? empEndDate;
  final int? perId;
  final String? perName;
  final String? empImage;
  final String? perLastName;
  final String? perGender;
  final String? perDoB;
  final String? perEnidNo;
  final int? perAddress;
  final String? perPhone;
  final String? perEmail;
  final bool? isDriver;
  EmployeeModel({
    this.empId,
    this.empPersonal,
    this.empSalAccount,
    this.empEmail,
    this.empHireDate,
    this.empDepartment,
    this.empPosition,
    this.empSalCalcBase,
    this.empPmntMethod,
    this.empSalary,
    this.empTaxInfo,
    this.empImage,
    this.empFingerprint,
    this.empStatus,
    this.empEndDate,
    this.perId,
    this.perName,
    this.perLastName,
    this.perGender,
    this.perDoB,
    this.perEnidNo,
    this.perAddress,
    this.perPhone,
    this.perEmail,
    this.isDriver = false
  });

  EmployeeModel copyWith({
    int? empId,
    int? empPersonal,
    int? empSalAccount,
    String? empEmail,
    DateTime? empHireDate,
    String? empDepartment,
    String? empPosition,
    String? empSalCalcBase,
    String? empPmntMethod,
    String? empSalary,
    String? empTaxInfo,
    String? empFingerprint,
    int? empStatus,
    String? empEndDate,
    int? perId,
    String? perName,
    String? perLastName,
    String? perGender,
    String? perDoB,
    String? perEnidNo,
    int? perAddress,
    String? perPhone,
    String? perEmail,
  }) =>
      EmployeeModel(
        empId: empId ?? this.empId,
        empPersonal: empPersonal ?? this.empPersonal,
        empSalAccount: empSalAccount ?? this.empSalAccount,
        empEmail: empEmail ?? this.empEmail,
        empHireDate: empHireDate ?? this.empHireDate,
        empDepartment: empDepartment ?? this.empDepartment,
        empPosition: empPosition ?? this.empPosition,
        empSalCalcBase: empSalCalcBase ?? this.empSalCalcBase,
        empPmntMethod: empPmntMethod ?? this.empPmntMethod,
        empSalary: empSalary ?? this.empSalary,
        empTaxInfo: empTaxInfo ?? this.empTaxInfo,
        empFingerprint: empFingerprint ?? this.empFingerprint,
        empStatus: empStatus ?? this.empStatus,
        empEndDate: empEndDate ?? this.empEndDate,
        perId: perId ?? this.perId,
        perName: perName ?? this.perName,
        perLastName: perLastName ?? this.perLastName,
        perGender: perGender ?? this.perGender,
        perDoB: perDoB ?? this.perDoB,
        perEnidNo: perEnidNo ?? this.perEnidNo,
        perAddress: perAddress ?? this.perAddress,
        perPhone: perPhone ?? this.perPhone,
        perEmail: perEmail ?? this.perEmail,
      );

  factory EmployeeModel.fromMap(Map<String, dynamic> json) => EmployeeModel(
    empId: json["empID"],
    empPersonal: json["empPersonal"],
    empSalAccount: json["empSalAccount"],
    empEmail: json["empEmail"],
    empHireDate: json["empHireDate"] == null ? null : DateTime.parse(json["empHireDate"]),
    empDepartment: json["empDepartment"],
    empPosition: json["empPosition"],
    empSalCalcBase: json["empSalCalcBase"],
    empPmntMethod: json["empPmntMethod"],
    empSalary: json["empSalary"],
    empTaxInfo: json["empTaxInfo"],
    empFingerprint: json["empFingerprint"],
    empStatus: json["empStatus"],
    empEndDate: json["empEndDate"],
    perId: json["perID"],
    perName: json["perName"],
    perLastName: json["perLastName"],
    perGender: json["perGender"],
    perDoB: json["perDoB"],
    empImage: json["perPhoto"],
    perEnidNo: json["perENIDNo"],
    perAddress: json["perAddress"],
    perPhone: json["perPhone"],
    perEmail: json["perEmail"],
  );

  Map<String, dynamic> toMap() => {
    "empID": empId,
    "empPersonal": empPersonal,
    "empSalAccount": empSalAccount,
    "empEmail": empEmail,
    "empHireDate": "${empHireDate!.year.toString().padLeft(4, '0')}-${empHireDate!.month.toString().padLeft(2, '0')}-${empHireDate!.day.toString().padLeft(2, '0')}",
    "empDepartment": empDepartment,
    "empPosition": empPosition,
    "empSalCalcBase": empSalCalcBase,
    "empPmntMethod": empPmntMethod,
    "empSalary": empSalary,
    "empTaxInfo": empTaxInfo,
    "empFingerprint": empFingerprint,
    "empStatus": empStatus,
    "empEndDate": empEndDate,
    "perID": perId,
    "perName": perName,
    "perLastName": perLastName,
    "perGender": perGender,
    "perDoB": perDoB,
    "perENIDNo": perEnidNo,
    "perAddress": perAddress,
    "perPhone": perPhone,
    "perEmail": perEmail,
  };
}
