part of 'balance_sheet_bloc.dart';

sealed class BalanceSheetEvent extends Equatable {
  const BalanceSheetEvent();

  @override
  List<Object?> get props => [];
}

final class LoadBalanceSheet extends BalanceSheetEvent {
  final int? branchCode;
  const LoadBalanceSheet({this.branchCode});
}
