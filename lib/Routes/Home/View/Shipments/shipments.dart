import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Other/responsive_widget.dart';
import 'package:shipping/Features/Widgets/extensions.dart';
import 'package:shipping/Features/Widgets/search_field.dart';
import 'package:shipping/Features/Widgets/no_data_widget.dart';
import 'package:shipping/Features/Widgets/shimmer.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Features/Date/z_range_picker.dart';
import 'package:shipping/Routes/Home/View/Stock/Orders/features/status_method.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../Features/Other/zdropdown.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import 'bloc/shipment_bloc.dart';
import 'bloc/shipment_event.dart';
import 'bloc/shipment_state.dart';
import 'model/shp_model.dart';

class ShipmentsView extends StatelessWidget {
  const ShipmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileView(),
      tablet: _TabletView(),
      desktop: _DesktopView(),
    );
  }
}

// -----------------------------------------------------------------------------
// MOBILE
// -----------------------------------------------------------------------------

class _MobileView extends StatelessWidget {
  const _MobileView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Shipments')),
    );
  }
}

// -----------------------------------------------------------------------------
// TABLET
// -----------------------------------------------------------------------------

class _TabletView extends StatelessWidget {
  const _TabletView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Shipments')),
    );
  }
}

// -----------------------------------------------------------------------------
// DESKTOP
// -----------------------------------------------------------------------------

class _DesktopView extends StatefulWidget {
  const _DesktopView();

  @override
  State<_DesktopView> createState() => _DesktopViewState();
}

class _DesktopViewState extends State<_DesktopView> {
  static const List<_ShipmentStatusOption> _statusOptions = [
    _ShipmentStatusOption('pending'),
    _ShipmentStatusOption('shipped'),
    _ShipmentStatusOption('delivered'),
    _ShipmentStatusOption('all'),
  ];

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late _ShipmentStatusOption _status;
  late String _from;
  late String _to;
  late final String _defaultDate;

  // Do not apply a date range on the initial request. This prevents older
  // pending shipments from being hidden by an automatic "today" filter.
  bool _dateFilterActive = false;

  @override
  void initState() {
    super.initState();

    _status = _statusOptions.first;

    final today = _iso(DateTime.now());
    _defaultDate = today;
    _from = today;
    _to = today;

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  String _iso(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  bool get _hasActiveFilters {
    return _status.value != 'pending' ||
        _dateFilterActive ||
        _searchCtrl.text.trim().isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // LOAD / REFRESH
  // ---------------------------------------------------------------------------

  void _reload() {
    context.read<ShipmentBloc>().add(
      LoadShipments(
        status: _status.value,
        search: _searchCtrl.text.trim().isEmpty
            ? null
            : _searchCtrl.text.trim(),
        from: _dateFilterActive ? _from : null,
        to: _dateFilterActive ? _to : null,
      ),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 250) {
      context.read<ShipmentBloc>().add(const LoadMoreShipments());
    }
  }

  void _clearFilters() {
    setState(() {
      _status = _statusOptions.first;
      _searchCtrl.clear();
      _dateFilterActive = false;
      _from = _defaultDate;
      _to = _defaultDate;
    });

    _reload();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthenticatedState) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: color.surface,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(textTheme, color),
            const SizedBox(height: 14),
            _buildFilters(color, textTheme),
            const SizedBox(height: 12),
            _buildTableHeader(color, textTheme),
            const SizedBox(height: 6),
            Expanded(child: _buildBody(color)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(TextTheme textTheme, ColorScheme color) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SHIPMENTS',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'CONTAINER AND SHIPMENT MANAGEMENT',
                style: textTheme.bodySmall?.copyWith(
                  color: color.outline,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        if (_hasActiveFilters) ...[
          _ShipmentPillButton(
            icon: Icons.filter_alt_off_outlined,
            label: 'Clear filters',
            onPressed: _clearFilters,
          ),
          const SizedBox(width: 8),
        ],
        _ShipmentPillButton(
          icon: Icons.refresh,
          label: 'Refresh',
          onPressed: _reload,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FILTERS
  // ---------------------------------------------------------------------------

  Widget _buildFilters(ColorScheme color, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 6,
          child: ReusableSearchBar(
            height: 41,
            controller: _searchCtrl,
            onChanged: (_) {
              setState(() {});
              _reload();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ZDropdown<_ShipmentStatusOption>(
            title: 'Status',
            items: _statusOptions,
            selectedItem: _status,
            initialValue: _statusLabel(_status),
            itemLabel: (item) => _statusLabel(item),
            height: 40,
            onItemSelected: (value) {
              setState(() => _status = value);
              _reload();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: ZRangeDatePicker(
            label: 'Loading date',
            startValue: _from,
            endValue: _to,
            onStartDateChanged: (value) {
              setState(() {
                _from = value;
                _dateFilterActive = true;
              });
              _reload();
            },
            onEndDateChanged: (value) {
              setState(() {
                _to = value;
                _dateFilterActive = true;
              });
              _reload();
            },
            gregorianTextStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _statusLabel(_ShipmentStatusOption status) {
    switch (status.value) {
      case 'all':
        return 'All statuses';
      case 'pending':
        return 'Pending';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      default:
        return status.value;
    }
  }

  // ---------------------------------------------------------------------------
  // TABLE HEADER
  // ---------------------------------------------------------------------------

  Widget _buildTableHeader(ColorScheme color, TextTheme textTheme) {
    final tr = AppLocalizations.of(context)!;
    final style = textTheme.titleSmall?.copyWith(
      letterSpacing: 0.8,
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: color.primary, width: 1.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 115, child: Text(tr.loadingDate.toUpperCase(), style: style)),
          SizedBox(width: 155, child: Text(tr.containerNo.toUpperCase(), style: style)),
          SizedBox(width: 190, child: Text(tr.reference.toUpperCase(), style: style)),
          SizedBox(width: 125, child: Text(tr.sequence.toUpperCase(), style: style)),
          Expanded(child: Text(tr.port.toUpperCase(), style: style)),
          SizedBox(
            width: 75,
            child: Text(tr.items, textAlign: TextAlign.end, style: style),
          ),
          SizedBox(
            width: 145,
            child: Text(tr.totalRent.toUpperCase(), textAlign: TextAlign.end, style: style),
          ),
          SizedBox(
            width: 105,
            child: Text(tr.status.toUpperCase(), textAlign: TextAlign.center, style: style),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------

  Widget _buildBody(ColorScheme color) {
    return BlocBuilder<ShipmentBloc, ShipmentState>(
      builder: (context, state) {
        if (state is ShipmentLoading) {
          return Center(
            child: UniversalShimmer.dataList(
              itemCount: 8,
              numberOfColumns: 7,
            ),
          );
        }

        if (state is ShipmentError) {
          return _buildError(state.message, color);
        }

        if (state is ShipmentLoaded) {
          if (state.shipments.isEmpty) {
            return _buildEmpty();
          }

          return _buildList(
            state.shipments,
            color,
            isLoadingMore: state.isLoadingMore,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildList(
      List<ShipmentModel> shipments,
      ColorScheme color, {
        required bool isLoadingMore,
      }) {
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: shipments.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: color.outlineVariant.withValues(alpha: .2),
      ),
      itemBuilder: (context, index) {
        if (index >= shipments.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _ShipmentRowWidget(
          shipment: shipments[index],
          isOdd: index.isOdd,
        );
      },
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: NoDataWidget(
        title: 'No shipments found',
        message: 'There are no containers matching your filters.',
        enableAction: false,
      ),
    );
  }

  Widget _buildError(String message, ColorScheme color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: color.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ZOutlineButton(
              label: const Text('Try again'),
              icon: Icons.refresh,
              onPressed: _reload,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SHIPMENT ROW
// -----------------------------------------------------------------------------

class _ShipmentRowWidget extends StatelessWidget {
  final ShipmentModel shipment;
  final bool isOdd;

  const _ShipmentRowWidget({
    required this.shipment,
    required this.isOdd,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget cell(
        String value, {
          double? width,
          TextAlign align = TextAlign.start,
          FontWeight? weight,
          Color? textColor,
        }) {
      final child = Text(
        value.isEmpty ? '—' : value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: textTheme.bodySmall?.copyWith(
          fontWeight: weight,
          color: textColor ?? color.onSurface,
        ),
      );

      return width == null
          ? Expanded(child: child)
          : SizedBox(width: width, child: child);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: isOdd ? color.outline.withValues(alpha: .045) : null,
      ),
      child: Row(
        children: [
          cell(shipment.loadingDate ?? '—', width: 115),
          cell(
            shipment.containerNo ?? '—',
            width: 155,
            weight: FontWeight.w600,
          ),
          cell(
            shipment.shpReference,
            width: 190,
            weight: FontWeight.w600,
            textColor: color.primary,
          ),
          cell(shipment.sequenceNo ?? '—', width: 125),
          cell(shipment.portName ?? '—'),
          cell(
            shipment.totalItems.toString(),
            width: 75,
            align: TextAlign.end,
          ),
          cell(
            shipment.totalRent.toAmount(),
            width: 145,
            align: TextAlign.end,
            weight: FontWeight.w700,
          ),
          SizedBox(
            width: 105,
            child: StatusDotIndicator(status: shipment.status),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STATUS OPTION
// -----------------------------------------------------------------------------

class _ShipmentStatusOption {
  final String value;

  const _ShipmentStatusOption(this.value);

  @override
  bool operator ==(Object other) =>
      other is _ShipmentStatusOption && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

// -----------------------------------------------------------------------------
// HEADER PILL BUTTON
// -----------------------------------------------------------------------------

class _ShipmentPillButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ShipmentPillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_ShipmentPillButton> createState() => _ShipmentPillButtonState();
}

class _ShipmentPillButtonState extends State<_ShipmentPillButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: widget.onPressed,
      onHover: (value) => setState(() => _hover = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _hover
              ? color.primary.withValues(alpha: .08)
              : color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: .3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 16, color: color.primary),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
