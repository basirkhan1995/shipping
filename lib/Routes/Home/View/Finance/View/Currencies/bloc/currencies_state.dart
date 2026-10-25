part of 'currencies_bloc.dart';

sealed class CurrenciesState extends Equatable {
  const CurrenciesState();
}

final class CurrenciesInitial extends CurrenciesState {
  @override
  List<Object?> get props => [];
}

final class CurrenciesLoadingState extends CurrenciesState {
  /// Keep last-known data so views don't flash empty during reload.
  final Map<int?, List<CurrenciesModel>> previous;

  const CurrenciesLoadingState({this.previous = const {}});

  @override
  List<Object?> get props => [previous];
}

final class CurrenciesSuccessState extends CurrenciesState {
  @override
  List<Object?> get props => [];
}

final class CurrenciesErrorState extends CurrenciesState {
  final String message;
  const CurrenciesErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class CurrenciesLoadedState extends CurrenciesState {
  /// Key = the `status` filter used to fetch the slice.
  /// `null` = all, `1` = active only, `0` = inactive only.
  final Map<int?, List<CurrenciesModel>> byStatus;

  const CurrenciesLoadedState(this.byStatus);

  /// The "all currencies" slice used by the Finance view.
  List<CurrenciesModel> get all => byStatus[null] ?? const [];

  /// The "active only" slice used by currency selectors.
  List<CurrenciesModel> get active => byStatus[1] ?? const [];

  List<CurrenciesModel> forStatus(int? status) =>
      byStatus[status] ?? const [];

  bool hasStatus(int? status) => byStatus.containsKey(status);

  @override
  List<Object?> get props => [byStatus];
}