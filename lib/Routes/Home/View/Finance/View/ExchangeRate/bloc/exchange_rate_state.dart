// lib/features/exchange/bloc/exchange_rate_state.dart
part of 'exchange_rate_bloc.dart';

abstract class ExchangeRateState extends Equatable {
  const ExchangeRateState();
  @override
  List<Object?> get props => [];
}

class ExchangeRateInitial extends ExchangeRateState {}

class ExchangeRateLoadingState extends ExchangeRateState {}

class ExchangeRateLoadedState extends ExchangeRateState {
  final List<ExchangeRateModel> rates;

  /// Raw rate string from the API (e.g. "70.0000").
  final String? rate;

  /// The pair this rate belongs to.
  final String? fromCcy;
  final String? toCcy;

  /// Monotonically increasing id so the UI can tell a stale response
  /// from a fresh one when the user changes the pair quickly.
  final int requestId;

  const ExchangeRateLoadedState({
    required this.rates,
    this.rate,
    this.fromCcy,
    this.toCcy,
    this.requestId = 0,
  });

  /// Convenience: `rate` as a double, `null` when the API returned
  /// nothing parseable.
  double? get rateValue {
    final r = rate;
    if (r == null) return null;
    return double.tryParse(r);
  }

  ExchangeRateLoadedState copyWith({
    List<ExchangeRateModel>? rates,
    String? rate,
    String? fromCcy,
    String? toCcy,
    int? requestId,
  }) {
    return ExchangeRateLoadedState(
      rates: rates ?? this.rates,
      rate: rate ?? this.rate,
      fromCcy: fromCcy ?? this.fromCcy,
      toCcy: toCcy ?? this.toCcy,
      requestId: requestId ?? this.requestId,
    );
  }

  @override
  List<Object?> get props => [rates, rate, fromCcy, toCcy, requestId];
}

/// One-shot success signal emitted after `AddExchangeRateEvent`.
/// Carries nothing — the follow-up `LoadExchangeRateEvent` refreshes
/// the list, and the UI only needs to show a "Saved" toast.
class ExchangeRateSuccessState extends ExchangeRateState {
  const ExchangeRateSuccessState();
}

class ExchangeRateErrorState extends ExchangeRateState {
  final String message;
  const ExchangeRateErrorState(this.message);
  @override
  List<Object?> get props => [message];
}