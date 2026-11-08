part of 'pro_cat_bloc.dart';

sealed class ProCatState extends Equatable {
  const ProCatState();
}

final class ProCatInitial extends ProCatState {
  @override
  List<Object> get props => [];
}

final class ProCatSuccessState extends ProCatState {
  @override
  List<Object> get props => [];
}

final class ProCatErrorState extends ProCatState {
  final String message;
  const ProCatErrorState(this.message);
  @override
  List<Object> get props => [message];
}


final class ProCatLoadingState extends ProCatState {
  @override
  List<Object> get props => [];
}

final class ProCatLoadedState extends ProCatState {
  final List<ProCategoryModel> proCategory;
  const ProCatLoadedState(this.proCategory);
  @override
  List<Object> get props => [proCategory];
}
