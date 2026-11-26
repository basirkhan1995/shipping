part of 'container_invoices_bloc.dart';

sealed class ContainerInvoicesEvent extends Equatable {
  const ContainerInvoicesEvent();

  @override
  List<Object?> get props => const [];
}

class ContainerInvoicesRequested extends ContainerInvoicesEvent {
  final ContainerInvoiceRequest request;
  const ContainerInvoicesRequested(this.request);

  @override
  List<Object?> get props => [request];
}

class ContainerInvoicesReset extends ContainerInvoicesEvent {
  const ContainerInvoicesReset();
}