import 'package:equatable/equatable.dart';

abstract class StkAccountsEvent extends Equatable {
  const StkAccountsEvent();
  @override
  List<Object?> get props => [];
}

/// The only event that carries [perId].
/// It is the entry point of the bloc's lifecycle for one stakeholder.
class LoadStkAccountsEvent extends StkAccountsEvent {
  final int perId;
  const LoadStkAccountsEvent(this.perId);
  @override
  List<Object?> get props => [perId];
}

/// Optional: switch to a different stakeholder without recreating the bloc.
/// Semantically equivalent to LoadStkAccountsEvent but clearer intent
/// when the bloc is already showing another stakeholder's accounts.
class SwitchStakeholderEvent extends StkAccountsEvent {
  final int perId;
  const SwitchStakeholderEvent(this.perId);
  @override
  List<Object?> get props => [perId];
}

class AddStkAccountEvent extends StkAccountsEvent {
  final int? perId;
  final String accName;
  final String actCurrency;
  final dynamic actCreditLimit;
  const AddStkAccountEvent({
    this.perId,
    required this.accName,
    required this.actCurrency,
    required this.actCreditLimit,
  });
  @override
  List<Object?> get props => [perId, accName, actCurrency, actCreditLimit];
}

class EditStkAccountEvent extends StkAccountsEvent {
  final int perId;                 // <-- required now
  final int accNumber;
  final String? accName;
  final String? actCurrency;
  final dynamic actCreditLimit;
  final int? actStatus;
  const EditStkAccountEvent({
    required this.perId,           // <-- required now
    required this.accNumber,
    this.accName,
    this.actCurrency,
    this.actCreditLimit,
    this.actStatus,
  });
  @override
  List<Object?> get props =>
      [perId, accNumber, accName, actCurrency, actCreditLimit, actStatus];
}

class BlockStkAccountEvent extends StkAccountsEvent {
  final int perId;                 // <-- required now
  final int accNumber;
  const BlockStkAccountEvent(this.perId, this.accNumber);
  @override
  List<Object?> get props => [perId, accNumber];
}

class UnblockStkAccountEvent extends StkAccountsEvent {
  final int perId;                 // <-- required now
  final int accNumber;
  const UnblockStkAccountEvent(this.perId, this.accNumber);
  @override
  List<Object?> get props => [perId, accNumber];
}

class DeleteStkAccountEvent extends StkAccountsEvent {
  final int perId;                 // <-- required now
  final int accNumber;
  const DeleteStkAccountEvent(this.perId, this.accNumber);
  @override
  List<Object?> get props => [perId, accNumber];
}

class ClearStkAccountMessagesEvent extends StkAccountsEvent {
  const ClearStkAccountMessagesEvent();
}