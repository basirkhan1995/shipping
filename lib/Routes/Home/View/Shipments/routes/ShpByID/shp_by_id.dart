// lib/.../ShpById/shp_by_id_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Services/repository.dart';

import '../../../../../Auth/bloc/auth_bloc.dart';
import 'bloc/shp_by_id_bloc.dart';
import 'model/shp_details_model.dart';
import 'shp_by_id_form.dart';

class ShpByIdView extends StatelessWidget {
  final int shpId;
  const ShpByIdView({super.key, required this.shpId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
      ShpByIdBloc(context.read<Repositories>())
        ..add(ShpByIdLoadRequested(shpId)),
      child: _ShpByIdBody(shpId: shpId),
    );
  }
}

class _ShpByIdBody extends StatelessWidget {
  final int shpId;
  const _ShpByIdBody({required this.shpId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShpByIdBloc, ShpByIdState>(
      listenWhen: (prev, curr) =>
      curr is ShpByIdLoaded &&
          (curr.successMessage != null || curr.actionError != null),
      listener: (context, state) {
        if (state is! ShpByIdLoaded) return;
        if (state.successMessage != null) {
          _toast(context, state.successMessage!);
        } else if (state.actionError != null) {
          _toast(context, state.actionError!, isError: true);
          context
              .read<ShpByIdBloc>()
              .add(const ShpByIdActionErrorCleared());
        }
      },
      builder: (context, state) {
        if (state is ShpByIdLoading && state.previous == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ShpByIdError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Shipment')),
            body: _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<ShpByIdBloc>()
                  .add(ShpByIdLoadRequested(shpId)),
            ),
          );
        }

        final details = state is ShpByIdLoaded
            ? state.details
            : state is ShpByIdLoading
            ? state.previous!
            : null;

        if (details == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final loaded = state is ShpByIdLoaded ? state : null;
        final isMutating = loaded?.isMutating ?? false;
        final pending = loaded?.pendingAction;
        final color = Theme.of(context).colorScheme;

        return Scaffold(
          backgroundColor: color.surfaceContainerLow,
          appBar: AppBar(
            backgroundColor: color.surface,
            elevation: 0.5,
            surfaceTintColor: color.surface,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.shipment.containerNo ?? 'Container',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color.onSurface,
                  ),
                ),
                Text(
                  details.shipment.shpReference,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ZOutlineButton(
                  isActive: true,
                  height: 36,
                  width: 130,
                  icon: Icons.add,
                  label: const Text('Add Item'),
                  disable: isMutating,
                  onPressed: () => _openItemDialog(context, shpId, null),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<ShpByIdBloc>().add(ShpByIdRefreshed(shpId));
            },
            child: Column(
              children: [
                _ShipmentHeaderStrip(shipment: details.shipment),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: const _ItemsTableHeader(),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: _ItemsList(
                      items: details.items,
                      shpId: shpId,
                      isMutating: isMutating,
                      pendingAction: pending,
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _TotalRentBar(items: details.items),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared column widths
// ─────────────────────────────────────────────────────────────────────────────
class _Cols {
  static const double indexW = 36;
  static const int itemFlex = 6;
  static const int customerFlex = 4;
  static const double qtyW = 70;
  static const double cbmW = 80;
  static const double weightW = 95;
  static const double weightAvgW = 105;
  static const double rateCbmW = 95;
  static const double rateKgW = 95;
  static const double extraW = 90;
  static const double rentW = 110;
  static const double statusW = 100;
  static const double datesW = 120;
  static const double actionsW = 40;

  static const double totalFixed =
      indexW + qtyW + cbmW + weightW + weightAvgW + rateCbmW + rateKgW +
          extraW + rentW + statusW + datesW + actionsW;

  static const double minTableWidth = totalFixed + 400;
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER STRIP (includes container number, radius 5)
// ─────────────────────────────────────────────────────────────────────────────
class _ShipmentHeaderStrip extends StatelessWidget {
  final ShipmentModel shipment;
  const _ShipmentHeaderStrip({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statusPill(shipment.status ?? 'pending',context),
            _vDivider(color),
            _stat(Icons.inventory_2_outlined, 'Container',
                shipment.containerNo ?? '—',context),
            _vDivider(color),
            _stat(Icons.anchor_outlined, 'Port', shipment.portName ?? '—',context),
            _vDivider(color),
            _stat(Icons.tag_outlined, 'Seq', shipment.sequenceNo ?? '—',context),
            _vDivider(color),
            _stat(Icons.event_outlined, 'Loading',
                shipment.loadingDate ?? '—',context),
            _vDivider(color),
            _stat(Icons.event_available_outlined, 'Unloading',
                shipment.unloadingDate ?? '—',context),
            if ((shipment.description ?? '').isNotEmpty) ...[
              _vDivider(color),
              _stat(Icons.notes_outlined, 'Description',
                  shipment.description!,context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _vDivider(ColorScheme color) => Container(
    height: 26,
    width: 1,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: color.outlineVariant.withValues(alpha: 0.4),
  );

  Widget _stat(IconData icon, String label, String value, BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color.onSurfaceVariant),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusPill(String status,BuildContext context) {
    final color = Theme.of(context).colorScheme;
    late final Color bg;
    late final Color fg;
    late final String label;

    switch (status) {
      case 'delivered':
        bg = color.primaryContainer;
        fg = color.onPrimaryContainer;
        label = 'DELIVERED';
        break;
      case 'shipped':
        bg = color.secondaryContainer;
        fg = color.onSecondaryContainer;
        label = 'SHIPPED';
        break;
      case 'partiallyDelivered':
        bg = color.tertiaryContainer;
        fg = color.onTertiaryContainer;
        label = 'PARTIAL';
        break;
      default:
        bg = color.surfaceContainerHighest;
        fg = color.onSurfaceVariant;
        label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: .6,
          color: fg,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TABLE HEADER — includes `#` column
// ─────────────────────────────────────────────────────────────────────────────
class _ItemsTableHeader extends StatelessWidget {
  const _ItemsTableHeader();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
      letterSpacing: 0.8,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: color.onSurface,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _Cols.minTableWidth;

        final headerRow = Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color.primary, width: 1.2),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: _Cols.indexW,
                child: Text('#',
                    textAlign: TextAlign.center, style: style),
              ),
              Expanded(
                flex: _Cols.itemFlex,
                child: Text('ITEM',
                    textAlign: TextAlign.start, style: style),
              ),
              Expanded(
                flex: _Cols.customerFlex,
                child: Text('CUSTOMER / ACCOUNT',
                    textAlign: TextAlign.start, style: style),
              ),
              SizedBox(
                width: _Cols.qtyW,
                child: Text('QTY',
                    textAlign: TextAlign.end, style: style),
              ),
              SizedBox(
                width: _Cols.cbmW,
                child: Text('CBM',
                    textAlign: TextAlign.end, style: style),
              ),
              SizedBox(
                width: _Cols.weightW,
                child: Text('WEIGHT',
                    textAlign: TextAlign.end, style: style),
              ),
              SizedBox(
                width: _Cols.weightAvgW,
                child: Text('WEIGHT AVG',
                    textAlign: TextAlign.end, style: style),
              ),
              SizedBox(
                width: _Cols.rateCbmW,
                child: Text('RATE/CBM',
                    textAlign: TextAlign.end, style: style),
              ),
              SizedBox(
                width: _Cols.rateKgW,
                child: Text('RATE/KG',
                    textAlign: TextAlign.end, style: style),
              ),
              SizedBox(
                width: _Cols.extraW,
                child: Text('EXTRA',
                    textAlign: TextAlign.end, style: style),
              ),
              SizedBox(
                width: _Cols.rentW,
                child: Text('RENT',
                    textAlign: TextAlign.end, style: style),
              ),
              SizedBox(
                width: _Cols.statusW,
                child: Text('STATUS',
                    textAlign: TextAlign.center, style: style),
              ),
              SizedBox(
                width: _Cols.datesW,
                child: Text('ENTRY / UPDATED',
                    textAlign: TextAlign.start, style: style),
              ),
              const SizedBox(width: _Cols.actionsW),
            ],
          ),
        );

        return wide
            ? headerRow
            : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
              width: _Cols.minTableWidth, child: headerRow),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEMS LIST
// ─────────────────────────────────────────────────────────────────────────────
class _ItemsList extends StatelessWidget {
  final List<ShipmentItemModel> items;
  final int shpId;
  final bool isMutating;
  final ShpByIdAction? pendingAction;

  const _ItemsList({
    required this.items,
    required this.shpId,
    required this.isMutating,
    required this.pendingAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: color.outline),
              const SizedBox(height: 8),
              Text(
                'No items yet — tap Add Item to start',
                style: TextStyle(color: color.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _Cols.minTableWidth;

        final list = ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: .2),
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _ItemRow(
              item: item,
              index: index + 1, // 1-based index
              shpId: shpId,
              isOdd: index.isOdd,
              isMutating: isMutating,
              pendingAction: pendingAction,
            );
          },
        );

        return wide
            ? list
            : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: _Cols.minTableWidth, child: list),
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ShipmentItemModel item;
  final int index;
  final int shpId;
  final bool isOdd;
  final bool isMutating;
  final ShpByIdAction? pendingAction;

  const _ItemRow({
    required this.item,
    required this.index,
    required this.shpId,
    required this.isOdd,
    required this.isMutating,
    required this.pendingAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isBusy = isMutating &&
        (pendingAction == ShpByIdAction.updateItem ||
            pendingAction == ShpByIdAction.deleteItem);

    Widget numCell(
        String value,
        double width, {
          FontWeight? weight,
          Color? textColor,
        }) {
      return SizedBox(
        width: width,
        child: Text(
          value.isEmpty ? '—' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: weight,
            color: textColor ?? color.onSurface,
          ),
        ),
      );
    }

    return Opacity(
      opacity: isBusy ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: isOdd
              ? color.outline.withValues(alpha: .045)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // ── Index column ─────────────────────────────────────────
            SizedBox(
              width: _Cols.indexW,
              child: Text(
                '$index',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.onSurfaceVariant,
                ),
              ),
            ),
            // ── Item ────────────────────────────────────────────────
            Expanded(
              flex: _Cols.itemFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemDescription ?? 'Untitled item',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID #${item.shpItmId}',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: color.outline,
                    ),
                  ),
                ],
              ),
            ),
            // ── Customer / Account ─────────────────────────────────
            Expanded(
              flex: _Cols.customerFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fullName ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.perCode ?? '—'} · ${item.accountNo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: color.primary,
                    ),
                  ),
                ],
              ),
            ),
            numCell(_fmt(item.qty), _Cols.qtyW),
            numCell(_fmt(item.cbm, decimals: 3), _Cols.cbmW),
            numCell('${_fmt(item.weight, decimals: 2)} kg', _Cols.weightW),
            numCell('${_fmt(item.weightAvg, decimals: 2)} kg',
                _Cols.weightAvgW),
            numCell(_fmt(item.ratePerCbm, decimals: 2), _Cols.rateCbmW),
            numCell(_fmt(item.ratePerWeight, decimals: 2), _Cols.rateKgW),
            numCell('\$${_fmt(item.extraCharges, decimals: 2)}',
                _Cols.extraW),
            numCell(
              '\$${_fmt(item.itemRent, decimals: 2)}',
              _Cols.rentW,
              weight: FontWeight.w700,
              textColor: color.primary,
            ),
            SizedBox(
              width: _Cols.statusW,
              child: Center(
                child: _StatusChip(status: item.status ?? 'pending'),
              ),
            ),
            SizedBox(
              width: _Cols.datesW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _shortDate(item.entryDate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _shortDate(item.updatedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: color.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: _Cols.actionsW,
              child: _ItemMenu(
                item: item,
                shpId: shpId,
                disabled: isMutating,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso.replaceFirst(' ', 'T'));
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS CHIP (theme-driven)
// ─────────────────────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    late final Color bg;
    late final Color fg;
    late final String label;

    switch (status) {
      case 'delivered':
        bg = color.primaryContainer;
        fg = color.onPrimaryContainer;
        label = 'Delivered';
        break;
      case 'shipped':
        bg = color.secondaryContainer;
        fg = color.onSecondaryContainer;
        label = 'Shipped';
        break;
      case 'partiallyDelivered':
        bg = color.tertiaryContainer;
        fg = color.onTertiaryContainer;
        label = 'Partial';
        break;
      default:
        bg = color.surfaceContainerHighest;
        fg = color.onSurfaceVariant;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-DOT MENU
// ─────────────────────────────────────────────────────────────────────────────
enum _ItemMenuAction { edit, delete }

class _ItemMenu extends StatelessWidget {
  final ShipmentItemModel item;
  final int shpId;
  final bool disabled;

  const _ItemMenu({
    required this.item,
    required this.shpId,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return PopupMenuButton<_ItemMenuAction>(
      enabled: !disabled,
      icon: Icon(Icons.more_vert, size: 18, color: color.onSurfaceVariant),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case _ItemMenuAction.edit:
            _openItemDialog(context, shpId, item);
            break;
          case _ItemMenuAction.delete:
            _confirmDelete(context, item, shpId);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _ItemMenuAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Edit item'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ItemMenuAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: color.error),
              const SizedBox(width: 8),
              Text('Delete item', style: TextStyle(color: color.error)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM TOTAL RENT BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TotalRentBar extends StatelessWidget {
  final List<ShipmentItemModel> items;
  const _TotalRentBar({required this.items});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    final totalQty = items.fold<double>(0, (s, i) => s + i.qty);
    final totalCbm = items.fold<double>(0, (s, i) => s + i.cbm);
    final totalWeight = items.fold<double>(0, (s, i) => s + i.weight);
    final totalRent = items.fold<double>(0, (s, i) => s + i.itemRent);

    final totalDelivered =
    items.fold<double>(0, (s, i) => s + i.delivered);
    final totalReturned = items.fold<double>(0, (s, i) => s + i.returned);
    final pendingQty = totalQty - totalDelivered + totalReturned;

    final containerWeightAvg =
    totalCbm > 0 ? totalWeight / totalCbm : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: color.surface,
        boxShadow: [
          BoxShadow(
            color: color.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('Items', items.length.toString(),context),
              _miniStat('Qty', _fmt(totalQty),context),
              _miniStat('Pending',
                  _fmt(pendingQty < 0 ? 0 : pendingQty),context),
              _miniStat('CBM', _fmt(totalCbm, decimals: 2),context),
              _miniStat('Weight', '${_fmt(totalWeight)} kg',context),
              _miniStat('Weight Avg',
                  '${_fmt(containerWeightAvg, decimals: 2)} kg',context),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: color.outlineVariant),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total shipment rent',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color.onSurface,
                ),
              ),
              Text(
                '\$${_fmt(totalRent, decimals: 2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value,BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: color.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOWS
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _openItemDialog(
    BuildContext context,
    int shpId,
    ShipmentItemModel? existing,
    ) async {
  final bloc = context.read<ShpByIdBloc>();
  final state = bloc.state;
  if (state is! ShpByIdLoaded) return;

  final usrName = _currentUsername(context);
  if (usrName == null) {
    _toast(context, 'Not signed in. Please sign in again.', isError: true);
    return;
  }

  final result = await showShpItemForm(context, existing: existing);
  if (result == null) return;
  if (!context.mounted) return;

  if (existing == null) {
    bloc.add(ShpByIdAddItemRequested(
      shpId: shpId,
      usrName: usrName,
      accountNo: result.accountNo,
      itemDescription: result.itemDescription,
      qty: result.qty,
      cbm: result.cbm,
      weight: result.weight,
      ratePerCbm: result.ratePerCbm,
      ratePerWeight: result.ratePerWeight,
      extraCharges: result.extraCharges,
    ));
  } else {
    bloc.add(ShpByIdUpdateItemRequested(
      shpId: shpId,
      shpItmId: existing.shpItmId,
      usrName: usrName,
      accountNo: result.accountNo,
      itemDescription: result.itemDescription,
      qty: result.qty,
      cbm: result.cbm,
      weight: result.weight,
      ratePerCbm: result.ratePerCbm,
      ratePerWeight: result.ratePerWeight,
      extraCharges: result.extraCharges,
    ));
  }
}

Future<void> _confirmDelete(
    BuildContext context,
    ShipmentItemModel item,
    int shpId,
    ) async {
  final bloc = context.read<ShpByIdBloc>();
  final usrName = _currentUsername(context);
  if (usrName == null) {
    _toast(context, 'Not signed in. Please sign in again.', isError: true);
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final color = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: const Text('Delete item?'),
        content: Text(
          'Are you sure you want to delete '
              '"${item.itemDescription ?? 'this item'}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;
  if (!context.mounted) return;

  bloc.add(ShpByIdDeleteItemRequested(
    shpId: shpId,
    shpItmId: item.shpItmId,
    usrName: usrName,
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String? _currentUsername(BuildContext context) {
  final state = context.read<AuthBloc>().state;
  if (state is! AuthenticatedState) return null;
  final name = state.loginData.usrName?.trim();
  if (name == null || name.isEmpty) return null;
  return name;
}

void _toast(BuildContext context, String msg, {bool isError = false}) {
  ToastManager.show(
    context: context,
    message: msg,
    type: isError ? ToastType.error : ToastType.success,
  );
}

String _fmt(double v, {int decimals = 0}) {
  final s = v.toStringAsFixed(decimals);
  final parts = s.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return parts.length > 1 ? '${buf.toString()}.${parts[1]}' : buf.toString();
}