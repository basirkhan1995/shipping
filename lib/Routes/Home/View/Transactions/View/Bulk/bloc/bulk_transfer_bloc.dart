import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../Services/api_exception.dart';
import '../../../../../../../../Services/repository.dart';
import '../model/bulk_model.dart';
import 'bulk_transfer_event.dart';
import 'bulk_transfer_state.dart';

class BulkTransferBloc extends Bloc<BulkTransferEvent, BulkTransferState> {
  final Repositories _repo;

  BulkTransferBloc(this._repo)
      : super(BulkTransferEditing(
    // ✅ Start with ONE empty row so the form isn't blank on open.
    rows: [BulkTransferRow(rowId: DateTime.now().microsecondsSinceEpoch)],
    totalDebit: 0,
    totalCredit: 0,
  )) {
    on<BulkTransferAddRow>(_onAdd);
    on<BulkTransferRemoveRow>(_onRemove);
    on<BulkTransferUpdateRow>(_onUpdate);
    on<BulkTransferSubmitted>(_onSubmit);
    on<BulkTransferReset>((_, emit) => emit(BulkTransferEditing(
      rows: [
        BulkTransferRow(rowId: DateTime.now().microsecondsSinceEpoch)
      ],
      totalDebit: 0,
      totalCredit: 0,
    )));
  }

  BulkTransferEditing get _editing {
    final s = state;
    if (s is BulkTransferEditing) return s;
    if (s is BulkTransferFailure) return _fromRows(s.rows);
    return BulkTransferEditing(
      rows: [BulkTransferRow(rowId: DateTime.now().microsecondsSinceEpoch)],
      totalDebit: 0,
      totalCredit: 0,
    );
  }

  BulkTransferEditing _fromRows(List<BulkTransferRow> rows) {
    final debit = rows.fold<double>(0, (a, r) => a + r.debit);
    final credit = rows.fold<double>(0, (a, r) => a + r.credit);
    return BulkTransferEditing(
      rows: rows,
      totalDebit: double.parse(debit.toStringAsFixed(2)),
      totalCredit: double.parse(credit.toStringAsFixed(2)),
    );
  }

  void _onAdd(BulkTransferAddRow _, Emitter<BulkTransferState> emit) {
    final cur = _editing;
    final nextId = DateTime.now().microsecondsSinceEpoch;
    final defaultCcy =
    cur.rows.isNotEmpty ? (cur.rows.first.currency ?? '') : '';
    emit(_fromRows(
        [...cur.rows, BulkTransferRow(rowId: nextId, currency: defaultCcy)]));
  }

  void _onRemove(
      BulkTransferRemoveRow e,
      Emitter<BulkTransferState> emit,
      ) {
    final cur = _editing;
    final remaining =
    cur.rows.where((r) => r.rowId != e.rowId).toList();
    // Never end up with zero rows — the form always needs at least one.
    if (remaining.isEmpty) {
      remaining.add(BulkTransferRow(
        rowId: DateTime.now().microsecondsSinceEpoch,
      ));
    }
    emit(_fromRows(remaining));
  }

  void _onUpdate(
      BulkTransferUpdateRow e,
      Emitter<BulkTransferState> emit,
      ) {
    final cur = _editing;
    final updated = cur.rows.map((r) {
      if (r.rowId != e.rowId) return r;
      return r.copyWith(
        accountNumber: e.accountNumber,
        accountName: e.accountName,
        currency: e.currency,
        debit: e.debit,
        credit: e.credit,
        narration: e.narration,
        clearAccount: e.clearAccount,
      );
    }).toList();
    emit(_fromRows(updated));
  }

  Future<void> _onSubmit(
      BulkTransferSubmitted e,
      Emitter<BulkTransferState> emit,
      ) async {
    final cur = _editing;

    if (!cur.canSubmit) {
      emit(BulkTransferFailure(
        'Transaction is not ready to submit.',
        rows: cur.rows,
      ));
      return;
    }

    emit(BulkTransferSubmitting(
      rows: cur.rows,
      totalDebit: cur.totalDebit,
      totalCredit: cur.totalCredit,
    ));

    try {
      final records = cur.rows.map((r) => r.toRecord()).toList();
      final result = await _repo.bulkTransfer(
        userName: e.userName,
        records: records,
      );

      final msg = result['msg']?.toString().toLowerCase() ?? '';
      if (msg == 'success' || msg.contains('success')) {
        emit(BulkTransferSuccess(
          result['reference']?.toString() ?? 'Bulk transfer created',
          reference: result['reference']?.toString(),
        ));
        add(const BulkTransferReset());
      } else {
        emit(BulkTransferFailure(
          _humanError(msg),
          errorType: msg,
          rows: cur.rows,
        ));
      }
    } on ApiException catch (x) {
      emit(BulkTransferFailure(x.message, rows: cur.rows));
    } catch (x) {
      emit(BulkTransferFailure(x.toString(), rows: cur.rows));
    }
  }

  String _humanError(String code) {
    switch (code) {
      case 'no limit':
        return 'One or more accounts exceeded their credit limit.';
      case 'blocked':
        return 'One or more accounts are blocked.';
      case 'diff ccy':
        return 'All rows must use the same currency.';
      case 'failed':
      case 'empty':
        return 'The transaction could not be processed.';
      default:
        return code.isEmpty ? 'Transaction failed.' : code;
    }
  }
}