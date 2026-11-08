part of 'stock_record_bloc.dart';

sealed class StockRecordState extends Equatable {
  const StockRecordState();
}

final class StockRecordInitial extends StockRecordState {
  @override
  List<Object> get props => [];
}

final class StockRecordLoadingState extends StockRecordState {
  @override
  List<Object> get props => [];
}

final class StockRecordErrorState extends StockRecordState {
  final String error;
  const StockRecordErrorState(this.error);
  @override
  List<Object> get props => [error];
}

final class StockRecordLoadedState extends StockRecordState {
  final List<StockRecordModel> cardX;
  const StockRecordLoadedState(this.cardX);
  @override
  List<Object> get props => [cardX];
}


