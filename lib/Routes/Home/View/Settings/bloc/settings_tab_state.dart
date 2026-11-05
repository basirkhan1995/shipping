part of 'settings_tab_bloc.dart';

enum SettingsTabName {general, company, backup, about}

final class SettingsTabState extends Equatable {
  final SettingsTabName tabs;
  const SettingsTabState({this.tabs = SettingsTabName.general});
  @override
  List<Object> get props => [tabs];
}





