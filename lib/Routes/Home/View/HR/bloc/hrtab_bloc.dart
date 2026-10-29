import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'hrtab_event.dart';
part 'hrtab_state.dart';

class HrTabBloc extends Bloc<HrTabEvent, HrTabState> {
  HrTabBloc() : super(HrTabState(tabs: HrTabName.employees)) {
    on<HrOnchangeEvent>((event, emit) {
      emit(HrTabState(tabs: event.tab));
    });
  }
}
