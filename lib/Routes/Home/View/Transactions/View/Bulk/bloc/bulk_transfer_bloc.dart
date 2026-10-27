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
    rows: [BulkTransferRow(rowId: DateTime.now().microsecondsSinceEpoch)],
    totalDebit: 0,
    totalCredit: 0,
  )) {
    on<BulkTransferAddRow>(_onAdd);
    on<BulkTransferRemoveRow>(_onRemove);
    on<BulkTransferUpdateRow>(_onUpdate);
    on<BulkTransferSubmitted>(_onSubmit);
    on<BulkTransferDeleteRequested>(_onDelete);
    on<BulkTransferReset>((_, emit) => emit(BulkTransferEditing(
      rows: [
        BulkTransferRow(rowId: DateTime.now().microsecondsSinceEpoch)
      ],
      totalDebit: 0,
      totalCredit: 0,
    )));
    on<BulkTransferLoadForEditRequested>(_onLoadForEdit);
  }

  // ── helpers ────────────────────────────────────────────────
  BulkTransferEditing get _editing {
    final s = state;
    if (s is BulkTransferEditing) return s;
    if (s is BulkTransferFailure) {
      return _fromRows(
        s.rows,
        reference: s.reference,
        status: s.status,
        stateText: s.stateText,
        makerName: s.makerName,
      );
    }
    return BulkTransferEditing(
      rows: [BulkTransferRow(rowId: DateTime.now().microsecondsSinceEpoch)],
      totalDebit: 0,
      totalCredit: 0,
    );
  }

  BulkTransferEditing _fromRows(
      List<BulkTransferRow> rows, {
        String? reference,
        int? status,
        String? stateText,
        String? makerName,
      }) {
    final debit = rows.fold<double>(0, (a, r) => a + r.debit);
    final credit = rows.fold<double>(0, (a, r) => a + r.credit);
    return BulkTransferEditing(
      rows: rows,
      totalDebit: double.parse(debit.toStringAsFixed(2)),
      totalCredit: double.parse(credit.toStringAsFixed(2)),
      reference: reference,
      status: status,
      stateText: stateText,
      makerName: makerName,
    );
  }

  // ── row ops ────────────────────────────────────────────────
  void _onAdd(BulkTransferAddRow _, Emitter<BulkTransferState> emit) {
    final cur = _editing;
    final nextId = DateTime.now().microsecondsSinceEpoch;
    final defaultCcy =
    cur.rows.isNotEmpty ? (cur.rows.first.currency ?? '') : '';
    emit(_fromRows(
      [...cur.rows, BulkTransferRow(rowId: nextId, currency: defaultCcy)],
      reference: cur.reference,
      status: cur.status,
      stateText: cur.stateText,
      makerName: cur.makerName,
    ));
  }

  void _onRemove(
      BulkTransferRemoveRow e,
      Emitter<BulkTransferState> emit,
      ) {
    final cur = _editing;
    final remaining = cur.rows.where((r) => r.rowId != e.rowId).toList();
    if (remaining.isEmpty) {
      remaining.add(BulkTransferRow(
        rowId: DateTime.now().microsecondsSinceEpoch,
        currency: cur.rows.isNotEmpty ? (cur.rows.first.currency ?? '') : '',
      ));
    }
    emit(_fromRows(
      remaining,
      reference: cur.reference,
      status: cur.status,
      stateText: cur.stateText,
      makerName: cur.makerName,
    ));
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
    emit(_fromRows(
      updated,
      reference: cur.reference,
      status: cur.status,
      stateText: cur.stateText,
      makerName: cur.makerName,
    ));
  }

  // ── load for edit ──────────────────────────────────────────
  Future<void> _onLoadForEdit(
      BulkTransferLoadForEditRequested e,
      Emitter<BulkTransferState> emit,
      ) async {
    emit(const BulkTransferLoadingForEdit());
    try {
      final body = await _repo.getBulkTransferByReference(
        reference: e.reference,
      );

      final lines = (body['lines'] as List?) ?? const [];
      final headerCcy = (lines.isNotEmpty
          ? (lines.first['trdCcy']?.toString() ?? '')
          : '');
      final status = int.tryParse(body['status']?.toString() ?? '');
      final stateText = body['stateText']?.toString();
      final makerName = body['makerName']?.toString();

      var rowId = DateTime.now().microsecondsSinceEpoch;
      final rows = <BulkTransferRow>[];
      for (final raw in lines) {
        if (raw is! Map) continue;
        rows.add(BulkTransferRow.fromServerLine(
          Map<String, dynamic>.from(raw),
          rowId: rowId++,
        ));
      }

      if (rows.isEmpty) {
        rows.add(BulkTransferRow(
          rowId: rowId++,
          currency: headerCcy.isEmpty ? null : headerCcy,
        ));
      }

      final distinctAccounts =
      rows.map((r) => r.accountNumber).whereType<int>().toSet();

      Map<int, String> nameMap = {};
      if (distinctAccounts.isNotEmpty) {
        for (final acc in distinctAccounts) {
          try {
            final list = await _repo.getAccounts(search: acc.toString());
            for (final a in list) {
              if (a.accNumber == acc && a.accName != null) {
                nameMap[acc] = a.accName!;
                break;
              }
            }
          } catch (_) {
            // ignore
          }
        }
      }

      final hydrated = rows
          .map((r) =>
      r.accountNumber != null && nameMap[r.accountNumber] != null
          ? r.copyWith(accountName: nameMap[r.accountNumber])
          : r)
          .toList();

      emit(_fromRows(
        hydrated,
        reference: e.reference,
        status: status,
        stateText: stateText,
        makerName: makerName,
      ));
    } on ApiException catch (x) {
      emit(BulkTransferFailure(
        x.message,
        rows: const [],
        reference: e.reference,
      ));
    } catch (x) {
      emit(BulkTransferFailure(
        x.toString(),
        rows: const [],
        reference: e.reference,
      ));
    }
  }

  // ── submit ─────────────────────────────────────────────────
  Future<void> _onSubmit(
      BulkTransferSubmitted e,
      Emitter<BulkTransferState> emit,
      ) async {
    final cur = _editing;

    if (!cur.canSubmit) {
      emit(BulkTransferFailure(
        'Transaction is not ready to submit.',
        rows: cur.rows,
        reference: cur.reference,
        status: cur.status,
        stateText: cur.stateText,
        makerName: cur.makerName,
      ));
      return;
    }

    // Client-side guard — mirrors the server's only_pending rule.
    if (cur.isEditing && !cur.isPending) {
      emit(BulkTransferFailure(
        'Only pending transactions can be edited.',
        errorType: 'invalid action',
        rows: cur.rows,
        reference: cur.reference,
        status: cur.status,
        stateText: cur.stateText,
        makerName: cur.makerName,
      ));
      return;
    }

    emit(BulkTransferSubmitting(
      rows: cur.rows,
      totalDebit: cur.totalDebit,
      totalCredit: cur.totalCredit,
      reference: cur.reference,
      status: cur.status,
      stateText: cur.stateText,
      makerName: cur.makerName,
    ));

    try {
      final records = cur.rows.map((r) => r.toRecord()).toList();

      final result = cur.isEditing
          ? await _repo.updateBulkTransfer(
        reference: cur.reference!,
        userName: e.userName,
        records: records,
      )
          : await _repo.bulkTransfer(
        userName: e.userName,
        records: records,
      );

      final msg = result['msg']?.toString().toLowerCase() ?? '';
      if (msg == 'success' || msg.contains('success')) {
        emit(BulkTransferSuccess(
          result['reference']?.toString() ??
              cur.reference ??
              'Bulk transfer created',
          reference: result['reference']?.toString() ?? cur.reference,
        ));
        add(const BulkTransferReset());
      } else {
        emit(BulkTransferFailure(
          _humanError(msg),
          errorType: msg,
          rows: cur.rows,
          reference: cur.reference,
          status: cur.status,
          stateText: cur.stateText,
          makerName: cur.makerName,
        ));
      }
    } on ApiException catch (x) {
      emit(BulkTransferFailure(
        x.message,
        rows: cur.rows,
        reference: cur.reference,
        status: cur.status,
        stateText: cur.stateText,
        makerName: cur.makerName,
      ));
    } catch (x) {
      emit(BulkTransferFailure(
        x.toString(),
        rows: cur.rows,
        reference: cur.reference,
        status: cur.status,
        stateText: cur.stateText,
        makerName: cur.makerName,
      ));
    }
  }

  // ── delete ─────────────────────────────────────────────────
  Future<void> _onDelete(
      BulkTransferDeleteRequested e,
      Emitter<BulkTransferState> emit,
      ) async {
    final cur = _editing;

    try {
      await _repo.deleteBulkTransfer(
        reference: e.reference,
        userName: e.userName,
      );
      emit(BulkTransferDeleted(e.reference));
    } on ApiException catch (x) {
      emit(BulkTransferFailure(
        x.message,
        rows: cur.rows,
        reference: e.reference,
        status: cur.status,
        stateText: cur.stateText,
        makerName: cur.makerName,
      ));
    } catch (x) {
      emit(BulkTransferFailure(
        x.toString(),
        rows: cur.rows,
        reference: e.reference,
        status: cur.status,
        stateText: cur.stateText,
        makerName: cur.makerName,
      ));
    }
  }

  // ── error mapping ──────────────────────────────────────────
  String _humanError(String code) {
    switch (code) {
      case 'no limit':
        return 'One or more accounts exceeded their credit limit.';
      case 'blocked':
        return 'One or more accounts are blocked.';
      case 'diff ccy':
        return 'All rows must use the same currency as their account.';
      case 'unbalanced':
        return 'Total debit must equal total credit.';
      case 'not_found':
        return 'Transaction not found.';
      case 'invalid user':
        return 'You are not allowed to edit this transaction.';
      case 'invalid action':
        return 'This transaction can no longer be edited.';
      case 'failed':
      case 'empty':
        return 'The transaction could not be processed.';
      default:
        return code.isEmpty ? 'Transaction failed.' : code;
    }
  }
}