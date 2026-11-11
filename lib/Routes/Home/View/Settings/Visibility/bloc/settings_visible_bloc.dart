import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_visible_event.dart';
part 'settings_visible_state.dart';

class SettingsVisibleBloc
    extends Bloc<SettingsVisibleEvent, SettingsVisibilityState> {
  static const String _key = 'visibility_settings';

  SettingsVisibleBloc() : super(const SettingsVisibilityState()) {
    on<LoadSettingsEvent>(loadSettingsEvent);
    on<SaveSettingsEvent>(saveSettingsEvent);
    on<UpdateSettingsEvent>(updateSettingsEvent);
  }

  Future<void> loadSettingsEvent(
      LoadSettingsEvent event,
      Emitter<SettingsVisibilityState> emit,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString != null) {
      try {
        final map = json.decode(jsonString) as Map<String, dynamic>;
        emit(SettingsVisibilityState.fromMap(map));
      } catch (_) {
        emit(const SettingsVisibilityState());
      }
    } else {
      emit(const SettingsVisibilityState());
    }
  }

  Future<void> saveSettingsEvent(
      SaveSettingsEvent event,
      Emitter<SettingsVisibilityState> emit,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(event.value.toMap()));
    emit(event.value);
  }

  Future<void> updateSettingsEvent(
      UpdateSettingsEvent event,
      Emitter<SettingsVisibilityState> emit,
      ) async {
    // ── Resolve customTermsAndConditions ──────────────────────
    //   event.customTermsAndConditions == null  → keep existing
    //   event.customTermsAndConditions == ''    → clear
    //   event.customTermsAndConditions == 'txt' → save trimmed
    final bool shouldUpdateCustomTerms = event.customTermsAndConditions != null;
    final String? trimmedCustomTerms = shouldUpdateCustomTerms
        ? event.customTermsAndConditions!.trim()
        : null;
    final bool shouldClearCustomTerms =
        shouldUpdateCustomTerms && (trimmedCustomTerms == null || trimmedCustomTerms.isEmpty);

    final updated = state.copyWith(
      moneyTransfer: event.moneyTransfer,
      shipping: event.shipping,
      stock: event.stock,
      attendance: event.attendance,
      exchangeRate: event.exchangeRate,
      currencyRates: event.currencyRates,
      termsAndConditions: event.termsAndConditions,

      // Only pass a value if the caller actually provided one.
      customTermsAndConditions:
      shouldUpdateCustomTerms && !shouldClearCustomTerms
          ? trimmedCustomTerms
          : null,

      // Force-reset when the caller cleared the field.
      clearCustomTerms: shouldClearCustomTerms,

      quickAccess: event.quickAccess,
      recentTransactions: event.recentTransactions,
      dateType: event.dateType,
      isDateExpiry: event.isDateExpiry,
      dateFormat: event.dateFormat,
      profitAndLoss: event.profitAndLoss,
      transport: event.transport,
      orders: event.orders,
      showHideLogo: event.showHideLogo,
      statsCount: event.statsCount,
      todayTotalTxnChart: event.todayTotalTxnChart,
      benefit: event.benefit,
      isWholeSale: event.isWholeSale,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(updated.toMap()));

    emit(updated);
  }
}