class AttendanceModel {
  final int? emaID;
  final int? emaEmployee;
  final String? empPosition;
  final String? fullName;
  final String? emaDate;
  final String? emaCheckedIn;      // may be null
  final String? emaCheckedOut;     // may be null
  final double? emaWorkHours;      // may be null
  final String? emaStatus;
  final bool emaCompleted;         // ← NEW
  final String? emaEntryTime;

  const AttendanceModel({
    this.emaID,
    this.emaEmployee,
    this.empPosition,
    this.fullName,
    this.emaDate,
    this.emaCheckedIn,
    this.emaCheckedOut,
    this.emaWorkHours,
    this.emaStatus,
    this.emaCompleted = false,
    this.emaEntryTime,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> j) => AttendanceModel(
    emaID: _toInt(j['emaID']),
    emaEmployee: _toInt(j['emaEmployee']),
    empPosition: _toStr(j['empPosition']),
    fullName: _toStr(j['fullName']),
    emaDate: _toStr(j['emaDate']),
    emaCheckedIn: _toStr(j['emaCheckedIn']),
    emaCheckedOut: _toStr(j['emaCheckedOut']),
    emaWorkHours: _toDouble(j['emaWorkHours']),
    emaStatus: _toStr(j['emaStatus']),
    emaCompleted: _toBool(j['emaCompleted']),
    emaEntryTime: _toStr(j['emaEntryTime']),
  );

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  static String? _toStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    return s == '1' || s == 'true';
  }
}