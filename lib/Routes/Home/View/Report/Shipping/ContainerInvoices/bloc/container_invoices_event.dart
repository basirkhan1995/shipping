part of 'container_invoices_bloc.dart';

sealed class ContainerInvoicesEvent extends Equatable {
  const ContainerInvoicesEvent();

  @override
  List<Object?> get props => const [];
}

/// Fetches all customers in a container.
///
/// If [previewAccountNo] is set, the bloc emits
/// [ContainerInvoicePreviewReady] for just that customer.
/// Otherwise it emits [ContainerInvoicesSuccess] with the full list.
class ContainerInvoicesRequested extends ContainerInvoicesEvent {
  final ContainerInvoiceRequest request;
  final int? previewAccountNo;

  const ContainerInvoicesRequested(
      this.request, {
        this.previewAccountNo,
      });

  @override
  List<Object?> get props => [request, previewAccountNo];
}

class ContainerInvoicesReset extends ContainerInvoicesEvent {
  const ContainerInvoicesReset();
}