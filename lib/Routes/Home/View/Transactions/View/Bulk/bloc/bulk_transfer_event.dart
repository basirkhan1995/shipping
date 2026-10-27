import 'package:equatable/equatable.dart';

sealed class BulkTransferEvent extends Equatable {
  const BulkTransferEvent();
  @override
  List<Object?> get props => const [];
}

class BulkTransferAddRow extends BulkTransferEvent {
  const BulkTransferAddRow();
}

class BulkTransferRemoveRow extends BulkTransferEvent {
  final int rowId;
  const BulkTransferRemoveRow(this.rowId);
  @override
  List<Object?> get props => [rowId];
}

class BulkTransferUpdateRow extends BulkTransferEvent {
  final int rowId;
  final int? accountNumber;
  final String? accountName;
  final String? currency;
  final double? debit;
  final double? credit;
  final String? narration;
  final bool clearAccount;

  const BulkTransferUpdateRow({
    required this.rowId,
    this.accountNumber,
    this.accountName,
    this.currency,
    this.debit,
    this.credit,
    this.narration,
    this.clearAccount = false,
  });

  @override
  List<Object?> get props => [
    rowId,
    accountNumber,
    accountName,
    currency,
    debit,
    credit,
    narration,
    clearAccount,
  ];
}

class BulkTransferSubmitted extends BulkTransferEvent {
  final String userName;
  const BulkTransferSubmitted({required this.userName});
  @override
  List<Object?> get props => [userName];
}

class BulkTransferReset extends BulkTransferEvent {
  const BulkTransferReset();
}

// ── NEW: edit mode ─────────────────────────────────────────────

/// Load an existing bulk transfer for editing.
class BulkTransferLoadForEditRequested extends BulkTransferEvent {
  final String reference;
  const BulkTransferLoadForEditRequested(this.reference);
  @override
  List<Object?> get props => [reference];
}

/// Delete the currently-edited bulk transaction entirely
/// (header + every line).
class BulkTransferDeleteRequested extends BulkTransferEvent {
  final String reference;
  final String userName;
  const BulkTransferDeleteRequested({
    required this.reference,
    required this.userName,
  });

  @override
  List<Object?> get props => [reference, userName];
}