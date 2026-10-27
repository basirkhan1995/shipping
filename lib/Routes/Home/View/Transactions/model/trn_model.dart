class TransactionListItem {
  final String reference;
  final String typeCode;
  final String typeName;
  final int status;                 // 0 pending, 1 authorized
  final String statusText;          // 'Pending' | 'Authorized' | 'Reversed' | 'Deleted'
  final String maker;
  final String? checker;
  final String currencies;          // 'USD' or 'USD, EUR'
  final double totalDebit;
  final double totalCredit;
  final String? narration;
  final DateTime entryDate;

  const TransactionListItem({
    required this.reference,
    required this.typeCode,
    required this.typeName,
    required this.status,
    required this.statusText,
    required this.maker,
    required this.checker,
    required this.currencies,
    required this.totalDebit,
    required this.totalCredit,
    required this.narration,
    required this.entryDate,
  });

  factory TransactionListItem.fromMap(Map<String, dynamic> m) {
    double d(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

    return TransactionListItem(
      reference: m['reference']?.toString() ?? '',
      typeCode: m['typeCode']?.toString() ?? '',
      typeName: m['typeName']?.toString() ?? '',
      status: m['status'] is num ? (m['status'] as num).toInt() : 0,
      statusText: m['statusText']?.toString() ?? 'Pending',
      maker: m['maker']?.toString() ?? '',
      checker: m['checker']?.toString(),
      currencies: m['currencies']?.toString() ?? '',
      totalDebit: d(m['totalDebit']),
      totalCredit: d(m['totalCredit']),
      narration: m['narration']?.toString(),
      entryDate: DateTime.tryParse(m['entryDate']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String get amountFormatted {
    // Debit == Credit in balanced journals; show the debit side.
    final v = totalDebit == 0 ? totalCredit : totalDebit;
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]}';
  }
}

class TransactionDraft {
  /// ── Identity (server-side, read back into the detail view) ──
  final String? trnReference;
  final String? trnType;        // CHDP | CHWL | INCM | XPNS | GLDR | GLCR | ATAT | BULK | CRFX
  final String? trntName;
  final int? trdBranch;
  final String? maker;
  final String? checker;
  final int? trnStatus;
  final String? trnStateText;
  final DateTime? trnEntryDate;

  /// ── Common request fields ──
  final String? usrName;        // always required for writes
  final String? trdNarration;   // 'narration' on the wire
  final String? trdAmount;      // 'amount' on the wire (string)

  /// ── Cash family (CHDP, CHWL, INCM, XPNS, GLDR, GLCR) ──
  final int? trdAccount;        // 'account' on the wire
  final String? trdCcy;         // 'accCcy'  on the wire
  final String? accName;        // display only, never sent

  /// ── Account-to-account family (ATAT, BULK) ──
  final int? fromAccount;
  final int? toAccount;
  final String? fromAccCy;
  final String? toAccCcy;

  /// ── FX family (CRFX) ──
  final String? fromCcy;
  final String? toCcy;
  final String? fxRate;         // rate captured at submit time
  final String? fxAmount;       // amount in `toCcy` (optional)

  TransactionDraft({
    this.trnReference,
    this.trnType,
    this.trntName,
    this.maker,
    this.checker,
    this.trnStatus,
    this.trnStateText,
    this.trnEntryDate,
    this.trdBranch,

    this.usrName,
    this.trdNarration,
    this.trdAmount,

    this.trdAccount,
    this.trdCcy,
    this.accName,

    this.fromAccount,
    this.toAccount,
    this.fromAccCy,
    this.toAccCcy,

    this.fromCcy,
    this.toCcy,
    this.fxRate,
    this.fxAmount,
  });

  // ── copyWith — now covers ALL fields, not just read ones ──────
  TransactionDraft copyWith({
    String? trnReference,
    String? trnType,
    String? trntName,
    String? maker,
    String? checker,
    int? trnStatus,
    String? trnStateText,
    DateTime? trnEntryDate,
    int? trdBranch,
    String? usrName,
    String? trdNarration,
    String? trdAmount,
    int? trdAccount,
    String? trdCcy,
    String? accName,
    int? fromAccount,
    int? toAccount,
    String? fromAccCy,
    String? toAccCcy,
    String? fromCcy,
    String? toCcy,
    String? fxRate,
    String? fxAmount,
  }) =>
      TransactionDraft(
        trnReference: trnReference ?? this.trnReference,
        trnType: trnType ?? this.trnType,
        trntName: trntName ?? this.trntName,
        maker: maker ?? this.maker,
        checker: checker ?? this.checker,
        trnStatus: trnStatus ?? this.trnStatus,
        trnStateText: trnStateText ?? this.trnStateText,
        trnEntryDate: trnEntryDate ?? this.trnEntryDate,
        trdBranch: trdBranch ?? this.trdBranch,
        usrName: usrName ?? this.usrName,
        trdNarration: trdNarration ?? this.trdNarration,
        trdAmount: trdAmount ?? this.trdAmount,
        trdAccount: trdAccount ?? this.trdAccount,
        trdCcy: trdCcy ?? this.trdCcy,
        accName: accName ?? this.accName,
        fromAccount: fromAccount ?? this.fromAccount,
        toAccount: toAccount ?? this.toAccount,
        fromAccCy: fromAccCy ?? this.fromAccCy,
        toAccCcy: toAccCcy ?? this.toAccCcy,
        fromCcy: fromCcy ?? this.fromCcy,
        toCcy: toCcy ?? this.toCcy,
        fxRate: fxRate ?? this.fxRate,
        fxAmount: fxAmount ?? this.fxAmount,
      );

  factory TransactionDraft.fromMap(Map<String, dynamic> json) =>
      TransactionDraft(
        trnReference: json['trnReference']?.toString(),
        trnType: json['trnType']?.toString(),
        trntName: json['trntName']?.toString(),
        trdBranch: _i(json['trdBranch']),
        maker: json['maker']?.toString(),
        checker: json['checker']?.toString(),
        trnStatus: _i(json['trnStatus']),
        trnStateText: json['trnStateText']?.toString(),
        trnEntryDate: DateTime.tryParse(json['trnEntryDate']?.toString() ?? ''),

        usrName: json['usrName']?.toString(),
        trdNarration: json['trdNarration']?.toString(),
        trdAmount: json['trdAmount']?.toString(),

        trdAccount: _i(json['trdAccount']),
        trdCcy: json['trdCcy']?.toString(),
        accName: json['accName']?.toString(),

        fromAccount: _i(json['fromAccount']),
        toAccount: _i(json['toAccount']),
        fromAccCy: json['fromAccCcy']?.toString(),
        toAccCcy: json['toAccCcy']?.toString(),

        fromCcy: json['fromCcy']?.toString(),
        toCcy: json['toCcy']?.toString(),
        fxRate: json['fxRate']?.toString(),
        fxAmount: json['fxAmount']?.toString(),
      );

  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  // ── toMap — one payload per flow, no stray nulls ──────────────
  //
  // cashWD.php expects:           {trnType, usrName, account, accCcy, amount, narration}
  // fundTransfer.php expects:     {usrName, fromAccount, fromAccCcy, toAccount, toAccCcy, amount, narration}
  // crossCurrency.php expects:    {usrName, fromAccount, fromCcy, toAccount, toCcy, amount, rate, narration}
  //
  // We dispatch on `trnType` so the same draft works everywhere.
  Map<String, dynamic> toMap() {
    switch (trnType) {
    // ── Cash / GL family ────────────────────────────────────────
      case 'CHDP':
      case 'CHWL':
      case 'INCM':
      case 'XPNS':
      case 'GLDR':
      case 'GLCR':
        return {
          if (trnReference != null) 'reference': trnReference,
          'trnType': trnType,
          'usrName': usrName,
          'account': trdAccount,
          'accCcy': trdCcy,
          'amount': trdAmount,
          'narration': trdNarration,
        };

    // ── Account-to-account (single) ─────────────────────────────
      case 'ATAT':
        return {
          if (trnReference != null) 'reference': trnReference,
          'usrName': usrName,
          'fromAccount': fromAccount,
          'fromAccCcy': fromAccCy,
          'toAccount': toAccount,
          'toAccCcy': toAccCcy,
          'amount': trdAmount,
          'narration': trdNarration,
        };

    // ── FX (crossCurrency.php) ──────────────────────────────────
      case 'CRFX':
        return {
          if (trnReference != null) 'reference': trnReference,
          'usrName': usrName,
          'fromAccount': fromAccount,
          'fromCcy': fromCcy ?? fromAccCy,
          'toAccount': toAccount,
          'toCcy': toCcy ?? toAccCcy,
          'amount': trdAmount,
          'rate': fxRate,
          'narration': trdNarration,
        };

    // ── Bulk: caller passes the full `records` list separately;
    //    we only serialize the "envelope" here. ────────────────
      case 'BULK':
        return {
          'usrName': usrName,
          // `records` is supplied by the caller in `bulkTransfer(...)`
        };

    // ── Unknown — emit the common fields only; server will reject.
      default:
        return {
          if (trnReference != null) 'reference': trnReference,
          if (trnType != null) 'trnType': trnType,
          if (usrName != null) 'usrName': usrName,
          if (trdAmount != null) 'amount': trdAmount,
          if (trdNarration != null) 'narration': trdNarration,
        };
    }
  }

  /// Convenience for the bulk screen — same shape as `toMap()` for
  /// a single ATAT row, no envelope.
  Map<String, dynamic> toBulkRow() => {
    'fromAccount': fromAccount,
    'fromAccCcy': fromAccCy,
    'toAccount': toAccount,
    'toAccCcy': toAccCcy,
    'amount': trdAmount,
    'narration': trdNarration,
  };
}