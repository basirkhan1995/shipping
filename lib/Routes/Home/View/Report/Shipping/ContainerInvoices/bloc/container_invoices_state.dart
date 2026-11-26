part of 'container_invoices_bloc.dart';

sealed class ContainerInvoicesState extends Equatable {
  const ContainerInvoicesState();

  @override
  List<Object?> get props => const [];
}

class ContainerInvoicesInitial extends ContainerInvoicesState {
  const ContainerInvoicesInitial();
}

class ContainerInvoicesLoading extends ContainerInvoicesState {
  const ContainerInvoicesLoading();
}

/// Full list — for the "Print ALL" dialog.
class ContainerInvoicesSuccess extends ContainerInvoicesState {
  final ContainerInvoices data;
  const ContainerInvoicesSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

/// Single invoice — for the "Preview" dialog.
/// Carries the full [ContainerInvoices] too so the UI can still open
/// the batch dialog afterwards if needed.
class ContainerInvoicePreviewReady extends ContainerInvoicesState {
  final ContainerInvoices data;
  final ShippingInvoice invoice;

  const ContainerInvoicePreviewReady(this.data, this.invoice);

  @override
  List<Object?> get props => [data, invoice];
}

class ContainerInvoicesFailure extends ContainerInvoicesState {
  final String message;
  const ContainerInvoicesFailure(this.message);

  @override
  List<Object?> get props => [message];
}