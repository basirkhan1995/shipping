
class AccountStatementModel {
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

  AccountStatementModel copyWith({
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

  // Updated factory method to handle Map<dynamic, dynamic>
  factory AccountStatementModel.fromMap(dynamic json) {
    // Convert Map<dynamic, dynamic> to Map<String, dynamic>
    final Map<String, dynamic> data = _convertMap(json);

    return AccountStatementModel(
      accNumber: data["accNumber"] as int?,
      accName: data["accName"] as String?,
      signatory: data["signatory"] as String?,
      perPhone: data["perPhone"] as String?,
      perEmail: data["perEmail"] as String?,
      address: data["address"] as String?,
      actCurrency: data["actCurrency"] as String?,
      ccySymbol: data["ccySymbol"] as String?,
      actCreditLimit: data["actCreditLimit"] as String?,
      curBalance: data["curBalance"] as String?,
      avilBalance: data["avilBalance"] as String?,
      actStatus: data["actStatus"] as int?,
      records: data["records"] == null ? [] : List<StmtRecord>.from((data["records"] as List).map((x) => StmtRecord.fromMap(x))),
    );
  }

  // Static method to handle API response (List with one item)
  static AccountStatementModel fromApiResponse(dynamic response) {
    if (response is List) {
      if (response.isEmpty) {
        throw "No account statement data found";
      }
      return AccountStatementModel.fromMap(response.first);
    } else if (response is Map) {
      return AccountStatementModel.fromMap(response);
    } else {
      throw "Invalid response format";
    }
  }

  Map<String, dynamic> toMap() => {
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
    "records": records == null ? [] : List<dynamic>.from(records!.map((x) => x.toMap())),
  };

  // Helper method to convert Map<dynamic, dynamic> to Map<String, dynamic>
  static Map<String, dynamic> _convertMap(dynamic json) {
    if (json is Map<String, dynamic>) {
      return json;
    } else if (json is Map<dynamic, dynamic>) {
      return json.map<String, dynamic>((key, value) => MapEntry(key.toString(), value));
    } else {
      throw FormatException("Expected a Map but got ${json.runtimeType}");
    }
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
    }) => StmtRecord(
        sortOrder: sortOrder ?? this.sortOrder,
        trnEntryDate: trnEntryDate ?? this.trnEntryDate,
        trnReference: trnReference ?? this.trnReference,
        trdNarration: trdNarration ?? this.trdNarration,
        debit: debit ?? this.debit,
        credit: credit ?? this.credit,
        total: total ?? this.total,
        status: status ?? this.status,
      );

  // Updated factory method to handle Map<dynamic, dynamic>
  factory StmtRecord.fromMap(dynamic json) {
    final Map<String, dynamic> data = AccountStatementModel._convertMap(json);

    return StmtRecord(
      sortOrder: data["sort_order"] as int?,
      trnEntryDate: data["trnEntryDate"] as String?,
      trnReference: data["trnReference"] as String?,
      trdNarration: data["trdNarration"] as String?,
      debit: data["debit"] as String?,
      credit: data["credit"] as String?,
      total: data["total"] as String?,
      status: data["status"] as String?,
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
