class DashboardStatsModel {
  final DashboardCounts counts;
  final DashboardCash cash;
  final DashboardFinance finance;
  final String currency;

  DashboardStatsModel({
    required this.counts,
    required this.cash,
    required this.finance,
    required this.currency,
  });

  factory DashboardStatsModel.fromMap(Map<String, dynamic> json) {
    return DashboardStatsModel(
      counts: DashboardCounts.fromMap(json['counts'] ?? {}),
      cash: DashboardCash.fromMap(json['cash'] ?? {}),
      finance: DashboardFinance.fromMap(json['finance'] ?? {}),
      currency: json['currency']?.toString() ?? 'USD',
    );
  }
}

class DashboardCounts {
  final int accounts;
  final int stakeholders;
  final int users;
  final int employees;
  final int branches;

  DashboardCounts({
    required this.accounts,
    required this.stakeholders,
    required this.users,
    required this.employees,
    required this.branches,
  });

  factory DashboardCounts.fromMap(Map<String, dynamic> j) => DashboardCounts(
    accounts: _toInt(j['accounts']),
    stakeholders: _toInt(j['stakeholders']),
    users: _toInt(j['users']),
    employees: _toInt(j['employees']),
    branches: _toInt(j['branches']),
  );
}

class DashboardCash {
  final double inAmount;
  final double outAmount;
  final double net;

  DashboardCash({
    required this.inAmount,
    required this.outAmount,
    required this.net,
  });

  factory DashboardCash.fromMap(Map<String, dynamic> j) => DashboardCash(
    inAmount: _toDouble(j['in']),
    outAmount: _toDouble(j['out']),
    net: _toDouble(j['net']),
  );
}

class DashboardFinance {
  final double income;
  final double expense;
  final double profit;

  DashboardFinance({
    required this.income,
    required this.expense,
    required this.profit,
  });

  factory DashboardFinance.fromMap(Map<String, dynamic> j) => DashboardFinance(
    income: _toDouble(j['income']),
    expense: _toDouble(j['expense']),
    profit: _toDouble(j['profit']),
  );
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}