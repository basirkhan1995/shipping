import 'package:equatable/equatable.dart';
import '../model/ar_ap_model.dart';

abstract class ArApReportState extends Equatable {
  const ArApReportState();

  @override
  List<Object?> get props => [];
}

class ArApReportInitial extends ArApReportState {
  const ArApReportInitial();
}

class ArApReportLoading extends ArApReportState {
  /// Keep the previous filters so the UI doesn't reset the header
  /// while refreshing.
  final ArApFilters filters;

  const ArApReportLoading({required this.filters});

  @override
  List<Object?> get props => [filters];
}

class ArApReportLoaded extends ArApReportState {
  final ArApReportModel data;

  const ArApReportLoaded(this.data);

  // Convenience getters — the UI can render directly from these.
  List<ArApAccount> get receivables => data.receivables;
  List<ArApAccount> get payables => data.payables;
  ArApTotals get totals => data.totals;
  ArApFilters get filters => data.filters;

  @override
  List<Object?> get props => [data];
}

class ArApReportError extends ArApReportState {
  final String message;
  final ArApFilters filters;

  const ArApReportError({
    required this.message,
    required this.filters,
  });

  @override
  List<Object?> get props => [message, filters];
}