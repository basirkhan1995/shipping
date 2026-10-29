part of 'general_tab_bloc.dart';

sealed class GeneralTabEvent extends Equatable {
  const GeneralTabEvent();
}

class GeneralTabOnChangedEvent extends GeneralTabEvent{
  final GeneralTabName tab;
  const GeneralTabOnChangedEvent(this.tab);
  @override
  List<Object?> get props => [tab];
}