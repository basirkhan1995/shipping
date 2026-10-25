part of 'gl_category_bloc.dart';

sealed class GlCategoryState extends Equatable {
  const GlCategoryState();
}

final class GlCategoryInitial extends GlCategoryState {
  @override
  List<Object> get props => [];
}


final class GlCategoryLoadedState extends GlCategoryState {
  final List<GlCategoriesModel> glCat;
  const GlCategoryLoadedState(this.glCat);
  @override
  List<Object> get props => [glCat];
}

final class GlCategoryLoadingState extends GlCategoryState {
  @override
  List<Object> get props => [];
}

final class GlCategorySuccessState extends GlCategoryState {
  @override
  List<Object> get props => [];
}


final class GlCategoryErrorState extends GlCategoryState {
  final String error;
  const GlCategoryErrorState(this.error);
  @override
  List<Object> get props => [error];
}


