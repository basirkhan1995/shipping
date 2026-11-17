import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/utils.dart';
import '../../../../../Features/Widgets/extensions.dart';
import '../../../../../Features/Widgets/search_field.dart';
import '../../../../../Features/Widgets/section.dart';
import '../../../../../Features/Widgets/shimmer.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../Auth/bloc/auth_bloc.dart';
import '../../Settings/Visibility/bloc/settings_visible_bloc.dart';
import '../bloc/products_bloc.dart';
import '../model/product_stock_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point — call this from anywhere (button, shortcut, menu).
// ─────────────────────────────────────────────────────────────────────────────
Future<void> showProductPriceChecker(
    BuildContext context, {
      int? initialProductId,
    }) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .35),
    builder: (_) => ProductPriceChecker(initialProductId: initialProductId),
  );
}

// Convenience for shortcut handlers that don't have a good BuildContext:
Future<void> showProductPriceCheckerFromKey(
    GlobalKey<NavigatorState> navigatorKey, {
      int? initialProductId,
    }) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return Future.value();
  return showProductPriceChecker(ctx, initialProductId: initialProductId);
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel widget
// ─────────────────────────────────────────────────────────────────────────────
class ProductPriceChecker extends StatefulWidget {
  final int? initialProductId;

  const ProductPriceChecker({super.key, this.initialProductId});

  @override
  State<ProductPriceChecker> createState() => _ProductPriceCheckerState();
}

class _ProductPriceCheckerState extends State<ProductPriceChecker> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _searchFocus = FocusNode();

  Timer? _debounce;
  String? _baseCurrency;

  int _highlightedIndex = -1;
  List<ProductsStockModel> _items = const [];
  ProductsStockModel? _highlighted;

  // Local loading flag — mirrors the bloc's loading state so the UI can show
  // a shimmer while a fresh query is in flight. Also acts as a guard so we
  // don't blank the list on every keystroke.
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();

    final auth = context.read<AuthBloc>().state;
    if (auth is AuthenticatedState) {
      _baseCurrency = auth.loginData.company?.comLocalCcy;
    }

    _search.addListener(_onQueryChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocus.requestFocus();
      // NOTE: if your bloc has a "load by id" event, add it here:
      //   context.read<ProductsBloc>().add(LoadProductsStockByIdEvent(id: ...));
      // For now we always load the full list.
      _loadAll();
    });
  }

  @override
  void dispose() {
    _search.removeListener(_onQueryChanged);
    _search.dispose();
    _scroll.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadAll() {
    if (!mounted) return;
    setState(() => _isFetching = true);
    context.read<ProductsBloc>().add(LoadProductsStockEvent());
  }

  void _searchFor(String q) {
    if (!mounted) return;
    setState(() => _isFetching = true);
    context.read<ProductsBloc>().add(LoadProductsStockEvent(input: q));
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final q = _search.text.trim();
    if (q.isEmpty) {
      _loadAll();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _searchFor(q);
    });
  }

  void _select(ProductsStockModel p) {
    setState(() {
      _highlighted = p;
      _highlightedIndex = _items.indexOf(p);
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_items.isEmpty) return KeyEventResult.handled;
      final i = (_highlightedIndex + 1) % _items.length;
      setState(() {
        _highlightedIndex = i;
        _highlighted = _items[i];
      });
      _scrollIntoView(i);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_items.isEmpty) return KeyEventResult.handled;
      final i = (_highlightedIndex - 1 + _items.length) % _items.length;
      setState(() {
        _highlightedIndex = i;
        _highlighted = _items[i];
      });
      _scrollIntoView(i);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _scrollIntoView(int index) {
    if (!_scroll.hasClients) return;
    const approx = 60.0;
    final target =
    (index * approx).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final screen = MediaQuery.of(context).size;
    final panelW = (screen.width * 0.85).clamp(800.0, 1400.0);
    final panelH = (screen.height * 0.90).clamp(500.0, 900.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: panelW,
        height: panelH,
        child: BlocListener<ProductsBloc, ProductsState>(
          listenWhen: (_, s) =>
          s is ProductsStockLoadedState || s is ProductsErrorState,
          listener: (context, s) {
            if (!mounted) return;
            if (s is ProductsStockLoadedState) {
              setState(() {
                _isFetching = false;
                _items = s.products;
                if (_items.isNotEmpty &&
                    (_highlighted == null ||
                        !_items.contains(_highlighted))) {
                  _highlightedIndex = 0;
                  _highlighted = _items.first;
                } else if (_items.isEmpty) {
                  _highlightedIndex = -1;
                  _highlighted = null;
                }
              });
            } else if (s is ProductsErrorState) {
              setState(() => _isFetching = false);
            }
          },
          child: BlocBuilder<ProductsBloc, ProductsState>(
            builder: (context, state) {
              final blocLoading = state is ProductsLoadingState;
              final loading = blocLoading || _isFetching;

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 5,
                      color: Theme.of(context).colorScheme.primary,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── LEFT: search + list ─────────────────────
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Focus(
                          autofocus: true,
                          onKeyEvent: _onKey,
                          child: Column(
                            children: [
                              _header(tr),
                              _searchBar(),
                              const SizedBox(height: 6),
                              _columnTitles(tr),
                              Expanded(
                                child: loading && _items.isEmpty
                                    ? Center(
                                  child: UniversalShimmer.dataList(
                                    itemCount: 10,
                                    numberOfColumns: 6,
                                  ),
                                )
                                    : _items.isEmpty
                                    ? _empty(tr)
                                    : _list(tr),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── RIGHT: details ───────────────────────────
                    Container(
                      width: 400,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: .03),
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: .15),
                          ),
                        ),
                      ),
                      child: _highlighted == null
                          ? Center(
                        child: Text(
                          tr.noDataFound,
                          style: TextStyle(
                            color:
                            Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      )
                          : SingleChildScrollView(
                        padding: const EdgeInsets.all(10),
                        child: _details(tr, _highlighted!),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations tr) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.shopify_rounded, size: 22),
        const SizedBox(width: 6),
        Text(
          tr.products.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: .3,
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return ReusableSearchBar(
      controller: _search,
      focusNode: _searchFocus,
      autofocus: true,
      onSubmitted: (_) {
        if (_items.isNotEmpty) {
          setState(() {
            if (_highlightedIndex < 0) _highlightedIndex = 0;
            _highlighted = _items[_highlightedIndex];
          });
        }
      },
      onChanged: (_) {},
    );
  }

  Widget _columnTitles(AppLocalizations tr) {
    final style = TextStyle(
      fontSize: 13,
      color: Theme.of(context).colorScheme.outline,
      fontWeight: FontWeight.w700,
    );
    final vis = context.watch<SettingsVisibleBloc>().state;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      child: Row(
        children: [
          Expanded(child: Text(tr.productName, style: style)),
          SizedBox(width: 110, child: Text(tr.storage, style: style)),
          SizedBox(
            width: 60,
            child: Text(tr.unit,
                textAlign: TextAlign.center, style: style),
          ),
          if (vis.isWholeSale)
            SizedBox(
              width: 70,
              child:
              Text(tr.item, textAlign: TextAlign.end, style: style),
            ),
          SizedBox(
            width: 100,
            child: Text(tr.stockBalance,
                textAlign: TextAlign.end, style: style),
          ),
          SizedBox(
            width: 90,
            child: Text(tr.unitPrice,
                textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }

  Widget _empty(AppLocalizations tr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            _search.text.isEmpty ? tr.searchProducts : tr.noDataFound,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(AppLocalizations tr) {
    final vis = context.watch<SettingsVisibleBloc>().state;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final p = _items[index];
        final sel = index == _highlightedIndex;
        final available = double.tryParse(p.available ?? '0') ?? 0;
        final availColor = available <= 0
            ? Colors.red
            : available < 10
            ? Colors.orange
            : Colors.green;

        return InkWell(
          onTap: () => _select(p),
          onHover: (h) {
            if (h) _select(p);
          },
          child: Container(
            padding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: sel
                  ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: .08)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: .15),
                  width: .5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    p.proName ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: available <= 0 ? Colors.red : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    p.stgName ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    p.proUnit ?? '-',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (vis.isWholeSale)
                  SizedBox(
                    width: 70,
                    child: Text(
                      (p.stkQtyInBatch ?? 0).toString(),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                SizedBox(
                  width: 100,
                  child: Text(
                    available.toAmount(decimal: 2),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: availColor,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    p.sellPrice.toAmount(),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  // ── details panel ─────────────────────────────────────────────────
  Widget _details(AppLocalizations tr, ProductsStockModel p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titleBlock(tr, p),
        const SizedBox(height: 10),
        _card(tr.pricing, [
          _row(Icons.price_change_outlined, tr.batchPurPrice,
              p.fifoNextUnitCost.toAmount(decimal: 2)),
          _row(Icons.local_shipping_outlined, tr.landedCost,
              p.averageLandedPrice.toAmount(decimal: 2)),
          _row(Icons.trending_up, tr.avgPurchasePrice,
              p.averagePrice.toAmount(decimal: 2)),
          _row(Icons.history, tr.recentPurchasePrice,
              p.recentPurPrice.toAmount(decimal: 2)),
          _row(Icons.calculate_outlined, tr.cogs,
              p.fifoCogsTotal.toAmount(decimal: 2),
              isLast: true),
        ]),
        const SizedBox(height: 10),
        _recentCard(tr, p),
      ],
    );
  }

  Widget _titleBlock(AppLocalizations tr, ProductsStockModel p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.proName ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              p.proCode ?? 'N/A',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            Text(
              p.proUnit ?? 'N/A',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            _dot(),
            Text(
              "${tr.productId} - ${p.proId ?? 'N/A'}",
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            _dot(),
            Text(
              "${tr.batchCode} - ${p.fifoNextBatchRef ?? 'N/A'}",
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dot() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 6),
    height: 12,
    width: 1.5,
    decoration: BoxDecoration(
      color:
      Theme.of(context).colorScheme.outline.withValues(alpha: .3),
    ),
  );

  Widget _card(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: .2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
      IconData icon,
      String label,
      String value, {
        bool isLast = false,
      }) {
    final display =
    _baseCurrency == null ? value : "$value $_baseCurrency";
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(
            color:
            Theme.of(context).colorScheme.surfaceContainer,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: .8),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              display,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentCard(AppLocalizations tr, ProductsStockModel p) {
    final rows = p.recentTxn ?? const <RecentTxn>[];
    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.outline,
    );
    final cellStyle = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: .2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: tr.recentSales),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  tr.noDataFound,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            )
          else ...[
            // header
            Row(
              children: [
                SizedBox(width: 50,  child: Text(tr.invoice,     style: headerStyle)),
                Expanded(child: Text(tr.customer,  style: headerStyle,textAlign: TextAlign.start,)),
                SizedBox(width: 35,  child: Text(tr.qty, textAlign: TextAlign.center, style: headerStyle)),
                SizedBox(width: 100, child: Text(tr.unitPrice, textAlign: TextAlign.end, style: headerStyle)),
              ],
            ),
            const SizedBox(height: 4),
            ...rows.map((r) => _recentRow(r, cellStyle)),
          ],
        ],
      ),
    );
  }

  Widget _recentRow(RecentTxn r, TextStyle cellStyle) {
    final baseUnit  = (r.unitPrice ?? 0).toDouble();
    final baseCur   = r.currency ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.surfaceContainer,
            width: .5,
          ),
        ),
      ),
      child: Row(
        children: [
          // order id + type
          SizedBox(
            width: 50,
            child: Text(
              r.orderId.toString(),
              textAlign: TextAlign.start,
              style: cellStyle.copyWith(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              r.customer ?? '',
              style: cellStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              r.quantity.toString(),
              textAlign: TextAlign.center,
              style: cellStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // SizedBox(
          //   width: 35,
          //   child: Text(
          //     batchQty.toString(),
          //     textAlign: TextAlign.center,
          //     style: cellStyle.copyWith(fontWeight: FontWeight.w600),
          //   ),
          // ),
          SizedBox(
            width: 100,
            child: Text(
              "${baseUnit.toAmount(decimal: 2)} ${Utils.ccy(type: baseCur, locale: AppLocalizations.of(context)!)}",
              textAlign: TextAlign.end,
              style: cellStyle.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),

        ],
      ),
    );
  }
}