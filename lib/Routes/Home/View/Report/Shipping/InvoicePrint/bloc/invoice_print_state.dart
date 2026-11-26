part of 'invoice_print_bloc.dart';

sealed class InvoicePrintState extends Equatable {
  const InvoicePrintState();

  @override
  List<Object?> get props => const [];
}

class InvoicePrintInitial extends InvoicePrintState {
  const InvoicePrintInitial();
}

class InvoicePrintLoading extends InvoicePrintState {
  const InvoicePrintLoading();
}

class InvoicePrintSuccess extends InvoicePrintState {
  final ShippingInvoice invoice;
  const InvoicePrintSuccess(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class InvoicePrintFailure extends InvoicePrintState {
  final String message;
  const InvoicePrintFailure(this.message);

  @override
  List<Object?> get props => [message];
}