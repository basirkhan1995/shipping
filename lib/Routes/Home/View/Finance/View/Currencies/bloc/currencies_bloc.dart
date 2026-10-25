import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/ccy_model.dart';

part 'currencies_event.dart';
part 'currencies_state.dart';

class CurrenciesBloc extends Bloc<CurrenciesEvent, CurrenciesState> {
  final Repositories _repo;

  CurrenciesBloc(this._repo) : super(CurrenciesInitial()) {
    // ── LOAD one slice ────────────────────────────────────────────────
    on<LoadCurrenciesEvent>((event, emit) async {
      final current = _currentMap();
      emit(CurrenciesLoadingState(previous: current));

      try {
        final ccy = await _repo.getCurrencies(status: event.status);
        current[event.status] = ccy;
        emit(CurrenciesLoadedState(current));
      } on ApiException catch (e) {
        // Keep whatever was already loaded for other screens.
        if (current.isNotEmpty) emit(CurrenciesLoadedState(current));
        emit(CurrenciesErrorState(e.message));
      } catch (e) {
        if (current.isNotEmpty) emit(CurrenciesLoadedState(current));
        emit(CurrenciesErrorState(e.toString()));
      }
    });

    // ── TOGGLE active flag ────────────────────────────────────────────
    on<UpdateCcyStatusEvent>((event, emit) async {
      try {
        await _repo.updateCcyStatus(
          status: event.status,
          ccyCode: event.ccyCode,
        );
        // Status affects BOTH the "all" and "active" slices.
        add(const LoadCurrenciesEvent());           // all
        add(const LoadCurrenciesEvent(status: 1));  // active
      } on ApiException catch (e) {
        emit(CurrenciesErrorState(e.message));
      } catch (e) {
        emit(CurrenciesErrorState(e.toString()));
      }
    });

    on<AddCcyEvent>((event, emit) async {
      final before = _currentMap();
      emit(CurrenciesLoadingState(previous: before));

      try {
        await _repo.addCurrency(ccy: event.ccy);

        final all = await _repo.getCurrencies(status: null);
        final active = await _repo.getCurrencies(status: 1);

        emit(CurrenciesSuccessState());
        emit(CurrenciesLoadedState({
          null: all,
          1: active,
        }));
      } on ApiException catch (e) {
        if (before.isNotEmpty) emit(CurrenciesLoadedState(before));
        emit(CurrenciesErrorState(e.message));
      } catch (e) {
        if (before.isNotEmpty) emit(CurrenciesLoadedState(before));
        emit(CurrenciesErrorState(e.toString()));
      }
    });

    on<UpdateCcyEvent>((event, emit) async {
      final before = _currentMap();
      emit(CurrenciesLoadingState(previous: before));

      try {
        await _repo.updateCurrency(ccy: event.ccy);

        final all = await _repo.getCurrencies(status: null);
        final active = await _repo.getCurrencies(status: 1);

        emit(CurrenciesSuccessState());
        emit(CurrenciesLoadedState({
          null: all,
          1: active,
        }));
      } on ApiException catch (e) {
        if (before.isNotEmpty) emit(CurrenciesLoadedState(before));
        emit(CurrenciesErrorState(e.message));
      } catch (e) {
        if (before.isNotEmpty) emit(CurrenciesLoadedState(before));
        emit(CurrenciesErrorState(e.toString()));
      }
    });
  }

  Map<int?, List<CurrenciesModel>> _currentMap() =>
      state is CurrenciesLoadedState
          ? Map<int?, List<CurrenciesModel>>.from(
        (state as CurrenciesLoadedState).byStatus,
      )
          : <int?, List<CurrenciesModel>>{};
}