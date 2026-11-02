class AttendanceModel {
  final int? emaID;
  final int? emaEmployee;
  final String? empPosition;
  final String? fullName;
  final String? emaDate;
  final String? emaCheckedIn;
  final String? emaCheckedOut;
  final double? emaWorkHours;
  final String? emaStatus;
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
    this.emaEntryTime,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> j) => AttendanceModel(
    emaID: (j['emaID'] as num?)?.toInt(),
    emaEmployee: (j['emaEmployee'] as num?)?.toInt(),
    empPosition: j['empPosition'] as String?,
    fullName: j['fullName'] as String?,
    emaDate: j['emaDate'] as String?,
    emaCheckedIn: j['emaCheckedIn'] as String?,
    emaCheckedOut: j['emaCheckedOut'] as String?,
    emaWorkHours: (j['emaWorkHours'] as num?)?.toDouble(),
    emaStatus: j['emaStatus'] as String?,
    emaEntryTime: j['emaEntryTime'] as String?,
  );
}