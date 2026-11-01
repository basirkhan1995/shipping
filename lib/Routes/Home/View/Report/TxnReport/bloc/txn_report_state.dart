part of 'txn_report_bloc.dart';

sealed class TxnReportState extends Equatable {
  const TxnReportState();
}

final class TxnReportInitial extends TxnReportState {
  @override
  List<Object> get props => [];
}


final class TxnReportErrorState extends TxnReportState {
  final String error;
  const TxnReportErrorState(this.error);
  @override
  List<Object> get props => [error];
}

final class TxnReportLoadingState extends TxnReportState {
  @override
  List<Object> get props => [];
}

final class TxnReportLoadedState extends TxnReportState {
  final List<TransactionReportModel> txn;
  const TxnReportLoadedState(this.txn);
  @override
  List<Object> get props => [txn];
}

