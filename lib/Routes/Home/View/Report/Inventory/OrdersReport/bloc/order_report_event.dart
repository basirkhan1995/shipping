part of 'order_report_bloc.dart';

sealed class OrderReportEvent extends Equatable {
  const OrderReportEvent();
}


class LoadOrderReportEvent extends OrderReportEvent{
  final String? fromDate;
  final String? toDate;
  final String? orderName;
  final int? orderId;
  final int? customerId;
  final int? branchId;

  const LoadOrderReportEvent({this.fromDate, this.toDate, this.orderName, this.orderId, this.customerId, this.branchId});
  @override

  List<Object?> get props => [fromDate, toDate, orderName, orderId, customerId, branchId];
}

class ResetOrderReportEvent extends OrderReportEvent{
  @override
  List<Object?> get props => [];
}