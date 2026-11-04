// features/journal/cash/bloc/cash_txn_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../../../model/trn_model.dart';
import '../model/wd_model.dart';
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
      final d = await _repo.getCashTxnByRef(reference: e.reference);

      if (d.lines.isEmpty) {
        emit(const CashTxnFailure('Transaction has no detail lines.'));
        return;
      }

      final subject = d.subjectLine!;

      final draft = TransactionDraft(
        trnReference: d.reference,
        trnType:      d.type,
        trdBranch:    subject.branch,
        maker:        d.makerName,
        checker:      d.checkerName,
        trnStatus:    d.status,
        trnStateText: d.stateText,
        trnEntryDate: d.entryDate,

        trdAccount:   subject.trdAccount,
        trdCcy:       subject.ccy,
        trdAmount:    subject.amountDisplay,
        trdNarration: subject.narration,
        accName:      subject.accName,
      );

      emit(CashTxnLoadedForEdit(
        detail:    d,
        draft:     draft,
        stateText: d.stateText,
        status:    d.status,
        makerName: d.makerName,
        typeCode:  d.type,
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
      final detail = await _reloadForPrint(result, e.draft.trnReference);
      emit(CashTxnSuccess(result, detail: detail));
    } on ApiException catch (x) {
      emit(CashTxnFailure(x.message));
    } catch (x) {
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
      final detail = await _reloadForPrint(result, e.draft.trnReference);
      emit(CashTxnSuccess(result, detail: detail));
    } on ApiException catch (x) {
      emit(CashTxnFailure(x.message));
    } catch (x) {
      emit(CashTxnFailure(x.toString()));
    }
  }

  Future<CashTxnDetail?> _reloadForPrint(
      Map<String, dynamic> result,
      String? fallbackRef,
      ) async {
    // The POST/PUT now return the same flat shape as GET.
    try {
      if ((result['lines'] as List?)?.isNotEmpty == true) {
        return CashTxnDetail.fromJson(result);
      }
    } catch (_) {}

    // Defensive: if the backend still wraps in "print", handle it.
    final printData = result['print'];
    if (printData is Map && (printData['lines'] as List?)?.isNotEmpty == true) {
      try {
        return CashTxnDetail.fromJson(Map<String, dynamic>.from(printData));
      } catch (_) {}
    }

    // Fallback: reload by reference.
    final ref = (result['reference'] ?? fallbackRef)?.toString();
    if (ref == null || ref.isEmpty) return null;

    try {
      return await _repo.getCashTxnByRef(reference: ref);
    } catch (_) {
      return null;
    }
  }
}