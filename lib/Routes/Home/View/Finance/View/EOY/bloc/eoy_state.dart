part of 'eoy_bloc.dart';

sealed class EoyState extends Equatable {
  const EoyState();
}

final class EoyInitial extends EoyState {
  @override
  List<Object> get props => [];
}

final class EoyLoadingState extends EoyState {
  @override
  List<Object> get props => [];
}

final class EoyErrorState extends EoyState {
  final String error;
  const EoyErrorState(this.error);
  @override
  List<Object> get props => [error];
}

final class EoySuccessState extends EoyState {
  @override
  List<Object> get props => [];
}

final class EoyLoadedState extends EoyState {
  final List<PAndLModel> eoy;
  const EoyLoadedState(this.eoy);
  @override
  List<Object> get props => [eoy];
}

