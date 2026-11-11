import 'package:equatable/equatable.dart';

sealed class OrdersTxnEvent extends Equatable {
  const OrdersTxnEvent();
  @override
  List<Object?> get props => const [];
}

class OrdersTxnAddRow extends OrdersTxnEvent {
  const OrdersTxnAddRow();
}

class OrdersTxnRemoveRow extends OrdersTxnEvent {
  final int rowId;
  const OrdersTxnRemoveRow(this.rowId);
  @override
  List<Object?> get props => [rowId];
}

class OrdersTxnUpdateRow extends OrdersTxnEvent {
  final int rowId;
  final int? accountNumber;
  final String? accountName;
  final String? currency;
  final double? debit;
  final double? credit;
  final String? narration;
  final bool clearAccount;

  const OrdersTxnUpdateRow({
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

class OrdersTxnSubmitted extends OrdersTxnEvent {
  final String userName;
  const OrdersTxnSubmitted({required this.userName});
  @override
  List<Object?> get props => [userName];
}

class OrdersTxnReset extends OrdersTxnEvent {
  const OrdersTxnReset();
}

class OrdersTxnLoadForEditRequested extends OrdersTxnEvent {
  final String reference;
  const OrdersTxnLoadForEditRequested(this.reference);
  @override
  List<Object?> get props => [reference];
}

class OrdersTxnDeleteRequested extends OrdersTxnEvent {
  final String reference;
  final String userName;
  const OrdersTxnDeleteRequested({
    required this.reference,
    required this.userName,
  });

  @override
  List<Object?> get props => [reference, userName];
}