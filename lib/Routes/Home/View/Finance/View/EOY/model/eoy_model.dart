/// ================= P&L Models =================
class PAndLModel {
  final int? trdBranch;
  final int? accountNumber;
  final String? accountName;
  final String? currency;
  final String? category;
  final String? debit;
  final String? credit;

  PAndLModel({
    this.trdBranch,
    this.accountNumber,
    this.accountName,
    this.currency,
    this.category,
    this.debit,
    this.credit,
  });

  /// ================= Computed values =================
  double get debitAmount => double.tryParse(debit ?? "0") ?? 0;
  double get creditAmount => double.tryParse(credit ?? "0") ?? 0;
  bool get isIncome => (category ?? "").toLowerCase() == "income";
  bool get isExpense => (category ?? "").toLowerCase() == "expense";

  /// ================= Map / JSON =================
  factory PAndLModel.fromMap(Map<String, dynamic> json) {
    return PAndLModel(
      trdBranch: json["trdBranch"] as int?,
      accountNumber: json["account_number"] as int?,
      accountName: json["account_name"] as String?,
      currency: json["currency"] as String?,
      category: json["category"] as String?,
      debit: json["debit"]?.toString(),
      credit: json["credit"]?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "trdBranch": trdBranch,
      "account_number": accountNumber,
      "account_name": accountName,
      "currency": currency,
      "category": category,
      "debit": debit,
      "credit": credit,
    };
  }
}

/// ================= P&L Summary (multi-currency) =================
class PAndLSummary {
  final Map<String, double> incomeByCurrency;
  final Map<String, double> expenseByCurrency;

  PAndLSummary({
    required this.incomeByCurrency,
    required this.expenseByCurrency,
  });

  Map<String, double> get retainedByCurrency {
    final retained = <String, double>{};
    final allCurrencies = {...incomeByCurrency.keys, ...expenseByCurrency.keys};
    for (final cur in allCurrencies) {
      final income = incomeByCurrency[cur] ?? 0;
      final expense = expenseByCurrency[cur] ?? 0;
      retained[cur] = income - expense;
    }
    return retained;
  }
}

/// ================= Extension to compute summary =================
extension PAndLListExtension on List<PAndLModel> {
  PAndLSummary get summary {
    final incomeByCurrency = <String, double>{};
    final expenseByCurrency = <String, double>{};

    for (final item in this) {
      final cur = item.currency ?? "N/A";
      if (item.isIncome) {
        incomeByCurrency[cur] = (incomeByCurrency[cur] ?? 0) + item.creditAmount;
      } else if (item.isExpense) {
        expenseByCurrency[cur] = (expenseByCurrency[cur] ?? 0) + item.debitAmount;
      }
    }

    return PAndLSummary(
      incomeByCurrency: incomeByCurrency,
      expenseByCurrency: expenseByCurrency,
    );
  }
}
