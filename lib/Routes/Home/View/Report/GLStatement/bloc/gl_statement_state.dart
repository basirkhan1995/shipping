part of 'gl_statement_bloc.dart';

sealed class GlStatementState extends Equatable {
  const GlStatementState();
}

final class GlStatementInitial extends GlStatementState {
  @override
  List<Object> get props => [];
}

final class GlStatementLoadingState extends GlStatementState{
  @override
  List<Object> get props => [];
}

final class GlStatementLoadedState extends GlStatementState{
  final GlStatementModel stmt;
  const GlStatementLoadedState({required this.stmt});
  @override
  List<Object> get props => [stmt];
}

final class GlStatementErrorState extends GlStatementState{
  final String message;
  const GlStatementErrorState(this.message);
  @override
  List<Object> get props => [message];
}