part of 'pro_cat_bloc.dart';

sealed class ProCatEvent extends Equatable {
  const ProCatEvent();
}

class LoadProCatEvent extends ProCatEvent{
  final int? catId;
  const LoadProCatEvent({this.catId});
  @override
  List<Object?> get props => [];
}

class AddProCatEvent extends ProCatEvent{
  final ProCategoryModel newProCat;
  const AddProCatEvent(this.newProCat);
  @override
  List<Object?> get props => [newProCat];
}

class UpdateProCatEvent extends ProCatEvent{
  final ProCategoryModel newProCat;
  const UpdateProCatEvent(this.newProCat);
  @override
  List<Object?> get props => [newProCat];
}

class DeleteProCatEvent extends ProCatEvent{
  final int catId;
  const DeleteProCatEvent(this.catId);
  @override
  List<Object?> get props => [catId];
}