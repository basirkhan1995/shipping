part of 'settings_visible_bloc.dart';

enum DateType {
  hijriShamsi,
  gregorian,
}

class SettingsVisibilityState extends Equatable {
  final bool shipping;
  final bool moneyTransfer;
  final bool stock;
  final bool attendance;
  final bool exchangeRate;
  final bool currencyRates;
  final bool dashboardClock;
  final bool recentTransactions;
  final DateType dateType;
  final String dateFormat;
  final bool isDateExpiry;
  final bool quickAccess;
  final bool profitAndLoss;
  final bool todayTotalTransactions;
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
    this.dashboardClock = true,
    this.recentTransactions = false,
    this.quickAccess = true,
    this.dateType = DateType.gregorian,
    this.dateFormat = 'yyyy-MM-dd',
    this.profitAndLoss = true,
    this.todayTotalTransactions = true,
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
      dashboardClock: map['dashboardClock'] ?? true,
      isDateExpiry: map['isDateExpiry'] ?? false,
      quickAccess: map['quickAccess'] ?? true,
      recentTransactions: map['recentTransactions'] ?? false,
      dateType: _dateTypeFromString(map['dateType'] ?? 'gregorian'),
      dateFormat: map['dateFormat'] ?? 'yyyy-MM-dd',
      profitAndLoss: map['profitAndLoss'] ?? true,
      statsCount: map['statsCount'] ?? true,
      todayTotalTransactions: map['todayTotalTransactions'] ?? true,
      todayTotalTxnChart: map['todayTotalTxnChart'] ?? true,
      transport: map['transport'] ?? true,
      orders: map['orders'] ?? true,
      isWholeSale: map['isWholeSale'] ?? false
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
      'dashboardClock': dashboardClock,
      'dateType': dateType.name,
      'dateFormat': dateFormat,
      'isDateExpiry': isDateExpiry,
      'quickAccess': quickAccess,
      'recentTransactions': recentTransactions,
      'profitAndLoss': profitAndLoss,
      'statsCount': statsCount,
      'todayTotalTransactions': todayTotalTransactions,
      'todayTotalTxnChart': todayTotalTxnChart,
      'transport': transport,
      'orders': orders,
      'isWholeSale': isWholeSale
    };
  }

  static DateType _dateTypeFromString(String value) {
    return DateType.values.firstWhere(
          (e) => e.name == value,
      orElse: () => DateType.gregorian,
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
    dashboardClock,
    recentTransactions,
    dateType,
    dateFormat,
    isDateExpiry,
    quickAccess,
    profitAndLoss,
    todayTotalTransactions,
    statsCount,
    todayTotalTxnChart,
    transport,
    orders,
    benefit,
    isWholeSale
  ];
}
