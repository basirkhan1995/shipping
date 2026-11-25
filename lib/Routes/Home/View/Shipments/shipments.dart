import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Date/shamsi_converter.dart';
import 'package:shipping/Features/Other/responsive_widget.dart';
import 'package:shipping/Features/Widgets/extensions.dart';
import 'package:shipping/Features/Widgets/search_field.dart';
import 'package:shipping/Features/Widgets/no_data_widget.dart';
import 'package:shipping/Features/Widgets/shimmer.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Features/Date/z_range_picker.dart';
import 'package:shipping/Routes/Home/View/Shipments/routes/ShpByID/shp_by_id.dart';
import 'package:shipping/Routes/Home/View/Shipments/shp_form.dart';
import 'package:shipping/Routes/Home/View/Stock/Orders/features/status_method.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../Features/Other/zdropdown.dart';
import '../../../../Features/Widgets/toast.dart';
import '../../../../Features/Widgets/znavigator.dart';
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

  late _ShipmentStatusOption _status;
  late String _from;
  late String _to;
  late final String _defaultDate;

  bool _dateFilterActive = false;

  /// Tracks which container numbers were copied within the last 2 seconds,
  /// so the icon can flip to a checkmark momentarily.
  final Map<String, bool> _copiedRefs = {};

  @override
  void initState() {
    super.initState();

    _status = _statusOptions.first;

    final today = _iso(DateTime.now());
    _defaultDate = today;
    _from = today;
    _to = today;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
  // SEARCH → OPEN CONTAINER DETAIL
  // ---------------------------------------------------------------------------

  void _onSearchSubmitted(String raw) {
    final query = raw.trim();

    if (query.isEmpty) {
      _reload();
      return;
    }

    context.read<ShipmentBloc>().add(ResolveShipmentByInput(query));
  }

  void _openDetailsById(int shpId) {
    ZNavigator.goto(
      BlocProvider.value(
        value: context.read<ShipmentBloc>(),
        child: ShpByIdView(shpId: shpId),
      ),
      context: context,
    );
  }

  void _showToast(String message, {bool isError = false}) {
    ToastManager.show(
      context: context,
      message: message,
      type: isError ? ToastType.error : ToastType.success,
    );
  }

  // ---------------------------------------------------------------------------
  // COPY ACTION
  // ---------------------------------------------------------------------------

  Future<void> _copyContainerNo(String containerNo) async {
    if (containerNo.isEmpty || containerNo == '—') return;

    await Clipboard.setData(ClipboardData(text: containerNo));

    if (!mounted) return;
    setState(() => _copiedRefs[containerNo] = true);

    _showToast('Copied: $containerNo');

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _copiedRefs.remove(containerNo));
    });
  }

  // ---------------------------------------------------------------------------
  // ROW ACTIONS
  // ---------------------------------------------------------------------------

  void _openDetails(ShipmentModel shipment) {
    _openDetailsById(shipment.shpId);
  }

  void _openEdit(ShipmentModel shipment) {
    ShipmentContainerDialog.show(context, shipment: shipment);
  }

  Future<void> _confirmDelete(ShipmentModel shipment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete container?'),
        content: Text(
          'Are you sure you want to delete container '
              '"${shipment.containerNo}"? '
              'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) return;

    context.read<ShipmentBloc>().add(
      DeleteShipment(
        usrName: authState.loginData.usrName ?? "",
        shpId: shipment.shpId,
      ),
    );
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

    return BlocListener<ShipmentBloc, ShipmentState>(
      listenWhen: (prev, curr) =>
      curr is ShipmentResolved ||
          curr is ShipmentResolveNotFound ||
          curr is ShipmentOperationError,
      listener: (context, state) {
        if (state is ShipmentResolved) {
          _openDetailsById(state.shpId);
        } else if (state is ShipmentResolveNotFound) {
          _showToast(
            'No container found for "${state.input}".',
            isError: true,
          );
        } else if (state is ShipmentOperationError) {
          _showToast(state.message, isError: true);
        }
      },
      child: Scaffold(
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(TextTheme textTheme, ColorScheme color) {
    final tr = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.shipments.toUpperCase(),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                tr.shipmentHint.toUpperCase(),
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
            label: tr.clearFilters,
            onPressed: _clearFilters,
          ),
          const SizedBox(width: 8),
        ],
        _ShipmentPillButton(
          icon: Icons.refresh,
          label: tr.refresh,
          onPressed: _reload,
        ),
        const SizedBox(width: 8),
        _ShipmentPillButton(
          icon: Icons.add,
          label: tr.addShipment,
          onPressed: () {
            ShipmentContainerDialog.show(context);
          },
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
            onSubmitted: _onSearchSubmitted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ZDropdown<_ShipmentStatusOption>(
            title: AppLocalizations.of(context)!.filterByStatus,
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
            label: AppLocalizations.of(context)!.dateFilter,
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
    final tr = AppLocalizations.of(context)!;
    switch (status.value) {
      case 'all':
        return tr.all;
      case 'pending':
        return tr.pending;
      case 'shipped':
        return tr.shipped;
      case 'delivered':
        return tr.delivered;
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
          SizedBox(
              width: 130,
              child: Text(tr.entryDate.toUpperCase(), style: style)),
          SizedBox(
              width: 180, // Increased from 155 to accommodate the copy button
              child: Text(tr.containerNo.toUpperCase(), style: style)),
          SizedBox(
              width: 125,
              child: Text(tr.sequence.toUpperCase(),
                  style: style, textAlign: TextAlign.start)),
          Expanded(child: Text(tr.port.toUpperCase(), style: style)),
          SizedBox(
            width: 75,
            child: Text(tr.totalQty, textAlign: TextAlign.center, style: style),
          ),
          SizedBox(
            width: 100,
            child: Text(tr.weight.toUpperCase(),
                textAlign: TextAlign.end, style: style),
          ),
          SizedBox(
            width: 100,
            child: Text(tr.cbm.toUpperCase(),
                textAlign: TextAlign.end, style: style),
          ),
          SizedBox(
            width: 145,
            child: Text(tr.totalRent.toUpperCase(),
                textAlign: TextAlign.end, style: style),
          ),
          SizedBox(
            width: 123,
            child: Text(tr.status.toUpperCase(),
                textAlign: TextAlign.end, style: style),
          ),
          const SizedBox(width: 40),
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
          return _buildList(state.shipments, color);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildList(List<ShipmentModel> shipments, ColorScheme color) {
    final hoverColor =
    Theme.of(context).colorScheme.primary.withValues(alpha: .07);

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: shipments.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: color.outlineVariant.withValues(alpha: .2),
      ),
      itemBuilder: (context, index) {
        final shipment = shipments[index];

        return InkWell(
          hoverColor: hoverColor,
          highlightColor: hoverColor,
          splashColor: hoverColor,
          onTap: () => _openDetails(shipment),
          child: _ShipmentRowWidget(
            shipment: shipment,
            isOdd: index.isOdd,
            onView: () => _openDetails(shipment),
            onEdit: () => _openEdit(shipment),
            onDelete: () => _confirmDelete(shipment),
            isCopied: _copiedRefs[shipment.containerNo] ?? false,
            onCopy: () => _copyContainerNo(shipment.containerNo),
          ),
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
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isCopied;
  final VoidCallback onCopy;

  const _ShipmentRowWidget({
    required this.shipment,
    required this.isOdd,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    this.isCopied = false,
    required this.onCopy,
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
          fontSize: 13,
          color: textColor ?? color.onSurface,
        ),
      );

      return width == null
          ? Expanded(child: child)
          : SizedBox(width: width, child: child);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOdd ? color.outline.withValues(alpha: .045) : null,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell(shipment.entryDate.shamsiDateString, width: 130),
              cell(
                shipment.entryDate.toFormattedDateTime(),
                width: 130,
                align: TextAlign.start,
              ),
            ],
          ),

          // ── CONTAINER NO + COPY ──────────────────────────────────────────
          SizedBox(
            width: 180, // Matches header
            child: Row(
              children: [
                _CopyRefButton(
                  isCopied: isCopied,
                  onPressed: onCopy,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    shipment.containerNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: color.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          cell(shipment.sequenceNo ?? '—', width: 125),
          cell(shipment.portName),
          cell(
            shipment.totalItems.toAmount(decimal: 0),
            width: 75,
            weight: FontWeight.bold,
            align: TextAlign.center,
          ),
          cell(
            "${shipment.totalWeight.toAmount()} kg",
            width: 100,
            align: TextAlign.end,
            weight: FontWeight.w700,
          ),
          cell(
            shipment.totalCbm.toAmount(decimal: 3),
            width: 100,
            align: TextAlign.end,
            weight: FontWeight.w700,
          ),
          cell(
            shipment.totalRent.toAmount(),
            width: 145,
            align: TextAlign.end,
            weight: FontWeight.w700,
          ),
          const SizedBox(width: 32),
          StatusDotIndicator(
            status: shipment.status,
            size: 15,
            showText: true,
            spacing: 3,
            textPosition: 'before',
          ),
          SizedBox(
            width: 40,
            child: _ShipmentRowMenu(
              onView: onView,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ROW 3-DOT MENU
// -----------------------------------------------------------------------------

enum _ShipmentRowAction { view, edit, delete }

class _ShipmentRowMenu extends StatelessWidget {
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShipmentRowMenu({
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return PopupMenuButton<_ShipmentRowAction>(
      icon: Icon(Icons.more_vert, size: 18, color: color.onSurfaceVariant),
      padding: EdgeInsets.zero,
      tooltip: 'Actions',
      splashRadius: 18,
      onSelected: (action) {
        switch (action) {
          case _ShipmentRowAction.view:
            onView();
            break;
          case _ShipmentRowAction.edit:
            onEdit();
            break;
          case _ShipmentRowAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ShipmentRowAction.view,
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.view),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ShipmentRowAction.edit,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.editContainer),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ShipmentRowAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: color.error),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.delete,
                style: TextStyle(color: color.error),
              ),
            ],
          ),
        ),
      ],
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

// -----------------------------------------------------------------------------
// COPY BUTTON
// -----------------------------------------------------------------------------

class _CopyRefButton extends StatelessWidget {
  final bool isCopied;
  final VoidCallback? onPressed;

  const _CopyRefButton({required this.isCopied, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Tooltip(
      message: isCopied ? 'Copied' : 'Copy container no',
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          hoverColor: color.primary.withValues(alpha: .05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCopied
                  ? color.primary.withAlpha(25)
                  : Colors.transparent,
              border: Border.all(
                color: isCopied
                    ? color.primary
                    : color.outline.withValues(alpha: .3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isCopied ? Icons.check : Icons.content_copy,
                  key: ValueKey<bool>(isCopied),
                  size: 13,
                  color: isCopied
                      ? color.primary
                      : color.outline.withValues(alpha: .6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}