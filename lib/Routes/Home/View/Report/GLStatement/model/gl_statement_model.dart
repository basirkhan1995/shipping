// =======================
// Helper (local to GL model)
// =======================

Map<String, dynamic> _glConvertMap(dynamic json) {
  if (json is Map<String, dynamic>) {
    return json;
  } else if (json is Map<dynamic, dynamic>) {
    return json.map<String, dynamic>(
          (key, value) => MapEntry(key.toString(), value),
    );
  } else {
    throw FormatException("Expected Map but got ${json.runtimeType}");
  }
}

// =======================
// GL Record Model
// =======================

class GlRecord {
  final int? sortOrder;
  final String? trnEntryDate;
  final String? trnReference;
  final String? trdNarration;
  final String? debit;
  final String? credit;
  final String? total;
  final String? status;

  GlRecord({
    this.sortOrder,
    this.trnEntryDate,
    this.trnReference,
    this.trdNarration,
    this.debit,
    this.credit,
    this.total,
    this.status,
  });

  GlRecord copyWith({
    int? sortOrder,
    String? trnEntryDate,
    String? trnReference,
    String? trdNarration,
    String? debit,
    String? credit,
    String? total,
    String? status,
  }) =>
      GlRecord(
        sortOrder: sortOrder ?? this.sortOrder,
        trnEntryDate: trnEntryDate ?? this.trnEntryDate,
        trnReference: trnReference ?? this.trnReference,
        trdNarration: trdNarration ?? this.trdNarration,
        debit: debit ?? this.debit,
        credit: credit ?? this.credit,
        total: total ?? this.total,
        status: status ?? this.status,
      );

  factory GlRecord.fromMap(dynamic json) {
    final data = _glConvertMap(json);

    return GlRecord(
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

// =======================
// GL Statement Model
// =======================

class GlStatementModel {
  final int? accNumber;
  final String? accName;
  final String? ccyCode;
  final String? ccySymbol;
  final String? ccyName;
  final int? brcId;
  final String? brcName;
  final String? glCategory;
  final String? curBalance;
  final String? avilBalance;
  final List<GlRecord>? records;

  GlStatementModel({
    this.accNumber,
    this.accName,
    this.ccyCode,
    this.ccySymbol,
    this.ccyName,
    this.brcId,
    this.brcName,
    this.glCategory,
    this.curBalance,
    this.avilBalance,
    this.records,
  });

  GlStatementModel copyWith({
    int? accNumber,
    String? accName,
    String? ccyCode,
    String? ccySymbol,
    String? ccyName,
    int? brcId,
    String? brcName,
    String? glCategory,
    String? curBalance,
    String? avilBalance,
    List<GlRecord>? records,
  }) =>
      GlStatementModel(
        accNumber: accNumber ?? this.accNumber,
        accName: accName ?? this.accName,
        ccyCode: ccyCode ?? this.ccyCode,
        ccySymbol: ccySymbol ?? this.ccySymbol,
        ccyName: ccyName ?? this.ccyName,
        brcId: brcId ?? this.brcId,
        brcName: brcName ?? this.brcName,
        glCategory: glCategory ?? this.glCategory,
        curBalance: curBalance ?? this.curBalance,
        avilBalance: avilBalance ?? this.avilBalance,
        records: records ?? this.records,
      );

  factory GlStatementModel.fromMap(dynamic json) {
    final data = _glConvertMap(json);

    return GlStatementModel(
      accNumber: data["accNumber"] as int?,
      accName: data["accName"] as String?,
      ccyCode: data["ccyCode"] as String?,
      ccySymbol: data["ccySymbol"] as String?,
      ccyName: data["ccyName"] as String?,
      brcId: data["brcID"] as int?,
      brcName: data["brcName"] as String?,
      glCategory: data["GL_Category"] as String?,
      curBalance: data["curBalance"] as String?,
      avilBalance: data["avilBalance"] as String?,
      records: data["records"] == null
          ? []
          : List<GlRecord>.from(
        (data["records"] as List).map((x) => GlRecord.fromMap(x)),
      ),
    );
  }

  /// API may return List or Map
  static GlStatementModel fromApiResponse(dynamic response) {
    if (response is List) {
      if (response.isEmpty) {
        throw "No GL statement data found";
      }
      return GlStatementModel.fromMap(response.first);
    } else if (response is Map) {
      return GlStatementModel.fromMap(response);
    } else {
      throw "Invalid response format";
    }
  }

  Map<String, dynamic> toMap() => {
    "accNumber": accNumber,
    "accName": accName,
    "ccyCode": ccyCode,
    "ccySymbol": ccySymbol,
    "ccyName": ccyName,
    "brcID": brcId,
    "brcName": brcName,
    "GL_Category": glCategory,
    "curBalance": curBalance,
    "avilBalance": avilBalance,
    "records":
    records == null ? [] : records!.map((e) => e.toMap()).toList(),
  };
}
