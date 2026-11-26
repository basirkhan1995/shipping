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

class ContainerInvoicesSuccess extends ContainerInvoicesState {
  final ContainerInvoices data;
  const ContainerInvoicesSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

class ContainerInvoicesFailure extends ContainerInvoicesState {
  final String message;
  const ContainerInvoicesFailure(this.message);

  @override
  List<Object?> get props => [message];
}