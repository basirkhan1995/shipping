import 'dart:convert';

List<UserLogModel> userLogModelFromMap(String str) => List<UserLogModel>.from(json.decode(str).map((x) => UserLogModel.fromMap(x)));

String userLogModelToMap(List<UserLogModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class UserLogModel {
  final int? ualId;
  final int? usrId;
  final String? userProfile;
  final String? usrName;
  final String? fullName;
  final String? usrRole;
  final int? usrBranch;
  final String? ualType;
  final String? ualDetails;
  final String? ualIp;
  final String? ualDevice;
  final DateTime? ualTiming;

  UserLogModel({
    this.ualId,
    this.usrId,
    this.userProfile,
    this.usrName,
    this.fullName,
    this.usrRole,
    this.usrBranch,
    this.ualType,
    this.ualDetails,
    this.ualIp,
    this.ualDevice,
    this.ualTiming,
  });

  UserLogModel copyWith({
    int? ualId,
    int? usrId,
    String? usrName,
    String? fullName,
    String? usrRole,
    int? usrBranch,
    String? ualType,
    String? ualDetails,
    String? ualIp,
    String? ualDevice,
    DateTime? ualTiming,
    String? userProfile,
  }) =>
      UserLogModel(
        ualId: ualId ?? this.ualId,
        usrId: usrId ?? this.usrId,
        usrName: usrName ?? this.usrName,
        fullName: fullName ?? this.fullName,
        usrRole: usrRole ?? this.usrRole,
        usrBranch: usrBranch ?? this.usrBranch,
        ualType: ualType ?? this.ualType,
        ualDetails: ualDetails ?? this.ualDetails,
        ualIp: ualIp ?? this.ualIp,
        ualDevice: ualDevice ?? this.ualDevice,
        ualTiming: ualTiming ?? this.ualTiming,
        userProfile: userProfile ?? this.userProfile
      );

  factory UserLogModel.fromMap(Map<String, dynamic> json) => UserLogModel(
    ualId: json["ualID"],
    usrId: json["usrID"],
    usrName: json["usrName"],
    fullName: json["fullName"],
    usrRole: json["usrRole"],
    usrBranch: json["usrBranch"],
    ualType: json["ualType"],
    ualDetails: json["ualDetails"],
    ualIp: json["ualIP"],
    ualDevice: json["ualDevice"],
    ualTiming: json["ualTiming"] == null ? null : DateTime.parse(json["ualTiming"]),
    userProfile: json["perPhoto"],
  );

  Map<String, dynamic> toMap() => {
    "ualID": ualId,
    "usrID": usrId,
    "usrName": usrName,
    "fullName": fullName,
    "usrRole": usrRole,
    "usrBranch": usrBranch,
    "ualType": ualType,
    "ualDetails": ualDetails,
    "ualIP": ualIp,
    "ualDevice": ualDevice,
    "ualTiming": ualTiming?.toIso8601String(),
  };
}
