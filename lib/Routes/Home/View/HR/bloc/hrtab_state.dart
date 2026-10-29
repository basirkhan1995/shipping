part of 'hrtab_bloc.dart';

enum HrTabName {employees, attendance, users}

class HrTabState extends Equatable {
  final HrTabName tabs;
  const HrTabState({this.tabs = HrTabName.employees});
  @override
  List<Object> get props => [tabs];
}