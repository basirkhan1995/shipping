import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/inv_print_model.dart';


part 'invoice_print_event.dart';
part 'invoice_print_state.dart';

class InvoicePrintBloc extends Bloc<InvoicePrintEvent, InvoicePrintState> {
  final Repositories _repo;

  InvoicePrintBloc(this._repo) : super(const InvoicePrintInitial()) {
    on<InvoicePrintRequested>(_onRequested);
    on<InvoicePrintReset>(_onReset);
  }

  Future<void> _onRequested(
      InvoicePrintRequested event,
      Emitter<InvoicePrintState> emit,
      ) async {
    // Client-side validation first — fails fast, no round trip.
    try {
      event.request.validate();
    } on ArgumentError catch (e) {
      emit(InvoicePrintFailure(e.message.toString()));
      return;
    }

    emit(const InvoicePrintLoading());

    try {
      final invoice = await _repo.printShippingInvoice(event.request);
      emit(InvoicePrintSuccess(invoice));
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return; // silent cancel
      emit(InvoicePrintFailure(
        e.message ?? 'Failed to load invoice.',
      ));
    } on ApiException catch (e) {
      emit(InvoicePrintFailure(e.message));
    } catch (e) {
      emit(InvoicePrintFailure('Unexpected error: $e'));
    }
  }

  void _onReset(
      InvoicePrintReset event,
      Emitter<InvoicePrintState> emit,
      ) {
    emit(const InvoicePrintInitial());
  }
}