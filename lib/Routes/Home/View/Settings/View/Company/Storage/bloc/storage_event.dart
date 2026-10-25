part of 'storage_bloc.dart';

sealed class StorageEvent extends Equatable {
  const StorageEvent();
}

class LoadStorageEvent extends StorageEvent{
  @override
  List<Object?> get props => [];
}

class AddStorageEvent extends StorageEvent{
  final StorageModel newStorage;
  const AddStorageEvent(this.newStorage);
  @override
  List<Object?> get props => [newStorage];
}

class UpdateStorageEvent extends StorageEvent{
  final StorageModel newStorage;
  const UpdateStorageEvent(this.newStorage);
  @override
  List<Object?> get props => [newStorage];
}
