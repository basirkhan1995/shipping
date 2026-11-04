import 'package:equatable/equatable.dart';

// ═════════════════════════════════════════════════════════════════
// ROOT — GET /users/profile.php?usrName=…
// ═════════════════════════════════════════════════════════════════

class UserProfile extends Equatable {
  final String msg;
  final UserAccount user;
  final UserPersonal personal;
  final UserAddress? address;

  const UserProfile({
    this.msg = 'success',
    required this.user,
    required this.personal,
    this.address,
  });

  bool get isSuccess => msg.toLowerCase() == 'success';

  /// Full display name — useful for the app bar / avatar fallback.
  String get displayName {
    final last = (personal.perLastName ?? '').trim();
    return last.isEmpty
        ? personal.perName ?? ''
        : '${personal.perName ?? ''} $last'.trim();
  }

  /// Absolute photo URL (already returned by the API) or `null`.
  String? get photoUrl => personal.perPhoto;

  /// Two-letter initials for an avatar fallback.
  String get initials {
    final f = (personal.perName ?? '').trim();
    final l = (personal.perLastName ?? '').trim();
    final a = f.isNotEmpty ? f[0] : '';
    final b = l.isNotEmpty ? l[0] : '';
    return '$a$b'.toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    return UserProfile(
      msg:      (j['msg'] ?? '').toString(),
      user:     UserAccount.fromJson(_map(j['user'])),
      personal: UserPersonal.fromJson(_map(j['personal'])),
      address:  j['address'] == null
          ? null
          : UserAddress.fromJson(_map(j['address'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'msg':      msg,
    'user':     user.toJson(),
    'personal': personal.toJson(),
    'address':  address?.toJson(),
  };

  UserProfile copyWith({
    String? msg,
    UserAccount? user,
    UserPersonal? personal,
    UserAddress? address,
    bool clearAddress = false,
  }) {
    return UserProfile(
      msg:      msg ?? this.msg,
      user:     user ?? this.user,
      personal: personal ?? this.personal,
      address:  clearAddress ? null : (address ?? this.address),
    );
  }

  @override
  List<Object?> get props => [msg, user, personal, address];
}

// ═════════════════════════════════════════════════════════════════
// USER BLOCK
// ═════════════════════════════════════════════════════════════════

class UserAccount extends Equatable {
  final int usrID;
  final String usrName;
  final String? usrEmail;
  final int usrStatus;
  final int usrFCP;
  final String? usrToken;
  final DateTime? usrEntryDate;

  const UserAccount({
    required this.usrID,
    required this.usrName,
    this.usrEmail,
    this.usrStatus = 1,
    this.usrFCP = 0,
    this.usrToken,
    this.usrEntryDate,
  });

  bool get isEnabled     => usrStatus == 1;
  bool get mustChangePass => usrFCP == 1;
  bool get isVerified    => (usrToken ?? '').toLowerCase() == 'verified';

  factory UserAccount.fromJson(Map<String, dynamic> j) {
    return UserAccount(
      usrID:        _int(j['usrID']) ?? 0,
      usrName:      _str(j['usrName']) ?? '',
      usrEmail:     _str(j['usrEmail']),
      usrStatus:    _int(j['usrStatus']) ?? 0,
      usrFCP:       _int(j['usrFCP']) ?? 0,
      usrToken:     _str(j['usrToken']),
      usrEntryDate: _date(j['usrEntryDate']),
    );
  }

  Map<String, dynamic> toJson() => {
    'usrID':        usrID,
    'usrName':      usrName,
    'usrEmail':     usrEmail,
    'usrStatus':    usrStatus,
    'usrFCP':       usrFCP,
    'usrToken':     usrToken,
    'usrEntryDate': usrEntryDate?.toIso8601String(),
  };

  UserAccount copyWith({
    int? usrID,
    String? usrName,
    String? usrEmail,
    int? usrStatus,
    int? usrFCP,
    String? usrToken,
    DateTime? usrEntryDate,
  }) {
    return UserAccount(
      usrID:        usrID ?? this.usrID,
      usrName:      usrName ?? this.usrName,
      usrEmail:     usrEmail ?? this.usrEmail,
      usrStatus:    usrStatus ?? this.usrStatus,
      usrFCP:       usrFCP ?? this.usrFCP,
      usrToken:     usrToken ?? this.usrToken,
      usrEntryDate: usrEntryDate ?? this.usrEntryDate,
    );
  }

  @override
  List<Object?> get props => [
    usrID, usrName, usrEmail, usrStatus, usrFCP, usrToken, usrEntryDate,
  ];
}

// ═════════════════════════════════════════════════════════════════
// PERSONAL BLOCK
// ═════════════════════════════════════════════════════════════════

class UserPersonal extends Equatable {
  final int perID;
  final String? perName;
  final String? perLastName;
  final String? perGender;      // 'Male' | 'Female' | 'Other' | null
  final DateTime? perDoB;
  final String? perENIDNo;
  final String? perPhone;
  final String? perEmail;
  final String? perPhoto;       // full URL: /images/personal/xxx.jpg

  const UserPersonal({
    required this.perID,
    this.perName,
    this.perLastName,
    this.perGender,
    this.perDoB,
    this.perENIDNo,
    this.perPhone,
    this.perEmail,
    this.perPhoto,
  });

  String get fullName {
    final l = (perLastName ?? '').trim();
    return l.isEmpty
        ? perName ?? ''
        : '${perName ?? ''} $l'.trim();
  }

  factory UserPersonal.fromJson(Map<String, dynamic> j) {
    return UserPersonal(
      perID:       _int(j['perID']) ?? 0,
      perName:     _str(j['perName']),
      perLastName: _str(j['perLastName']),
      perGender:   _str(j['perGender']),
      perDoB:      _date(j['perDoB']),
      perENIDNo:   _str(j['perENIDNo']),
      perPhone:    _str(j['perPhone']),
      perEmail:    _str(j['perEmail']),
      perPhoto:    _str(j['perPhoto']),
    );
  }

  Map<String, dynamic> toJson() => {
    'perID':       perID,
    'perName':     perName,
    'perLastName': perLastName,
    'perGender':   perGender,
    'perDoB':      _dateOnly(perDoB),
    'perENIDNo':   perENIDNo,
    'perPhone':    perPhone,
    'perEmail':    perEmail,
    'perPhoto':    perPhoto,
  };

  UserPersonal copyWith({
    int? perID,
    String? perName,
    String? perLastName,
    String? perGender,
    DateTime? perDoB,
    String? perENIDNo,
    String? perPhone,
    String? perEmail,
    String? perPhoto,
  }) {
    return UserPersonal(
      perID:       perID ?? this.perID,
      perName:     perName ?? this.perName,
      perLastName: perLastName ?? this.perLastName,
      perGender:   perGender ?? this.perGender,
      perDoB:      perDoB ?? this.perDoB,
      perENIDNo:   perENIDNo ?? this.perENIDNo,
      perPhone:    perPhone ?? this.perPhone,
      perEmail:    perEmail ?? this.perEmail,
      perPhoto:    perPhoto ?? this.perPhoto,
    );
  }

  @override
  List<Object?> get props => [
    perID, perName, perLastName, perGender, perDoB,
    perENIDNo, perPhone, perEmail, perPhoto,
  ];
}

// ═════════════════════════════════════════════════════════════════
// ADDRESS BLOCK
// ═════════════════════════════════════════════════════════════════

class UserAddress extends Equatable {
  final int addID;
  final String? addName;
  final String? addCity;
  final String? addProvince;
  final String? addCountry;
  final String? addZipCode;
  final int addMailing;

  const UserAddress({
    required this.addID,
    this.addName,
    this.addCity,
    this.addProvince,
    this.addCountry,
    this.addZipCode,
    this.addMailing = 0,
  });

  bool get isMailing => addMailing == 1;

  factory UserAddress.fromJson(Map<String, dynamic> j) {
    return UserAddress(
      addID:       _int(j['addID']) ?? 0,
      addName:     _str(j['addName']),
      addCity:     _str(j['addCity']),
      addProvince: _str(j['addProvince']),
      addCountry:  _str(j['addCountry']),
      addZipCode:  _str(j['addZipCode']),
      addMailing:  _int(j['addMailing']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'addID':       addID,
    'addName':     addName,
    'addCity':     addCity,
    'addProvince': addProvince,
    'addCountry':  addCountry,
    'addZipCode':  addZipCode,
    'addMailing':  addMailing,
  };

  UserAddress copyWith({
    int? addID,
    String? addName,
    String? addCity,
    String? addProvince,
    String? addCountry,
    String? addZipCode,
    int? addMailing,
  }) {
    return UserAddress(
      addID:       addID ?? this.addID,
      addName:     addName ?? this.addName,
      addCity:     addCity ?? this.addCity,
      addProvince: addProvince ?? this.addProvince,
      addCountry:  addCountry ?? this.addCountry,
      addZipCode:  addZipCode ?? this.addZipCode,
      addMailing:  addMailing ?? this.addMailing,
    );
  }

  @override
  List<Object?> get props => [
    addID, addName, addCity, addProvince,
    addCountry, addZipCode, addMailing,
  ];
}

// ═════════════════════════════════════════════════════════════════
// PUT / POST → update payload
// ═════════════════════════════════════════════════════════════════

class UpdateUserProfileRequest extends Equatable {
  final String usrName;
  final String? perName;
  final String? perLastName;
  final String? perGender;
  final DateTime? perDoB;
  final String? perENIDNo;
  final String? perPhone;
  final String? perEmail;
  final UserAddress? address;

  const UpdateUserProfileRequest({
    required this.usrName,
    this.perName,
    this.perLastName,
    this.perGender,
    this.perDoB,
    this.perENIDNo,
    this.perPhone,
    this.perEmail,
    this.address,
  });

  factory UpdateUserProfileRequest.fromProfile(
      UserProfile p, {
        String? newName,
        String? newLastName,
        String? newGender,
        DateTime? newDoB,
        String? newENID,
        String? newPhone,
        String? newEmail,
        UserAddress? newAddress,
      }) {
    return UpdateUserProfileRequest(
      usrName:     p.user.usrName,
      perName:     newName     ?? p.personal.perName,
      perLastName: newLastName ?? p.personal.perLastName,
      perGender:   newGender   ?? p.personal.perGender,
      perDoB:      newDoB      ?? p.personal.perDoB,
      perENIDNo:   newENID     ?? p.personal.perENIDNo,
      perPhone:    newPhone    ?? p.personal.perPhone,
      perEmail:    newEmail    ?? p.personal.perEmail,
      address:     newAddress  ?? p.address,
    );
  }

  /// Only sends keys that are non-null — the backend treats missing
  /// keys as "don't touch this field".
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'usrName': usrName};

    if (perName     != null) map['perName']     = perName;
    if (perLastName != null) map['perLastName'] = perLastName;
    if (perGender   != null) map['perGender']   = perGender;
    if (perDoB      != null) map['perDoB']      = _dateOnly(perDoB);
    if (perENIDNo   != null) map['perENIDNo']   = perENIDNo;
    if (perPhone    != null) map['perPhone']    = perPhone;
    if (perEmail    != null) map['perEmail']    = perEmail;
    if (address     != null) map['address']     = address!.toJson();

    return map;
  }

  @override
  List<Object?> get props => [
    usrName, perName, perLastName, perGender, perDoB,
    perENIDNo, perPhone, perEmail, address,
  ];
}

// ═════════════════════════════════════════════════════════════════
// POST ?action=password
// ═════════════════════════════════════════════════════════════════

class ChangePasswordRequest extends Equatable {
  final String usrName;
  final String oldPassword;
  final String newPassword;

  const ChangePasswordRequest({
    required this.usrName,
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'usrName':     usrName,
    'oldPassword': oldPassword,
    'newPassword': newPassword,
  };

  @override
  List<Object?> get props => [usrName, oldPassword, newPassword];
}

// ═════════════════════════════════════════════════════════════════
// POST ?action=photo  (response)
// ═════════════════════════════════════════════════════════════════

class UploadProfilePhotoResult extends Equatable {
  final String msg;
  final String? photoUrl;

  const UploadProfilePhotoResult({required this.msg, this.photoUrl});

  bool get isSuccess => msg.toLowerCase() == 'success';

  factory UploadProfilePhotoResult.fromJson(Map<String, dynamic> j) {
    return UploadProfilePhotoResult(
      msg:      (j['msg'] ?? '').toString(),
      photoUrl: _str(j['photo']),
    );
  }

  @override
  List<Object?> get props => [msg, photoUrl];
}

// ═════════════════════════════════════════════════════════════════
// Safe coercers
// ═════════════════════════════════════════════════════════════════

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty || s.toLowerCase() == 'null' ? null : s;
}

int? _int(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim());
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty || s.toLowerCase() == 'null') return null;
  return DateTime.tryParse(s) ??
      DateTime.tryParse(s.replaceFirst(' ', 'T'));
}

/// Serialises a `DateTime` as `yyyy-MM-dd` (matches SQL `DATE`).
String? _dateOnly(DateTime? d) {
  if (d == null) return null;
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

Map<String, dynamic> _map(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return const {};
}