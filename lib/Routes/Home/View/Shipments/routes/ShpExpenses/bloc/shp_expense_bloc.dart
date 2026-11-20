import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'shp_expense_event.dart';
part 'shp_expense_state.dart';

class ShpExpenseBloc extends Bloc<ShpExpenseEvent, ShpExpenseState> {
  ShpExpenseBloc() : super(ShpExpenseInitial()) {
    on<ShpExpenseEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
