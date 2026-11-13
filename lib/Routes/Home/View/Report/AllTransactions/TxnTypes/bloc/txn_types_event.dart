part of 'txn_types_bloc.dart';

sealed class TxnTypesEvent extends Equatable {
  const TxnTypesEvent();
}

class LoadTxnTypesEvent extends TxnTypesEvent{
  final String? trnCode;
  const LoadTxnTypesEvent({this.trnCode});
  @override
  List<Object?> get props => [trnCode];
}

class AddTxnTypeEvent extends TxnTypesEvent{
  final TxnTypeModel newType;
  const AddTxnTypeEvent(this.newType);
  @override
  List<Object?> get props => [newType];
}

class UpdateTxnTypeEvent extends TxnTypesEvent{
  final TxnTypeModel newType;
  const UpdateTxnTypeEvent(this.newType);
  @override
  List<Object?> get props => [newType];
}

class DeleteTxnTypeEvent extends TxnTypesEvent{
  final String trnCode;
  const DeleteTxnTypeEvent(this.trnCode);
  @override
  List<Object?> get props => [trnCode];
}