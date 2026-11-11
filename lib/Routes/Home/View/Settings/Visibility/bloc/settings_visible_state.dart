part of 'settings_visible_bloc.dart';

enum DateType {
  hijriShamsi,
  gregorian,
}

class SettingsVisibilityState extends Equatable {
  // ── Existing flags (unchanged) ─────────────────────────────
  final bool shipping;
  final bool moneyTransfer;
  final bool stock;
  final bool attendance;
  final bool exchangeRate;
  final bool currencyRates;

  /// Show / hide the Terms & Conditions block on the invoice.
  /// (Unchanged — still the toggle.)
  final bool termsAndConditions;

  /// Optional user-edited terms text.
  /// When null/empty, the translated defaults are shown instead.
  /// Completely independent from [termsAndConditions].
  final String? customTermsAndConditions;

  final bool recentTransactions;
  final DateType dateType;
  final String dateFormat;
  final bool isDateExpiry;
  final bool quickAccess;
  final bool profitAndLoss;
  final bool showHideLogo;
  final bool statsCount;
  final bool todayTotalTxnChart;
  final bool transport;
  final bool orders;
  final bool benefit;
  final bool isWholeSale;

  const SettingsVisibilityState({
    this.stock = false,
    this.moneyTransfer = false,
    this.shipping = false,
    this.attendance = false,
    this.benefit = true,
    this.exchangeRate = true,
    this.isDateExpiry = false,
    this.currencyRates = false,
    this.termsAndConditions = true,
    this.customTermsAndConditions,          // null → default
    this.recentTransactions = false,
    this.quickAccess = true,
    this.dateType = DateType.gregorian,
    this.dateFormat = 'yyyy-MM-dd',
    this.profitAndLoss = true,
    this.showHideLogo = true,
    this.statsCount = true,
    this.todayTotalTxnChart = true,
    this.transport = true,
    this.orders = true,
    this.isWholeSale = false,
  });

  factory SettingsVisibilityState.fromMap(Map<String, dynamic> map) {
    return SettingsVisibilityState(
      stock: map['Purchase'] ?? false,
      moneyTransfer: map['moneyTransfer'] ?? false,
      shipping: map['shipping'] ?? false,
      benefit: map['benefit'] ?? true,
      attendance: map['attendance'] ?? false,
      exchangeRate: map['exchangeRate'] ?? true,
      currencyRates: map['currencyRates'] ?? false,
      termsAndConditions: map['termsAndConditions'] ?? true,
      customTermsAndConditions: (map['customTermsAndConditions'] as String?)
          ?.trim()
          .isEmpty == true
          ? null
          : (map['customTermsAndConditions'] as String?)?.trim(),
      isDateExpiry: map['isDateExpiry'] ?? false,
      quickAccess: map['quickAccess'] ?? true,
      recentTransactions: map['recentTransactions'] ?? false,
      dateType: _dateTypeFromString(map['dateType'] ?? 'gregorian'),
      dateFormat: map['dateFormat'] ?? 'yyyy-MM-dd',
      profitAndLoss: map['profitAndLoss'] ?? true,
      statsCount: map['statsCount'] ?? true,
      showHideLogo: map['showHideLogo'] ?? true,
      todayTotalTxnChart: map['todayTotalTxnChart'] ?? true,
      transport: map['transport'] ?? true,
      orders: map['orders'] ?? true,
      isWholeSale: map['isWholeSale'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Purchase': stock,
      'moneyTransfer': moneyTransfer,
      'shipping': shipping,
      'attendance': attendance,
      'exchangeRate': exchangeRate,
      'benefit': benefit,
      'currencyRates': currencyRates,
      'termsAndConditions': termsAndConditions,
      'customTermsAndConditions': customTermsAndConditions,
      'dateType': dateType.name,
      'dateFormat': dateFormat,
      'isDateExpiry': isDateExpiry,
      'quickAccess': quickAccess,
      'recentTransactions': recentTransactions,
      'profitAndLoss': profitAndLoss,
      'statsCount': statsCount,
      'showHideLogo': showHideLogo,
      'todayTotalTxnChart': todayTotalTxnChart,
      'transport': transport,
      'orders': orders,
      'isWholeSale': isWholeSale,
    };
  }

  static DateType _dateTypeFromString(String value) {
    return DateType.values.firstWhere(
          (e) => e.name == value,
      orElse: () => DateType.gregorian,
    );
  }

  /// Convenience helper — returns the text to show on the invoice.
  ///
  /// • If [customTermsAndConditions] is set and non-empty → returns it.
  /// • Otherwise returns `null`, signalling the caller to fall back to
  ///   the translated defaults (`termsAndCondition1/2/3`).
  String? get effectiveTermsText {
    final t = customTermsAndConditions?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  /// Explicit-copy helper. Pass [clearCustomTerms] = true to reset
  /// the custom text back to `null` (revert to defaults).
  SettingsVisibilityState copyWith({
    bool? shipping,
    bool? moneyTransfer,
    bool? stock,
    bool? attendance,
    bool? exchangeRate,
    bool? currencyRates,
    bool? termsAndConditions,
    String? customTermsAndConditions,
    bool clearCustomTerms = false,
    bool? recentTransactions,
    DateType? dateType,
    String? dateFormat,
    bool? isDateExpiry,
    bool? quickAccess,
    bool? profitAndLoss,
    bool? showHideLogo,
    bool? statsCount,
    bool? todayTotalTxnChart,
    bool? transport,
    bool? orders,
    bool? benefit,
    bool? isWholeSale,
  }) {
    return SettingsVisibilityState(
      shipping: shipping ?? this.shipping,
      moneyTransfer: moneyTransfer ?? this.moneyTransfer,
      stock: stock ?? this.stock,
      attendance: attendance ?? this.attendance,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      currencyRates: currencyRates ?? this.currencyRates,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      customTermsAndConditions: clearCustomTerms
          ? null
          : (customTermsAndConditions ?? this.customTermsAndConditions),
      recentTransactions: recentTransactions ?? this.recentTransactions,
      dateType: dateType ?? this.dateType,
      dateFormat: dateFormat ?? this.dateFormat,
      isDateExpiry: isDateExpiry ?? this.isDateExpiry,
      quickAccess: quickAccess ?? this.quickAccess,
      profitAndLoss: profitAndLoss ?? this.profitAndLoss,
      showHideLogo: showHideLogo ?? this.showHideLogo,
      statsCount: statsCount ?? this.statsCount,
      todayTotalTxnChart: todayTotalTxnChart ?? this.todayTotalTxnChart,
      transport: transport ?? this.transport,
      orders: orders ?? this.orders,
      benefit: benefit ?? this.benefit,
      isWholeSale: isWholeSale ?? this.isWholeSale,
    );
  }

  @override
  List<Object?> get props => [
    moneyTransfer,
    shipping,
    stock,
    attendance,
    exchangeRate,
    currencyRates,
    termsAndConditions,
    customTermsAndConditions,
    recentTransactions,
    dateType,
    dateFormat,
    isDateExpiry,
    quickAccess,
    profitAndLoss,
    showHideLogo,
    statsCount,
    todayTotalTxnChart,
    transport,
    orders,
    benefit,
    isWholeSale,
  ];
}