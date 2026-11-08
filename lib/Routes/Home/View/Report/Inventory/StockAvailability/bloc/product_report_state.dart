part of 'product_report_bloc.dart';

sealed class ProductReportState extends Equatable {
  const ProductReportState();
}

final class ProductReportInitial extends ProductReportState {
  @override
  List<Object> get props => [];
}

final class ProductReportLoadedState extends ProductReportState {
  final List<ProductReportModel> stock;
  const ProductReportLoadedState(this.stock);
  @override
  List<Object> get props => [stock];
}


final class ProductReportLoadingState extends ProductReportState {
  @override
  List<Object> get props => [];
}

final class ProductReportErrorState extends ProductReportState {
  final String message;
  const ProductReportErrorState(this.message);
  @override
  List<Object> get props => [message];
}
