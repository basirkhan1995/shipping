part of 'balance_sheet_bloc.dart';

sealed class BalanceSheetState extends Equatable {
  const BalanceSheetState();

  @override
  List<Object?> get props => [];
}

final class BalanceSheetInitial extends BalanceSheetState {}

final class BalanceSheetLoading extends BalanceSheetState {}

final class BalanceSheetLoaded extends BalanceSheetState {
  final BalanceSheetModel data;

  const BalanceSheetLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

final class BalanceSheetError extends BalanceSheetState {
  final String message;

  const BalanceSheetError(this.message);

  @override
  List<Object?> get props => [message];
}
