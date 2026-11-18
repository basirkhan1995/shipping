import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shipping/Routes/Home/View/Dashboard/DailyPnL/profit_loss_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../../Features/Other/responsive_widget.dart';
import '../../../../../Features/Widgets/cover.dart';
import '../../../../../l10n/app_localizations.dart';
import 'bloc/pnl_stats_bloc.dart';
import 'bloc/pnl_stats_event.dart';
import 'bloc/pnl_stats_state.dart';

class PnLChartContent extends StatelessWidget {
  const PnLChartContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _PnLChartBody(),
      tablet: _PnLChartBody(),
      desktop: _PnLChartBody(),
    );
  }
}

class _PnLChartBody extends StatefulWidget {
  const _PnLChartBody();

  @override
  State<_PnLChartBody> createState() => _PnLChartBodyState();
}

class _PnLChartBodyState extends State<_PnLChartBody> {
  int days = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  void _loadData() {
    context.read<PnLChartBloc>().add(LoadPnLChartEvent(days: days));
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return ZCover(
      radius: 8,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header + range picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Text(
                  '${tr.incomeStatement} · ${tr.profitAndLoss}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: days,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 7,   child: Text('7 days')),
                    DropdownMenuItem(value: 30,  child: Text('30 days')),
                    DropdownMenuItem(value: 90,  child: Text('90 days')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => days = v);
                    _loadData();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 280,
            width: double.infinity,
            child: BlocBuilder<PnLChartBloc, PnLChartState>(
              builder: (context, state) {
                if (state is PnLChartError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }

                if (state is PnLChartLoaded && state.data.series.isNotEmpty) {
                  return Stack(
                    children: [
                      _buildChart(context, state.data),
                      if (state.isRefreshing)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: .8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  SfCartesianChart _buildChart(BuildContext context, PnLChartModel data) {
    final green = Colors.green.shade600;
    final red = Colors.red.shade600;
    final blue = Theme.of(context).colorScheme.primary;

    return SfCartesianChart(
      tooltipBehavior: TooltipBehavior(enable: true),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      ),
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      primaryXAxis: DateTimeAxis(
        intervalType: DateTimeIntervalType.days,
        dateFormat: DateFormat('MM/dd'),
        majorGridLines: const MajorGridLines(width: 0.2),
      ),
      primaryYAxis: NumericAxis(
        numberFormat: NumberFormat.compactCurrency(
          symbol: data.currency,
          decimalDigits: 0,
        ),
      ),
      series: <CartesianSeries>[
        AreaSeries<PnLPoint, DateTime>(
          dataSource: data.series,
          xValueMapper: (d, _) => d.day,
          yValueMapper: (d, _) => d.revenue,
          name: 'Revenue',
          borderColor: green,
          borderWidth: 2,
          gradient: LinearGradient(
            colors: [green.withValues(alpha: .25), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          markerSettings: const MarkerSettings(isVisible: false),
        ),
        LineSeries<PnLPoint, DateTime>(
          dataSource: data.series,
          xValueMapper: (d, _) => d.day,
          yValueMapper: (d, _) => d.expense,
          name: 'Expense',
          color: red,
          width: 2,
          markerSettings: const MarkerSettings(isVisible: false),
        ),
        LineSeries<PnLPoint, DateTime>(
          dataSource: data.series,
          xValueMapper: (d, _) => d.day,
          yValueMapper: (d, _) => d.profit,
          name: 'Profit',
          color: blue,
          width: 2.5,
          dashArray: const <double>[6, 3],
          markerSettings: const MarkerSettings(isVisible: false),
        ),
      ],
    );
  }
}