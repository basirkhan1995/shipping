import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../../Services/api_exception.dart';
import '../../../../../../../../Services/repository.dart';
import '../model/storage_model.dart';

part 'storage_event.dart';
part 'storage_state.dart';

class StorageBloc extends Bloc<StorageEvent, StorageState> {
  final Repositories _repo;

  StorageBloc(this._repo) : super(StorageInitial()) {
    // ── LOAD ────────────────────────────────────────────────────────
    on<LoadStorageEvent>((event, emit) async {
      emit(StorageLoadingState());
      try {
        final storage = await _repo.getStorage();
        emit(StorageLoadedState(storage));
      } on ApiException catch (e) {
        emit(StorageErrorState(e.message));
      } catch (e) {
        emit(StorageErrorState(e.toString()));
      }
    });

    // ── ADD ────────────────────────────────────────────────────────
    on<AddStorageEvent>((event, emit) async {
      emit(StorageLoadingState());
      try {
        await _repo.addStorage(newStorage: event.newStorage);
        emit(StorageSuccessState());
        add(LoadStorageEvent());
      } on ApiException catch (e) {
        emit(StorageErrorState(e.message));
      } catch (e) {
        emit(StorageErrorState(e.toString()));
      }
    });

    // ── UPDATE ──────────────────────────────────────────────────────
    on<UpdateStorageEvent>((event, emit) async {
      emit(StorageLoadingState());
      try {
        await _repo.updateStorage(newStorage: event.newStorage);
        emit(StorageSuccessState());
        add(LoadStorageEvent());
      } on ApiException catch (e) {
        emit(StorageErrorState(e.message));
      } catch (e) {
        emit(StorageErrorState(e.toString()));
      }
    });
  }
}