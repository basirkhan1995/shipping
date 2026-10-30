part of 'txn_ref_report_bloc.dart';

sealed class TxnRefReportState extends Equatable {
  const TxnRefReportState();
}

final class TxnRefReportInitial extends TxnRefReportState {
  @override
  List<Object> get props => [];
}

final class TxnRefReportLoadingState extends TxnRefReportState {
  @override
  List<Object> get props => [];
}

final class TxnRefReportErrorState extends TxnRefReportState {
  final String message;
  const TxnRefReportErrorState(this.message);
  @override
  List<Object> get props => [message];
}


final class TxnRefReportLoadedState extends TxnRefReportState {
  final TxnReportByRefModel txn;
  const TxnRefReportLoadedState(this.txn);
  @override
  List<Object> get props => [txn];
}