// features/journal/cash/bloc/cash_txn_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import 'cash_txn_event.dart';

part 'cash_txn_state.dart';

class CashTxnBloc extends Bloc<CashTxnEvent, CashTxnState> {
  final Repositories _repo;

  CashTxnBloc(this._repo) : super(const CashTxnIdle()) {
    on<CashTxnCreateRequested>(_onCreate);
    on<CashTxnUpdateRequested>(_onUpdate);
    on<CashTxnReset>((_, emit) => emit(const CashTxnIdle()));
  }

  Future<void> _onCreate(
      CashTxnCreateRequested e,
      Emitter<CashTxnState> emit,
      ) async {
    emit(const CashTxnSubmitting());
    try {
      final result = await _repo.cashFlowOperations(newTransaction: e.draft);
      debugPrint('CashTxnBloc SUCCESS: $result');
      emit(CashTxnSuccess(result));
    } on ApiException catch (x) {
      debugPrint('CashTxnBloc ApiException: ${x.message}');
      emit(CashTxnFailure(x.message));
    } catch (x, st) {
      debugPrint('CashTxnBloc UNEXPECTED: $x\n$st');
      emit(CashTxnFailure(x.toString()));
    }
  }

  Future<void> _onUpdate(
      CashTxnUpdateRequested e,
      Emitter<CashTxnState> emit,
      ) async {
    emit(const CashTxnSubmitting());
    try {
      final result = await _repo.updateTxn(newTxn: e.draft);
      emit(CashTxnSuccess(result));
    } on ApiException catch (x) {
      emit(CashTxnFailure(x.message));
    } catch (x) {
      emit(CashTxnFailure(x.toString()));
    }
  }
}