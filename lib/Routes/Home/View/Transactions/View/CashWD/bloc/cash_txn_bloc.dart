// features/journal/cash/bloc/cash_txn_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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

      if (body['msg'] != null && body['msg'] != 'success') {
        emit(CashTxnFailure(body['msg'].toString()));
        return;
      }

      final lines = (body['lines'] as List?) ?? const [];
      if (lines.isEmpty) {
        emit(const CashTxnFailure('Transaction has no detail lines.'));
        return;
      }

      // ── 1. Pick the subject leg ─────────────────────────────
      // The two legs are: the subject account and the contra GL 10101010.
      // The dialog only needs the subject leg.
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
      subjectLeg ??= Map<String, dynamic>.from(lines.first as Map);

      final subjectAcc = int.tryParse(subjectLeg['trdAccount']?.toString() ?? '');
      final ccy        = subjectLeg['trdCcy']?.toString();
      final amount     = subjectLeg['trdAmount']?.toString() ?? '0';
      final narration  = (subjectLeg['trdNarration'] ?? '').toString();

      // ── 2. Header fields — display names, not ids ──────────
      String? pickNonEmpty(List<String> keys) {
        for (final k in keys) {
          final s = body[k]?.toString().trim();
          if (s != null && s.isNotEmpty && s != 'null') return s;
        }
        return null;
      }

      final makerName   = pickNonEmpty(const ['makerName', 'maker']);
      final checkerName = pickNonEmpty(const ['checkerName', 'checker']);

      final statusInt = int.tryParse(body['status']?.toString() ?? '');
      final stateText = pickNonEmpty(const ['stateText', 'trnStateText']) ??
          _statusLabel(statusInt);

      // ── 3. Date — SQL Server sends "yyyy-MM-dd HH:mm:ss" ───
      DateTime? parsedDate;
      final rawDate = pickNonEmpty(const ['entryDate', 'trnEntryDate']);
      if (rawDate != null) {
        parsedDate = DateTime.tryParse(rawDate) ??
            DateTime.tryParse(rawDate.replaceFirst(' ', 'T'));
      }

      // ── 4. Build the draft with ALL audit fields ───────────
      final draft = TransactionDraft(
        trnReference: e.reference,
        trnType:      pickNonEmpty(const ['trnType', 'type']),
        trdBranch:    int.tryParse(subjectLeg['trdBranch']?.toString() ?? ''),
        maker:        makerName,     // ← "basir" not 2
        checker:      checkerName,   // ← null / "ali"
        trnStatus:    statusInt,
        trnStateText: stateText,
        trnEntryDate: parsedDate,

        trdAccount:   subjectAcc,
        trdCcy:       ccy,
        trdAmount:    amount,
        trdNarration: narration,
        accName:      subjectLeg['accName']?.toString(),
      );

      emit(CashTxnLoadedForEdit(
        draft:     draft,
        stateText: stateText,
        status:    statusInt,
        makerName: makerName,        // ← display name, for isMaker comparison
        typeCode:  pickNonEmpty(const ['trnType', 'type']),
      ));
    } on ApiException catch (x) {
      emit(CashTxnFailure(x.message));
    } catch (x) {
      emit(CashTxnFailure(x.toString()));
    }
  }

  String? _statusLabel(int? status) {
    switch (status) {
      case 0: return 'Pending';
      case 1: return 'Authorized';
      case 2: return 'Reversed';
      case 3: return 'Deleted';
      default: return null;
    }
  }



  Future<void> _onCreate(
      CashTxnCreateRequested e,
      Emitter<CashTxnState> emit,
      ) async {
    emit(const CashTxnSubmitting());
    try {
      final result = await _repo.cashFlowOperations(newTransaction: e.draft);
      emit(CashTxnSuccess(result));
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
      emit(CashTxnSuccess(result));
    } on ApiException catch (x) {
      emit(CashTxnFailure(x.message));
    } catch (x) {
      emit(CashTxnFailure(x.toString()));
    }
  }
}