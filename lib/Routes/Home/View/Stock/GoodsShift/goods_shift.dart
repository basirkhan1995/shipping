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
import '../../../../../Features/Date/z_range_picker.dart';
import '../../Report/AllTransactions/features/status_drop.dart';
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
// STATUS CHIP
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
// 3-DOT MENU
// ------------------------------------------------------------------
Widget _rowMenu({
  required AppLocalizations tr,
  required String status,
  required VoidCallback onEdit,
  required VoidCallback onView,
  required VoidCallback onDelete,
  required VoidCallback onAuthorize,
  required VoidCallback onRevert,
}) {
  final isPending = status.toLowerCase() == 'pending';
  return PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert, size: 18),
    tooltip: tr.actions,
    onSelected: (value) {
      switch (value) {
        case 'edit':
          onEdit();
          break;
        case 'view':
          onView();
          break;
        case 'delete':
          onDelete();
          break;
        case 'authorize':
          onAuthorize();
          break;
        case 'revert':
          onRevert();
          break;
      }
    },
    itemBuilder: (context) {
      final errorColor = Theme.of(context).colorScheme.error;
      return [
        if (isPending)
          PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              const Icon(Icons.edit, size: 16),
              const SizedBox(width: 8),
              Text(tr.edit),
            ]),
          ),
        PopupMenuItem(
          value: 'view',
          child: Row(children: [
            const Icon(Icons.visibility, size: 16),
            const SizedBox(width: 8),
            Text(tr.view),
          ]),
        ),
        if (isPending)
          PopupMenuItem(
            value: 'authorize',
            child: Row(children: [
              const Icon(Icons.check_circle_outline,
                  size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(tr.authorize, style: const TextStyle(color: Colors.green)),
            ]),
          ),
        if (!isPending)
          PopupMenuItem(
            value: 'revert',
            child: Row(children: [
              const Icon(Icons.undo, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Revert to Pending',
                  style: TextStyle(color: Colors.orange.shade800)),
            ]),
          ),
        const PopupMenuDivider(),
        if (isPending)
          PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline, size: 16, color: errorColor),
              const SizedBox(width: 8),
              Text(tr.delete, style: TextStyle(color: errorColor)),
            ]),
          ),
      ];
    },
  );
}

// ------------------------------------------------------------------
// SHARED ACTIONS MIXIN — WITH FILTER + CLEAR + AUTO RELOAD
// ------------------------------------------------------------------
mixin _GoodsShiftActions<T extends StatefulWidget> on State<T> {
  // ── selection state ────────────────────────────────────────
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;
  List<GoodShiftModel> _visibleCache = [];

  // ── filter state (matches backend contract) ────────────────
  /// `null`  → 'All'
  /// `0`     → 'Pending'
  /// `1`     → 'Authorized'
  int? _statusFilter; // default = All

  DateTime _fromDate =
  DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
  DateTime _toDate =
  DateTime(DateTime.now().year, DateTime.now().month, 0);

  // ── status ↔ string mapping ────────────────────────────────
  String? get _statusParam {
    switch (_statusFilter) {
      case 0:
        return 'Pending';
      case 1:
        return 'Authorized';
      default:
        return 'All';
    }
  }

  // ── is any filter currently narrowing the view? ────────────
  bool get _hasActiveFilter {
    // status: null = All (default), so any non-null means filtered
    if (_statusFilter != null) return true;

    // date: default is last month; anything else is filtered
    final now = DateTime.now();
    final defFrom = DateTime(now.year, now.month - 1, 1);
    final defTo = DateTime(now.year, now.month, 0);

    final fromChanged = !(_fromDate.year == defFrom.year &&
        _fromDate.month == defFrom.month &&
        _fromDate.day == defFrom.day);
    final toChanged = !(_toDate.year == defTo.year &&
        _toDate.month == defTo.month &&
        _toDate.day == defTo.day);

    return fromChanged || toChanged;
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  // ── reload carries the current filters ─────────────────────
  void _reload() {
    context.read<GoodsShiftBloc>().add(LoadGoodsShiftsEvent(
      status: _statusParam,
      from: _fromDate,
      to: _toDate,
    ));
  }

  void _applyFilters() {
    setState(() {});
    _reload();
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      final now = DateTime.now();
      _fromDate = DateTime(now.year, now.month - 1, 1);
      _toDate = DateTime(now.year, now.month, 0);
    });
    _reload();
  }

  // ── selection helpers ──────────────────────────────────────
  void _toggleSelection(int id) {
    if (!mounted) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _enterSelectionMode(int id) {
    if (!mounted) return;
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _selectAll() {
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
      for (final s in _visibleCache) {
        if (s.ordId != null) _selectedIds.add(s.ordId!);
      }
      _isSelectionMode = _selectedIds.isNotEmpty;
    });
  }

  void _deselectAll() {
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  // ── status change (authorize / revert) ─────────────────────
  Future<void> _changeStatusFor(
      Set<int> ids, {
        required String targetStatus,
      }) async {
    if (ids.isEmpty) return;
    final count = ids.length;
    final tr = AppLocalizations.of(context)!;
    final isRevert = targetStatus == 'Pending';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(tr.areYouSure),
        content: Text(
          isRevert
              ? (count == 1
              ? 'Revert this goods shift to Pending so it can be edited?'
              : 'Revert $count goods shifts to Pending?')
              : (count == 1
              ? 'Authorize this goods shift?'
              : 'Authorize $count goods shifts?'),
        ),
        actions: [
          ZOutlineButton(
            onPressed: () => Navigator.pop(ctx, false),
            label: Text(tr.cancel),
          ),
          ZOutlineButton(
            isActive: true,
            onPressed: () => Navigator.pop(ctx, true),
            label: Text(tr.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final payload = ids
        .map((id) => {'ordID': id, 'ordStatus': targetStatus})
        .toList();

    context.read<GoodsShiftBloc>().add(AuthorizeGoodsShiftsEvent(
      payload,
      targetStatus: targetStatus,
    ));
  }

  Future<void> _authorizeSelected() =>
      _changeStatusFor(_selectedIds, targetStatus: 'Authorized');

  Future<void> _revertSelected() =>
      _changeStatusFor(_selectedIds, targetStatus: 'Pending');

  // ── add / edit / view / delete ─────────────────────────────
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

  Future<void> _openView(int ordId) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthenticatedState) return;

    await showGoodsShiftDialog(
      context,
      usrName: auth.loginData.usrName ?? '',
      ordId: ordId,
      readOnly: true,
    );
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

  // ── bloc listener — ALWAYS RELOAD ON ANY MUTATION ──────────
  void _onBlocState(BuildContext context, GoodsShiftState state) {
    if (state is GoodsShiftDeletedState) {
      ToastManager.show(
        context: context,
        title: "Success",
        message: state.message,
        type: ToastType.success,
      );
      _deselectAll();
      _reload();
    } else if (state is GoodsShiftAuthorizedState) {
      ToastManager.show(
        context: context,
        title: "Success",
        message: state.message,
        type: ToastType.success,
      );
      _deselectAll();
      _reload();
    } else if (state is GoodsShiftSavedState ||
        state is GoodsShiftUpdatedState) {
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

  List<GoodShiftModel> _filtered(List<GoodShiftModel> shifts, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return shifts;
    return shifts.where((item) {
      final ordId = item.ordId?.toString() ?? '';
      final status = item.trnStateText?.toLowerCase() ?? '';
      return ordId.contains(q) || status.contains(q);
    }).toList();
  }

  // ── filter widget with Clear button ────────────────────────
  Widget _buildFilterBar(
      BuildContext context,
      AppLocalizations tr,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 8,
      children: [
        SizedBox(
          width: 260,
          child: ZRangeDatePicker(
            height: 40,
            label: tr.selectDate,
            initialStartDate: _fromDate,
            initialEndDate: _toDate,
            startValue: _ymd(_fromDate),
            endValue: _ymd(_toDate),
            onStartDateChanged: (v) {
              final d = DateTime.tryParse(v);
              if (d != null) setState(() => _fromDate = d);
            },
            onEndDateChanged: (v) {
              final d = DateTime.tryParse(v);
              if (d != null) {
                setState(() => _toDate = d);
                _reload();
              }
            },
            disablePastDate: false,
            minYear: 2000,
            maxYear: 2100,
          ),
        ),
        SizedBox(
          width: 260,
          child: StatusDropdown(
            value: _statusFilter,
            items: [
              StatusItem(null, tr.all),
              StatusItem(0, tr.pending),
              StatusItem(1, tr.authorized),
            ],
            onChanged: (v) {
              setState(() => _statusFilter = v);
            },
          ),
        ),

        // ── Clear button — only when something is filtered ──
        if (_hasActiveFilter)
          ZOutlineButton(
            icon: Icons.filter_alt_off_outlined,
            height: 47,
            isActive:true,
            backgroundHover: Theme.of(context).colorScheme.error,
            onPressed: _clearFilters,
            label: Text(tr.clearFilters),
          ),

        ZOutlineButton(
          isActive: true,
          height: 47,
          icon: Icons.filter_alt_outlined,
          onPressed: _applyFilters,
          label: Text(tr.applyFilter),
        ),
      ],
    );
  }

  // ── selection action bar ───────────────────────────────────
  Widget _buildSelectionActionBar(
      BuildContext context, AppLocalizations tr, int visibleCount) {
    final color = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: .05),
        border: Border.all(color: color.primary.withValues(alpha: .2)),
        borderRadius: BorderRadius.circular(4),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 1,vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedIds.length} of $visibleCount selected',
            style: TextStyle(
              color: color.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: _selectAll,
                icon: const Icon(Icons.select_all, size: 18),
                label: Text('${tr.selectAll} ($visibleCount)'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              if (_statusFilter == 0 || _statusFilter == null)
                ZOutlineButton(
                  isActive: true,
                  icon: Icons.check_circle,
                  onPressed: _authorizeSelected,
                  label: Text(tr.authorize),
                ),
              if (_statusFilter == 1 || _statusFilter == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ZOutlineButton(
                    isActive: true,
                    icon: Icons.undo,
                    onPressed: _revertSelected,
                    label: const Text('Revert'),
                  ),
                ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _deselectAll,
                icon: const Icon(Icons.deselect, size: 18),
                label: Text(tr.deselectAll),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    actionsPadding: const EdgeInsets.symmetric(horizontal: 15),
    titleSpacing: 0,
    actions: [
      ZOutlineButton(
        icon: Icons.add,
        isActive: true,
        label: const Text("Add Goods Shift"),
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
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: _buildFilterBar(context, tr),
          ),
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
                    state is GoodsShiftDeletingState ||
                    state is GoodsShiftAuthorizingState) {
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
                  _visibleCache = filteredList;

                  if (filteredList.isEmpty) {
                    return NoDataWidget(
                      message: tr.noDataFound,
                      onRefresh: _reload,
                    );
                  }

                  return Column(
                    children: [
                      if (_isSelectionMode)
                        _buildSelectionActionBar(
                            context, tr, filteredList.length),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final shift = filteredList[index];
                            final isSelected =
                            _selectedIds.contains(shift.ordId);

                            return ZCover(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              radius: 4,
                              child: InkWell(
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleSelection(shift.ordId!);
                                  } else {
                                    _openAddEdit(ordId: shift.ordId);
                                  }
                                },
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    _enterSelectionMode(shift.ordId!);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: isSelected
                                      ? BoxDecoration(
                                    color: color.primary
                                        .withValues(alpha: .08),
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  )
                                      : null,
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (_isSelectionMode)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: Checkbox(
                                                  value: isSelected,
                                                  onChanged: (_) =>
                                                      _toggleSelection(
                                                          shift.ordId!),
                                                  visualDensity:
                                                  VisualDensity.compact,
                                                  materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                                ),
                                              ),
                                            ),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 8, vertical: 4),
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
                                          _statusChip(
                                              context, shift.trnStateText),
                                          const Spacer(),
                                          Text(
                                            shift.ordEntryDate != null
                                                ? shift.ordEntryDate
                                                .toFormattedDate()
                                                : "",
                                            style: const TextStyle(
                                                fontSize: 12),
                                          ),
                                          if (!_isSelectionMode)
                                            _rowMenu(
                                              tr: tr,
                                              status: shift.trnStateText ??
                                                  'Pending',
                                              onEdit: () => _openAddEdit(
                                                  ordId: shift.ordId),
                                              onView: () =>
                                                  _openView(shift.ordId!),
                                              onDelete: () =>
                                                  _confirmDelete(shift),
                                              onAuthorize: () =>
                                                  _changeStatusFor(
                                                    {shift.ordId!},
                                                    targetStatus: 'Authorized',
                                                  ),
                                              onRevert: () =>
                                                  _changeStatusFor(
                                                    {shift.ordId!},
                                                    targetStatus: 'Pending',
                                                  ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.inventory_2_outlined,
                                              size: 16, color: color.outline),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${shift.records?.length ?? (shift.outCount + shift.inCount)} lines",
                                            style:
                                            const TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
            _buildFilterBar(context, tr),
            const SizedBox(height: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: .9),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: _isSelectionMode ? _idW + 24 : _idW,
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
                      state is GoodsShiftDeletingState ||
                      state is GoodsShiftAuthorizingState) {
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
                    _visibleCache = filteredList;

                    if (filteredList.isEmpty) {
                      return NoDataWidget(
                        message: tr.noDataFound,
                        onRefresh: _reload,
                      );
                    }

                    return Column(
                      children: [
                        if (_isSelectionMode)
                          _buildSelectionActionBar(
                              context, tr, filteredList.length),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final shift = filteredList[index];
                              final isSelected =
                              _selectedIds.contains(shift.ordId);

                              return InkWell(
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleSelection(shift.ordId!);
                                  } else {
                                    _openAddEdit(ordId: shift.ordId);
                                  }
                                },
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    _enterSelectionMode(shift.ordId!);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.primary
                                        .withValues(alpha: .1)
                                        : index.isEven
                                        ? color.primary
                                        .withValues(alpha: .05)
                                        : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: _isSelectionMode
                                            ? _idW + 24
                                            : _idW,
                                        child: Row(
                                          children: [
                                            if (_isSelectionMode)
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: Checkbox(
                                                  value: isSelected,
                                                  onChanged: (_) =>
                                                      _toggleSelection(
                                                          shift.ordId!),
                                                  visualDensity:
                                                  VisualDensity.compact,
                                                  materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                                ),
                                              ),
                                            Expanded(
                                              child: Text(
                                                  shift.ordId.toString()),
                                            ),
                                          ],
                                        ),
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
                                          child: _isSelectionMode
                                              ? const SizedBox.shrink()
                                              : _rowMenu(
                                            tr: tr,
                                            status: shift.trnStateText ??
                                                'Pending',
                                            onEdit: () => _openAddEdit(
                                                ordId: shift.ordId),
                                            onView: () =>
                                                _openView(shift.ordId!),
                                            onDelete: () =>
                                                _confirmDelete(shift),
                                            onAuthorize: () =>
                                                _changeStatusFor(
                                                  {shift.ordId!},
                                                  targetStatus:
                                                  'Authorized',
                                                ),
                                            onRevert: () =>
                                                _changeStatusFor(
                                                  {shift.ordId!},
                                                  targetStatus: 'Pending',
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
            _buildFilterBar(context, tr),
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
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: _isSelectionMode ? _idW + 24 : _idW,
                    child: Text("#", style: titleStyle),
                  ),
                  Expanded(
                    child: Text(tr.date, style: titleStyle),
                  ),
                  SizedBox(
                    width: _statusW,
                    child: Text(tr.status,
                        style: titleStyle, textAlign: TextAlign.center),
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
                      state is GoodsShiftDeletingState ||
                      state is GoodsShiftAuthorizingState) {
                    return Center(
                        child: UniversalShimmer.dataList(
                            numberOfColumns: 5, itemCount: 10));
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
                    _visibleCache = filteredList;

                    if (filteredList.isEmpty) {
                      return NoDataWidget(
                        message: tr.noDataFound,
                        onRefresh: _reload,
                      );
                    }

                    return Column(
                      children: [
                        if (_isSelectionMode)
                          _buildSelectionActionBar(
                              context, tr, filteredList.length),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final shift = filteredList[index];
                              final isSelected =
                              _selectedIds.contains(shift.ordId);

                              return InkWell(
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleSelection(shift.ordId!);
                                  } else {
                                    _openAddEdit(ordId: shift.ordId);
                                  }
                                },
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    _enterSelectionMode(shift.ordId!);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.primary
                                        .withValues(alpha: .1)
                                        : index.isOdd
                                        ? color.outline
                                        .withValues(alpha: .08)
                                        : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: _isSelectionMode
                                            ? _idW + 24
                                            : _idW,
                                        child: Row(
                                          children: [
                                            if (_isSelectionMode)
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: Checkbox(
                                                  value: isSelected,
                                                  onChanged: (_) =>
                                                      _toggleSelection(
                                                          shift.ordId!),
                                                  visualDensity:
                                                  VisualDensity.compact,
                                                  materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                                ),
                                              ),
                                            Expanded(
                                              child: Text(
                                                  shift.ordId.toString()),
                                            ),
                                          ],
                                        ),
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
                                          child: _isSelectionMode
                                              ? const SizedBox.shrink()
                                              : _rowMenu(
                                            tr: tr,
                                            status: shift.trnStateText ??
                                                'Pending',
                                            onEdit: () => _openAddEdit(
                                                ordId: shift.ordId),
                                            onView: () =>
                                                _openView(shift.ordId!),
                                            onDelete: () =>
                                                _confirmDelete(shift),
                                            onAuthorize: () =>
                                                _changeStatusFor(
                                                  {shift.ordId!},
                                                  targetStatus:
                                                  'Authorized',
                                                ),
                                            onRevert: () =>
                                                _changeStatusFor(
                                                  {shift.ordId!},
                                                  targetStatus: 'Pending',
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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