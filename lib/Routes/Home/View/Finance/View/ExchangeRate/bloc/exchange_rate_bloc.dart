// lib/features/exchange/bloc/exchange_rate_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/ex_rate_model.dart';

part 'exchange_rate_event.dart';
part 'exchange_rate_state.dart';

class ExchangeRateBloc extends Bloc<ExchangeRateEvent, ExchangeRateState> {
  final Repositories _repo;
  int _requestId = 0;

  ExchangeRateBloc(this._repo) : super(ExchangeRateInitial()) {
    // ── LOAD list ─────────────────────────────────────────────────
    on<LoadExchangeRateEvent>((event, emit) async {
      // Preserve existing data.
      List<ExchangeRateModel>? currentRates;
      String? currentSingleRate;
      String? currentFrom;
      String? currentTo;
      if (state is ExchangeRateLoadedState) {
        final s = state as ExchangeRateLoadedState;
        currentRates = s.rates;
        currentSingleRate = s.rate;
        currentFrom = s.fromCcy;
        currentTo = s.toCcy;
      }

      // Only show the full-screen loader if there's nothing to display.
      if (currentRates == null || currentRates.isEmpty) {
        emit(ExchangeRateLoadingState());
      }

      try {
        final rates = await _repo.getExchangeRate(ccyCode: event.ccyCode);
        emit(ExchangeRateLoadedState(
          rates: rates,
          rate: currentSingleRate,
          fromCcy: currentFrom,
          toCcy: currentTo,
          requestId: ++_requestId,
        ));
      } on ApiException catch (e) {
        if (currentRates != null && currentRates.isNotEmpty) {
          emit(ExchangeRateLoadedState(
            rates: currentRates,
            rate: currentSingleRate,
            fromCcy: currentFrom,
            toCcy: currentTo,
            requestId: ++_requestId,
          ));
        } else {
          emit(ExchangeRateErrorState(e.message));
        }
      } catch (e) {
        if (currentRates != null && currentRates.isNotEmpty) {
          emit(ExchangeRateLoadedState(
            rates: currentRates,
            rate: currentSingleRate,
            fromCcy: currentFrom,
            toCcy: currentTo,
            requestId: ++_requestId,
          ));
        } else {
          emit(ExchangeRateErrorState(e.toString()));
        }
      }
    });

    // ── GET single rate (used by FX transaction forms) ────────────
    on<GetExchangeRateEvent>((event, emit) async {
      // Same-currency pairs → rate is 1.0, no API call.
      if (event.fromCcy == event.toCcy) {
        final rates = state is ExchangeRateLoadedState
            ? (state as ExchangeRateLoadedState).rates
            : const <ExchangeRateModel>[];
        emit(ExchangeRateLoadedState(
          rates: rates,
          rate: '1',
          fromCcy: event.fromCcy,
          toCcy: event.toCcy,
          requestId: ++_requestId,
        ));
        return;
      }

      // Preserve existing list.
      List<ExchangeRateModel>? currentRates;
      if (state is ExchangeRateLoadedState) {
        currentRates = (state as ExchangeRateLoadedState).rates;
      }

      try {
        final rate = await _repo.getSingleRate(
          fromCcy: event.fromCcy,
          toCcy: event.toCcy,
        );
        emit(ExchangeRateLoadedState(
          rates: currentRates ?? const [],
          rate: rate,
          fromCcy: event.fromCcy,
          toCcy: event.toCcy,
          requestId: ++_requestId,
        ));
      } on ApiException catch (e) {
        emit(ExchangeRateErrorState(e.message));
      } catch (e) {
        emit(ExchangeRateErrorState(e.toString()));
      }
    });

    // ── ADD ───────────────────────────────────────────────────────
    on<AddExchangeRateEvent>((event, emit) async {
      emit(ExchangeRateLoadingState());
      try {
        await _repo.addExchangeRate(newRate: event.newRate);
        emit(ExchangeRateSuccessState());
        // Refresh the list using the base currency carried by the event.
        add(LoadExchangeRateEvent(event.baseCcy ?? ''));
      } on ApiException catch (e) {
        emit(ExchangeRateErrorState(e.message));
      } catch (e) {
        emit(ExchangeRateErrorState(e.toString()));
      }
    });
  }
}