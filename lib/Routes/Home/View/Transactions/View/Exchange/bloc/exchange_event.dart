// lib/features/exchange/bloc/exchange_event.dart
part of 'exchange_bloc.dart';

abstract class ExchangeEvent extends Equatable {
  const ExchangeEvent();
  @override
  List<Object?> get props => [];
}

// ── Load list ─────────────────────────────────────────────
class LoadExchangesEvent extends ExchangeEvent {
  final String? state;
  final String? search;

  const LoadExchangesEvent({this.state, this.search});

  @override
  List<Object?> get props => [state, search];
}

// ── Load single (edit form) ───────────────────────────────
class LoadExchangeDetailEvent extends ExchangeEvent {
  final String reference;
  const LoadExchangeDetailEvent(this.reference);
  @override
  List<Object?> get props => [reference];
}

// ── Add ──────────────────────────────────────────────────
class AddExchangeEvent extends ExchangeEvent {
  final String usrName;
  final ExchangeLeg debit;
  final ExchangeLeg credit;

  const AddExchangeEvent({
    required this.usrName,
    required this.debit,
    required this.credit,
  });

  @override
  List<Object?> get props => [usrName, debit, credit];
}

// ── Edit ─────────────────────────────────────────────────
class EditExchangeEvent extends ExchangeEvent {
  final String reference;
  final String usrName;
  final ExchangeLeg debit;
  final ExchangeLeg credit;

  const EditExchangeEvent({
    required this.reference,
    required this.usrName,
    required this.debit,
    required this.credit,
  });

  @override
  List<Object?> get props => [reference, usrName, debit, credit];
}

// ── Delete (soft) ────────────────────────────────────────
class DeleteExchangeEvent extends ExchangeEvent {
  final String reference;
  final String usrName;

  const DeleteExchangeEvent({
    required this.reference,
    required this.usrName,
  });

  @override
  List<Object?> get props => [reference, usrName];
}

// ── Banner clearers ──────────────────────────────────────
class ClearExchangeErrorEvent extends ExchangeEvent {
  const ClearExchangeErrorEvent();
}

class ClearExchangeSuccessEvent extends ExchangeEvent {
  const ClearExchangeSuccessEvent();
}