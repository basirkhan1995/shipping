// lib/features/fund_transfer/bloc/fund_transfer_event.dart
part of 'fund_transfer_bloc.dart';

abstract class FundTransferEvent extends Equatable {
  const FundTransferEvent();
  @override
  List<Object?> get props => [];
}

// ── Load list ───────────────────────────────────────────────
class LoadFundTransfersEvent extends FundTransferEvent {
  final String? state;
  final String? search;

  const LoadFundTransfersEvent({this.state, this.search});

  @override
  List<Object?> get props => [state, search];
}

// ── Load single (edit form) ─────────────────────────────────
class LoadFundTransferDetailEvent extends FundTransferEvent {
  final String reference;

  const LoadFundTransferDetailEvent(this.reference);

  @override
  List<Object?> get props => [reference];
}

// ── Add ─────────────────────────────────────────────────────
class AddFundTransferEvent extends FundTransferEvent {
  final String usrName;
  final int fromAccount;
  final String fromAccCcy;
  final int toAccount;
  final String toAccCcy;
  final double amount;
  final String narration;

  const AddFundTransferEvent({
    required this.usrName,
    required this.fromAccount,
    required this.fromAccCcy,
    required this.toAccount,
    required this.toAccCcy,
    required this.amount,
    required this.narration,
  });

  @override
  List<Object?> get props => [
    usrName, fromAccount, fromAccCcy,
    toAccount, toAccCcy, amount, narration,
  ];
}

// ── Edit ────────────────────────────────────────────────────
class EditFundTransferEvent extends FundTransferEvent {
  final String reference;
  final String usrName;
  final int fromAccount;
  final int toAccount;
  final double amount;
  final String narration;

  const EditFundTransferEvent({
    required this.reference,
    required this.usrName,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.narration,
  });

  @override
  List<Object?> get props => [
    reference, usrName, fromAccount, toAccount, amount, narration,
  ];
}

// ── Delete (soft, row-level) ────────────────────────────────
class DeleteFundTransferEvent extends FundTransferEvent {
  final String reference;
  final String usrName;

  const DeleteFundTransferEvent({
    required this.reference,
    required this.usrName,
  });

  @override
  List<Object?> get props => [reference, usrName];
}

// ── Banner clearers ────────────────────────────────────────
class ClearFundTransferErrorEvent extends FundTransferEvent {
  const ClearFundTransferErrorEvent();
}

class ClearFundTransferSuccessEvent extends FundTransferEvent {
  const ClearFundTransferSuccessEvent();
}