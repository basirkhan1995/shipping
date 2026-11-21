import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/cover.dart';
import 'package:shipping/Features/Widgets/shimmer.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Services/repository.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../model/shp_model.dart';
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
    final tr = AppLocalizations.of(context)!;
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
          context.read<ShpByIdBloc>().add(const ShpByIdActionErrorCleared());
        }
      },
      builder: (context, state) {
        if (state is ShpByIdLoading && state.previous == null) {
          return Scaffold(
            body: Center(child: UniversalShimmer.dataList(itemCount: 15,numberOfColumns: 8)),
          );
        }

        if (state is ShpByIdError) {
          return Scaffold(
            appBar: AppBar(title: Text(tr.shipment)),
            body: _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<ShpByIdBloc>().add(ShpByIdLoadRequested(shpId)),
            ),
          );
        }

        final details = state is ShpByIdLoaded
            ? state.details
            : state is ShpByIdLoading
            ? state.previous!
            : null;

        if (details == null) {
          return Scaffold(
            body: Center(child: UniversalShimmer.dataList(itemCount: 15,numberOfColumns: 8)),
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
            titleSpacing: 0,
            surfaceTintColor: color.surface,
            actionsPadding: EdgeInsets.all(8),
            title: Text(
              '${details.shipment.containerNo} (${details.shipment.sequenceNo})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color.onSurface,
              ),
            ),
            actions: [
              ZOutlineButton(
                icon: Icons.refresh,
                label: Text(tr.refresh),
                disable: isMutating,
                onPressed: () => context.read<ShpByIdBloc>().add(
                  ShpByIdLoadRequested(shpId),
                ),
              ),
              SizedBox(width: 8),
              //Excel Export
              ZOutlineButton(
                icon: Icons.document_scanner_outlined,
                label: Text(tr.excelTitle),
                disable: isMutating,
                backgroundHover: Colors.green,
                onPressed: null,
              ),
              SizedBox(width: 8),
              //Invoice Print
              ZOutlineButton(
                icon: Icons.print_rounded,
                label: Text(tr.print),
                disable: isMutating,
                onPressed: null,
              ),
              SizedBox(width: 8),

              ///Expense Handling
              ZOutlineButton(
                icon: Icons.trending_down_rounded,
                label: Text(tr.expenseEntry),
                disable: isMutating,
                onPressed: null,
              ),
              SizedBox(width: 8),
              ZOutlineButton(
                isActive: true,
                icon: Icons.add,
                label: Text(tr.addItem),
                disable: isMutating,
                onPressed: () => _openItemDialog(context, shpId, null),
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
  static const int customerFlex = 3;
  static const double qtyW = 70;
  static const double cbmW = 80;
  static const double weightW = 95;
  static const double weightAvgW = 115;
  static const double rateCbmW = 95;
  static const double rateKgW = 95;
  static const double extraW = 90;
  static const double rentW = 110;
  static const double statusW = 100;
  static const double actionsW = 40;
  static const double totalFixed =
      indexW +
      qtyW +
      cbmW +
      weightW +
      weightAvgW +
      rateCbmW +
      rateKgW +
      extraW +
      rentW +
      statusW +
      actionsW;

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
    final tr = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _statusPill(shipment.status, context),
            _vDivider(color),
            _stat(
              Icons.inventory_2_outlined,
              tr.containerNo,
              shipment.containerNo ?? '—',
              context,
            ),
            _vDivider(color),
            _stat(
              Icons.anchor_outlined,
              tr.port,
              shipment.portName ?? '—',
              context,
            ),
            _vDivider(color),
            _stat(
              Icons.tag_outlined,
              tr.seq,
              shipment.sequenceNo ?? '—',
              context,
            ),
            _vDivider(color),
            _stat(
              Icons.date_range_rounded,
              tr.loadingDate,
              shipment.loadingDate ?? '—',
              context,
            ),
            _vDivider(color),
            _stat(
              Icons.event_available_outlined,
              tr.unloadingDate,
              shipment.unloadingDate ?? '—',
              context,
            ),
            if ((shipment.description ?? '').isNotEmpty) ...[
              _vDivider(color),
              _stat(
                Icons.notes_outlined,
                tr.description,
                shipment.description!,
                context,
              ),
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

  Widget _stat(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    final color = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZCover(
          radius: 50,
          padding: EdgeInsets.all(10),
          child: Icon(icon, size: 15, color: color.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusPill(String status, BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    late final Color bg;
    late final Color fg;
    late final String label;

    switch (status) {
      case 'delivered':
        bg = color.primaryContainer;
        fg = color.onPrimaryContainer;
        label = tr.delivered.toUpperCase();
        break;
      default:
        bg = color.surfaceContainerHighest;
        fg = color.onSurfaceVariant;
        label = tr.pending.toUpperCase();
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
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
      letterSpacing: 0.8,
      fontSize: 13,
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
                child: Text('#', textAlign: TextAlign.center, style: style),
              ),
              Expanded(
                flex: _Cols.itemFlex,
                child: Text(
                  tr.items.toUpperCase(),
                  textAlign: TextAlign.start,
                  style: style,
                ),
              ),
              Expanded(
                flex: _Cols.customerFlex,
                child: Text(
                  tr.customerAndAccount.toUpperCase(),
                  textAlign: TextAlign.start,
                  style: style,
                ),
              ),
              SizedBox(
                width: _Cols.qtyW,
                child: Text(
                  tr.qty.toUpperCase(),
                  textAlign: TextAlign.end,
                  style: style,
                ),
              ),
              SizedBox(
                width: _Cols.cbmW,
                child: Text(
                  tr.cbm.toUpperCase(),
                  textAlign: TextAlign.end,
                  style: style,
                ),
              ),
              SizedBox(
                width: _Cols.weightW,
                child: Text(
                  tr.weight.toUpperCase(),
                  textAlign: TextAlign.end,
                  style: style,
                ),
              ),
              SizedBox(
                width: _Cols.weightAvgW,
                child: Text(
                  tr.weightAvg.toUpperCase(),
                  textAlign: TextAlign.end,
                  style: style,
                ),
              ),
              SizedBox(
                width: _Cols.rateCbmW,
                child: Text(
                  tr.cbmRate.toUpperCase(),
                  textAlign: TextAlign.end,
                  style: style,
                ),
              ),
              SizedBox(
                width: _Cols.rateKgW,
                child: Text(
                  tr.weightRate.toUpperCase(),
                  textAlign: TextAlign.end,
                  style: style,
                ),
              ),
              SizedBox(
                width: _Cols.extraW,
                child: Text(
                  tr.extra.toUpperCase(),
                  textAlign: TextAlign.end,
                  style: style,
                ),
              ),
              SizedBox(
                width: _Cols.rentW,
                child: Text(
                  tr.rent.toUpperCase(),
                  textAlign: TextAlign.end,
                  style: style,
                ),
              ),
              SizedBox(
                width: _Cols.statusW,
                child: Text(
                  tr.status.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
              const SizedBox(width: _Cols.actionsW),
            ],
          ),
        );

        return wide
            ? headerRow
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: _Cols.minTableWidth, child: headerRow),
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
        Color hoverColor = Theme.of(context).colorScheme.primary.withValues(alpha: .07);
        final list = ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: .2),
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              highlightColor: hoverColor,
              hoverColor: hoverColor,
              splashColor: hoverColor,
              onTap: (){
                _openItemDialog(context, shpId, item);
              },
              child: _ItemRow(
                item: item,
                index: index + 1, // 1-based index
                shpId: shpId,
                isOdd: index.isOdd,
                isMutating: isMutating,
                pendingAction: pendingAction,
              ),
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

    final isBusy =
        isMutating &&
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
            fontSize: 13,
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
                      fontSize: 15,
                      color: color.onSurface,
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
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${item.perCode ?? '—'} · ${item.accountNo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: color.primary,
                    ),
                  ),
                ],
              ),
            ),
            numCell(_fmt(item.qty), _Cols.qtyW),
            numCell(_fmt(item.cbm, decimals: 3), _Cols.cbmW),
            numCell('${_fmt(item.weight, decimals: 2)} kg', _Cols.weightW),
            numCell('${_fmt(item.weightAvg, decimals: 2)} kg', _Cols.weightAvgW),
            numCell(_fmt(item.ratePerCbm, decimals: 2), _Cols.rateCbmW),
            numCell(_fmt(item.ratePerWeight, decimals: 2), _Cols.rateKgW),
            numCell(_fmt(item.extraCharges, decimals: 2), _Cols.extraW),
            numCell(_fmt(item.itemRent, decimals: 2), _Cols.rentW, weight: FontWeight.w700, textColor: color.primary),
            SizedBox(
              width: _Cols.statusW,
              child: Center(
                child: _StatusChip(status: item.status ?? ''),
              ),
            ),

            SizedBox(
              width: _Cols.actionsW,
              child: _ItemMenu(item: item, shpId: shpId, disabled: isMutating),
            ),
          ],
        ),
      ),
    );
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
    final tr = AppLocalizations.of(context)!;
    late final Color bg;
    late final Color fg;
    late final String label;

    switch (status) {
      case 'delivered':
        bg = color.primaryContainer;
        fg = color.onPrimaryContainer;
        label = tr.delivered;
        break;
      default:
        bg = Colors.amber.withValues(alpha: .08);
        fg = Colors.amber;
        label = tr.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: fg.withValues(alpha: .4), width: 0.1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-DOT MENU
// ─────────────────────────────────────────────────────────────────────────────
enum _ItemMenuAction { edit, delete, markDelivered, markPending }

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
          case _ItemMenuAction.markDelivered:
            _updateItemStatus(context, item, shpId, 'delivered');
            break;
          case _ItemMenuAction.markPending:
            _updateItemStatus(context, item, shpId, 'pending');
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ItemMenuAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.editItem),
            ],
          ),
        ),
        PopupMenuItem(
          value: (item.status ?? 'pending').toLowerCase() == 'delivered'
              ? _ItemMenuAction.markPending
              : _ItemMenuAction.markDelivered,
          child: Row(
            children: [
              Icon(
                (item.status ?? 'pending').toLowerCase() == 'delivered'
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
                color: (item.status ?? 'pending').toLowerCase() == 'delivered'
                    ? color.tertiary
                    : color.primary,
              ),
              const SizedBox(width: 8),
              Text(
                (item.status ?? 'pending').toLowerCase() == 'delivered'
                    ? AppLocalizations.of(context)!.markAsPending
                    : AppLocalizations.of(context)!.markAsDelivered,
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ItemMenuAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: color.error),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.deleteItem,
                style: TextStyle(color: color.error),
              ),
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
    final tr = AppLocalizations.of(context)!;

    final totalQty = items.fold<double>(
      0,
          (sum, item) => sum + item.qty,
    );

    final totalCbm = items.fold<double>(
      0,
          (sum, item) => sum + item.cbm,
    );

    final totalWeight = items.fold<double>(
      0,
          (sum, item) => sum + item.weight,
    );

    final totalRent = items.fold<double>(
      0,
          (sum, item) => sum + item.itemRent,
    );

    // Calculate quantities using the item's current status.
    final totalDelivered = items.fold<double>(
      0,
          (sum, item) =>
      sum + (item.status?.toLowerCase() == 'delivered' ? item.qty : 0),
    );

    final pendingQty = items.fold<double>(
      0,
          (sum, item) =>
      sum + (item.status?.toLowerCase() == 'pending' ? item.qty : 0),
    );

    final containerWeightAvg =
    totalCbm > 0 ? totalWeight / totalCbm : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: color.surface,
        border: Border.all(color: color.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: color.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat(tr.items, items.length.toString(), context),
              _miniStat(tr.qty, _fmt(totalQty), context),
              _miniStat(
                tr.notDeliveredYet,
                _fmt(pendingQty),
                context,
              ),
              _miniStat(
                tr.delivered,
                _fmt(totalDelivered),
                context,
              ),
              _miniStat(
                tr.cbm,
                _fmt(totalCbm, decimals: 3),
                context,
              ),
              _miniStat(
                tr.weight,
                '${_fmt(totalWeight)} kg',
                context,
              ),
              _miniStat(
                tr.weightAvg,
                '${_fmt(containerWeightAvg, decimals: 2)} kg',
                context,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: color.outlineVariant),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr.totalShipmentRent,
                style: TextStyle(
                  fontSize: 15,
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

  Widget _miniStat(
      String label,
      String value,
      BuildContext context,
      ) {
    final color = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
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
  final usrName = _currentUsername(context);
  if (usrName == null) {
    _toast(context, 'Not signed in. Please sign in again.', isError: true);
    return;
  }

  // The dialog now does the dispatch + waits for success itself.
  final result = await showShpItemForm(
    context,
    existing: existing,
    shpId: shpId,
    usrName: usrName,
  );

  // result is non-null only when the BLoC confirmed success.
  // (Dialog already re-fetched fresh details via the bloc.)
  if (result == null) return;
  if (!context.mounted) return;

  _toast(context, existing == null ? 'Item added' : 'Item updated');
}

Future<void> _updateItemStatus(
  BuildContext context,
  ShipmentItemModel item,
  int shpId,
  String targetStatus,
) async {
  final usrName = _currentUsername(context);
  if (usrName == null) {
    _toast(context, 'Not signed in. Please sign in again.', isError: true);
    return;
  }

  final bloc = context.read<ShpByIdBloc>();
  final isDelivered = targetStatus == 'delivered';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        isDelivered ? 'Mark item as delivered?' : 'Mark item as pending?',
      ),
      content: Text(
        isDelivered
            ? 'Set "${item.itemDescription ?? 'this item'}" status to Delivered?'
            : 'Reopen "${item.itemDescription ?? 'this item'}" and set its status to Pending?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(isDelivered ? 'Mark Delivered' : 'Mark Pending'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  bloc.add(
    ShpByIdUpdateItemStatusRequested(
      usrName: usrName,
      shpId: shpId,
      shpItmId: item.shpItmId,
      status: targetStatus,
    ),
  );
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

  bloc.add(
    ShpByIdDeleteItemRequested(
      shpId: shpId,
      shpItmId: item.shpItmId,
      usrName: usrName,
    ),
  );
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
