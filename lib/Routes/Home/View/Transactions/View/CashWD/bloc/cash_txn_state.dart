// features/journal/cash/bloc/cash_txn_state.dart
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

class CashTxnSuccess extends CashTxnState {
  /// Raw response from cashWD.php — either `{"msg":"success"}`
  /// or a print-ready payload (reference/amount/…).
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