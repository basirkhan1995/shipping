part of 'txn_types_bloc.dart';

sealed class TxnTypesState extends Equatable {
  const TxnTypesState();
}

final class TxnTypesInitial extends TxnTypesState {
  @override
  List<Object> get props => [];
}

final class TxnTypesLoadedState extends TxnTypesState {
  final List<TxnTypeModel> types;
  const TxnTypesLoadedState(this.types);
  @override
  List<Object> get props => [types];
}


final class TxnTypeLoadingState extends TxnTypesState {
  @override
  List<Object> get props => [];
}

final class TxnTypeErrorState extends TxnTypesState {
  final String message;
  const TxnTypeErrorState(this.message);
  @override
  List<Object> get props => [message];
}

final class TxnTypeSuccessState extends TxnTypesState {
  @override
  List<Object> get props => [];
}
