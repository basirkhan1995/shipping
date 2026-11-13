part of 'txn_report_bloc.dart';

sealed class TxnReportEvent extends Equatable {
  const TxnReportEvent();
}

class LoadTxnReportEvent extends TxnReportEvent{
  final String? fromDate;
  final String? toDate;
  final String? txnType;
  final int? status;
  final String? maker;
  final String? checker;
  final String? currency;
  const LoadTxnReportEvent({this.fromDate, this.toDate, this.txnType,this.status, this.maker,this.checker,this.currency});

  @override
  List<Object?> get props => [fromDate, toDate, txnType, status, maker, checker,currency];
}

class ResetTxnReportEvent extends TxnReportEvent{
  @override
  List<Object?> get props => [];
}