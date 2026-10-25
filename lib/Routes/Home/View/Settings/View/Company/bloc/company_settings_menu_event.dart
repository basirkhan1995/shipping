part of 'company_settings_menu_bloc.dart';

sealed class CompanySettingsMenuEvent extends Equatable {
  const CompanySettingsMenuEvent();
}

class CompanySettingsOnChangedEvent extends CompanySettingsMenuEvent{
  final CompanySettingsMenuName tabs;
  const CompanySettingsOnChangedEvent(this.tabs);
  @override
  List<Object?> get props => [tabs];
}