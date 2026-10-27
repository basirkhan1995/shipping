class BulkTransferRow {
  final int rowId;
  final int? accountNumber;
  final String? accountName;
  final String? currency;
  final double debit;
  final double credit;
  final String narration;

  const BulkTransferRow({
    required this.rowId,
    this.accountNumber,
    this.accountName,
    this.currency,
    this.debit = 0.0,
    this.credit = 0.0,
    this.narration = '',
  });

  BulkTransferRow copyWith({
    int? accountNumber,
    String? accountName,
    String? currency,
    double? debit,
    double? credit,
    String? narration,
    bool clearAccount = false,
  }) {
    return BulkTransferRow(
      rowId: rowId,
      accountNumber: clearAccount ? null : (accountNumber ?? this.accountNumber),
      accountName: clearAccount ? null : (accountName ?? this.accountName),
      currency: clearAccount ? null : (currency ?? this.currency),
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      narration: narration ?? this.narration,
    );
  }

  /// One row → one `records[]` entry in the bulk POST/PUT.
  Map<String, dynamic> toRecord() => {
    'account': accountNumber ?? 0,
    'ccy': currency ?? '',
    'debit': double.parse(debit.toStringAsFixed(2)),
    'credit': double.parse(credit.toStringAsFixed(2)),
    'narration': narration,
  };

  /// One `lines[]` entry from GET → one row.
  /// Server returns Dr/Cr per line; the form expects debit OR credit on
  /// each row — so map Dr → debit, Cr → credit.
  factory BulkTransferRow.fromServerLine(
      Map<String, dynamic> line, {
        int? rowId,
      }) {
    final drCr = (line['trdDrCr'] ?? '').toString();
    final amount = double.tryParse(line['trdAmount']?.toString() ?? '') ?? 0;
    final isDebit = drCr == 'Dr';
    return BulkTransferRow(
      rowId: rowId ?? DateTime.now().microsecondsSinceEpoch,
      accountNumber: int.tryParse(line['trdAccount']?.toString() ?? ''),
      accountName: null, // filled client-side from the account picker
      currency: line['trdCcy']?.toString(),
      debit: isDebit ? amount : 0,
      credit: isDebit ? 0 : amount,
      narration: (line['trdNarration'] ?? '').toString(),
    );
  }
}