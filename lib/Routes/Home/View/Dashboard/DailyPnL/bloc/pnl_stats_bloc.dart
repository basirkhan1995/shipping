import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/Dashboard/DailyPnL/bloc/pnl_stats_event.dart';
import 'package:shipping/Routes/Home/View/Dashboard/DailyPnL/bloc/pnl_stats_state.dart';
import '../../../../../../Services/api_exception.dart';
import '../../../../../../Services/repository.dart';


class PnLChartBloc extends Bloc<PnLChartEvent, PnLChartState> {
  final Repositories _repo;

  PnLChartBloc(this._repo) : super(const PnLChartInitial()) {
    on<LoadPnLChartEvent>(_onLoad);
  }

  Future<void> _onLoad(
      LoadPnLChartEvent event,
      Emitter<PnLChartState> emit,
      ) async {
    final current = state;

    // Show a subtle "refreshing" overlay when we already have data.
    if (current is PnLChartLoaded) {
      emit(PnLChartLoaded(current.data, isRefreshing: true));
    } else {
      emit(const PnLChartLoading());
    }

    try {
      final data = await _repo.getDailyPnL(days: event.days);
      emit(PnLChartLoaded(data));
    } on ApiException catch (e) {
      emit(PnLChartError(e.message));
    } catch (e) {
      emit(PnLChartError(e.toString()));
    }
  }
}