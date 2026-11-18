class PnLPoint {
  final DateTime day;
  final double revenue;
  final double expense;
  final double profit;

  const PnLPoint({
    required this.day,
    required this.revenue,
    required this.expense,
    required this.profit,
  });

  factory PnLPoint.fromMap(Map<String, dynamic> json) => PnLPoint(
    day: DateTime.parse(json["day"] as String),
    revenue: (json["revenue"] as num).toDouble(),
    expense: (json["expense"] as num).toDouble(),
    profit: (json["profit"] as num).toDouble(),
  );
}

class PnLChartModel {
  final String currency;
  final String? from;
  final String? to;
  final List<PnLPoint> series;
  final double totalRevenue;
  final double totalExpense;
  final double totalProfit;

  const PnLChartModel({
    required this.currency,
    required this.from,
    required this.to,
    required this.series,
    required this.totalRevenue,
    required this.totalExpense,
    required this.totalProfit,
  });

  factory PnLChartModel.fromMap(Map<String, dynamic> json) {
    final totals = json["totals"] as Map<String, dynamic>? ?? const {};
    return PnLChartModel(
      currency: json["currency"] as String? ?? 'USD',
      from: json["from"] as String?,
      to: json["to"] as String?,
      series: (json["series"] as List? ?? const [])
          .whereType<Map>()
          .map((e) => PnLPoint.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      totalRevenue: (totals["revenue"] as num?)?.toDouble() ?? 0,
      totalExpense: (totals["expense"] as num?)?.toDouble() ?? 0,
      totalProfit: (totals["profit"] as num?)?.toDouble() ?? 0,
    );
  }
}