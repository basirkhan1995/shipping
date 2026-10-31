// lib/features/fund_transfer/model/ft_model.dart
import 'package:equatable/equatable.dart';

/// One leg of a fund transfer (Dr or Cr side).
class FundTransferLeg extends Equatable {
  final int account;
  final String accountName;
  final String currency;
  final double amount;
  final String drCr;
  final String narration;

  /// 8 = stakeholder (own currency). Anything else = GL.
  final int accCategory;

  const FundTransferLeg({
    required this.account,
    required this.accountName,
    required this.currency,
    required this.amount,
    required this.drCr,
    this.narration = '',
    this.accCategory = 8,
  });

  factory FundTransferLeg.fromMap(Map<String, dynamic> j) => FundTransferLeg(
    account: _toInt(j['trdAccount']),
    accountName: '${j['accName'] ?? ''}',
    currency: '${j['trdCcy'] ?? ''}',
    amount: _toDouble(j['trdAmount']),
    drCr: '${j['trdDrCr'] ?? ''}',
    narration: '${j['trdNarration'] ?? ''}',
    accCategory: _toInt(j['accCategory'] ?? 8),
  );

  bool get isGl => accCategory != 8;
  bool get isStakeholder => accCategory == 8;

  @override
  List<Object?> get props => [
    account,
    accountName,
    currency,
    amount,
    drCr,
    narration,
    accCategory,
  ];
}

/// A row in the fund-transfer list.
class FundTransferListItem extends Equatable {
  final String reference;
  final int status;
  final String stateText;
  final String maker;
  final String? checker;
  final DateTime entryDate;
  final int fromAccount;
  final String fromAccountName;
  final String fromCcy;
  final int toAccount;
  final String toAccountName;
  final String toCcy;
  final double amount;
  final String narration;

  const FundTransferListItem({
    required this.reference,
    required this.status,
    required this.stateText,
    required this.maker,
    this.checker,
    required this.entryDate,
    required this.fromAccount,
    required this.fromAccountName,
    required this.fromCcy,
    required this.toAccount,
    required this.toAccountName,
    required this.toCcy,
    required this.amount,
    required this.narration,
  });

  factory FundTransferListItem.fromMap(Map<String, dynamic> j) =>
      FundTransferListItem(
        reference: '${j['reference'] ?? j['trnReference'] ?? ''}',
        status: _toInt(j['status'] ?? j['trnStatus']),
        stateText: '${j['stateText'] ?? j['trnStateText'] ?? ''}',
        maker: '${j['maker'] ?? ''}',
        checker: (j['checker'] == null || '${j['checker']}'.isEmpty)
            ? null
            : '${j['checker']}',
        entryDate: _toDate(j['entryDate'] ?? j['trnEntryDate']),
        fromAccount: _toInt(j['fromAccount']),
        fromAccountName: '${j['fromAccountName'] ?? ''}',
        fromCcy: '${j['fromCcy'] ?? ''}',
        toAccount: _toInt(j['toAccount']),
        toAccountName: '${j['toAccountName'] ?? ''}',
        toCcy: '${j['toCcy'] ?? ''}',
        amount: _toDouble(j['amount']),
        narration: '${j['narration'] ?? ''}',
      );

  bool get isPending    => stateText == 'Pending';
  bool get isAuthorized => stateText == 'Authorized';
  bool get isReversed   => stateText == 'Reversed';
  bool get isDeleted    => stateText == 'Deleted';

  @override
  List<Object?> get props => [
    reference,
    status,
    stateText,
    maker,
    checker,
    entryDate,
    fromAccount,
    fromAccountName,
    fromCcy,
    toAccount,
    toAccountName,
    toCcy,
    amount,
    narration,
  ];
}

/// Full single-record view (used by the edit form).
class FundTransferDetail extends Equatable {
  final String reference;
  final int status;
  final String stateText;
  final String maker;
  final String? checker;
  final DateTime entryDate;
  final List<FundTransferLeg> debit;
  final List<FundTransferLeg> credit;
  final String narration;

  const FundTransferDetail({
    required this.reference,
    required this.status,
    required this.stateText,
    required this.maker,
    this.checker,
    required this.entryDate,
    required this.debit,
    required this.credit,
    required this.narration,
  });

  factory FundTransferDetail.fromMap(Map<String, dynamic> j) {
    final debitRaw =
    (j['debit'] as List? ?? const []).whereType<Map>().toList();
    final creditRaw =
    (j['credit'] as List? ?? const []).whereType<Map>().toList();

    final debit = debitRaw
        .map((m) => FundTransferLeg.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    final credit = creditRaw
        .map((m) => FundTransferLeg.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    String narration = '';
    if (debitRaw.isNotEmpty) {
      narration = '${debitRaw.first['trdNarration'] ?? ''}';
    } else if (creditRaw.isNotEmpty) {
      narration = '${creditRaw.first['trdNarration'] ?? ''}';
    }

    return FundTransferDetail(
      reference: '${j['trnReference'] ?? ''}',
      status: _toInt(j['trnStatus']),
      stateText: '${j['trnStateText'] ?? ''}',
      maker: '${j['maker'] ?? ''}',
      checker: (j['checker'] == null || '${j['checker']}'.isEmpty)
          ? null
          : '${j['checker']}',
      entryDate: _toDate(j['trnEntryDate']),
      debit: debit,
      credit: credit,
      narration: narration,
    );
  }

  bool get isPending => stateText == 'Pending';

  FundTransferLeg? get fromLeg => debit.isNotEmpty ? debit.first : null;
  FundTransferLeg? get toLeg => credit.isNotEmpty ? credit.first : null;

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
    narration,
  ];
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