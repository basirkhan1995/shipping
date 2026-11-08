part of 'order_report_bloc.dart';

sealed class OrderReportState extends Equatable {
  const OrderReportState();
}

final class OrderReportInitial extends OrderReportState {
  @override
  List<Object> get props => [];
}

final class OrderReportErrorState extends OrderReportState {
  final String error;
  const OrderReportErrorState(this.error);
  @override
  List<Object> get props => [error];
}

final class OrderReportLoadingState extends OrderReportState {
  @override
  List<Object> get props => [];
}

final class OrderReportLoadedSate extends OrderReportState {
  final List<OrderReportModel> orders;
  const  OrderReportLoadedSate(this.orders);
  @override
  List<Object> get props => [orders];
}


