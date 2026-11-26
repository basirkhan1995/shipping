part of 'invoice_print_bloc.dart';

sealed class InvoicePrintEvent extends Equatable {
  const InvoicePrintEvent();

  @override
  List<Object?> get props => const [];
}

class InvoicePrintRequested extends InvoicePrintEvent {
  final PrintInvoiceRequest request;
  const InvoicePrintRequested(this.request);

  @override
  List<Object?> get props => [request.accountNo, request.containerNo, request.sequenceNo];
}

class InvoicePrintReset extends InvoicePrintEvent {
  const InvoicePrintReset();
}