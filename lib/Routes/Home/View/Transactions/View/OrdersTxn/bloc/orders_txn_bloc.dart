import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../Services/api_exception.dart';
import '../../../../../../../../Services/repository.dart';
import '../model/order_txn_model.dart';
import 'orders_txn_event.dart';
import 'orders_txn_state.dart';

class OrdersTxnBloc extends Bloc<OrdersTxnEvent, OrdersTxnState> {
  final Repositories _repo;

  OrdersTxnBloc(this._repo, {String? headerCurrency})
      : super(OrdersTxnEditing(
    rows: [OrdersTxnRow(rowId: DateTime.now().microsecondsSinceEpoch)],
    totalDebit: 0,
    totalCredit: 0,
    headerCurrency: headerCurrency,
  )) {
    on<OrdersTxnAddRow>(_onAdd);
    on<OrdersTxnRemoveRow>(_onRemove);
    on<OrdersTxnUpdateRow>(_onUpdate);
    on<OrdersTxnSubmitted>(_onSubmit);
    on<OrdersTxnDeleteRequested>(_onDelete);
    on<OrdersTxnReset>((_, emit) => emit(OrdersTxnEditing(
      rows: [OrdersTxnRow(rowId: DateTime.now().microsecondsSinceEpoch)],
      totalDebit: 0,
      totalCredit: 0,
      headerCurrency: (state is OrdersTxnEditing)
          ? (state as OrdersTxnEditing).headerCurrency
          : null,
    )));
    on<OrdersTxnLoadForEditRequested>(_onLoadForEdit);
  }

  // ── helpers ────────────────────────────────────────────────
  OrdersTxnEditing get _editing {
    final s = state;
    if (s is OrdersTxnEditing) return s;
    if (s is OrdersTxnFailure) {
      return _fromRows(
        s.rows,
        reference: s.reference,
        status: s.status,
        stateText: s.stateText,
        makerName: s.makerName,
        headerCurrency: s.headerCurrency,
        txnType: s.txnType,
        entryDate: s.entryDate,
      );
    }
    return OrdersTxnEditing(
      rows: [OrdersTxnRow(rowId: DateTime.now().microsecondsSinceEpoch)],
      totalDebit: 0,
      totalCredit: 0,
    );
  }

  OrdersTxnEditing _fromRows(
      List<OrdersTxnRow> rows, {
        String? reference,
        int? status,
        String? stateText,
        String? makerName,
        String? headerCurrency,
        String? txnType,
        String? entryDate,
      }) {
    final debit = rows.fold<double>(0, (a, r) => a + r.debit);
    final credit = rows.fold<double>(0, (a, r) => a + r.credit);
    return OrdersTxnEditing(
      rows: rows,
      totalDebit: double.parse(debit.toStringAsFixed(2)),
      totalCredit: double.parse(credit.toStringAsFixed(2)),
      reference: reference,
      status: status,
      stateText: stateText,
      makerName: makerName,
      headerCurrency: headerCurrency,
      txnType: txnType,
      entryDate: entryDate,
    );
  }

  // ── row ops ────────────────────────────────────────────────
  void _onAdd(OrdersTxnAddRow _, Emitter<OrdersTxnState> emit) {
    final cur = _editing;
    final nextId = DateTime.now().microsecondsSinceEpoch;
    // No default currency propagation — each row picks its own.
    emit(_fromRows(
      [...cur.rows, OrdersTxnRow(rowId: nextId)],
      reference: cur.reference,
      status: cur.status,
      stateText: cur.stateText,
      makerName: cur.makerName,
      headerCurrency: cur.headerCurrency,
      txnType: cur.txnType,
      entryDate: cur.entryDate,
    ));
  }

  void _onRemove(OrdersTxnRemoveRow e, Emitter<OrdersTxnState> emit) {
    final cur = _editing;
    final remaining = cur.rows.where((r) => r.rowId != e.rowId).toList();
    if (remaining.isEmpty) {
      remaining.add(OrdersTxnRow(
        rowId: DateTime.now().microsecondsSinceEpoch,
      ));
    }
    emit(_fromRows(
      remaining,
      reference: cur.reference,
      status: cur.status,
      stateText: cur.stateText,
      makerName: cur.makerName,
      headerCurrency: cur.headerCurrency,
      txnType: cur.txnType,
      entryDate: cur.entryDate,
    ));
  }

  void _onUpdate(OrdersTxnUpdateRow e, Emitter<OrdersTxnState> emit) {
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
      headerCurrency: cur.headerCurrency,
      txnType: cur.txnType,
      entryDate: cur.entryDate,
    ));
  }

  // ── load for edit ──────────────────────────────────────────
  Future<void> _onLoadForEdit(
      OrdersTxnLoadForEditRequested e,
      Emitter<OrdersTxnState> emit,
      ) async {
    emit(const OrdersTxnLoadingForEdit());
    try {
      final body = await _repo.getBulkTransferByReference(
        reference: e.reference,
      );

      final lines = (body['lines'] as List?) ?? const [];
      final headerCcy = lines.isNotEmpty
          ? (lines.first['trdCcy']?.toString() ?? '')
          : '';
      final status = int.tryParse(body['status']?.toString() ?? '');
      final stateText = body['stateText']?.toString();
      final makerName = body['makerName']?.toString();

      // ── NEW: header meta straight from the API ────────────
      final txnType   = body['type']?.toString();
      final entryDate = body['entryDate']?.toString();
      // ──────────────────────────────────────────────────────

      var rowId = DateTime.now().microsecondsSinceEpoch;
      final rows = <OrdersTxnRow>[];
      for (final raw in lines) {
        if (raw is! Map) continue;
        rows.add(OrdersTxnRow.fromServerLine(
          Map<String, dynamic>.from(raw),
          rowId: rowId++,
        ));
      }

      if (rows.isEmpty) {
        rows.add(OrdersTxnRow(rowId: rowId++));
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
        headerCurrency: headerCcy.isEmpty ? null : headerCcy,
        txnType: txnType,
        entryDate: entryDate,
      ));
    } on ApiException catch (x) {
      emit(OrdersTxnFailure(
        x.message,
        rows: const [],
        reference: e.reference,
      ));
    } catch (x) {
      emit(OrdersTxnFailure(
        x.toString(),
        rows: const [],
        reference: e.reference,
      ));
    }
  }

  // ── submit ─────────────────────────────────────────────────
  Future<void> _onSubmit(
      OrdersTxnSubmitted e,
      Emitter<OrdersTxnState> emit,
      ) async {
    final cur = _editing;

    if (!cur.canSubmit) {
      emit(OrdersTxnFailure(
        'Transaction is not ready to submit.',
        rows: cur.rows,
        reference: cur.reference,
        status: cur.status,
        stateText: cur.stateText,
        makerName: cur.makerName,
        headerCurrency: cur.headerCurrency,
        txnType: cur.txnType,
        entryDate: cur.entryDate,
      ));
      return;
    }

    if (cur.isEditing && !cur.isPending) {
      emit(OrdersTxnFailure(
        'Only pending transactions can be edited.',
        errorType: 'invalid action',
        rows: cur.rows,
        reference: cur.reference,
        status: cur.status,
        stateText: cur.stateText,
        makerName: cur.makerName,
        headerCurrency: cur.headerCurrency,
        txnType: cur.txnType,
        entryDate: cur.entryDate,
      ));
      return;
    }

    emit(OrdersTxnSubmitting(
      rows: cur.rows,
      totalDebit: cur.totalDebit,
      totalCredit: cur.totalCredit,
      reference: cur.reference,
      status: cur.status,
      stateText: cur.stateText,
      makerName: cur.makerName,
      headerCurrency: cur.headerCurrency,
      txnType: cur.txnType,
      entryDate: cur.entryDate,
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
        emit(OrdersTxnSuccess(
          result['reference']?.toString() ??
              cur.reference ??
              'Orders transaction created',
          reference: result['reference']?.toString() ?? cur.reference,
        ));
        add(const OrdersTxnReset());
      } else {
        emit(OrdersTxnFailure(
          _humanError(msg),
          errorType: msg,
          rows: cur.rows,
          reference: cur.reference,
          status: cur.status,
          stateText: cur.stateText,
          makerName: cur.makerName,
          headerCurrency: cur.headerCurrency,
          txnType: cur.txnType,
          entryDate: cur.entryDate,
        ));
      }
    } on ApiException catch (x) {
      emit(OrdersTxnFailure(
        x.message,
        rows: cur.rows,
        reference: cur.reference,
        status: cur.status,
        stateText: cur.stateText,
        makerName: cur.makerName,
        headerCurrency: cur.headerCurrency,
        txnType: cur.txnType,
        entryDate: cur.entryDate,
      ));
    } catch (x) {
      emit(OrdersTxnFailure(
        x.toString(),
        rows: cur.rows,
        reference: cur.reference,
        status: cur.status,
        stateText: cur.stateText,
        makerName: cur.makerName,
        headerCurrency: cur.headerCurrency,
        txnType: cur.txnType,
        entryDate: cur.entryDate,
      ));
    }
  }

  // ── delete ─────────────────────────────────────────────────
  Future<void> _onDelete(
      OrdersTxnDeleteRequested e,
      Emitter<OrdersTxnState> emit,
      ) async {
    final cur = _editing;
    try {
      await _repo.deleteBulkTransfer(
        reference: e.reference,
        userName: e.userName,
      );
      emit(OrdersTxnDeleted(e.reference));
    } on ApiException catch (x) {
      emit(OrdersTxnFailure(
        x.message,
        rows: cur.rows,
        reference: e.reference,
        status: cur.status,
        stateText: cur.stateText,
        makerName: cur.makerName,
        headerCurrency: cur.headerCurrency,
        txnType: cur.txnType,
        entryDate: cur.entryDate,
      ));
    } catch (x) {
      emit(OrdersTxnFailure(
        x.toString(),
        rows: cur.rows,
        reference: e.reference,
        status: cur.status,
        stateText: cur.stateText,
        makerName: cur.makerName,
        headerCurrency: cur.headerCurrency,
        txnType: cur.txnType,
        entryDate: cur.entryDate,
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
        return 'Currency conversion failed — please check the amounts.';
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