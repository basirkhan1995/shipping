import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/search_field.dart';
import 'package:shipping/Routes/Home/View/Report/Inventory/Cardx/Ui/cardx.dart';
import 'package:shipping/Routes/Home/View/Report/Inventory/StockAvailability/product_report.dart';
import 'package:shipping/Routes/Home/View/Stock/GoodsShift/goods_shift.dart';
import 'package:shipping/Routes/Home/View/Stock/Orders/features/status_method.dart';
import '../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../Features/Other/global_shortcut.dart';
import '../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../Features/Widgets/extensions.dart';
import '../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../../Features/Widgets/shimmer.dart';
import '../../../../../../Features/Widgets/toast.dart';
import '../../../../../../Features/Widgets/utils.dart';
import '../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/model/user_model.dart';
import '../../../Settings/Visibility/bloc/settings_visible_bloc.dart';
import '../../Purchase/bloc/purchase_invoice_bloc.dart';
import '../../Purchase/new_purchase.dart';
import '../../Sale/bloc/sale_invoice_bloc.dart';
import '../../Sale/new_sale.dart';
import '../bloc/orders_bloc.dart';
import '../model/orders_model.dart';

class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _DesktopOrdersView(),
      tablet: _DesktopOrdersView(),
      desktop: _DesktopOrdersView(),
    );
  }
}

class _DesktopOrdersView extends StatefulWidget {
  const _DesktopOrdersView();
  @override
  State<_DesktopOrdersView> createState() => _DesktopOrdersViewState();
}

class _DesktopOrdersViewState extends State<_DesktopOrdersView> {
  String? baseCurrency;
  final Map<String, bool> _copiedStates = {};
  final TextEditingController searchController = TextEditingController();
  final invController = TextEditingController();

  final Set<int> _selectedOrderIds = {};
  bool _isSelectionMode = false;
  List<OrdersModel> cachedOrders = [];
  bool isRefreshing = false;

  // ── Ribbon spec ───────────────────────────────────────────────
  static const _stockRibbonButtons = <_OrderRibbonSpec>[
    _OrderRibbonSpec(
      code: 'SALE',
      icon: Icons.shopping_cart_checkout_rounded,
      permission: null,
      shortcut: 'F1',
    ),
    _OrderRibbonSpec(
      code: 'PURCHASE',
      icon: Icons.add_shopping_cart_rounded,
      permission: null,
      shortcut: 'F2',
    ),
    _OrderRibbonSpec(
      code: 'SHIFT',
      icon: Icons.swap_horiz_rounded,
      permission: null,
      shortcut: 'F3',
    ),
  ];

  static const _ribbonReportButtons = <_OrderRibbonSpec>[
    _OrderRibbonSpec(
      code: 'INOUT',
      icon: Icons.shopping_cart_checkout_rounded,
      permission: null,
      shortcut: 'F4',
    ),
    _OrderRibbonSpec(
      code: 'STOCK',
      icon: Icons.add_shopping_cart_rounded,
      permission: null,
      shortcut: 'F5',
    ),
  ];

  late final Map<ShortcutActivator, VoidCallback> _shortcuts = {
    const SingleActivator(LogicalKeyboardKey.f1): () => _onRibbonTapped('SALE'),
    const SingleActivator(LogicalKeyboardKey.f2): () => _onRibbonTapped('PURCHASE'),
    const SingleActivator(LogicalKeyboardKey.f3): () => _onRibbonTapped('SHIFT'),
    const SingleActivator(LogicalKeyboardKey.f4): () => _onRibbonTapped('INOUT'),
    const SingleActivator(LogicalKeyboardKey.f5): () => _onRibbonTapped('STOCK'),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrdersBloc>().add(const LoadOrdersEvent());
      }
    });

    final companyState = context.read<AuthBloc>().state;
    if (companyState is AuthenticatedState) {
      baseCurrency = companyState.loginData.company?.comLocalCcy ?? "";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    invController.dispose();
    super.dispose();
  }

  void onRefresh() {
    if (!mounted) return;
    setState(() => isRefreshing = true);
    _exitSelectionMode();
    context.read<OrdersBloc>().add(const LoadOrdersEvent());
  }

  void _exitSelectionMode() {
    if (!mounted) return;
    setState(() {
      _selectedOrderIds.clear();
      _isSelectionMode = false;
    });
  }

  void _enterSelectionMode() {
    if (!mounted) return;
    setState(() => _isSelectionMode = true);
  }

  void _toggleSelection(int orderId) {
    if (!mounted) return;
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
        if (_selectedOrderIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedOrderIds.add(orderId);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<OrdersModel> orders) {
    if (!mounted) return;
    setState(() {
      _selectedOrderIds.clear();
      for (var order in orders) {
        if (order.ordId != null) _selectedOrderIds.add(order.ordId!);
      }
      _isSelectionMode = _selectedOrderIds.isNotEmpty;
    });
  }

  void _deselectAll() {
    if (!mounted) return;
    setState(() {
      _selectedOrderIds.clear();
      _isSelectionMode = false;
    });
  }

  void getInvoice({required dynamic invoiceId}) {
    if (invoiceId.toString().trim().isEmpty) {
      ToastManager.show(
        context: context,
        title: "Invoice ID Required",
        message: "Please enter an Invoice ID or reference number.",
        type: ToastType.info,
      );
      return;
    }
    context.read<OrdersBloc>().add(LoadOrderByIdEvent(orderId: invoiceId));
  }

  Future<void> _updateSelectedOrdersStatus() async {
    if (!mounted) return;

    if (_selectedOrderIds.isEmpty) {
      _showSnackBar('No orders selected', isError: true);
      return;
    }

    final selectedCount = _selectedOrderIds.length;
    final ordersData = _selectedOrderIds
        .map((orderId) => {'ordID': orderId, 'ordStatus': 'Authorized'})
        .toList();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(AppLocalizations.of(context)!.areYouSure),
        content: Text(
          'Do you want to update $selectedCount order(s) status to "Authorized"?',
        ),
        actions: [
          ZOutlineButton(
            onPressed: () {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext, false);
              }
            },
            label: Text(AppLocalizations.of(context)!.cancel),
          ),
          ZOutlineButton(
            isActive: true,
            onPressed: () {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext, true);
              }
            },
            label: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      context.read<OrdersBloc>().add(UpdateOrdersStatusEvent(ordersData));
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ToastManager.show(
      context: context,
      title: isError
          ? AppLocalizations.of(context)!.errorTitle
          : AppLocalizations.of(context)!.successTitle,
      message: message,
      type: isError ? ToastType.error : ToastType.success,
    );
  }

  Future<void> _copyToClipboard(String reference, BuildContext context) async {
    await Utils.copyToClipboard(reference);
    if (!mounted) return;
    setState(() => _copiedStates[reference] = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedStates.remove(reference));
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // RIBBON helpers
  // ═══════════════════════════════════════════════════════════════
  void _onRibbonTapped(String code) {
    switch (code) {
      case 'SALE':
        Utils.goto(context, const NewSaleView());
        break;
      case 'PURCHASE':
        Utils.goto(context, const NewPurchaseOrderView());
        break;
      case 'SHIFT':
        Utils.goto(context, const GoodsShiftView());
        break;
      case 'INOUT':
        Utils.goto(context, const StockRecordReportView());
        break;
      case 'STOCK':
        Utils.goto(context, const ProductReportView());
        break;
    }
  }

  String _ribbonLabel(String code, AppLocalizations tr) => switch (code) {
    'SALE' => tr.newSale.toUpperCase(),
    'PURCHASE' => tr.newPurchase.toUpperCase(),
    'SHIFT' => tr.goodShift.toUpperCase(),
    'INOUT' => tr.stockInOut.toUpperCase(),
    'STOCK' => tr.stockReport.toUpperCase(),
    _ => code,
  };

  bool _hasPermission(int permission) {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthenticatedState) return false;
    return auth.loginData.hasPermission(permission) ?? false;
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOLBAR  (ribbons + title + search + refresh)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildToolbar(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;

    final primary = _stockRibbonButtons
        .where((b) => b.permission == null || _hasPermission(b.permission!))
        .toList();
    final reports = _ribbonReportButtons
        .where((b) => b.permission == null || _hasPermission(b.permission!))
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                // ── Middle: title + subtitle fills the empty band ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr.orders,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        tr.orderSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 14,
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // ── Right: search + refresh ────────────────────────
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: ReusableSearchBar(
                        showClearButton: true,
                        controller: searchController,
                        onChanged: (_) {
                          if (!mounted) return;
                          setState(() {
                            if (_isSelectionMode) _exitSelectionMode();
                          });
                        },
                        onSubmitted: (e) {
                          getInvoice(invoiceId: e.trim());
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ZOutlineButton(
                      toolTip: "F5",
                      height: 44,
                      isActive: true,
                      icon: isRefreshing ? null : Icons.refresh,
                      onPressed: isRefreshing ? null : onRefresh,
                      label: isRefreshing ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ) : Text(tr.refresh),
                    ),
                  ],
                )
              ],
            ),
          ),

          Row(
            children: [
              // ── Left: ribbon sections ──────────────────────────
              if (primary.isNotEmpty)
                _RibbonSection(
                  title: tr.stockActions,
                  specs: primary,
                  labelBuilder: (c) => _ribbonLabel(c, tr),
                  onTap: _onRibbonTapped,
                ),

              if (primary.isNotEmpty && reports.isNotEmpty)
                Container(
                  width: 1,
                  height: _RibbonButton.height + 18,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: color.outlineVariant.withValues(alpha: .4),
                ),

              if (reports.isNotEmpty)
                _RibbonSection(
                  title: tr.reports,
                  specs: reports,
                  labelBuilder: (c) => _ribbonLabel(c, tr),
                  onTap: _onRibbonTapped,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COLUMN HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildColumnHeader(BuildContext context, AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(
      color: color.onSurface,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1.5,
            color: color.primary,
          )
        )
      ),
      child: Row(
        children: [
          SizedBox(
            width: _isSelectionMode ? 74 : 50,
            child: Row(
              children: [
                if (_isSelectionMode) const SizedBox(width: 24),
                const SizedBox(width: 4),
                Text("#", style: titleStyle),
              ],
            ),
          ),
          SizedBox(width: 100, child: Text(tr.date, style: titleStyle)),
          SizedBox(width: 215, child: Text(tr.reference, style: titleStyle)),
          SizedBox(width: 100, child: Text(tr.invoiceType, style: titleStyle)),
          Expanded(child: Text(tr.party, style: titleStyle)),
          SizedBox(
            width: 160,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                tr.totalInvoice,
                style: titleStyle,
                textAlign: TextAlign.end,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              tr.status,
              style: titleStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SELECTION ACTION BAR
  // (Select all · Authorize · Deselect all)  — Cancel/clear is elsewhere
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSelectionActionBar(
      BuildContext context, AppLocalizations tr, int visibleCount) {
    final color = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: .05),
        border: Border.all(color: color.primary.withValues(alpha: .2)),
        borderRadius: BorderRadius.circular(4),
      ),
      margin: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedOrderIds.length} از $visibleCount انتخاب شده ',
            style: TextStyle(
              color: color.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              // ── Select all ──────────────────────────────
              TextButton.icon(
                onPressed: () => _selectAll(cachedOrders),
                icon: const Icon(Icons.select_all, size: 18),
                label: Text('${tr.selectAll} ($visibleCount)'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),

              // ── Authorize ───────────────────────────────
              ZOutlineButton(
                width: 120,
                isActive: true,
                icon: Icons.check_circle,
                onPressed: _updateSelectedOrdersStatus,
                label: Text(tr.authorize),
              ),
              const SizedBox(width: 8),

              // ── Deselect all ────────────────────────────
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

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final visibility = context.read<SettingsVisibleBloc>().state;

    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<PurchaseInvoiceBloc, PurchaseInvoiceState>(
            listener: (context, state) {
              if (state is PurchaseInvoiceSaved && state.success) {
                context.read<OrdersBloc>().add(const LoadOrdersEvent());
              }
            },
          ),
          BlocListener<SaleInvoiceBloc, SaleInvoiceState>(
            listener: (context, state) {
              if (state is SaleInvoiceSaved && state.success) {
                context.read<OrdersBloc>().add(const LoadOrdersEvent());
              }
            },
          ),
          BlocListener<OrdersBloc, OrdersState>(
            listener: (context, state) {
              if (state is OrdersLoadedState) {
                setState(() => isRefreshing = false);
              }
              if (state is OrdersErrorState) {
                setState(() => isRefreshing = false);
              }
              if (state is SingleOrderLoadedState) {
                final ordName = state.order['ordName'];
                if (ordName == "Sale") {
                  Utils.goto(context,
                      NewSaleView(orderId: searchController.text.trim()));
                } else if (ordName == "Purchase") {
                  Utils.goto(context,
                      NewPurchaseOrderView(orderId: searchController.text.trim()));
                } else {
                  ToastManager.show(
                      context: context,
                      message: "No Invoice Found",
                      type: ToastType.warning);
                }
              }
              if (state is OrdersDeletedState) {
                Navigator.of(context).pop();
                ToastManager.show(
                    context: context,
                    message: tr.successMsg,
                    title: tr.successTitle,
                    type: ToastType.success);
              }
              if (!mounted) return;
              if (state is OrdersStatusUpdatedState) {
                _showSnackBar(state.message);
                _exitSelectionMode();
              } else if (state is OrdersErrorState) {
                _showSnackBar(state.message, isError: true);
              }
            },
          ),
        ],
        child: GlobalShortcuts(
          shortcuts: _shortcuts,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1) TOOLBAR (ribbons + title + search + refresh) ─
              _buildToolbar(context),

              // ── 2) COLUMN HEADER ─────────────────────────────────
              _buildColumnHeader(context, tr),

              // ── 3) ORDERS LIST ───────────────────────────────────
              Expanded(
                child: BlocBuilder<OrdersBloc, OrdersState>(
                  builder: (context, state) {
                    if (state is OrdersLoadedState) {
                      cachedOrders = state.order;
                    }

                    if (state is OrdersErrorState && cachedOrders.isEmpty) {
                      return NoDataWidget(
                        message: state.message,
                        onRefresh: onRefresh,
                      );
                    }

                    if (state is OrdersLoadingState && cachedOrders.isEmpty) {
                      return UniversalShimmer.dataList(
                        itemCount: 15,
                        numberOfColumns: 7,
                      );
                    }

                    if (state is OrdersStatusUpdatingState) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('در حال بروزرسانی...'),
                          ],
                        ),
                      );
                    }

                    final currentOrders = cachedOrders;
                    final query = searchController.text.toLowerCase().trim();

                    final filteredList = currentOrders.where((item) {
                      final ref = item.ordTrnRef?.toLowerCase() ?? '';
                      final ordId = item.ordId?.toString() ?? '';
                      final ordName = item.ordName?.toLowerCase() ?? '';
                      return ref.contains(query) ||
                          ordId.contains(query) ||
                          ordName.contains(query);
                    }).toList();

                    if (filteredList.isEmpty) {
                      return NoDataWidget(
                        message:
                        query.isEmpty ? tr.noDataFound : "No result found",
                        onRefresh: onRefresh,
                      );
                    }

                    return Column(
                      children: [
                        // ── Selection action bar ─────────────────
                        if (_isSelectionMode && filteredList.isNotEmpty)
                          _buildSelectionActionBar(
                            context,
                            tr,
                            filteredList.length,
                          ),

                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final ord = filteredList[index];
                              final isCopied =
                                  _copiedStates[ord.ordTrnRef ?? ""] ?? false;
                              final reference = ord.ordTrnRef ?? "";
                              final isSelected =
                              _selectedOrderIds.contains(ord.ordId);

                              return InkWell(
                                hoverColor: color.primary.withValues(alpha: .06),
                                highlightColor: color.primary.withValues(alpha: .06),
                                splashColor: color.primary.withValues(alpha: .06),
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleSelection(ord.ordId!);
                                  } else {
                                    Utils.goto(
                                      context,
                                      ord.ordName == "Sale"
                                          ? NewSaleView(orderId: ord.ordId)
                                          : NewPurchaseOrderView(
                                          orderId: ord.ordId),
                                    );
                                  }
                                },
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    _enterSelectionMode();
                                    _toggleSelection(ord.ordId!);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8,),
                                  margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.primary.withValues(alpha: .15)
                                        : index.isOdd
                                        ? color.surfaceContainer
                                        .withValues(alpha: .6)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: isSelected
                                        ? Border.all(
                                        color: color.primary.withValues(alpha: .3), width: 1)
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: _isSelectionMode ? 74 : 50,
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
                                                          ord.ordId!),
                                                  visualDensity:
                                                  VisualDensity.compact,
                                                  materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                                  activeColor: color.primary,
                                                ),
                                              ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                ord.ordId.toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (visibility.dateType ==
                                          DateType.gregorian) ...[
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            ord.ordEntryDate.toFormattedDate(),
                                          ),
                                        ),
                                      ] else ...[
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            ord.ordEntryDate?.shamsiDateString ??
                                                "",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                      ],

                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _copyToClipboard(
                                                    reference, context),
                                                borderRadius:
                                                BorderRadius.circular(4),
                                                hoverColor: color.primary
                                                    .withValues(alpha: .05),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 100),
                                                  decoration: BoxDecoration(
                                                    color: isCopied
                                                        ? color.primary
                                                        .withAlpha(25)
                                                        : Colors.transparent,
                                                    border: Border.all(
                                                      color: isCopied
                                                          ? color.primary
                                                          : color.outline
                                                          .withValues(
                                                          alpha: .3),
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        4),
                                                  ),
                                                  child: Center(
                                                    child: AnimatedSwitcher(
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                      child: Icon(
                                                        isCopied
                                                            ? Icons.check
                                                            : Icons.content_copy,
                                                        key: ValueKey<bool>(
                                                            isCopied),
                                                        size: 15,
                                                        color: isCopied
                                                            ? color.primary
                                                            : color.outline
                                                            .withValues(
                                                            alpha: .6),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 180,
                                            child: Text(
                                              reference,
                                              style: TextStyle(
                                                fontWeight: isSelected
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text(ord.ordName ?? ""),
                                      ),
                                      Expanded(
                                        child: Text(
                                          ord.personal ?? "",
                                          style: TextStyle(
                                            color: isSelected
                                                ? color.primary
                                                : null,
                                            fontWeight: isSelected
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15),
                                        width: 160,
                                        child: Text(
                                          "${ord.totalBill?.toAmount()} $baseCurrency",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.w500
                                                : FontWeight.bold,
                                            color: isSelected
                                                ? color.primary
                                                : null,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: StatusIcon(
                                          status: ord.ordStatus ?? "",
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Ribbon spec + widgets
// ═══════════════════════════════════════════════════════════════════
class _OrderRibbonSpec {
  final String code;
  final IconData icon;
  final int? permission;
  final String? shortcut;
  const _OrderRibbonSpec({
    required this.code,
    required this.icon,
    this.permission,
    this.shortcut,
  });
}

class _RibbonButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? shortcut;
  final VoidCallback onPressed;

  static const double width = 125;
  static const double height = 95;

  const _RibbonButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.shortcut,
  });

  @override
  State<_RibbonButton> createState() => _RibbonButtonState();
}

class _RibbonButtonState extends State<_RibbonButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final borderColor = _hover
        ? color.primary.withValues(alpha: .6)
        : color.outlineVariant.withValues(alpha: .45);

    return Tooltip(
      message: widget.shortcut == null
          ? widget.label
          : '${widget.label}  (${widget.shortcut})',
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: widget.onPressed,
        onHover: (v) => setState(() => _hover = v),
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(
          width: _RibbonButton.width,
          height: _RibbonButton.height,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: _hover ? color.primary.withValues(alpha: .06)
                  : color.primary.withValues(alpha: .04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  height: 20,
                  child: Icon(widget.icon, size: 25, color: color.primary),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 28,
                  child: Center(
                    child: Text(
                      widget.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w600,
                        color: color.onSurface,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 13,
                  child: widget.shortcut == null
                      ? const SizedBox.shrink()
                      : Center(
                    child: Text(
                      widget.shortcut!,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color:
                        color.onSurfaceVariant.withValues(alpha: .7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RibbonSection extends StatelessWidget {
  final String title;
  final List<_OrderRibbonSpec> specs;
  final String Function(String code) labelBuilder;
  final void Function(String code) onTap;

  const _RibbonSection({
    required this.title,
    required this.specs,
    required this.labelBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Text(
            title.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: color.onSurfaceVariant.withValues(alpha: .8),
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final spec in specs)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _RibbonButton(
                  icon: spec.icon,
                  label: labelBuilder(spec.code),
                  shortcut: spec.shortcut,
                  onPressed: () => onTap(spec.code),
                ),
              ),
          ],
        ),
      ],
    );
  }
}