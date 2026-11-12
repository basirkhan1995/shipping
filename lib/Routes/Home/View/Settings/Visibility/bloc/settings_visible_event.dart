part of 'settings_visible_bloc.dart';

sealed class SettingsVisibleEvent extends Equatable {
  const SettingsVisibleEvent();
}

class SaveSettingsEvent extends SettingsVisibleEvent {
  final SettingsVisibilityState value;
  const SaveSettingsEvent(this.value);
  @override
  List<Object?> get props => [value];
}

class LoadSettingsEvent extends SettingsVisibleEvent {
  @override
  List<Object?> get props => [];
}

class UpdateSettingsEvent extends SettingsVisibleEvent {
  final bool? moneyTransfer;
  final bool? shipping;
  final bool? stock;
  final bool? attendance;
  final bool? exchangeRate;
  final bool? currencyRates;

  /// Toggle: show/hide the terms block. Unchanged.
  final bool? termsAndConditions;

  /// Custom text. Pass `''` (empty) to clear & fall back to defaults.
  /// Pass `null` to leave as-is.
  final String? customTermsAndConditions;

  final bool? benefit;
  final bool? quickAccess;
  final bool? recentTransactions;
  final DateType? dateType;
  final bool? isDateExpiry;
  final String? dateFormat;
  final bool? profitAndLoss;
  final bool? invoiceWatermark;
  final bool? orders;
  final bool? showHideLogo;
  final bool? statsCount;
  final bool? todayTotalTxnChart;
  final bool? isWholeSale;

  const UpdateSettingsEvent({
    this.moneyTransfer,
    this.shipping,
    this.stock,
    this.attendance,
    this.exchangeRate,
    this.benefit,
    this.isDateExpiry,
    this.currencyRates,
    this.termsAndConditions,
    this.customTermsAndConditions,
    this.quickAccess,
    this.dateType,
    this.dateFormat,
    this.recentTransactions,
    this.profitAndLoss,
    this.invoiceWatermark,
    this.orders,
    this.showHideLogo,
    this.statsCount,
    this.todayTotalTxnChart,
    this.isWholeSale,
  });

  @override
  List<Object?> get props => [
    moneyTransfer,
    shipping,
    stock,
    attendance,
    exchangeRate,
    benefit,
    isDateExpiry,
    currencyRates,
    termsAndConditions,
    customTermsAndConditions,
    quickAccess,
    recentTransactions,
    dateType,
    dateFormat,
    profitAndLoss,
    invoiceWatermark,
    orders,
    showHideLogo,
    statsCount,
    todayTotalTxnChart,
    isWholeSale,
  ];
}