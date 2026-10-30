class TrialBalanceModel {
  final String accountNumber;
  final String accountName;
  final String currency;
  final String category;

  /// Raw balances from API
  final double actualBalance;
  final double debit;
  final double credit;

  TrialBalanceModel({
    required this.accountNumber,
    required this.accountName,
    required this.currency,
    required this.category,
    required this.actualBalance,
    required this.debit,
    required this.credit,
  });

  /// ---------- FACTORY ----------
  factory TrialBalanceModel.fromMap(Map<String, dynamic> json) {
    double parse(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return TrialBalanceModel(
      accountNumber: json['account_number']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'USD',
      category: json['category']?.toString() ?? '',
      actualBalance: parse(json['actual_balance']),
      debit: parse(json['debit']),
      credit: parse(json['credit']),
    );
  }

  /// ---------- MAP ----------
  Map<String, dynamic> toMap() => {
    'account_number': accountNumber,
    'account_name': accountName,
    'currency': currency,
    'category': category,
    'actual_balance': actualBalance.toStringAsFixed(4),
    'debit': debit.toStringAsFixed(4),
    'credit': credit.toStringAsFixed(4),
  };

  /// ---------- UI HELPERS ----------

  bool get hasDebit => debit > 0;
  bool get hasCredit => credit > 0;

  double get debitAmount => hasDebit ? debit : 0.0;
  double get creditAmount => hasCredit ? credit : 0.0;

  /// For table display (Dr / Cr column)
  double get displayDebit => debit > 0 ? debit : 0.0;
  double get displayCredit => credit > 0 ? credit : 0.0;

  /// Absolute balance (useful for PDFs)
  double get absBalance => actualBalance.abs();
}

class TrialBalanceHelper {
  static double getTotalDebit(List<TrialBalanceModel> data) {
    return data.fold(0.0, (sum, e) => sum + e.debit);
  }

  static double getTotalCredit(List<TrialBalanceModel> data) {
    return data.fold(0.0, (sum, e) => sum + e.credit);
  }

  static double getDifference(List<TrialBalanceModel> data) {
    return getTotalDebit(data) - getTotalCredit(data);
  }

  static bool isBalanced(List<TrialBalanceModel> data) {
    return getDifference(data).abs() < 0.01;
  }

  static double getDifferencePercentage(List<TrialBalanceModel> data) {
    final totalDebit = getTotalDebit(data);
    if (totalDebit == 0) return 0.0;
    return (getDifference(data).abs() / totalDebit) * 100;
  }

  /// Currency-wise totals (VERY useful for your app)
  static Map<String, double> totalDebitByCurrency(
      List<TrialBalanceModel> data) {
    final map = <String, double>{};
    for (final e in data) {
      map[e.currency] = (map[e.currency] ?? 0) + e.debit;
    }
    return map;
  }

  static Map<String, double> totalCreditByCurrency(
      List<TrialBalanceModel> data) {
    final map = <String, double>{};
    for (final e in data) {
      map[e.currency] = (map[e.currency] ?? 0) + e.credit;
    }
    return map;
  }

  /// Formatting (safe for UI & PDF)
  static String formatAmount(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }
}
