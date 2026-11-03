import 'package:equatable/equatable.dart';

// ═════════════════════════════════════════════════════════════════
// ROOT
// ═════════════════════════════════════════════════════════════════

class CashTxnDetail extends Equatable {
  final String? msg;
  final String? reference;
  final String? type;
  final int? status;
  final String? stateText;

  // Audit — the API sends *both* id and display name
  final int? makerId;
  final String? makerName;
  final int? checkerId;
  final String? checkerName;

  final DateTime? entryDate;
  final List<CashTxnLine> lines;

  const CashTxnDetail({
    this.msg,
    this.reference,
    this.type,
    this.status,
    this.stateText,
    this.makerId,
    this.makerName,
    this.checkerId,
    this.checkerName,
    this.entryDate,
    this.lines = const [],
  });

  bool get isSuccess => (msg ?? '').toLowerCase() == 'success';
  bool get isPending    => stateText == 'Pending';
  bool get isAuthorized => stateText == 'Authorized';
  bool get isReversed   => stateText == 'Reversed';
  bool get isDeleted    => stateText == 'Deleted';

  /// The subject leg = the non-GL leg. The contra side is always
  /// the cash/bank GL (10101010).
  CashTxnLine? get subjectLine {
    for (final l in lines) {
      if (l.trdAccount != CashTxnLine.cashGL) return l;
    }
    return lines.isEmpty ? null : lines.first;
  }

  CashTxnLine? get contraLine {
    for (final l in lines) {
      if (l.trdAccount == CashTxnLine.cashGL) return l;
    }
    return null;
  }

  /// Quick totals for the voucher footer.
  double get totalDebit  => lines
      .where((l) => l.isDebit)
      .fold(0, (s, l) => s + (l.amountValue ?? 0));
  double get totalCredit => lines
      .where((l) => l.isCredit)
      .fold(0, (s, l) => s + (l.amountValue ?? 0));

  factory CashTxnDetail.fromJson(Map<String, dynamic> j) {
    return CashTxnDetail(
      msg:       _str(j['msg']),
      reference: _str(j['reference']),
      type:      _str(j['type']),
      status:    _int(j['status']),
      stateText: _str(j['stateText']),
      makerId:   _int(j['maker']),
      makerName: _str(j['makerName']),
      checkerId: _int(j['checker']),
      checkerName: _str(j['checkerName']),
      entryDate: _date(j['entryDate']),
      lines: (j['lines'] as List?)
          ?.whereType<Map>()
          .map((m) => CashTxnLine.fromJson(
        Map<String, dynamic>.from(m),
      ))
          .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
    msg, reference, type, status, stateText,
    makerId, makerName, checkerId, checkerName,
    entryDate, lines,
  ];
}

// ═════════════════════════════════════════════════════════════════
// LINE
// ═════════════════════════════════════════════════════════════════

class CashTxnLine extends Equatable {
  /// GL account used as the cash/bank contra side on every cash txn.
  static const int cashGL = 10101010;

  final String? ccy;
  final int? branch;
  final int? trdAccount;
  final String? drCr;        // "Dr" / "Cr"
  final String? amount;      // raw string "510.0000" — keep for display
  final String? narration;
  final DateTime? entryDate;

  const CashTxnLine({
    this.ccy,
    this.branch,
    this.trdAccount,
    this.drCr,
    this.amount,
    this.narration,
    this.entryDate,
  });

  bool get isDebit  => (drCr ?? '').toLowerCase() == 'dr';
  bool get isCredit => (drCr ?? '').toLowerCase() == 'cr';

  /// Numeric value for math / totals.
  double? get amountValue {
    final a = amount;
    if (a == null || a.isEmpty) return null;
    return double.tryParse(a.replaceAll(',', ''));
  }

  /// Human-friendly amount for the voucher — trims trailing zeros.
  String get amountDisplay {
    final v = amountValue;
    if (v == null) return amount ?? '0';
    // 510.0000 -> "510.00"
    return v.toStringAsFixed(2);
  }

  factory CashTxnLine.fromJson(Map<String, dynamic> j) {
    return CashTxnLine(
      ccy:        _str(j['trdCcy']),
      branch:     _int(j['trdBranch']),
      trdAccount: _int(j['trdAccount']),
      drCr:       _str(j['trdDrCr']),
      amount:     _str(j['trdAmount']),
      narration:  _str(j['trdNarration']),
      entryDate:  _date(j['trdEntryDate']),
    );
  }

  @override
  List<Object?> get props =>
      [ccy, branch, trdAccount, drCr, amount, narration, entryDate];
}

// ═════════════════════════════════════════════════════════════════
// SAFE COERCERS — tolerate numeric strings, nulls, timestamps
// ═════════════════════════════════════════════════════════════════

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty || s == 'null' ? null : s;
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
  if (s.isEmpty || s == 'null') return null;
  // SQL Server: "2026-11-03 06:33:31" or "...31.000"
  return DateTime.tryParse(s) ??
      DateTime.tryParse(s.replaceFirst(' ', 'T'));
}