// lib/features/exchange/model/exchange_model.dart
import 'package:equatable/equatable.dart';

// ═════════════════════════════════════════════════════════════════
// One leg of an exchange (Dr or Cr side).
// ═════════════════════════════════════════════════════════════════
class ExchangeLeg extends Equatable {
  final int account;
  final String accountName;
  final String currency;
  final double amount;
  final String drCr;
  final String narration;
  final int branch;

  const ExchangeLeg({
    required this.account,
    required this.accountName,
    required this.currency,
    required this.amount,
    required this.drCr,
    this.narration = '',
    this.branch = 0,
  });

  factory ExchangeLeg.fromMap(Map<String, dynamic> j) => ExchangeLeg(
    account: _toInt(j['trdAccount']),
    accountName: '${j['accName'] ?? ''}',
    currency: '${j['trdCcy'] ?? ''}',
    amount: _toDouble(j['trdAmount']),
    drCr: '${j['trdDrCr'] ?? ''}',
    narration: '${j['trdNarration'] ?? ''}',
    branch: _toInt(j['trdBranch']),
  );

  bool get isDebit => drCr == 'Dr';
  bool get isCredit => drCr == 'Cr';

  Map<String, dynamic> toMap() => {
    'account': account,
    'ccy': currency,
    'amount': amount,
    'narration': narration,
  };

  @override
  List<Object?> get props =>
      [account, accountName, currency, amount, drCr, narration, branch];
}

// ═════════════════════════════════════════════════════════════════
// A row in the exchange (CRFX) list.
// ═════════════════════════════════════════════════════════════════
class ExchangeListItem extends Equatable {
  final String reference;
  final int status;
  final String stateText;
  final String maker;
  final String? checker;
  final DateTime entryDate;

  final int debitAccount;
  final String debitAccountName;
  final String debitCcy;
  final double debitAmount;

  final int creditAccount;
  final String creditAccountName;
  final String creditCcy;
  final double creditAmount;

  final String narration;

  const ExchangeListItem({
    required this.reference,
    required this.status,
    required this.stateText,
    required this.maker,
    this.checker,
    required this.entryDate,
    required this.debitAccount,
    required this.debitAccountName,
    required this.debitCcy,
    required this.debitAmount,
    required this.creditAccount,
    required this.creditAccountName,
    required this.creditCcy,
    required this.creditAmount,
    required this.narration,
  });

  factory ExchangeListItem.fromMap(Map<String, dynamic> j) => ExchangeListItem(
    reference: '${j['reference'] ?? j['trnReference'] ?? ''}',
    status: _toInt(j['status'] ?? j['trnStatus']),
    stateText: '${j['stateText'] ?? j['trnStateText'] ?? ''}',
    maker: '${j['maker'] ?? ''}',
    checker: (j['checker'] == null || '${j['checker']}'.isEmpty)
        ? null
        : '${j['checker']}',
    entryDate: _toDate(j['entryDate'] ?? j['trnEntryDate']),
    debitAccount: _toInt(j['debitAccount']),
    debitAccountName: '${j['debitAccountName'] ?? ''}',
    debitCcy: '${j['debitCcy'] ?? ''}',
    debitAmount: _toDouble(j['debitAmount']),
    creditAccount: _toInt(j['creditAccount']),
    creditAccountName: '${j['creditAccountName'] ?? ''}',
    creditCcy: '${j['creditCcy'] ?? ''}',
    creditAmount: _toDouble(j['creditAmount']),
    narration: '${j['narration'] ?? ''}',
  );

  bool get isPending => stateText == 'Pending';
  bool get isAuthorized => stateText == 'Authorized';
  bool get isReversed => stateText == 'Reversed';
  bool get isDeleted => stateText == 'Deleted';

  /// Amount the user pays, expressed in the debit currency.
  String get formattedDebit =>
      '${debitAmount.toStringAsFixed(2)} $debitCcy';

  /// Amount the user receives, expressed in the credit currency.
  String get formattedCredit =>
      '${creditAmount.toStringAsFixed(2)} $creditCcy';

  /// Effective rate: how many credit units per 1 debit unit.
  double? get rate {
    if (debitAmount <= 0) return null;
    return creditAmount / debitAmount;
  }

  @override
  List<Object?> get props => [
    reference,
    status,
    stateText,
    maker,
    checker,
    entryDate,
    debitAccount,
    debitAccountName,
    debitCcy,
    debitAmount,
    creditAccount,
    creditAccountName,
    creditCcy,
    creditAmount,
    narration,
  ];
}

// ═════════════════════════════════════════════════════════════════
// Full single-record view (edit form).
// ═════════════════════════════════════════════════════════════════
class ExchangeDetail extends Equatable {
  final String reference;
  final int status;
  final String stateText;
  final String maker;
  final String? checker;
  final DateTime entryDate;
  final ExchangeLeg? debit;
  final ExchangeLeg? credit;

  const ExchangeDetail({
    required this.reference,
    required this.status,
    required this.stateText,
    required this.maker,
    this.checker,
    required this.entryDate,
    this.debit,
    this.credit,
  });

  factory ExchangeDetail.fromMap(Map<String, dynamic> j) {
    final debitList = (j['debit'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => ExchangeLeg.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    final creditList = (j['credit'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => ExchangeLeg.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    return ExchangeDetail(
      reference: '${j['trnReference'] ?? ''}',
      status: _toInt(j['trnStatus']),
      stateText: '${j['trnStateText'] ?? ''}',
      maker: '${j['maker'] ?? ''}',
      checker: (j['checker'] == null || '${j['checker']}'.isEmpty)
          ? null
          : '${j['checker']}',
      entryDate: _toDate(j['trnEntryDate']),
      debit: debitList.isEmpty ? null : debitList.first,
      credit: creditList.isEmpty ? null : creditList.first,
    );
  }

  bool get isPending => stateText == 'Pending';

  /// Effective rate: how many credit units per 1 debit unit.
  double? get rate {
    if (debit == null || credit == null || debit!.amount <= 0) return null;
    return credit!.amount / debit!.amount;
  }

  @override
  List<Object?> get props => [
    reference,
    status,
    stateText,
    maker,
    checker,
    entryDate,
    debit,
    credit,
  ];
}

// ═════════════════════════════════════════════════════════════════
// Request builders (POST / PUT)
// ═════════════════════════════════════════════════════════════════

/// The two legs, exactly as `crossCurrency.php` expects them for add.
class ExchangeDraft {
  final String usrName;
  final ExchangeLeg debit;
  final ExchangeLeg credit;

  const ExchangeDraft({
    required this.usrName,
    required this.debit,
    required this.credit,
  });

  /// `records` array for POST `/journal/crossCurrency.php`.
  List<Map<String, dynamic>> toRecords() => [
    {
      'account': debit.account,
      'ccy': debit.currency,
      'debit': debit.amount,
      'credit': 0,
      'narration': debit.narration,
    },
    {
      'account': credit.account,
      'ccy': credit.currency,
      'debit': 0,
      'credit': credit.amount,
      'narration': credit.narration,
    },
  ];
}

/// Edit payload (PUT).
class ExchangeEditDraft {
  final String reference;
  final String usrName;
  final ExchangeLeg debit;
  final ExchangeLeg credit;

  const ExchangeEditDraft({
    required this.reference,
    required this.usrName,
    required this.debit,
    required this.credit,
  });

  Map<String, dynamic> toMap() => {
    'reference': reference,
    'usrName': usrName,
    'debit': {
      'account': debit.account,
      'ccy': debit.currency,
      'amount': debit.amount,
      'narration': debit.narration,
    },
    'credit': {
      'account': credit.account,
      'ccy': credit.currency,
      'amount': credit.amount,
      'narration': credit.narration,
    },
  };
}

// ── tiny parsers ─────────────────────────────────────────────
int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double _toDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

DateTime _toDate(dynamic v) =>
    DateTime.tryParse('${v ?? ''}')?.toLocal() ?? DateTime.now();