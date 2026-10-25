part of 'gl_accounts_bloc.dart';

sealed class GlAccountsState extends Equatable {
  const GlAccountsState();
}

final class GlAccountsInitial extends GlAccountsState {
  @override
  List<Object> get props => [];
}

final class GlSuccessState extends GlAccountsState {
  @override
  List<Object> get props => [];
}

final class GlAccountsLoadingState extends GlAccountsState {
  @override
  List<Object> get props => [];
}

final class GlAccountLoadedState extends GlAccountsState {
  final List<GlAccountsModel> gl;
  const GlAccountLoadedState(this.gl);
  @override
  List<Object> get props => [gl];
}

final class GlAccountsErrorState extends GlAccountsState {
  final String message;
  const GlAccountsErrorState(this.message);
  @override
  List<Object> get props => [message];
}