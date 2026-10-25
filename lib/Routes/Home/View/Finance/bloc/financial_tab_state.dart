part of 'financial_tab_bloc.dart';

enum FinanceTabName {endOfYear, payroll, glAccounts, reminder, exchangeRate, currencies}

class FinanceTabState extends Equatable {
  final FinanceTabName tab;
  const FinanceTabState({this.tab = FinanceTabName.currencies});
  @override
  List<Object> get props => [tab];
}
