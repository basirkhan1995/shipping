part of 'eoy_bloc.dart';

sealed class EoyEvent extends Equatable {
  const EoyEvent();
}

class ProcessPLEvent extends EoyEvent{
  final String usrName;
  final String remark;
  final int branchCode;
  const ProcessPLEvent(this.usrName, this.remark, this.branchCode);
  @override
  List<Object?> get props => [usrName, remark, branchCode];
}

class LoadPLEvent extends EoyEvent{
  @override
  List<Object?> get props => [];
}