part of 'hrtab_bloc.dart';

sealed class HrTabEvent extends Equatable {
  const HrTabEvent();
}

class HrOnchangeEvent extends HrTabEvent{
  final HrTabName tab;
  const HrOnchangeEvent(this.tab);
  @override
  List<Object?> get props => [tab];
}