import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'financial_tab_event.dart';
part 'financial_tab_state.dart';

class FinanceTabBloc extends Bloc<FinanceTabEvent, FinanceTabState> {
  FinanceTabBloc() : super(FinanceTabState(tab: FinanceTabName.currencies)) {
    on<FinanceOnChangedEvent>((event, emit) {
      emit(FinanceTabState(tab: event.tab));
    });
  }
}
