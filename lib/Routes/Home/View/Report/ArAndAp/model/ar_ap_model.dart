// lib/Routes/Home/View/Report/ArApReport/model/ar_ap_report_model.dart

// ═════════════════════════════════════════════════════════════════
// Root response
// ═════════════════════════════════════════════════════════════════
class ArApReportModel {
  final bool success;
  final ArApFilters filters;
  final List<ArApAccount> receivables;
  final List<ArApAccount> payables;
  final ArApTotals totals;

  const ArApReportModel({
    required this.success,
    required this.filters,
    required this.receivables,
    required this.payables,
    required this.totals,
  });

  /// Entry-point used by the repository, matching the same
  /// `fromApiResponse(decodedData)` pattern as the other report models.
  factory ArApReportModel.fromApiResponse(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    return ArApReportModel(
      success: map['success'] == true,
      filters: ArApFilters.fromMap(
        Map<String, dynamic>.from(map['filters'] ?? const {}),
      ),
      receivables: _list(map['receivables'], ArApAccount.fromMap),
      payables: _list(map['payables'], ArApAccount.fromMap),
      totals: ArApTotals.fromMap(
        Map<String, dynamic>.from(map['totals'] ?? const {}),
      ),
    );
  }

  /// Convenience alias — same result as `fromApiResponse`.
  factory ArApReportModel.fromMap(Map<String, dynamic> map) =>
      ArApReportModel.fromApiResponse(map);

  static List<T> _list<T>(
      dynamic raw,
      T Function(Map<String, dynamic>) fromMap,
      ) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}

// ═════════════════════════════════════════════════════════════════
// Filters echoed back by the server
// ═════════════════════════════════════════════════════════════════
class ArApFilters {
  final String name;
  final String ccy;
  final String type; // '' | 'ar' | 'ap'
  final bool includeZero;

  const ArApFilters({
    required this.name,
    required this.ccy,
    required this.type,
    required this.includeZero,
  });

  factory ArApFilters.fromMap(Map<String, dynamic> map) => ArApFilters(
    name: (map['name'] ?? '').toString(),
    ccy: (map['ccy'] ?? '').toString(),
    type: (map['type'] ?? '').toString(),
    includeZero: map['include_zero'] == true,
  );

  ArApFilters copyWith({
    String? name,
    String? ccy,
    String? type,
    bool? includeZero,
  }) {
    return ArApFilters(
      name: name ?? this.name,
      ccy: ccy ?? this.ccy,
      type: type ?? this.type,
      includeZero: includeZero ?? this.includeZero,
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// One account row (used for both AR and AP)
// ═════════════════════════════════════════════════════════════════
class ArApAccount {
  final int perID;
  final String fullName;
  final String? perPhone;
  final int accNumber;
  final String accName;
  final String accCurrency;
  final int accStatus;
  final double accLimit;
  final double accBalance;

  const ArApAccount({
    required this.perID,
    required this.fullName,
    required this.perPhone,
    required this.accNumber,
    required this.accName,
    required this.accCurrency,
    required this.accStatus,
    required this.accLimit,
    required this.accBalance,
  });

  factory ArApAccount.fromMap(Map<String, dynamic> map) => ArApAccount(
    perID: _int(map['perID']),
    fullName: (map['fullName'] ?? '').toString(),
    perPhone: map['perPhone']?.toString(),
    accNumber: _int(map['accNumber']),
    accName: (map['accName'] ?? '').toString(),
    accCurrency: (map['accCurrency'] ?? '').toString(),
    accStatus: _int(map['accStatus']),
    accLimit: _double(map['accLimit']),
    accBalance: _double(map['accBalance']),
  );

  /// True when this row represents money owed TO us.
  bool get isReceivable => accBalance > 0;

  /// Positive value regardless of sign — handy for display.
  double get absBalance => accBalance.abs();

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _double(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }
}

// ═════════════════════════════════════════════════════════════════
// Totals per currency
// ═════════════════════════════════════════════════════════════════
class ArApTotals {
  /// currency -> amount
  final Map<String, double> receivables;
  final Map<String, double> payables;

  const ArApTotals({
    required this.receivables,
    required this.payables,
  });

  factory ArApTotals.fromMap(Map<String, dynamic> map) {
    return ArApTotals(
      receivables: _ccyMap(map['receivables']),
      payables: _ccyMap(map['payables']),
    );
  }

  static Map<String, double> _ccyMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map((k, v) {
      final d = v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;
      return MapEntry(k.toString(), d);
    });
  }

  /// Grand total across all currencies (naive — no FX conversion).
  double get totalReceivables =>
      receivables.values.fold(0.0, (a, b) => a + b);

  double get totalPayables =>
      payables.values.fold(0.0, (a, b) => a + b);
}