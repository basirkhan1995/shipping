part of 'gl_category_bloc.dart';

sealed class GlCategoryEvent extends Equatable {
  const GlCategoryEvent();
}

class LoadGlCategoriesEvent extends GlCategoryEvent{
  final int catId;
  const LoadGlCategoriesEvent(this.catId);
  @override
  List<Object?> get props => [catId];
}