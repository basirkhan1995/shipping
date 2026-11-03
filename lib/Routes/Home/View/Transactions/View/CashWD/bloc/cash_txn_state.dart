part of 'cash_txn_bloc.dart';

sealed class CashTxnState extends Equatable {
  const CashTxnState();
  @override
  List<Object?> get props => const [];
}

class CashTxnIdle extends CashTxnState {
  const CashTxnIdle();
}

class CashTxnSubmitting extends CashTxnState {
  const CashTxnSubmitting();
}

/// Loading the reference for edit/view.
class CashTxnLoading extends CashTxnState {
  const CashTxnLoading();
}

class CashTxnLoadedForEdit extends CashTxnState {
  final CashTxnDetail detail;      // ← NEW: full response for voucher
  final TransactionDraft draft;
  final String? stateText;
  final int? status;
  final String? makerName;
  final String? typeCode;

  const CashTxnLoadedForEdit({
    required this.detail,
    required this.draft,
    this.stateText,
    this.status,
    this.makerName,
    this.typeCode,
  });

  bool get isPending    => stateText == 'Pending';
  bool get isAuthorized => stateText == 'Authorized';
  bool get isReversed   => stateText == 'Reversed';
  bool get isDeleted    => stateText == 'Deleted';
  bool get isEditing    => draft.trnReference != null;

  @override
  List<Object?> get props =>
      [detail, draft, stateText, status, makerName, typeCode];
}

class CashTxnSuccess extends CashTxnState {
  final Map<String, dynamic> result;

  /// Full typed detail of the saved transaction, ready for printing.
  /// May be `null` if the save response only returned a reference and
  /// the follow-up fetch failed.
  final CashTxnDetail? detail;

  const CashTxnSuccess(this.result, {this.detail});

  @override
  List<Object?> get props => [result, detail];
}

class CashTxnFailure extends CashTxnState {
  final String message;
  const CashTxnFailure(this.message);
  @override
  List<Object?> get props => [message];
}

