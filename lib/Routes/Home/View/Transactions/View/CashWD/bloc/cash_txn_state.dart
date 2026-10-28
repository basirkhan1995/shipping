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

/// The transaction is loaded for edit. Carries the fields the dialog needs
/// to gate buttons.
class CashTxnLoadedForEdit extends CashTxnState {
  final TransactionDraft draft;    // pre-filled values
  final String? stateText;         // Pending | Authorized | Reversed | Deleted
  final int? status;
  final String? makerName;
  final String? typeCode;

  const CashTxnLoadedForEdit({
    required this.draft,
    this.stateText,
    this.status,
    this.makerName,
    this.typeCode,
  });

  bool get isPending => stateText == 'Pending';
  bool get isAuthorized => stateText == 'Authorized';
  bool get isReversed => stateText == 'Reversed';
  bool get isDeleted => stateText == 'Deleted';
  bool get isEditing => draft.trnReference != null;

  @override
  List<Object?> get props => [draft, stateText, status, makerName, typeCode];
}

class CashTxnSuccess extends CashTxnState {
  final Map<String, dynamic> result;
  const CashTxnSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

class CashTxnFailure extends CashTxnState {
  final String message;
  const CashTxnFailure(this.message);
  @override
  List<Object?> get props => [message];
}

