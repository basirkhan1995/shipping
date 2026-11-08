import 'dart:convert';

List<StakeholdersModel> individualsModelFromMap(String str) =>
    List<StakeholdersModel>.from(
      json.decode(str).map((x) => StakeholdersModel.fromMap(x)),
    );

String individualsModelToMap(List<StakeholdersModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

// =====================================================================
// StakeholdersModel
// =====================================================================
class StakeholdersModel {
  final int? perId;
  final String? perCode;
  final int perLock;                    // non-nullable — 0 or 1
  final String? perName;
  final String? perLastName;
  final String? perGender;
  final DateTime? perDoB;
  final String? perEnidNo;
  final int? perAddress;
  final String? perPhone;
  final String? perEmail;
  final String? imageProfile;

  // Address
  final int? addId;
  final String? addName;
  final String? addCity;
  final String? addProvince;
  final String? addCountry;
  final String? addZipCode;
  final int? addMailing;

  // Accounts (multi-currency)
  final List<StkAccountModel> accounts;

  // Recent transactions (up to 10, newest first, across all accounts)
  final List<RecentTransaction> recentTransactions;

  StakeholdersModel({
    this.perId,
    this.perCode,
    this.perLock = 0,                   // default 0
    this.perName,
    this.perLastName,
    this.perGender,
    this.perDoB,
    this.perEnidNo,
    this.perAddress,
    this.perPhone,
    this.perEmail,
    this.imageProfile,
    this.addId,
    this.addName,
    this.addCity,
    this.addProvince,
    this.addCountry,
    this.addZipCode,
    this.addMailing,
    this.accounts = const [],
    this.recentTransactions = const [],
  });

  StakeholdersModel copyWith({
    int? perId,
    String? perCode,
    int? perLock,
    String? perName,
    String? perLastName,
    String? perGender,
    DateTime? perDoB,
    String? perEnidNo,
    int? perAddress,
    String? perPhone,
    String? perEmail,
    String? imageProfile,
    int? addId,
    String? addName,
    String? addCity,
    String? addProvince,
    String? addCountry,
    String? addZipCode,
    int? addMailing,
    List<StkAccountModel>? accounts,
    List<RecentTransaction>? recentTransactions,
  }) =>
      StakeholdersModel(
        perId: perId ?? this.perId,
        perCode: perCode ?? this.perCode,
        perLock: perLock ?? this.perLock,
        perName: perName ?? this.perName,
        perLastName: perLastName ?? this.perLastName,
        perGender: perGender ?? this.perGender,
        perDoB: perDoB ?? this.perDoB,
        perEnidNo: perEnidNo ?? this.perEnidNo,
        perAddress: perAddress ?? this.perAddress,
        perPhone: perPhone ?? this.perPhone,
        perEmail: perEmail ?? this.perEmail,
        imageProfile: imageProfile ?? this.imageProfile,
        addId: addId ?? this.addId,
        addName: addName ?? this.addName,
        addCity: addCity ?? this.addCity,
        addProvince: addProvince ?? this.addProvince,
        addCountry: addCountry ?? this.addCountry,
        addZipCode: addZipCode ?? this.addZipCode,
        addMailing: addMailing ?? this.addMailing,
        accounts: accounts ?? this.accounts,
        recentTransactions: recentTransactions ?? this.recentTransactions,
      );

  factory StakeholdersModel.fromMap(Map<String, dynamic> json) =>
      StakeholdersModel(
        perId: _asInt(json["perID"]),
        perLock: _asInt(json['perLock']) ?? 0,
        perCode: _asString(json['perCode']),
        perName: _asString(json["perName"]),
        perLastName: _asString(json["perLastName"]),
        perGender: _asString(json["perGender"]),
        perDoB: json["perDoB"] == null
            ? null
            : DateTime.tryParse(json["perDoB"].toString()),
        perEnidNo: _asString(json["perENIDNo"]),
        perAddress: _asInt(json["perAddress"]),
        perPhone: _asString(json["perPhone"]),
        perEmail: _asString(json["perEmail"]),
        imageProfile: _asString(json["perPhoto"]),
        addId: _asInt(json["addID"]),
        addName: _asString(json["addName"]),
        addCity: _asString(json["addCity"]),
        addProvince: _asString(json["addProvince"]),
        addCountry: _asString(json["addCountry"]),
        addZipCode: _asString(json["addZipCode"]),
        addMailing: _asInt(json["addMailing"]),
        accounts: json["accounts"] == null
            ? const []
            : List<StkAccountModel>.from(
          (json["accounts"] as List)
              .map((x) => StkAccountModel.fromMap(x)),
        ),
        recentTransactions: json["recentTransactions"] == null
            ? const []
            : List<RecentTransaction>.from(
          (json["recentTransactions"] as List)
              .map((x) => RecentTransaction.fromMap(x)),
        ),
      );

  Map<String, dynamic> toMap() => {
    "per_ID": perId,
    "perCode": perCode,
    "perLock": perLock,             // always present
    "first_name": perName,
    "last_name": perLastName,
    "per_DoB": perDoB == null
        ? null
        : "${perDoB!.year.toString().padLeft(4, '0')}-"
        "${perDoB!.month.toString().padLeft(2, '0')}-"
        "${perDoB!.day.toString().padLeft(2, '0')}",
    "per_gender": perGender,
    "per_nidno": perEnidNo,
    "cell_number": perPhone,
    "add_ID": addId,
    "add_name": addName,
    "add_city": addCity,
    "add_province": addProvince,
    "add_country": addCountry,
    "zip_code": addZipCode,
    "email": perEmail,
    "is_mailing": addMailing,
  };

  /// Full display name convenience getter.
  String get fullName =>
      [perName, perLastName].where((e) => e != null && e.isNotEmpty).join(' ');

  /// Whether this stakeholder is currently locked.
  bool get isLocked => perLock == 1;

  /// Whether this stakeholder has at least one active account.
  bool get hasActiveAccount => accounts.any((a) => a.accStatus == 1);

  /// Total balance across all accounts, per currency.
  Map<String, double> get balancesByCurrency {
    final map = <String, double>{};
    for (final acc in accounts) {
      final ccy = acc.accCurrency ?? 'UNK';
      map[ccy] = (map[ccy] ?? 0) + acc.accBalance;
    }
    return map;
  }
}

// =====================================================================
// StakeholderAccount
// =====================================================================
class StkAccountModel {
  final int? accNumber;
  final String? accName;
  final String? accCurrency;
  final int? accCategory;
  final int? accStatus;

  /// Either a double (numeric limit) or the string "Unlimited".
  final dynamic accLimit;

  final double accBalance;

  StkAccountModel({
    this.accNumber,
    this.accName,
    this.accCurrency,
    this.accCategory,
    this.accStatus,
    this.accLimit,
    this.accBalance = 0,
  });

  StkAccountModel copyWith({
    int? accNumber,
    String? accName,
    String? accCurrency,
    int? accCategory,
    int? accStatus,
    dynamic accLimit,
    double? accBalance,
  }) =>
      StkAccountModel(
        accNumber: accNumber ?? this.accNumber,
        accName: accName ?? this.accName,
        accCurrency: accCurrency ?? this.accCurrency,
        accStatus: accStatus ?? this.accStatus,
        accLimit: accLimit ?? this.accLimit,
        accCategory: accCategory ?? this.accCategory,
        accBalance: accBalance ?? this.accBalance,
      );

  factory StkAccountModel.fromMap(Map<String, dynamic> json) =>
      StkAccountModel(
        accNumber: _asInt(json["accNumber"]),
        accName: _asString(json["accName"]),
        accCurrency: _asString(json["accCurrency"]),
        accStatus: _asInt(json["accStatus"]),
        accLimit: json["accLimit"],
        accCategory: _asInt(json["accCategory"]),
        accBalance: _asDouble(json["accBalance"]) ?? 0,
      );

  Map<String, dynamic> toMap() => {
    "accNumber": accNumber,
    "accName": accName,
    "accCurrency": accCurrency,
    "accStatus": accStatus,
    "accLimit": accLimit,
    "accCategory": accCategory,
    "accBalance": accBalance,
  };

  bool get isUnlimited =>
      accLimit is String && (accLimit as String).toLowerCase() == 'unlimited';

  double? get limitValue {
    if (isUnlimited) return null;
    if (accLimit is num) return (accLimit as num).toDouble();
    if (accLimit is String) return double.tryParse(accLimit as String);
    return null;
  }

  String get formattedBalance {
    final value = accBalance.toStringAsFixed(2);
    final parts = value.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]} ${accCurrency ?? ''}'.trim();
  }
}

// =====================================================================
// RecentTransaction
// =====================================================================
class RecentTransaction {
  final String? reference;
  final String? type;
  final String? statusText;
  final int? status;
  final DateTime? entryDate;
  final int? account;
  final String? accountName;
  final String? currency;
  final double amount;
  final String? drCr;
  final String? narration;
  final double runningBalance;

  const RecentTransaction({
    this.reference,
    this.type,
    this.statusText,
    this.status,
    this.entryDate,
    this.account,
    this.accountName,
    this.currency,
    this.amount = 0,
    this.drCr,
    this.narration,
    this.runningBalance = 0,
  });

  RecentTransaction copyWith({
    String? reference,
    String? type,
    String? statusText,
    int? status,
    DateTime? entryDate,
    int? account,
    String? accountName,
    String? currency,
    double? amount,
    String? drCr,
    String? narration,
    double? runningBalance,
  }) =>
      RecentTransaction(
        reference: reference ?? this.reference,
        type: type ?? this.type,
        statusText: statusText ?? this.statusText,
        status: status ?? this.status,
        entryDate: entryDate ?? this.entryDate,
        account: account ?? this.account,
        accountName: accountName ?? this.accountName,
        currency: currency ?? this.currency,
        amount: amount ?? this.amount,
        drCr: drCr ?? this.drCr,
        narration: narration ?? this.narration,
        runningBalance: runningBalance ?? this.runningBalance,
      );

  factory RecentTransaction.fromMap(Map<String, dynamic> json) =>
      RecentTransaction(
        reference: _asString(json["reference"]),
        type: _asString(json["type"]),
        statusText: _asString(json["statusText"]),
        status: _asInt(json["status"]),
        entryDate: json["entryDate"] == null
            ? null
            : DateTime.tryParse(json["entryDate"].toString()),
        account: _asInt(json["account"]),
        accountName: _asString(json["accountName"]),
        currency: _asString(json["currency"]),
        amount: _asDouble(json["amount"]) ?? 0,
        drCr: _asString(json["drCr"]),
        narration: _asString(json["narration"]),
        runningBalance: _asDouble(json["runningBalance"]) ?? 0,
      );

  Map<String, dynamic> toMap() => {
    "reference": reference,
    "type": type,
    "statusText": statusText,
    "status": status,
    "entryDate": entryDate == null
        ? null
        : "${entryDate!.year.toString().padLeft(4, '0')}-"
        "${entryDate!.month.toString().padLeft(2, '0')}-"
        "${entryDate!.day.toString().padLeft(2, '0')} "
        "${entryDate!.hour.toString().padLeft(2, '0')}:"
        "${entryDate!.minute.toString().padLeft(2, '0')}:"
        "${entryDate!.second.toString().padLeft(2, '0')}",
    "account": account,
    "accountName": accountName,
    "currency": currency,
    "amount": amount,
    "drCr": drCr,
    "narration": narration,
    "runningBalance": runningBalance,
  };

  bool get isAuthorized => status == 1;
  bool get isPending => status == 0;
  double get signedAmount => drCr == 'Dr' ? -amount : amount;

  String get formattedAmount {
    final sign = drCr == 'Dr' ? '-' : '+';
    final value = amount.toStringAsFixed(2);
    final parts = value.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return '$sign$intPart.${parts[1]} ${currency ?? ''}'.trim();
  }

  String get formattedRunningBalance {
    final parts = runningBalance.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]} ${currency ?? ''}'.trim();
  }

  String get accountLabel {
    if (account == null) return '—';
    return accountName != null && accountName!.isNotEmpty
        ? '$accountName · $account'
        : '$account';
  }

  String get formattedDate {
    if (entryDate == null) return '—';
    final d = entryDate!;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}

// =====================================================================
// Helpers — safely parse typed values from PHP's loosely-typed JSON
// =====================================================================
int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String? _asString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

// =====================================================================
// Extension — permission helper
// =====================================================================
extension LoginPermissionExt on StakeholdersModel {
  bool? hasPermission(int uprRole) {
    return null;
  }
}