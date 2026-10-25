part of 'brc_tab_bloc.dart';

sealed class BranchTabEvent extends Equatable {
  const BranchTabEvent();
}

class BrcOnChangedEvent extends BranchTabEvent{
  final BranchTabName tab;
  const BrcOnChangedEvent(this.tab);
  @override
  List<Object?> get props => [tab];
}