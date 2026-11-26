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
      final data = await _repo.printContainerInvoices(containerNo: event.request.containerNo, sequenceNo: event.request.sequenceNo);

      if (data.invoices.isEmpty) {
        emit(const ContainerInvoicesFailure(
          'No invoices found for this container.',
        ));
        return;
      }

      emit(ContainerInvoicesSuccess(data));
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