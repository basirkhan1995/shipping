abstract class PnLChartEvent {
  const PnLChartEvent();
}

class LoadPnLChartEvent extends PnLChartEvent {
  final int days;
  const LoadPnLChartEvent({this.days = 30});
}