import 'package:equatable/equatable.dart';
import '../../../model/trn_model.dart';

sealed class CashTxnEvent extends Equatable {
  const CashTxnEvent();
  @override
  List<Object?> get props => const [];
}

/// POST /journal/cashWD.php — creates a new transaction.
/// `draft.trnReference` must be null.
class CashTxnCreateRequested extends CashTxnEvent {
  final TransactionDraft draft;
  const CashTxnCreateRequested(this.draft);
  @override
  List<Object?> get props => [draft];
}

/// PUT /journal/cashWD.php — edits a pending transaction.
/// `draft.trnReference` must be non-null.
class CashTxnUpdateRequested extends CashTxnEvent {
  final TransactionDraft draft;
  const CashTxnUpdateRequested(this.draft);
  @override
  List<Object?> get props => [draft];
}

/// Clears any previous Success/Failure so the dialog can be reopened.
class CashTxnReset extends CashTxnEvent {
  const CashTxnReset();
}

/// Load an existing cash transaction for edit / view.
class CashTxnLoadRequested extends CashTxnEvent {
  final String reference;
  const CashTxnLoadRequested(this.reference);
  @override
  List<Object?> get props => [reference];
}
