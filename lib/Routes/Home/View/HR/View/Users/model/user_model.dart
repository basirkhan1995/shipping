// To parse this JSON data, do
//
//     final usersModel = usersModelFromMap(jsonString);

import 'dart:convert';

List<UsersModel> usersModelFromMap(String str) =>
    List<UsersModel>.from(json.decode(str).map((x) => UsersModel.fromMap(x)));

String usersModelToMap(List<UsersModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class UsersModel {
  final int? usrId;
  final int? rolID;
  final String? usrFullName;
  final String? usrName;
  final String? usrRole;
  final int? usrStatus;
  final int? usrBranch;
  final String? usrEmail;
  final String? usrToken;
  final DateTime? usrEntryDate;
  final int? usrOwner;
  final String? usrPass;
  final int? usrFcp;
  final String? loggedInUser;
  final bool? usrFev;
  final String? usrPhoto;

  /// rsgID -> 0/1 (user's override on top of the role).
  final Map<int, int>? usrPermissions;

  /// rsgID -> 0/1 (what the role grants — ceiling for the user).
  final Map<int, int>? rolePermissions;

  UsersModel({
    this.usrId,
    this.rolID,
    this.usrFullName,
    this.usrName,
    this.usrRole,
    this.usrOwner,
    this.usrFcp,
    this.usrFev,
    this.usrPass,
    this.usrStatus,
    this.usrBranch,
    this.loggedInUser,
    this.usrEmail,
    this.usrToken,
    this.usrEntryDate,
    this.usrPhoto,
    this.usrPermissions,
    this.rolePermissions,
  });

  // ── Convenience views for the UI ─────────────────────────────────

  /// Current permission state as bools — what the checkboxes reflect.
  Map<int, bool> get permissionsAsBool =>
      (usrPermissions ?? const {}).map((k, v) => MapEntry(k, v == 1));

  /// Role ceiling as bools — what the checkboxes are allowed to toggle.
  Map<int, bool> get roleCeilingAsBool =>
      (rolePermissions ?? const {}).map((k, v) => MapEntry(k, v == 1));

  // ────────────────────────────────────────────────────────────────

  UsersModel copyWith({
    int? usrId,
    int? rolID,
    String? usrFullName,
    String? usrName,
    String? usrRole,
    int? usrStatus,
    int? usrBranch,
    String? usrEmail,
    String? usrToken,
    String? usrPhoto,
    DateTime? usrEntryDate,
    Map<int, int>? usrPermissions,
    Map<int, int>? rolePermissions,
  }) =>
      UsersModel(
        usrId: usrId ?? this.usrId,
        rolID: rolID ?? this.rolID,
        usrFullName: usrFullName ?? this.usrFullName,
        usrName: usrName ?? this.usrName,
        usrRole: usrRole ?? this.usrRole,
        usrStatus: usrStatus ?? this.usrStatus,
        usrBranch: usrBranch ?? this.usrBranch,
        usrEmail: usrEmail ?? this.usrEmail,
        usrToken: usrToken ?? this.usrToken,
        usrEntryDate: usrEntryDate ?? this.usrEntryDate,
        usrPhoto: usrPhoto ?? this.usrPhoto,
        usrOwner: usrOwner,
        usrPass: usrPass,
        usrFcp: usrFcp,
        usrFev: usrFev,
        loggedInUser: loggedInUser,
        usrPermissions: usrPermissions ?? this.usrPermissions,
        rolePermissions: rolePermissions ?? this.rolePermissions,
      );

  factory UsersModel.fromMap(Map<String, dynamic> json) => UsersModel(
    usrId: json["usrID"],
    rolID: json["rolID"],
    usrFullName: json["usrFullName"],
    usrName: json["usrName"],
    usrRole: json["usrRole"],
    usrStatus: json["usrStatus"],
    usrBranch: json["usrBranch"],
    usrEmail: json["usrEmail"],
    usrToken: json["usrToken"],
    usrEntryDate: json["usrEntryDate"] == null
        ? null
        : DateTime.parse(json["usrEntryDate"]),
    usrPhoto: json["perPhoto"],
    usrFcp: json["usrFCP"],
    usrPermissions: _parsePermMap(json["usrPermissions"]),
    rolePermissions: _parsePermMap(json["rolePermissions"]),
  );

  /// Parses `{"1": 1, "2": 0, ...}` into `{1: 1, 2: 0, ...}`.
  static Map<int, int>? _parsePermMap(dynamic raw) {
    if (raw is! Map) return null;
    final out = <int, int>{};
    raw.forEach((k, v) {
      final key = int.tryParse(k.toString());
      if (key == null) return;
      out[key] = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    });
    return out;
  }

  Map<String, dynamic> toMap() => {
    "usrID": usrId,
    "rolID": rolID,
    "usrFullName": usrFullName,
    "usrName": usrName,
    "usrPass": usrPass,
    "usrOwner": usrOwner,
    "usrFCP": usrFcp,
    "usrFEV": usrFev,
    "usrRole": usrRole,
    "usrStatus": usrStatus,
    "usrBranch": usrBranch,
    "usrEmail": usrEmail,
    "usrToken": usrToken,
    "loggedInUser": loggedInUser,
    "usrEntryDate": usrEntryDate?.toIso8601String(),
    if (usrPermissions != null)
      "usrPermissions": usrPermissions!
          .map((k, v) => MapEntry(k.toString(), v)),
    // rolePermissions is read-only — never sent to the server.
  };

  UsersModel copyWithStatus(int status, {String? actor}) => UsersModel(
    usrId: usrId,
    usrName: usrName,
    usrPass: usrPass,
    usrBranch: usrBranch,
    rolID: rolID,
    usrEmail: usrEmail,
    usrFcp: usrFcp,
    usrFev: usrFev,
    usrOwner: usrOwner,
    usrStatus: status,
    loggedInUser: actor ?? loggedInUser,
    usrPermissions: usrPermissions,
    rolePermissions: rolePermissions,
  );
}