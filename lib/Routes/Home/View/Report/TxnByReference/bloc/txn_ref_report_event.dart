part of 'txn_ref_report_bloc.dart';

sealed class TxnRefReportEvent extends Equatable {
  const TxnRefReportEvent();
}

class LoadTxnReportByReferenceEvent extends TxnRefReportEvent{
  final String reference;
  const LoadTxnReportByReferenceEvent(this.reference);
  @override
  List<Object?> get props => [reference];
}

class ResetTxnReportByReferenceEvent extends TxnRefReportEvent{
  @override
  List<Object?> get props => [];
}