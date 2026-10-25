import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'company_settings_menu_event.dart';
part 'company_settings_menu_state.dart';

class CompanySettingsMenuBloc extends Bloc<CompanySettingsMenuEvent, CompanySettingsMenuState> {
  CompanySettingsMenuBloc() : super(CompanySettingsMenuState(tabs: CompanySettingsMenuName.profile)) {

    on<CompanySettingsOnChangedEvent>((event, emit) {
      emit(CompanySettingsMenuState(tabs: event.tabs));
    });
  }
}
