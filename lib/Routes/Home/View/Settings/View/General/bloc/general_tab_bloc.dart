import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'general_tab_event.dart';
part 'general_tab_state.dart';

class GeneralTabBloc extends Bloc<GeneralTabEvent, GeneralTabState> {
  GeneralTabBloc() : super(GeneralTabState(tab: GeneralTabName.system)) {
    on<GeneralTabOnChangedEvent>((event, emit) {
       emit(GeneralTabState(tab: event.tab));
    });
  }
}
