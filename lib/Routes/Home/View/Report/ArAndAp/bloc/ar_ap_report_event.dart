import 'package:equatable/equatable.dart';

abstract class ArApReportEvent extends Equatable {
  const ArApReportEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load or "refresh" — uses current filters held in state.
class LoadArApReport extends ArApReportEvent {
  const LoadArApReport();
}

/// User changed the header filters (currency, type, name, include zero).
class FilterArApReport extends ArApReportEvent {
  final String? name;
  final String? ccy;
  final String? type;         // '' | 'ar' | 'ap'
  final bool? includeZero;

  const FilterArApReport({
    this.name,
    this.ccy,
    this.type,
    this.includeZero,
  });

  @override
  List<Object?> get props => [name, ccy, type, includeZero];
}