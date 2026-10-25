import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'brc_tab_event.dart';
part 'brc_tab_state.dart';

class BranchTabBloc extends Bloc<BranchTabEvent, BranchTabState> {
  BranchTabBloc() : super(BranchTabState(tab: BranchTabName.overview)) {
    on<BrcOnChangedEvent>((event, emit) {
      emit(BranchTabState(tab: event.tab));
    });
  }
}
