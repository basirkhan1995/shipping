class TransactionRow {
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

  const TransactionRow({
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

  factory TransactionRow.fromMap(Map<String, dynamic> m) {
    double d(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

    return TransactionRow(
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