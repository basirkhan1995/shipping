part of 'currencies_bloc.dart';

sealed class CurrenciesEvent extends Equatable {
  const CurrenciesEvent();
}

class LoadCurrenciesEvent extends CurrenciesEvent{
  final int? status;
  const LoadCurrenciesEvent({this.status});
  @override
  List<Object?> get props => [status];
}

class UpdateCcyStatusEvent extends CurrenciesEvent{
  final bool status;
  final String ccyCode;
  const UpdateCcyStatusEvent({required this.status, required this.ccyCode});
  @override
  List<Object?> get props => [status,ccyCode];
}

class AddCcyEvent extends CurrenciesEvent{
  final CurrenciesModel ccy;
  const AddCcyEvent({required this.ccy,});
  @override
  List<Object?> get props => [ccy];
}


class UpdateCcyEvent extends CurrenciesEvent{
  final CurrenciesModel ccy;
  const UpdateCcyEvent({required this.ccy});
  @override
  List<Object?> get props => [ccy];
}