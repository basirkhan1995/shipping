// features/journal/cash/bloc/cash_txn_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../../../model/trn_model.dart';
import 'cash_txn_event.dart';

part 'cash_txn_state.dart';

class CashTxnBloc extends Bloc<CashTxnEvent, CashTxnState> {
  final Repositories _repo;

  CashTxnBloc(this._repo) : super(const CashTxnIdle()) {
    on<CashTxnCreateRequested>(_onCreate);
    on<CashTxnUpdateRequested>(_onUpdate);
    on<CashTxnLoadRequested>(_onLoad);
    on<CashTxnReset>((_, emit) => emit(const CashTxnIdle()));
  }

  Future<void> _onLoad(
      CashTxnLoadRequested e,
      Emitter<CashTxnState> emit,
      ) async {
    emit(const CashTxnLoading());
    try {
      final body = await _repo.getCashTxnByReference(reference: e.reference);
      final lines = (body['lines'] as List?) ?? const [];
      if (lines.isEmpty) {
        emit(const CashTxnFailure('Transaction has no detail lines.'));
        return;
      }

      // The two legs are:
      //   • the "subject" account leg (the user's account), and
      //   • the contra GL leg (10101010).
      // The dialog only needs the subject leg. Find the first line whose
      // account is NOT the GL.
      const valueGL = 10101010;

      Map<String, dynamic>? subjectLeg;

      for (final raw in lines) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final acc = int.tryParse(map['trdAccount']?.toString() ?? '');
        if (acc != null && acc != valueGL) {
          subjectLeg = map;
          break;
        }
      }

      // Fallback — if every line is the GL (data anomaly), use the first.
      subjectLeg ??= Map<String, dynamic>.from(lines.first as Map);

      final subjectAcc =
      int.tryParse(subjectLeg['trdAccount']?.toString() ?? '');
      final ccy = subjectLeg['trdCcy']?.toString();
      final amount = subjectLeg['trdAmount']?.toString() ?? '0';
      final narration = (subjectLeg['trdNarration'] ?? '').toString();

      emit(CashTxnLoadedForEdit(
        draft: TransactionDraft(
          trnReference: e.reference,
          trnType: body['type']?.toString(),
          trdAccount: subjectAcc,
          trdCcy: ccy,
          trdAmount: amount,
          trdNarration: narration,
        ),
        stateText: body['stateText']?.toString(),
        status: int.tryParse(body['status']?.toString() ?? ''),
        makerName: body['makerName']?.toString(),
        typeCode: body['type']?.toString(),
      ));

    } on ApiException catch (x) {
      emit(CashTxnFailure(x.message));
    } catch (x) {
      emit(CashTxnFailure(x.toString()));
    }
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