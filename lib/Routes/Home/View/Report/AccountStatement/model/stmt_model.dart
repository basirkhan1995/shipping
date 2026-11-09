class AccountStatementModel {
  final int? perId;
  final int perLock;
  final int? accNumber;
  final String? accName;
  final String? signatory;
  final String? perPhone;
  final String? perEmail;
  final String? address;
  final String? actCurrency;
  final String? ccySymbol;
  final String? actCreditLimit;
  final String? curBalance;
  final String? avilBalance;
  final int? actStatus;
  final String? trnStatus;
  final List<StmtRecord>? records;

  AccountStatementModel({
    this.perId,
    this.perLock = 0,
    this.accNumber,
    this.accName,
    this.trnStatus,
    this.signatory,
    this.perPhone,
    this.perEmail,
    this.address,
    this.actCurrency,
    this.ccySymbol,
    this.actCreditLimit,
    this.curBalance,
    this.avilBalance,
    this.actStatus,
    this.records,
  });

  bool get isLocked => perLock == 1;

  AccountStatementModel copyWith({
    int? perId,
    int? perLock,
    int? accNumber,
    String? accName,
    String? signatory,
    String? perPhone,
    String? perEmail,
    String? address,
    String? actCurrency,
    String? ccySymbol,
    String? actCreditLimit,
    String? curBalance,
    String? avilBalance,
    int? actStatus,
    List<StmtRecord>? records,
  }) =>
      AccountStatementModel(
        perId: perId ?? this.perId,
        perLock: perLock ?? this.perLock,
        accNumber: accNumber ?? this.accNumber,
        accName: accName ?? this.accName,
        signatory: signatory ?? this.signatory,
        perPhone: perPhone ?? this.perPhone,
        perEmail: perEmail ?? this.perEmail,
        address: address ?? this.address,
        actCurrency: actCurrency ?? this.actCurrency,
        ccySymbol: ccySymbol ?? this.ccySymbol,
        actCreditLimit: actCreditLimit ?? this.actCreditLimit,
        curBalance: curBalance ?? this.curBalance,
        avilBalance: avilBalance ?? this.avilBalance,
        actStatus: actStatus ?? this.actStatus,
        records: records ?? this.records,
      );

  factory AccountStatementModel.fromMap(dynamic json) {
    final Map<String, dynamic> data = _convertMap(json);

    return AccountStatementModel(
      perId: _asInt(data["perID"]),
      perLock: _asInt(data["perLock"]) ?? 0,
      accNumber: _asInt(data["accNumber"]),
      accName: _asString(data["accName"]),
      signatory: _asString(data["signatory"]),
      perPhone: _asString(data["perPhone"]),
      perEmail: _asString(data["perEmail"]),
      address: _asString(data["address"]),
      actCurrency: _asString(data["actCurrency"]),
      ccySymbol: _asString(data["ccySymbol"]),
      actCreditLimit: _asString(data["actCreditLimit"]),
      curBalance: _asString(data["curBalance"]),
      avilBalance: _asString(data["avilBalance"]),
      actStatus: _asInt(data["actStatus"]),
      trnStatus: _asString(data["trnStatus"]),
      records: data["records"] == null
          ? const []
          : List<StmtRecord>.from(
        (data["records"] as List).map((x) => StmtRecord.fromMap(x)),
      ),
    );
  }

  static AccountStatementModel fromApiResponse(dynamic response) {
    if (response is List) {
      if (response.isEmpty) throw "No account statement data found";
      return AccountStatementModel.fromMap(response.first);
    } else if (response is Map) {
      return AccountStatementModel.fromMap(response);
    }
    throw "Invalid response format";
  }

  Map<String, dynamic> toMap() => {
    "perID": perId,
    "perLock": perLock,
    "accNumber": accNumber,
    "accName": accName,
    "signatory": signatory,
    "perPhone": perPhone,
    "perEmail": perEmail,
    "address": address,
    "actCurrency": actCurrency,
    "ccySymbol": ccySymbol,
    "actCreditLimit": actCreditLimit,
    "curBalance": curBalance,
    "avilBalance": avilBalance,
    "actStatus": actStatus,
    "trnStatus": trnStatus,
    "records": records == null
        ? []
        : List<dynamic>.from(records!.map((x) => x.toMap())),
  };

  static Map<String, dynamic> _convertMap(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) {
      return json.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
      );
    }
    throw FormatException("Expected a Map but got ${json.runtimeType}");
  }
}

class StmtRecord {
  final int? sortOrder;
  final String? trnEntryDate;
  final String? trnReference;
  final String? trdNarration;
  final String? debit;
  final String? credit;
  final String? total;
  final String? status;

  StmtRecord({
    this.sortOrder,
    this.trnEntryDate,
    this.trnReference,
    this.trdNarration,
    this.debit,
    this.credit,
    this.total,
    this.status,
  });

  StmtRecord copyWith({
    int? sortOrder,
    String? trnEntryDate,
    String? trnReference,
    String? trdNarration,
    String? debit,
    String? credit,
    String? total,
    String? status,
  }) =>
      StmtRecord(
        sortOrder: sortOrder ?? this.sortOrder,
        trnEntryDate: trnEntryDate ?? this.trnEntryDate,
        trnReference: trnReference ?? this.trnReference,
        trdNarration: trdNarration ?? this.trdNarration,
        debit: debit ?? this.debit,
        credit: credit ?? this.credit,
        total: total ?? this.total,
        status: status ?? this.status,
      );

  factory StmtRecord.fromMap(dynamic json) {
    final Map<String, dynamic> data = AccountStatementModel._convertMap(json);

    return StmtRecord(
      sortOrder: _asInt(data["sort_order"]),
      trnEntryDate: _asString(data["trnEntryDate"]),
      trnReference: _asString(data["trnReference"]),
      trdNarration: _asString(data["trdNarration"]),
      debit: _asString(data["debit"]),
      credit: _asString(data["credit"]),
      total: _asString(data["total"]),
      status: _asString(data["status"]),
    );
  }

  Map<String, dynamic> toMap() => {
    "sort_order": sortOrder,
    "trnEntryDate": trnEntryDate,
    "trnReference": trnReference,
    "trdNarration": trdNarration,
    "debit": debit,
    "credit": credit,
    "total": total,
    "status": status,
  };
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

String? _asString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}