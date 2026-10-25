part of 'storage_bloc.dart';

sealed class StorageState extends Equatable {
  const StorageState();
}

final class StorageInitial extends StorageState {
  @override
  List<Object> get props => [];
}


final class StorageLoadingState extends StorageState {
  @override
  List<Object> get props => [];
}

final class StorageSuccessState extends StorageState {
  @override
  List<Object> get props => [];
}

final class StorageLoadedState extends StorageState {
  final List<StorageModel> storage;
  const StorageLoadedState(this.storage);
  @override
  List<Object> get props => [storage];
}

final class StorageErrorState extends StorageState {
  final String error;
  const StorageErrorState(this.error);
  @override
  List<Object> get props => [error];
}


