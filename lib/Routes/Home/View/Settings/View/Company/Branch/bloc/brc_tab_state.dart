part of 'brc_tab_bloc.dart';

enum BranchTabName {overview, limits}

class BranchTabState extends Equatable {
  final BranchTabName tab;
  const BranchTabState({this.tab = BranchTabName.overview});
  @override
  List<Object> get props => [tab];
}
