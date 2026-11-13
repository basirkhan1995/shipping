import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/shimmer.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import '../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../Features/Other/responsive_widget.dart';
import '../../../../../Features/Widgets/cover.dart';
import '../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../Features/Widgets/zbutton.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../Auth/bloc/auth_bloc.dart';
import 'add_shift.dart';
import 'bloc/goods_shift_bloc.dart';
import 'model/shift_model.dart';

// ------------------------------------------------------------------
// PUBLIC VIEW
// ------------------------------------------------------------------
class GoodsShiftView extends StatelessWidget {
  const GoodsShiftView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileGoodsShiftView(),
      tablet: _TabletGoodsShiftView(),
      desktop: _DesktopGoodsShiftView(),
    );
  }
}

// ------------------------------------------------------------------
// SHARED STATUS CHIP
// ------------------------------------------------------------------
Widget _statusChip(BuildContext context, String? stateText) {
  final color = Theme.of(context).colorScheme;
  final text = (stateText ?? 'Pending');
  final isPending = text.toLowerCase() == 'pending';

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: (isPending ? Colors.orange : color.primary)
          .withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isPending ? Colors.orange.shade800 : color.primary,
      ),
    ),
  );
}

// ------------------------------------------------------------------
// SHARED 3-DOT MENU (Edit / View / Delete)
// ------------------------------------------------------------------
Widget _rowMenu({
  required AppLocalizations tr,
  required VoidCallback onEdit,
  required VoidCallback onView,
  required VoidCallback onDelete,
}) {
  return PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert, size: 18),
    tooltip: tr.actions,
    onSelected: (value) {
      if (value == 'edit') onEdit();
      if (value == 'view') onView();
      if (value == 'delete') onDelete();
    },
    itemBuilder: (context) {
      final errorColor = Theme.of(context).colorScheme.error;
      return [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 16),
              const SizedBox(width: 8),
              Text(tr.edit),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              const Icon(Icons.visibility, size: 16),
              const SizedBox(width: 8),
              Text(tr.view),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: errorColor),
              const SizedBox(width: 8),
              Text(tr.delete, style: TextStyle(color: errorColor)),
            ],
          ),
        ),
      ];
    },
  );
}

// ------------------------------------------------------------------
// SHARED ACTIONS MIXIN
// ------------------------------------------------------------------
mixin _GoodsShiftActions<T extends StatefulWidget> on State<T> {
  void _reload() =>
      context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent());

  Future<void> _openAddEdit({int? ordId}) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthenticatedState) return;

    final saved = await showGoodsShiftDialog(
      context,
      usrName: auth.loginData.usrName ?? '',
      ordId: ordId,
    );

    if (!mounted) return;
    if (saved == true) _reload();
  }

  /// 3-dot "View" → same AddEditView, but read-only.
  Future<void> _openView(int ordId) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthenticatedState) return;

    await showGoodsShiftDialog(
      context,
      usrName: auth.loginData.usrName ?? '',
      ordId: ordId,

    );

    // No reload — view mode can't mutate anything.
  }

  Future<void> _confirmDelete(GoodShiftModel shift) async {
    final tr = AppLocalizations.of(context)!;
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthenticatedState) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.delete),
        content: Text('${tr.areYouSure} #${shift.ordId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(tr.delete),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    context.read<GoodsShiftBloc>().add(DeleteGoodsShiftEvent(
      orderId: shift.ordId!,
      usrName: auth.loginData.usrName ?? '',
    ));
  }

  /// Shared listener used by every layout's BlocConsumer.
  void _onBlocState(BuildContext context, GoodsShiftState state) {
    if (state is GoodsShiftDeletedState) {
      ToastManager.show(
        context: context,
        title: "Success",
        message: state.message,
        type: ToastType.success,
      );
      _reload();
    } else if (state is GoodsShiftErrorState) {
      ToastManager.show(
        context: context,
        title: "Error",
        message: state.error,
        type: ToastType.error,
      );
    }
  }

  /// Apply search filter (ordId + status only — no reference).
  List<GoodShiftModel> _filtered(List<GoodShiftModel> shifts, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return shifts;
    return shifts.where((item) {
      final ordId = item.ordId?.toString() ?? '';
      final status = item.trnStateText?.toLowerCase() ?? '';
      return ordId.contains(q) || status.contains(q);
    }).toList();
  }
}

// ------------------------------------------------------------------
// SHARED APP BAR
// ------------------------------------------------------------------
AppBar _buildAppBar(
    BuildContext context, {
      required AppLocalizations tr,
      required VoidCallback onAdd,
    }) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: Text(tr.goodShift),
    actionsPadding: EdgeInsets.symmetric(horizontal: 15),
    titleSpacing: 0,
    actions: [
      ZOutlineButton(
        icon: Icons.add,
        isActive: true,
        label: Text("Add Goods Shift"),
        onPressed: onAdd,
      ),
    ],
  );
}

// ------------------------------------------------------------------
// MOBILE
// ------------------------------------------------------------------
class _MobileGoodsShiftView extends StatefulWidget {
  const _MobileGoodsShiftView();

  @override
  State<_MobileGoodsShiftView> createState() => _MobileGoodsShiftViewState();
}

class _MobileGoodsShiftViewState extends State<_MobileGoodsShiftView>
    with _GoodsShiftActions {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(context, tr: tr, onAdd: () => _openAddEdit()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ReusableSearchBar(
              controller: searchController,
              onChanged: (e) => setState(() {}),
            ),
          ),
          Expanded(
            child: BlocConsumer<GoodsShiftBloc, GoodsShiftState>(
              listener: _onBlocState,
              builder: (context, state) {
                if (state is GoodsShiftLoadingState ||
                    state is GoodsShiftSavingState ||
                    state is GoodsShiftDeletingState) {
                  return Center(child: UniversalShimmer.dataList());
                }

                if (state is GoodsShiftErrorState) {
                  return NoDataWidget(
                    imageName: 'noData.png',
                    message: state.error,
                    onRefresh: _reload,
                  );
                }

                if (state is GoodsShiftLoadedState) {
                  final filteredList =
                  _filtered(state.shifts, searchController.text);

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: tr.noDataFound,
                      onRefresh: _reload,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final shift = filteredList[index];

                      return ZCover(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        radius: 4,
                        child: InkWell(
                          onTap: () => _openAddEdit(ordId: shift.ordId),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.primary
                                            .withValues(alpha: .1),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "#${shift.ordId}",
                                        style: TextStyle(
                                          color: color.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _statusChip(context, shift.trnStateText),
                                    const Spacer(),
                                    Text(
                                      shift.ordEntryDate != null
                                          ? shift.ordEntryDate
                                          .toFormattedDate()
                                          : "",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    _rowMenu(
                                      tr: tr,
                                      onEdit: () =>
                                          _openAddEdit(ordId: shift.ordId),
                                      onView: () => _openView(shift.ordId!),
                                      onDelete: () => _confirmDelete(shift),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 16,
                                      color: color.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${shift.records?.length ?? (shift.outCount + shift.inCount)} lines",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                return Center(child: UniversalShimmer.dataList());
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// TABLET
// ------------------------------------------------------------------
class _TabletGoodsShiftView extends StatefulWidget {
  const _TabletGoodsShiftView();

  @override
  State<_TabletGoodsShiftView> createState() => _TabletGoodsShiftViewState();
}

class _TabletGoodsShiftViewState extends State<_TabletGoodsShiftView>
    with _GoodsShiftActions {
  final TextEditingController searchController = TextEditingController();

  static const double _idW = 50;
  static const double _dateW = 110;
  static const double _actionsW = 50;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(color: color.surface);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(context, tr: tr, onAdd: () => _openAddEdit()),
      backgroundColor: color.surface,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ReusableSearchBar(
                    controller: searchController,
                    onChanged: (e) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  toolTip: "F5",
                  width: 100,
                  icon: Icons.refresh,
                  onPressed: _reload,
                  label: Text(tr.refresh),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: .9),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: _idW,
                    child: Text("#", style: titleStyle),
                  ),
                  SizedBox(
                    width: _dateW,
                    child: Text(tr.date, style: titleStyle),
                  ),
                  Expanded(
                    child: Text(tr.status, style: titleStyle),
                  ),
                  SizedBox(
                    width: _actionsW,
                    child: Text(tr.actions,
                        style: titleStyle, textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: BlocConsumer<GoodsShiftBloc, GoodsShiftState>(
                listener: _onBlocState,
                builder: (context, state) {
                  if (state is GoodsShiftLoadingState ||
                      state is GoodsShiftSavingState ||
                      state is GoodsShiftDeletingState) {
                    return Center(child: UniversalShimmer.dataList());
                  }

                  if (state is GoodsShiftErrorState) {
                    return NoDataWidget(
                      imageName: 'noData.png',
                      message: state.error,
                      onRefresh: _reload,
                    );
                  }

                  if (state is GoodsShiftLoadedState) {
                    final filteredList =
                    _filtered(state.shifts, searchController.text);

                    if (filteredList.isEmpty) {
                      return NoDataWidget(
                        message: tr.noDataFound,
                        onRefresh: _reload,
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final shift = filteredList[index];
                        return InkWell(
                          onTap: () => _openAddEdit(ordId: shift.ordId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? color.primary.withValues(alpha: .05)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: _idW,
                                  child: Text(shift.ordId.toString()),
                                ),
                                SizedBox(
                                  width: _dateW,
                                  child: Text(
                                    shift.ordEntryDate != null
                                        ? shift.ordEntryDate
                                        .toFormattedDate()
                                        : "",
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _statusChip(
                                        context, shift.trnStateText),
                                  ),
                                ),
                                SizedBox(
                                  width: _actionsW,
                                  child: Center(
                                    child: _rowMenu(
                                      tr: tr,
                                      onEdit: () =>
                                          _openAddEdit(ordId: shift.ordId),
                                      onView: () => _openView(shift.ordId!),
                                      onDelete: () => _confirmDelete(shift),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return Center(child: UniversalShimmer.dataList());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// DESKTOP
// ------------------------------------------------------------------
class _DesktopGoodsShiftView extends StatefulWidget {
  const _DesktopGoodsShiftView();

  @override
  State<_DesktopGoodsShiftView> createState() => _DesktopGoodsShiftViewState();
}

class _DesktopGoodsShiftViewState extends State<_DesktopGoodsShiftView>
    with _GoodsShiftActions {
  final TextEditingController searchController = TextEditingController();

  static const double _idW = 60;
  static const double _statusW = 140;
  static const double _actionsW = 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(color: color.surface);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(context, tr: tr, onAdd: () => _openAddEdit()),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: ReusableSearchBar(
                    controller: searchController,
                    onChanged: (e) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  toolTip: "F5",
                  width: 120,
                  height: 36,
                  icon: Icons.refresh,
                  onPressed: _reload,
                  label: Text(tr.refresh),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(3)
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: _idW,
                    child: Text("#", style: titleStyle),
                  ),
                  Expanded(
                    child: Text(tr.date, style: titleStyle),
                  ),
                  SizedBox(
                    width: _statusW,
                    child: Text(tr.status, style: titleStyle, textAlign: TextAlign.center,),
                  ),
                  SizedBox(
                    width: _actionsW,
                    child: Text(tr.actions,
                        style: titleStyle, textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<GoodsShiftBloc, GoodsShiftState>(
                listener: _onBlocState,
                builder: (context, state) {
                  if (state is GoodsShiftLoadingState ||
                      state is GoodsShiftSavingState ||
                      state is GoodsShiftDeletingState) {
                    return Center(child: UniversalShimmer.dataList(numberOfColumns: 5,itemCount: 10));
                  }

                  if (state is GoodsShiftErrorState) {
                    return NoDataWidget(
                      imageName: 'noData.png',
                      message: state.error,
                      onRefresh: _reload,
                    );
                  }

                  if (state is GoodsShiftLoadedState) {
                    final filteredList =
                    _filtered(state.shifts, searchController.text);

                    if (filteredList.isEmpty) {
                      return NoDataWidget(
                        message: tr.noDataFound,
                        onRefresh: _reload,
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final shift = filteredList[index];
                        return InkWell(
                          onTap: () => _openAddEdit(ordId: shift.ordId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: index.isOdd
                                  ? color.outline.withValues(alpha: .08)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: _idW,
                                  child: Text(shift.ordId.toString()),
                                ),
                                Expanded(
                                  child: Text(
                                    shift.ordEntryDate != null
                                        ? shift.ordEntryDate
                                        .toFormattedDate()
                                        : "",
                                  ),
                                ),
                                SizedBox(
                                  width: _statusW,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: _statusChip(
                                        context, shift.trnStateText),
                                  ),
                                ),
                                SizedBox(
                                  width: _actionsW,
                                  child: Center(
                                    child: _rowMenu(
                                      tr: tr,
                                      onEdit: () =>
                                          _openAddEdit(ordId: shift.ordId),
                                      onView: () => _openView(shift.ordId!),
                                      onDelete: () => _confirmDelete(shift),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return Center(child: UniversalShimmer.dataList());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}