import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Features/Widgets/ztextfield.dart';
import 'package:shipping/Services/repository.dart';
import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import 'bloc/shp_by_id_bloc.dart';
import 'model/shp_details_model.dart';

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

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            surfaceTintColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.shipment.containerNo ?? 'Container',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  details.shipment.shpReference,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
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
                _ItemsTableHeader(),
                const SizedBox(height: 4),
                Expanded(
                  child: _ItemsList(
                    items: details.items,
                    shpId: shpId,
                    isMutating: isMutating,
                    pendingAction: pending,
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
// HEADER STRIP — horizontal, compact (no tall key/value block)
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statusPill(shipment.status ?? 'pending'),
            _vDivider(color),
            _stat(Icons.anchor_outlined, 'Port',
                shipment.portName ?? '—'),
            _vDivider(color),
            _stat(Icons.tag_outlined, 'Seq',
                shipment.sequenceNo ?? '—'),
            _vDivider(color),
            _stat(Icons.event_outlined, 'Loading',
                shipment.loadingDate ?? '—'),
            _vDivider(color),
            _stat(Icons.event_available_outlined, 'Unloading',
                shipment.unloadingDate ?? '—'),
            if ((shipment.description ?? '').isNotEmpty) ...[
              _vDivider(color),
              _stat(Icons.notes_outlined, 'Description',
                  shipment.description!),
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

  Widget _stat(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusPill(String status) {
    late final Color bg;
    late final Color fg;
    late final String label;

    switch (status) {
      case 'delivered':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'DELIVERED';
        break;
      case 'shipped':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        label = 'SHIPPED';
        break;
      case 'partiallyDelivered':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'PARTIAL';
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF374151);
        label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
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
// ITEMS TABLE HEADER — matches your ShipmentsView table style
// ─────────────────────────────────────────────────────────────────────────────
class _ItemsTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
      letterSpacing: 0.8,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color.primary, width: 1.2)),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('ITEM', style: style)),
          Expanded(
              flex: 4,
              child: Text('CUSTOMER / ACCOUNT', style: style)),
          SizedBox(
              width: 80,
              child: Text('QTY',
                  textAlign: TextAlign.end, style: style)),
          SizedBox(
              width: 90,
              child: Text('CBM',
                  textAlign: TextAlign.end, style: style)),
          SizedBox(
              width: 105,
              child: Text('WEIGHT',
                  textAlign: TextAlign.end, style: style)),
          SizedBox(
              width: 110,
              child: Text('RENT',
                  textAlign: TextAlign.end, style: style)),
          SizedBox(
              width: 105,
              child: Text('STATUS',
                  textAlign: TextAlign.center, style: style)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEMS LIST — matches ShipmentsView row style
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined,
                  size: 40, color: color.outline),
              const SizedBox(height: 8),
              const Text(
                'No items yet — tap Add Item to start',
                style: TextStyle(
                    color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: color.outlineVariant.withValues(alpha: .2),
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ItemRow(
          item: item,
          shpId: shpId,
          isOdd: index.isOdd,
          isMutating: isMutating,
          pendingAction: pendingAction,
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ShipmentItemModel item;
  final int shpId;
  final bool isOdd;
  final bool isMutating;
  final ShpByIdAction? pendingAction;

  const _ItemRow({
    required this.item,
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

    Widget cell(
        String value, {
          int? flex,
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
      if (flex != null) return Expanded(flex: flex, child: child);
      return SizedBox(width: width, child: child);
    }

    return Opacity(
      opacity: isBusy ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: isOdd ? color.outline.withValues(alpha: .045) : null,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
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
            Expanded(
              flex: 4,
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
                  Text(
                    item.accountNo,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: color.primary,
                    ),
                  ),
                ],
              ),
            ),
            cell(_fmt(item.qty),
                width: 80, align: TextAlign.end),
            cell(_fmt(item.cbm, decimals: 3),
                width: 90, align: TextAlign.end),
            cell('${_fmt(item.weight, decimals: 2)} kg',
                width: 105, align: TextAlign.end),
            cell('\$${_fmt(item.itemRent, decimals: 2)}',
                width: 110,
                align: TextAlign.end,
                weight: FontWeight.w700,
                textColor: const Color(0xFF1E40AF)),
            SizedBox(
              width: 105,
              child: Center(
                child: _StatusChip(status: item.status ?? 'pending'),
              ),
            ),
            SizedBox(
              width: 40,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String label;

    switch (status) {
      case 'delivered':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'Delivered';
        break;
      case 'shipped':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        label = 'Shipped';
        break;
      case 'partiallyDelivered':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'Partial';
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF374151);
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
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
    return PopupMenuButton<_ItemMenuAction>(
      enabled: !disabled,
      icon: const Icon(Icons.more_vert,
          size: 18, color: Color(0xFF6B7280)),
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
      itemBuilder: (context) => const [
        PopupMenuItem(
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
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete item', style: TextStyle(color: Colors.red)),
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
    final totalQty = items.fold<double>(0, (s, i) => s + i.qty);
    final totalCbm = items.fold<double>(0, (s, i) => s + i.cbm);
    final totalWeight = items.fold<double>(0, (s, i) => s + i.weight);
    final totalWeightAvg = items.fold<double>(0, (s, i) => s + i.weightAvg);
    final totalRent = items.fold<double>(0, (s, i) => s + i.itemRent);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('Items', items.length.toString()),
              _miniStat('Qty', _fmt(totalQty)),
              _miniStat('CBM', _fmt(totalCbm, decimals: 2)),
              _miniStat('Weight', '${_fmt(totalWeight)} kg'),
              _miniStat('Weight Avg', '${_fmt(totalWeightAvg)} kg'),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total shipment rent',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                '\$${_fmt(totalRent, decimals: 2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Colors.redAccent),
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
// OPEN ADD / EDIT DIALOG
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _openItemDialog(
    BuildContext context,
    int shpId,
    ShipmentItemModel? existing,
    ) async {
  final bloc = context.read<ShpByIdBloc>();
  final state = bloc.state;
  if (state is! ShpByIdLoaded) return;

  final result = await showDialog<_ItemDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ItemDialog(existing: existing),
  );

  if (result == null) return;

  final usrName = _currentUsername(context);
  if (usrName == null) {
    _toast(context, 'Not signed in. Please sign in again.', isError: true);
    return;
  }

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
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
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
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final usrName = _currentUsername(context);
  if (usrName == null) {
    _toast(context, 'Not signed in. Please sign in again.', isError: true);
    return;
  }

  context.read<ShpByIdBloc>().add(ShpByIdDeleteItemRequested(
    shpId: shpId,
    shpItmId: item.shpItmId,
    usrName: usrName,
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEM DIALOG — uses your ZFormDialog + ZTextFieldEntitled + ZOutlineButton
// ─────────────────────────────────────────────────────────────────────────────
class _ItemDialogResult {
  final String accountNo;
  final String itemDescription;
  final double qty;
  final double cbm;
  final double weight;
  final double ratePerCbm;
  final double ratePerWeight;
  final double extraCharges;

  const _ItemDialogResult({
    required this.accountNo,
    required this.itemDescription,
    required this.qty,
    required this.cbm,
    required this.weight,
    required this.ratePerCbm,
    required this.ratePerWeight,
    required this.extraCharges,
  });
}

class _ItemDialog extends StatefulWidget {
  final ShipmentItemModel? existing;
  const _ItemDialog({this.existing});

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _accountNo;
  late final TextEditingController _description;
  late final TextEditingController _qty;
  late final TextEditingController _cbm;
  late final TextEditingController _weight;
  late final TextEditingController _ratePerCbm;
  late final TextEditingController _ratePerWeight;
  late final TextEditingController _extraCharges;

  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _accountNo = TextEditingController(text: e?.accountNo ?? '');
    _description = TextEditingController(text: e?.itemDescription ?? '');
    _qty = TextEditingController(text: e == null ? '' : _fmt(e.qty));
    _cbm =
        TextEditingController(text: e == null ? '' : _fmt(e.cbm, decimals: 4));
    _weight = TextEditingController(
        text: e == null ? '' : _fmt(e.weight, decimals: 3));
    _ratePerCbm = TextEditingController(
        text: e == null ? '' : _fmt(e.ratePerCbm, decimals: 4));
    _ratePerWeight = TextEditingController(
        text: e == null ? '' : _fmt(e.ratePerWeight, decimals: 4));
    _extraCharges = TextEditingController(
        text: e == null ? '' : _fmt(e.extraCharges, decimals: 2));
  }

  @override
  void dispose() {
    _accountNo.dispose();
    _description.dispose();
    _qty.dispose();
    _cbm.dispose();
    _weight.dispose();
    _ratePerCbm.dispose();
    _ratePerWeight.dispose();
    _extraCharges.dispose();
    super.dispose();
  }

  double _d(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0.0;

  void _submit() {
    setState(() => _error = null);

    if (_accountNo.text.trim().isEmpty) {
      setState(() => _error = 'Account No is required');
      return;
    }
    if (_description.text.trim().isEmpty) {
      setState(() => _error = 'Item description is required');
      return;
    }
    if (_qty.text.trim().isEmpty || _d(_qty) <= 0) {
      setState(() => _error = 'Qty must be greater than 0');
      return;
    }

    Navigator.of(context).pop(_ItemDialogResult(
      accountNo: _accountNo.text.trim(),
      itemDescription: _description.text.trim(),
      qty: _d(_qty),
      cbm: _d(_cbm),
      weight: _d(_weight),
      ratePerCbm: _d(_ratePerCbm),
      ratePerWeight: _d(_ratePerWeight),
      extraCharges: _d(_extraCharges),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ZFormDialog(
      title: _isEdit ? 'Edit item' : 'Add item',
      icon: _isEdit ? Icons.edit_outlined : Icons.add_box_outlined,
      width: 520,
      errorMessage: _error,
      onAction: _submit,
      actionLabel: Text(_isEdit ? 'Save changes' : 'Add item'),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Account No',
                      isRequired: true,
                      controller: _accountNo,
                      hint: 'e.g. 500005',
                      showClearButton: true,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Item description',
                      isRequired: true,
                      controller: _description,
                      hint: 'e.g. Car spare parts',
                      showClearButton: true,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Qty',
                      isRequired: true,
                      controller: _qty,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Extra charges',
                      controller: _extraCharges,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'CBM',
                      controller: _cbm,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Weight (kg)',
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Rate / CBM',
                      controller: _ratePerCbm,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: 'Rate / kg',
                      controller: _ratePerWeight,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Pulls the signed-in username from `AuthBloc`'s `AuthenticatedState`.
/// Returns `null` if not authenticated.
String? _currentUsername(BuildContext context) {
  final state = context.read<AuthBloc>().state;
  if (state is! AuthenticatedState) return null;
  final name = state.loginData.usrName?.trim();
  if (name == null || name.isEmpty) return null;
  return name;
}

  void _toast(BuildContext context, String msg, {bool isError = false}) {
  ToastManager.show(context: context, message: msg, type: isError? ToastType.error : ToastType.success);
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