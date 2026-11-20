part of 'shp_expense_bloc.dart';

sealed class ShpExpenseState extends Equatable {
  const ShpExpenseState();
}

final class ShpExpenseInitial extends ShpExpenseState {
  @override
  List<Object> get props => [];
}
