part of 'exchange_rate_bloc.dart';

sealed class ExchangeRateEvent extends Equatable {
  const ExchangeRateEvent();
}

class LoadExchangeRateEvent extends ExchangeRateEvent{
  final String ccyCode;
  const LoadExchangeRateEvent(this.ccyCode);
  @override
  List<Object?> get props => [ccyCode];
}

class AddExchangeRateEvent extends ExchangeRateEvent{
  final ExchangeRateModel newRate;
  final String? baseCcy;
  const AddExchangeRateEvent({required this.newRate, this.baseCcy});
  @override
  List<Object> get props => [newRate];
}

class GetExchangeRateEvent extends ExchangeRateEvent{
  final String fromCcy;
  final String toCcy;
  const GetExchangeRateEvent({required this.fromCcy, required this.toCcy});
  @override
  List<Object> get props => [fromCcy, toCcy];
}