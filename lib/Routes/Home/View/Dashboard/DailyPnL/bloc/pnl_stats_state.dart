import '../profit_loss_model.dart';

abstract class PnLChartState {
  const PnLChartState();
}

class PnLChartInitial extends PnLChartState {
  const PnLChartInitial();
}

class PnLChartLoading extends PnLChartState {
  const PnLChartLoading();
}

class PnLChartLoaded extends PnLChartState {
  final PnLChartModel data;
  final bool isRefreshing;

  const PnLChartLoaded(this.data, {this.isRefreshing = false});
}

class PnLChartError extends PnLChartState {
  final String message;
  const PnLChartError(this.message);
}