part of 'financial_tab_bloc.dart';

sealed class FinanceTabEvent extends Equatable {
  const FinanceTabEvent();
}

class FinanceOnChangedEvent extends FinanceTabEvent{
  final FinanceTabName tab;
  const FinanceOnChangedEvent(this.tab);
  @override
  List<Object?> get props => [tab];
}