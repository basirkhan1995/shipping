
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../Services/repository.dart';
import '../model/ar_ap_model.dart';
import 'ar_ap_report_event.dart';
import 'ar_ap_report_state.dart';

class ArApReportBloc extends Bloc<ArApReportEvent, ArApReportState> {
  final Repositories _repo;

  /// Optional — used if you want a different starting filter when the
  /// bloc is registered in main.dart. The page can override it later.
  ArApReportBloc(this._repo, {String initialType = ''})
      : _filters = ArApFilters(
    name: '',
    ccy: '',
    type: initialType,
    includeZero: false,
  ),
        super(const ArApReportInitial()) {
    on<LoadArApReport>(_onLoad);
    on<FilterArApReport>(_onFilter);
  }

  ArApFilters _filters;

  Future<void> _onLoad(
      LoadArApReport event,
      Emitter<ArApReportState> emit,
      ) async {
    emit(ArApReportLoading(filters: _filters));

    try {
      final data = await _repo.getArApReport(
        name: _filters.name,
        ccy: _filters.ccy,
        type: _filters.type,
        includeZero: _filters.includeZero,
      );
      emit(ArApReportLoaded(data));
    } catch (e) {
      emit(ArApReportError(message: e.toString(), filters: _filters));
    }
  }

  Future<void> _onFilter(
      FilterArApReport event,
      Emitter<ArApReportState> emit,
      ) async {
    _filters = _filters.copyWith(
      name: event.name,
      ccy: event.ccy,
      type: event.type,
      includeZero: event.includeZero,
    );
    add(const LoadArApReport());
  }
}