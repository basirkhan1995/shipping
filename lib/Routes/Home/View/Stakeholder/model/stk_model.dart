import 'dart:convert';

List<IndividualsModel> individualsModelFromMap(String str) =>
    List<IndividualsModel>.from(
      json.decode(str).map((x) => IndividualsModel.fromMap(x)),
    );

String individualsModelToMap(List<IndividualsModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

// =====================================================================
// IndividualsModel
// =====================================================================
class IndividualsModel {
  final int? perId;
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
  final List<StakeholderAccount> accounts;

  // Recent transactions (up to 10, newest first, across all accounts)
  final List<RecentTransaction> recentTransactions;

  IndividualsModel({
    this.perId,
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

  IndividualsModel copyWith({
    int? perId,
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
    List<StakeholderAccount>? accounts,
    List<RecentTransaction>? recentTransactions,
  }) =>
      IndividualsModel(
        perId: perId ?? this.perId,
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

  factory IndividualsModel.fromMap(Map<String, dynamic> json) =>
      IndividualsModel(
        perId: _asInt(json["perID"]),
        perName: json["perName"] as String?,
        perLastName: json["perLastName"] as String?,
        perGender: json["perGender"] as String?,
        perDoB: json["perDoB"] == null
            ? null
            : DateTime.tryParse(json["perDoB"].toString()),
        perEnidNo: json["perENIDNo"] as String?,
        perAddress: _asInt(json["perAddress"]),
        perPhone: json["perPhone"] as String?,
        perEmail: json["perEmail"] as String?,
        imageProfile: json["perPhoto"] as String?,
        addId: _asInt(json["addID"]),
        addName: json["addName"] as String?,
        addCity: json["addCity"] as String?,
        addProvince: json["addProvince"] as String?,
        addCountry: json["addCountry"] as String?,
        addZipCode: json["addZipCode"] as String?,
        addMailing: _asInt(json["addMailing"]),
        accounts: json["accounts"] == null
            ? const []
            : List<StakeholderAccount>.from(
          (json["accounts"] as List)
              .map((x) => StakeholderAccount.fromMap(x)),
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
    // accounts and recentTransactions are read-only from the server.
  };

  /// Full display name convenience getter.
  String get fullName =>
      [perName, perLastName].where((e) => e != null && e.isNotEmpty).join(' ');

  /// Whether this stakeholder has at least one active account.
  bool get hasActiveAccount => accounts.any((a) => a.accStatus == 1);

  /// Total balance across all accounts, per currency.
  /// Returns e.g. { 'USD': 1200.0, 'AFN': 54000.0 }
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
class StakeholderAccount {
  final int? accNumber;
  final String? accName;
  final String? accCurrency;
  final int? accStatus;

  /// Either a double (numeric limit) or the string "Unlimited".
  final dynamic accLimit;

  final double accBalance;

  StakeholderAccount({
    this.accNumber,
    this.accName,
    this.accCurrency,
    this.accStatus,
    this.accLimit,
    this.accBalance = 0,
  });

  StakeholderAccount copyWith({
    int? accNumber,
    String? accName,
    String? accCurrency,
    int? accStatus,
    dynamic accLimit,
    double? accBalance,
  }) =>
      StakeholderAccount(
        accNumber: accNumber ?? this.accNumber,
        accName: accName ?? this.accName,
        accCurrency: accCurrency ?? this.accCurrency,
        accStatus: accStatus ?? this.accStatus,
        accLimit: accLimit ?? this.accLimit,
        accBalance: accBalance ?? this.accBalance,
      );

  factory StakeholderAccount.fromMap(Map<String, dynamic> json) =>
      StakeholderAccount(
        accNumber: _asInt(json["accNumber"]),
        accName: json["accName"] as String?,
        accCurrency: json["accCurrency"] as String?,
        accStatus: _asInt(json["accStatus"]),
        accLimit: json["accLimit"],
        accBalance: _asDouble(json["accBalance"]) ?? 0,
      );

  Map<String, dynamic> toMap() => {
    "accNumber": accNumber,
    "accName": accName,
    "accCurrency": accCurrency,
    "accStatus": accStatus,
    "accLimit": accLimit,
    "accBalance": accBalance,
  };

  /// True when the credit limit is the unlimited sentinel.
  bool get isUnlimited =>
      accLimit is String && (accLimit as String).toLowerCase() == 'unlimited';

  /// Numeric limit, or null when unlimited.
  double? get limitValue {
    if (isUnlimited) return null;
    if (accLimit is num) return (accLimit as num).toDouble();
    if (accLimit is String) return double.tryParse(accLimit as String);
    return null;
  }

  /// Formatted balance, e.g. "1,200.00 USD".
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
// RecentTransaction — last N transactions across all stakeholder accounts
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
        reference: json["reference"] as String?,
        type: json["type"] as String?,
        statusText: json["statusText"] as String?,
        status: _asInt(json["status"]),
        entryDate: json["entryDate"] == null
            ? null
            : DateTime.tryParse(json["entryDate"].toString()),
        account: _asInt(json["account"]),
        accountName: json["accountName"] as String?,
        currency: json["currency"] as String?,
        amount: _asDouble(json["amount"]) ?? 0,
        drCr: json["drCr"] as String?,
        narration: json["narration"] as String?,
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

  /// True when the transaction is authorized.
  bool get isAuthorized => status == 1;

  /// True when it's still pending (maker has created but not authorized).
  bool get isPending => status == 0;

  /// Signed amount for balance math: + for credit to the account, - for debit.
  double get signedAmount => drCr == 'Dr' ? -amount : amount;

  /// Formatted amount with sign and currency, e.g. "+500.00 USD".
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

  /// Formatted running balance with currency, e.g. "1,200.00 USD".
  String get formattedRunningBalance {
    final parts = runningBalance.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]} ${currency ?? ''}'.trim();
  }

  /// Account label, e.g. "Zabi USD · 500000".
  String get accountLabel {
    if (account == null) return '—';
    return accountName != null && accountName!.isNotEmpty
        ? '$accountName · $account'
        : '$account';
  }

  /// Formatted date, e.g. "2026-10-20 14:32".
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
// Helpers — safely parse int / double from PHP's loosely-typed JSON
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

// =====================================================================
// Extension — permission helper
// =====================================================================
extension LoginPermissionExt on IndividualsModel {
  bool? hasPermission(int uprRole) {
    return null;
  }
}