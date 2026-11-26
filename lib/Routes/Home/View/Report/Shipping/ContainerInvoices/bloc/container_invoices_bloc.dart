import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/cont_invoices_model.dart';

part 'container_invoices_event.dart';
part 'container_invoices_state.dart';

class ContainerInvoicesBloc
    extends Bloc<ContainerInvoicesEvent, ContainerInvoicesState> {
  final Repositories _repo;

  ContainerInvoicesBloc(this._repo)
      : super(const ContainerInvoicesInitial()) {
    on<ContainerInvoicesRequested>(_onRequested);
    on<ContainerInvoicesReset>(_onReset);
  }

  Future<void> _onRequested(
      ContainerInvoicesRequested event,
      Emitter<ContainerInvoicesState> emit,
      ) async {
    // Fail fast, no round trip.
    try {
      event.request.validate();
    } on ArgumentError catch (e) {
      emit(ContainerInvoicesFailure(e.message.toString()));
      return;
    }

    emit(const ContainerInvoicesLoading());

    try {
      // Pass the request object (matches the repository signature).
      final data = await _repo.printContainerInvoices(containerNo: event.request.containerNo, sequenceNo: event.request.sequenceNo);

      if (data.invoices.isEmpty) {
        emit(const ContainerInvoicesFailure(
          'No invoices found for this container.',
        ));
        return;
      }

      // Preview-one mode: emit just the matching invoice.
      if (event.previewAccountNo != null) {
        final match = data.invoices.firstWhere(
              (inv) => inv.customer.accountNo == event.previewAccountNo,
          orElse: () => throw _AccountNotInContainer(
            event.previewAccountNo!,
          ),
        );
        emit(ContainerInvoicePreviewReady(data, match));
        return;
      }

      // Batch mode: emit the full list.
      emit(ContainerInvoicesSuccess(data));
    } on _AccountNotInContainer catch (e) {
      emit(ContainerInvoicesFailure(e.message));
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return; // silent cancel
      emit(ContainerInvoicesFailure(
        e.message ?? 'Failed to load container invoices.',
      ));
    } on ApiException catch (e) {
      emit(ContainerInvoicesFailure(e.message));
    } catch (e) {
      emit(ContainerInvoicesFailure('Unexpected error: $e'));
    }
  }

  void _onReset(
      ContainerInvoicesReset event,
      Emitter<ContainerInvoicesState> emit,
      ) {
    emit(const ContainerInvoicesInitial());
  }
}

/// Thrown internally when [ContainerInvoicesRequested.previewAccountNo]
/// is not present in the container's invoice list.
class _AccountNotInContainer implements Exception {
  final int accountNo;
  _AccountNotInContainer(this.accountNo);
  String get message =>
      'Account $accountNo has no items in this container.';
}