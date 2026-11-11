class OrdersTxnRow {
  final int rowId;
  final int? accountNumber;
  final String? accountName;
  final String? currency;
  final double debit;
  final double credit;
  final String narration;

  const OrdersTxnRow({
    required this.rowId,
    this.accountNumber,
    this.accountName,
    this.currency,
    this.debit = 0.0,
    this.credit = 0.0,
    this.narration = '',
  });

  OrdersTxnRow copyWith({
    int? accountNumber,
    String? accountName,
    String? currency,
    double? debit,
    double? credit,
    String? narration,
    bool clearAccount = false,
  }) {
    return OrdersTxnRow(
      rowId: rowId,
      accountNumber: clearAccount ? null : (accountNumber ?? this.accountNumber),
      accountName: clearAccount ? null : (accountName ?? this.accountName),
      currency: clearAccount ? null : (currency ?? this.currency),
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      narration: narration ?? this.narration,
    );
  }

  /// One row → one `records[]` entry in the POST/PUT.
  Map<String, dynamic> toRecord() => {
    'account': accountNumber ?? 0,
    'ccy': currency ?? '',
    'debit': double.parse(debit.toStringAsFixed(2)),
    'credit': double.parse(credit.toStringAsFixed(2)),
    'narration': narration,
  };

  /// One `lines[]` entry from GET → one row.
  factory OrdersTxnRow.fromServerLine(
      Map<String, dynamic> line, {
        int? rowId,
      }) {
    final drCr = (line['trdDrCr'] ?? '').toString();
    final amount = double.tryParse(line['trdAmount']?.toString() ?? '') ?? 0;
    final isDebit = drCr == 'Dr';
    return OrdersTxnRow(
      rowId: rowId ?? DateTime.now().microsecondsSinceEpoch,
      accountNumber: int.tryParse(line['trdAccount']?.toString() ?? ''),
      accountName: null,
      currency: line['trdCcy']?.toString(),
      debit: isDebit ? amount : 0,
      credit: isDebit ? 0 : amount,
      narration: (line['trdNarration'] ?? '').toString(),
    );
  }
}