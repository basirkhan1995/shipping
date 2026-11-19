import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Date/shamsi_converter.dart';
import 'package:shipping/Features/Widgets/search_field.dart';
import 'package:shipping/Features/Widgets/shimmer.dart';
import '../../../../../../Features/Widgets/extensions.dart';
import '../../../../../../Features/Widgets/section.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Products/model/product_stock_model.dart';
import '../../../Settings/Visibility/bloc/settings_visible_bloc.dart';

typedef LoadingBuilder = Widget Function(BuildContext context);
typedef ItemToString<T> = String Function(T item);
typedef OnProductSelected<T> = void Function(T? product);
typedef BlocSearchFunction<B> = void Function(B bloc, String query);
typedef BlocFetchAllFunction<B> = void Function(B bloc);
typedef BlocFetchByIdFunction<B> = void Function(B bloc, int productId);
typedef ProductListItemBuilder<T> = Widget Function(BuildContext context, T product);
typedef ProductDetailsBuilder<T> = Widget Function(BuildContext context, T product);

/// Single mapper: model → panel data.
typedef ProductFieldDataMapper<T> = ProductFieldData Function(T product);

// ─────────────────────────────────────────────────────────────────────────────
// Public controller — lets you open/close the product panel from anywhere.
// ─────────────────────────────────────────────────────────────────────────────

class ProductSearchFieldController<T> {
  ProductSearchFieldController._();

  _ProductSearchFieldHandle<T>? _handle;

  void _bind(_ProductSearchFieldHandle<T> handle) {
    _handle = handle;
  }

  void _unbind(_ProductSearchFieldHandle<T> handle) {
    if (identical(_handle, handle)) {
      _handle = null;
    }
  }

  void open([T? product]) {
    _handle?.open(product);
  }

  void close() {
    _handle?.close();
  }

  void toggle([T? product]) {
    _handle?.toggle(product);
  }

  bool get isOpen => _handle?.isOpen ?? false;

  // Default controller for one instance of a product field.
  static ProductSearchFieldController<T> of<T>() {
    return _Registry._instanceFor<T>(T);
  }

  // Separate controller for each invoice row.
  static ProductSearchFieldController<T> forKey<T>(Object key) {
    return _Registry._instanceFor<T>(key);
  }
}

class _Registry {
  static final Map<Object, Object> _instances = {};

  static ProductSearchFieldController<T> _instanceFor<T>(Object key) {
    return _instances.putIfAbsent(
      key,
          () => ProductSearchFieldController<T>._(),
    ) as ProductSearchFieldController<T>;
  }
}

abstract class _ProductSearchFieldHandle<T> {
  void open([T? product]);

  void close();

  void toggle([T? product]);

  bool get isOpen;
}

class ProductSearchField<T, B extends BlocBase<S>, S> extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool enabled;
  final B? bloc;
  final FocusNode? focusNode;
  final BlocSearchFunction<B>? searchFunction;
  final BlocFetchAllFunction<B>? fetchAllFunction;
  final BlocFetchByIdFunction<B>? fetchByIdFunction;
  final List<T> Function(S state) stateToItems;
  final bool Function(S state)? stateToLoading;
  final ItemToString<T> itemToString;
  final OnProductSelected<T>? onProductSelected;

  final ProductFieldDataMapper<T> productToFieldData;

  final ProductListItemBuilder<T>? customListItemBuilder;
  final ProductDetailsBuilder<T>? customDetailsBuilder;

  /// Bind to [ProductSearchFieldController] so the panel can be opened
  /// programmatically from anywhere.
  final ProductSearchFieldController<T>? controllerRef;

  /// When true, this widget renders **nothing** inline. The overlay is only
  /// opened externally through [controllerRef]. Use it once at app level for
  /// a global "price / batch lookup" panel.
  final bool viewOnly;

  final String noResultsText;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool showClearButton;
  final bool showAllOnFocus;
  final bool openOverlayOnFocus;
  final VoidCallback? onSubmit;

  final TextEditingController? headerSearchController;

  final int? initialProductId;
  final bool autoSelectInitialProduct;

  const ProductSearchField({
    super.key,
    required this.controller,
    required this.bloc,
    required this.stateToItems,
    required this.itemToString,
    required this.productToFieldData,
    this.searchFunction,
    this.fetchAllFunction,
    this.fetchByIdFunction,
    this.onProductSelected,
    this.focusNode,
    this.customListItemBuilder,
    this.customDetailsBuilder,
    this.hintText,
    this.enabled = true,
    this.stateToLoading,
    this.noResultsText = 'No products found',
    this.width,
    this.padding,
    this.showClearButton = true,
    this.showAllOnFocus = true,
    this.openOverlayOnFocus = false,
    this.headerSearchController,
    this.initialProductId,
    this.autoSelectInitialProduct = true,
    this.onSubmit,
    this.controllerRef,
    this.viewOnly = false,
  });

  @override
  State<ProductSearchField<T, B, S>> createState() =>
      _ProductSearchFieldState<T, B, S>();
}

class _ProductSearchFieldState<T, B extends BlocBase<S>, S>
    extends State<ProductSearchField<T, B, S>>
    implements _ProductSearchFieldHandle<T> {
  int _highlightedIndex = -1;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _fieldKey = GlobalKey();
  List<T> _currentSuggestions = [];
  Timer? _debounce;
  late FocusNode _internalFocusNode;
  bool _firstFocus = true;
  final FocusNode _keyboardListenerFocusNode = FocusNode(skipTraversal: true);
  T? _selectedItem;
  T? _currentHighlightedItem;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? baseCurrency;

  final TextEditingController _overlaySearchController = TextEditingController();

  bool _isSyncingFromMain = false;
  bool _isSyncingFromOverlay = false;
  bool _isSyncingFromHeader = false;

  bool _shouldKeepOverlayOpen = false;

  String _currentSearchQuery = '';

  Timer? _loadingTimeout;

  bool _isInitializing = false;
  bool _initialLoadDone = false;
  bool _isSearching = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  // ── Controller impl ────────────────────────────────────────────────
  @override
  bool get isOpen => _overlayEntry != null;

  @override
  void open([T? product]) {
    if (!mounted) return;

    if (product != null) {
      _currentHighlightedItem = product;
      if (!_currentSuggestions.contains(product)) {
        _currentSuggestions = [product, ..._currentSuggestions];
      }
      _highlightedIndex = _currentSuggestions.indexOf(product);
    } else if (_currentSuggestions.isEmpty && widget.fetchAllFunction != null) {
      // bare open(): pull a list so the panel is populated
      widget.fetchAllFunction!(widget.bloc!);
    }

    _showOverlay();
    _refreshOverlay();
  }

  @override
  void close() => _closeOverlay();

  @override
  void toggle([T? product]) => isOpen ? close() : open(product);

  // ── lifecycle ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    widget.controllerRef?._bind(this);
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onMainControllerChanged);
    _overlaySearchController.addListener(_onOverlaySearchChanged);

    if (widget.headerSearchController != null &&
        widget.headerSearchController != widget.controller) {
      widget.headerSearchController!.addListener(_onHeaderSearchChanged);
      if (widget.headerSearchController!.text != widget.controller.text) {
        widget.headerSearchController!.text = widget.controller.text;
      }
    }

    final auth = context.read<AuthBloc>().state;
    if (auth is AuthenticatedState) {
      baseCurrency = auth.loginData.company?.comLocalCcy;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.viewOnly) {
        _keyboardListenerFocusNode.requestFocus();
        _initializeFromProductId();
      }
    });
  }

  @override
  void dispose() {
    widget.controllerRef?._unbind(this);
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    widget.controller.removeListener(_onMainControllerChanged);
    _overlaySearchController.removeListener(_onOverlaySearchChanged);

    if (widget.headerSearchController != null &&
        widget.headerSearchController != widget.controller) {
      widget.headerSearchController!.removeListener(_onHeaderSearchChanged);
    }

    _debounce?.cancel();
    _loadingTimeout?.cancel();
    _removeOverlay();
    _scrollController.dispose();
    _overlaySearchController.dispose();
    super.dispose();
  }

  // ── init / sync / debounce ────────────────────────────────────────
  void _initializeFromProductId() {
    if (_isInitializing || _initialLoadDone) return;

    final hasInitialId = widget.initialProductId != null &&
        widget.initialProductId! > 0 &&
        widget.fetchByIdFunction != null;

    if (!hasInitialId) return;

    if (widget.controller.text.isNotEmpty) {
      _initialLoadDone = true;
      return;
    }

    _isInitializing = true;
    _setLoading(true);
    widget.fetchByIdFunction!(widget.bloc!, widget.initialProductId!);
  }

  void _onMainControllerChanged() {
    if (_isSyncingFromOverlay || _isSyncingFromHeader) return;
    _isSyncingFromMain = true;

    if (_overlaySearchController.text != widget.controller.text) {
      _overlaySearchController.text = widget.controller.text;
    }

    if (widget.headerSearchController != null &&
        widget.headerSearchController != widget.controller &&
        widget.headerSearchController!.text != widget.controller.text) {
      widget.headerSearchController!.text = widget.controller.text;
    }

    _isSyncingFromMain = false;
  }

  void _onOverlaySearchChanged() {
    if (_isSyncingFromMain || _isSyncingFromHeader) return;
    _isSyncingFromOverlay = true;

    final overlayText = _overlaySearchController.text;

    if (widget.controller.text != overlayText) {
      widget.controller.text = overlayText;
    }

    if (widget.headerSearchController != null &&
        widget.headerSearchController != widget.controller &&
        widget.headerSearchController!.text != overlayText) {
      widget.headerSearchController!.text = overlayText;
    }

    _isSearching = true;
    _triggerSearch(overlayText);

    _isSyncingFromOverlay = false;
  }

  void _onHeaderSearchChanged() {
    if (_isSyncingFromMain || _isSyncingFromOverlay) return;
    _isSyncingFromHeader = true;

    final headerText = widget.headerSearchController?.text ?? '';

    if (widget.controller.text != headerText) {
      widget.controller.text = headerText;
    }
    if (_overlaySearchController.text != headerText) {
      _overlaySearchController.text = headerText;
    }
    if (headerText != _currentSearchQuery) {
      _isSearching = true;
      _triggerSearch(headerText);
    }

    _isSyncingFromHeader = false;
  }

  void _setLoading(bool loading) {
    if (!mounted) return;

    _loadingTimeout?.cancel();

    if (loading) {
      _loadingTimeout = Timer(const Duration(seconds: 10), () {
        if (mounted && _isLoading) {
          debugPrint('Loading timeout - clearing loading state');
          setState(() => _isLoading = false);
          _loadingTimeout = null;
          _refreshOverlay();
        }
      });
    }

    setState(() => _isLoading = loading);
    _refreshOverlay();
  }

  void _triggerSearch(String query) {
    _debounce?.cancel();
    _loadingTimeout?.cancel();

    if (_selectedItem != null &&
        query != widget.itemToString(_selectedItem as T)) {
      setState(() {
        _selectedItem = null;
        _currentHighlightedItem = null;
        _highlightedIndex = -1;
      });
      widget.onProductSelected?.call(null);
    }

    if (query.isEmpty) {
      setState(() {
        _currentSuggestions = [];
        _isLoading = false;
        _currentSearchQuery = '';
      });
      _loadingTimeout?.cancel();
      if (!widget.viewOnly) _removeOverlay();
      _isSearching = false;
      return;
    }

    _currentSearchQuery = query;

    if (_effectiveFocusNode.hasFocus || widget.viewOnly) {
      _showOverlay();
    }

    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      if (query == _currentSearchQuery &&
          query.isNotEmpty &&
          widget.searchFunction != null) {
        _isSearching = true;
        _setLoading(true);

        try {
          widget.searchFunction!(widget.bloc!, query);
        } catch (e) {
          debugPrint('Search error: $e');
          _setLoading(false);
          _isSearching = false;
        }
      }
    });
  }

  void _closeOverlay({bool shouldResetFocus = true}) {
    _shouldKeepOverlayOpen = false;
    _removeOverlay();
    if (mounted) {
      setState(() {
        _highlightedIndex = -1;
        _currentHighlightedItem = null;
      });
    }
    if (shouldResetFocus && !widget.viewOnly) {
      _effectiveFocusNode.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _keyboardListenerFocusNode.requestFocus();
      });
    }
  }

  void _onFocusChange() {
    if (!mounted) return;

    if (_effectiveFocusNode.hasFocus) {
      if (widget.showAllOnFocus &&
          _firstFocus &&
          widget.fetchAllFunction != null) {
        _isSearching = false;
        widget.fetchAllFunction!(widget.bloc!);
        _firstFocus = false;
      }

      if ((_currentSuggestions.isNotEmpty ||
          _isLoading ||
          widget.controller.text.isNotEmpty ||
          widget.openOverlayOnFocus) &&
          widget.controller.text.isNotEmpty) {
        _showOverlay();
      }
    } else {
      if (!_shouldKeepOverlayOpen) {
        _closeOverlay(shouldResetFocus: false);
      }
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void _refreshOverlay() {
    if (_overlayEntry != null && mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _scrollToHighlightedItem() {
    if (!_scrollController.hasClients || _highlightedIndex < 0) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    if (_scrollController.position.hasContentDimensions) {
      final totalContentHeight =
          _scrollController.position.maxScrollExtent + viewportHeight;
      final approximateItemHeight = _currentSuggestions.isNotEmpty
          ? totalContentHeight / _currentSuggestions.length
          : 72.0;

      final itemPosition = _highlightedIndex * approximateItemHeight;
      final itemEnd = itemPosition + approximateItemHeight;

      if (itemPosition < currentScroll) {
        _scrollController.animateTo(
          itemPosition.clamp(0.0, maxScroll),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      } else if (itemEnd > currentScroll + viewportHeight) {
        _scrollController.animateTo(
          (itemEnd - viewportHeight).clamp(0.0, maxScroll),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // ── overlay builder ───────────────────────────────────────────────
  void _showOverlay() {
    if (_overlayEntry != null) {
      _refreshOverlay();
      return;
    }
    if (!mounted) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final overlayWidth = overlay.size.width;
    final overlayHeight = overlay.size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final panelWidth = (screenWidth * 0.85).clamp(800.0, 1400.0);
    final panelHeight = (screenHeight * 0.93).clamp(500.0, 900.0);

    final tr = AppLocalizations.of(context)!;
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontSize: 12,
      color: Theme.of(context).colorScheme.outline,
    );

    _shouldKeepOverlayOpen = true;
    final visibility = context.read<SettingsVisibleBloc>().state;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _closeOverlay(),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withValues(alpha: .3)),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: overlayWidth,
              height: overlayHeight,
              child: Center(
                child: Container(
                  width: panelWidth,
                  height: panelHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 5,
                          color: Theme.of(context).colorScheme.primary,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 5,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.clear),
                                        padding: EdgeInsets.zero,
                                        visualDensity: const VisualDensity(
                                            horizontal: -3, vertical: -3),
                                        isSelected: true,
                                        onPressed: _closeOverlay,
                                      ),
                                      const SizedBox(width: 5),
                                      Wrap(
                                        spacing: 4,
                                        crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                        children: [
                                          const Icon(Icons.shopify_rounded,
                                              size: 24),
                                          Text(
                                            tr.products.toUpperCase(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: .3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ReusableSearchBar(
                                    controller: _overlaySearchController,
                                    autofocus: true,
                                    onSubmitted: (_) {
                                      if (_highlightedIndex >= 0 &&
                                          _highlightedIndex <
                                              _currentSuggestions.length) {
                                        _handleItemSelection(
                                            _currentSuggestions[
                                            _highlightedIndex]);
                                      } else if (_currentSuggestions
                                          .isNotEmpty) {
                                        _handleItemSelection(
                                            _currentSuggestions.first);
                                      }
                                    },
                                    onChanged: (String value) {},
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  margin:
                                  const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(tr.productName,
                                            style: titleStyle?.copyWith()),
                                      ),
                                      SizedBox(
                                          width: 125,
                                          child: Text(tr.storage,
                                              style: titleStyle)),
                                      SizedBox(
                                          width: 65,
                                          child: Text(tr.unit,
                                              textAlign: TextAlign.center,
                                              style: titleStyle)),
                                      if (visibility.isWholeSale)
                                        SizedBox(
                                            width: 65,
                                            child: Text(tr.qty,
                                                textAlign: TextAlign.center,
                                                style: titleStyle)),
                                      if (visibility.isWholeSale)
                                        SizedBox(
                                            width: 65,
                                            child: Text(tr.item,
                                                textAlign: TextAlign.center,
                                                style: titleStyle)),
                                      SizedBox(
                                          width: 120,
                                          child: Text(tr.stockBalance,
                                              textAlign: TextAlign.center,
                                              style: titleStyle)),
                                      SizedBox(
                                          width: 90,
                                          child: Text(tr.unitPrice,
                                              textAlign: TextAlign.end,
                                              style: titleStyle)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _isLoading
                                      ? Center(
                                      child: UniversalShimmer.dataList(
                                          itemCount: 11,
                                          numberOfColumns: 6))
                                      : _currentSuggestions.isEmpty
                                      ? _buildEmptyState(tr)
                                      : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets
                                        .symmetric(vertical: 8),
                                    itemCount:
                                    _currentSuggestions.length,
                                    itemBuilder: (context, index) {
                                      final item =
                                      _currentSuggestions[index];
                                      final isHighlighted =
                                          index == _highlightedIndex;
                                      final isRTL =
                                          Directionality.of(context) ==
                                              TextDirection.rtl;

                                      return Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 12,
                                            vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isHighlighted
                                              ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(
                                              alpha: .08)
                                              : Colors.transparent,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Theme.of(
                                                  context)
                                                  .colorScheme
                                                  .outline
                                                  .withValues(
                                                  alpha: 0.2),
                                              width: 0.5,
                                            ),
                                            left: isHighlighted &&
                                                !isRTL
                                                ? BorderSide(
                                                color: Theme.of(
                                                    context)
                                                    .colorScheme
                                                    .primary,
                                                width: 3)
                                                : BorderSide.none,
                                            right: isHighlighted &&
                                                isRTL
                                                ? BorderSide(
                                                color: Theme.of(
                                                    context)
                                                    .colorScheme
                                                    .primary,
                                                width: 3)
                                                : BorderSide.none,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () =>
                                              _handleItemSelection(
                                                  item),
                                          onHover: (hovered) {
                                            if (hovered && mounted) {
                                              setState(() {
                                                _highlightedIndex =
                                                    index;
                                                _currentHighlightedItem =
                                                    item;
                                              });
                                              _refreshOverlay();
                                            }
                                          },
                                          child: widget
                                              .customListItemBuilder !=
                                              null
                                              ? widget
                                              .customListItemBuilder!(
                                              context, item)
                                              : _buildDefaultListItem(
                                              item),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_currentHighlightedItem != null && !_isLoading)
                          Container(
                            width: 380,
                            height: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _buildProductDetailsPanel(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildEmptyState(AppLocalizations tr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentSearchQuery.isEmpty
                  ? Icons.add_shopping_cart_rounded
                  : Icons.remove_shopping_cart_outlined,
              size: 68,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: .5),
            ),
            const SizedBox(height: 12),
            Text(
              _currentSearchQuery.isEmpty
                  ? tr.searchProducts
                  : widget.noResultsText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── panel content ─────────────────────────────────────────────────
  Widget _buildProductDetailsPanel() {
    return SingleChildScrollView(
      child: widget.customDetailsBuilder != null
          ? widget.customDetailsBuilder!(context, _currentHighlightedItem as T)
          : _buildDefaultDetails(_currentHighlightedItem as T),
    );
  }

  Widget _buildDefaultListItem(T product) {
    final data = widget.productToFieldData(product);
    final visibility = context.read<SettingsVisibleBloc>().state;
    final fontColor =
    (data.available?.toDoubleAmount() ?? 0) <= 0 ? Colors.red : null;

    final available = double.tryParse(data.available ?? '0') ?? 0;
    final batchSize = (data.batch ?? 0);
    final boxes = batchSize > 0 ? available / batchSize : 0.0;

    return Row(
      children: [
        Expanded(
          child: Text(
            data.name ?? '',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: fontColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 125,
          child: Text(data.storageName ?? '0',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        SizedBox(
          width: 65,
          child: Text(data.unit ?? '0',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        if (visibility.isWholeSale)
          SizedBox(
            width: 65,
            child: Text(
              boxes.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        if (visibility.isWholeSale)
          SizedBox(
            width: 65,
            child: Text(
              data.batch?.toString() ?? '0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        SizedBox(
          width: 120,
          child: Text(
            data.available.toAmount(decimal: 2),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _getAvailabilityColor(data.available ?? '0'),
            ),
          ),
        ),
        SizedBox(
          width: 90,
          child: Text(
            data.sellPrice.toAmount(),
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Color _getAvailabilityColor(String available) {
    final qty = int.tryParse(available) ?? 0;
    if (qty <= 0) return Colors.red;
    if (qty < 10) return Colors.orange;
    return Colors.green;
  }

  Widget _buildDefaultDetails(T product) {
    final tr = AppLocalizations.of(context)!;
    final data = widget.productToFieldData(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 3,
                      children: [
                        Text(
                          data.name ?? '',
                          style: TextStyle(
                            fontSize: context.scaledFont(0.03),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(data.code ?? 'N/A',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline)),
                            Text(data.unit ?? 'N/A',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline)),
                            _separatorDot(),
                            Text("${tr.productId} - ${data.id ?? 'N/A'}",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline)),
                            _separatorDot(),
                            Text(
                                "${tr.batchCode} - ${data.fifoNextBatchRef?.toString() ?? 'N/A'}",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_hasAnyFifo(data)) ...[
          const SizedBox(height: 8),
          _buildFifoCard(data, tr),
        ],
        const SizedBox(height: 8),
        _buildRecentSalesCard(data),
      ],
    );
  }

  Widget _separatorDot() => Container(
    margin: const EdgeInsets.all(5),
    height: 15,
    width: 1.5,
    decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withAlpha(60)),
  );

  bool _hasAnyFifo(ProductFieldData d) =>
      (d.fifoNextBatchRef?.isNotEmpty ?? false) ||
          (d.fifoNextBatchRemaining?.isNotEmpty ?? false) ||
          (d.fifoNextBatchEntry?.isNotEmpty ?? false) ||
          (d.fifoNextUnitCost?.isNotEmpty ?? false) ||
          (d.fifoNextUnitLanded?.isNotEmpty ?? false) ||
          (d.fifoCogsTotal?.isNotEmpty ?? false);

  Widget _buildFifoCard(ProductFieldData d, AppLocalizations tr) {
    return _buildDetailCard(tr.pricing, endTitle: d.fifoNextBatchRef, [
      if (d.fifoNextUnitCost != null)
        _buildDetailItem(Icons.price_change_outlined, tr.batchPurPrice,
            d.fifoNextUnitCost.toAmount(decimal: 2),
            currency: baseCurrency),
      if (d.fifoNextUnitLanded != null)
        _buildDetailItem(Icons.local_shipping_outlined, tr.landedCost,
            d.landedPrice.toAmount(decimal: 2),
            currency: baseCurrency),
      if (d.fifoNextUnitLanded != null)
        _buildDetailItem(Icons.calculate_outlined, tr.avgPurchasePrice,
            d.averagePrice.toAmount(decimal: 2),
            currency: baseCurrency),
      if (d.fifoNextUnitLanded != null)
        _buildDetailItem(Icons.calculate_outlined, tr.recentPurchasePrice,
            d.recentPrice.toAmount(decimal: 2),
            currency: baseCurrency),
      if (d.fifoCogsTotal != null)
        _buildDetailItem(Icons.calculate_outlined, tr.cogs,
            d.fifoCogsTotal.toAmount(decimal: 2),
            currency: baseCurrency, isLast: true),
    ]);
  }

  // ── recent sales ──────────────────────────────────────────────────
  Widget _buildRecentSalesCard(ProductFieldData data) {
    final tr = AppLocalizations.of(context)!;
    final rows = data.recentSales;

    if (rows.isEmpty) {
      return _buildDetailCard(tr.recentSales, [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(tr.noDataFound,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline)),
          ),
        ),
      ]);
    }

    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: .2,
      color: Theme.of(context).colorScheme.outline,
    );
    final cellStyle = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return _buildDetailCard(tr.recentSales, [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                width: 1,
                color: Theme.of(context).colorScheme.surfaceContainer),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 70, child: Text(tr.date, style: headerStyle)),
            Expanded(child: Text(tr.customer, style: headerStyle)),
            SizedBox(
                width: 35,
                child: Text(tr.qty,
                    textAlign: TextAlign.center, style: headerStyle)),
            SizedBox(
                width: 100,
                child: Text(tr.unitPrice,
                    textAlign: TextAlign.end, style: headerStyle)),
          ],
        ),
      ),
      ...rows.map((row) => _buildRecentSaleRow(row, cellStyle)),
    ]);
  }

  Widget _buildRecentSaleRow(RecentTxn row, TextStyle cellStyle) {
    final date = row.date ?? '';
    final customer = row.customer ?? '';
    final qty = row.quantity ?? 0;
    final visibility = context.watch<SettingsVisibleBloc>().state;
    final isGre = visibility.dateType == DateType.gregorian;
    final unitPrice = row.unitPrice ?? 0;
    final ccy = row.currency ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              width: .5,
              color: Theme.of(context).colorScheme.surfaceContainer),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              isGre ? date.toFormattedDate() : date.shamsiDateString,
              style: cellStyle.copyWith(
                  fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(customer,
                style: cellStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 35,
            child: Text(qty.toString(),
                textAlign: TextAlign.center,
                style: cellStyle.copyWith(fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: 100,
            child: Text("${unitPrice.toAmount()} $ccy",
                textAlign: TextAlign.end,
                style: cellStyle.copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── shared detail widgets ─────────────────────────────────────────
  Widget _buildDetailItem(
      IconData icon,
      String label,
      String value, {
        String? currency,
        Color? color,
        bool isBold = false,
        bool isLast = false,
      }) {
    final displayValue =
    currency != null && currency.isNotEmpty ? "$value $currency" : value;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
              bottom: BorderSide(
                  width: 1,
                  color: Theme.of(context).colorScheme.surfaceContainer))),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon,
                size: 18,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: .8)),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.outline)),
          ),
          Expanded(
            child: Text(displayValue,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
      String title,
      List<Widget> children, {
        String? endTitle,
      }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: .01),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: .2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              children: [
                SectionTitle(title: title),
                if (endTitle != null) ...[
                  const Spacer(),
                  Text(
                    endTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  // ── selection / clear / keys ──────────────────────────────────────
  void _handleItemSelection(T item) {
    final selectedProductName = widget.itemToString(item);

    _isSyncingFromMain = true;
    _isSyncingFromOverlay = true;
    _isSyncingFromHeader = true;

    widget.controller.text = selectedProductName;
    _overlaySearchController.text = selectedProductName;

    if (widget.headerSearchController != null &&
        widget.headerSearchController != widget.controller) {
      widget.headerSearchController!.text = selectedProductName;
    }

    _isSyncingFromMain = false;
    _isSyncingFromOverlay = false;
    _isSyncingFromHeader = false;

    setState(() {
      _selectedItem = item;
      _currentHighlightedItem = item;
      final idx = _currentSuggestions.indexWhere(
            (e) => widget.itemToString(e) == widget.itemToString(item),
      );
      if (idx >= 0) _highlightedIndex = idx;
    });

    widget.onProductSelected?.call(item);

    if (!widget.viewOnly) {
      _closeOverlay();
      widget.onSubmit?.call();
    }
    // In routes-only mode: keep the panel open so the user can keep inspecting.
  }

  Widget? _buildSuffixIcon() {
    return widget.showClearButton && widget.controller.text.isNotEmpty
        ? IconButton(
      constraints: const BoxConstraints(),
      splashRadius: 2,
      icon: Icon(Icons.clear,
          size: 16, color: Theme.of(context).colorScheme.secondary),
      onPressed: () {
        _isSyncingFromMain = true;
        _isSyncingFromOverlay = true;
        _isSyncingFromHeader = true;

        widget.controller.clear();
        _overlaySearchController.clear();

        if (widget.headerSearchController != null &&
            widget.headerSearchController != widget.controller) {
          widget.headerSearchController!.clear();
        }

        _isSyncingFromMain = false;
        _isSyncingFromOverlay = false;
        _isSyncingFromHeader = false;

        _debounce?.cancel();
        _loadingTimeout?.cancel();

        if (mounted) {
          setState(() {
            _currentSuggestions = [];
            _firstFocus = true;
            _selectedItem = null;
            _currentHighlightedItem = null;
            _highlightedIndex = -1;
            _isLoading = false;
            _currentSearchQuery = '';
            _initialLoadDone = false;
          });
        }
        widget.onProductSelected?.call(null);
        _closeOverlay();
      },
    )
        : null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_overlayEntry != null) _closeOverlay();
      return KeyEventResult.handled;
    }

    if (_overlayEntry == null) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        widget.onSubmit?.call();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_currentSuggestions.isNotEmpty && mounted) {
        setState(() {
          _highlightedIndex =
              (_highlightedIndex + 1) % _currentSuggestions.length;
          _currentHighlightedItem = _currentSuggestions[_highlightedIndex];
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToHighlightedItem();
        });
        _refreshOverlay();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_currentSuggestions.isNotEmpty && mounted) {
        setState(() {
          _highlightedIndex = (_highlightedIndex -
              1 +
              _currentSuggestions.length) %
              _currentSuggestions.length;
          _currentHighlightedItem = _currentSuggestions[_highlightedIndex];
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToHighlightedItem();
        });
        _refreshOverlay();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 &&
          _highlightedIndex < _currentSuggestions.length) {
        _handleItemSelection(_currentSuggestions[_highlightedIndex]);
      } else if (_currentSuggestions.isNotEmpty) {
        _handleItemSelection(_currentSuggestions.first);
      } else {
        _closeOverlay();
        widget.onSubmit?.call();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ── bloc listener (shared by both modes) ──────────────────────────
  void _onBlocStateChanged(BuildContext context, S state) {
    _loadingTimeout?.cancel();

    final items = widget.stateToItems(state);
    final isLoading =
        widget.stateToLoading != null && widget.stateToLoading!(state);

    if (!mounted) return;

    setState(() {
      if (_isSearching || _isInitializing) {
        _currentSuggestions = items;
      }

      _isLoading = isLoading;

      if (!isLoading) {
        if (_isInitializing && items.isNotEmpty && !_initialLoadDone) {
          final product = items.first;
          final productName = widget.itemToString(product);

          _isSyncingFromMain = true;
          _isSyncingFromOverlay = true;
          _isSyncingFromHeader = true;

          widget.controller.text = productName;
          _overlaySearchController.text = productName;

          if (widget.headerSearchController != null &&
              widget.headerSearchController != widget.controller) {
            widget.headerSearchController!.text = productName;
          }

          _isSyncingFromMain = false;
          _isSyncingFromOverlay = false;
          _isSyncingFromHeader = false;

          _selectedItem = product;
          _currentHighlightedItem = product;
          _highlightedIndex = 0;

          widget.onProductSelected?.call(product);
          _initialLoadDone = true;
          _isInitializing = false;
          _isSearching = false;
        } else if (items.isNotEmpty && _highlightedIndex >= items.length) {
          _highlightedIndex = items.length - 1;
          _currentHighlightedItem = items[_highlightedIndex];
        } else if (items.isEmpty) {
          _highlightedIndex = -1;
          _currentHighlightedItem = null;
        } else if (items.isNotEmpty &&
            _highlightedIndex >= 0 &&
            _highlightedIndex < items.length) {
          _currentHighlightedItem = items[_highlightedIndex];
        } else if (items.isNotEmpty) {
          _highlightedIndex = 0;
          _currentHighlightedItem = items[0];
        }

        if (_selectedItem != null && items.isNotEmpty) {
          final selectedIndex = items.indexWhere(
                (item) =>
            widget.itemToString(item) ==
                widget.itemToString(_selectedItem as T),
          );
          if (selectedIndex >= 0) {
            _highlightedIndex = selectedIndex;
            _currentHighlightedItem = items[selectedIndex];
          }
        }

        _isSearching = false;
      }
    });

    if (!isLoading &&
        _currentSuggestions.isNotEmpty &&
        _highlightedIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToHighlightedItem();
      });
    }

    _refreshOverlay();

    if (widget.viewOnly) {
      // Keep the overlay open; nothing to do on focus.
      return;
    }

    final hasText = widget.controller.text.isNotEmpty;
    if (_effectiveFocusNode.hasFocus &&
        (hasText || isLoading || widget.openOverlayOnFocus)) {
      _showOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    // View-only mode: contribute nothing to layout. Overlay is driven by
    // controllerRef.open() / close().
    if (widget.viewOnly) {
      return widget.bloc != null
          ? BlocListener<B, S>(
        bloc: widget.bloc,
        listener: _onBlocStateChanged,
        child: const SizedBox.shrink(),
      )
          : const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: widget.width ?? double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: Focus(
                focusNode: _keyboardListenerFocusNode,
                onKeyEvent: _handleKeyEvent,
                child: TextFormField(
                  focusNode: _effectiveFocusNode,
                  enabled: widget.enabled,
                  key: _fieldKey,
                  controller: widget.controller,
                  onChanged: (value) {
                    if (_isSyncingFromOverlay || _isSyncingFromHeader) return;

                    if (mounted) {
                      setState(() => _highlightedIndex = -1);
                    }

                    if (_selectedItem != null &&
                        value != widget.itemToString(_selectedItem as T)) {
                      setState(() {
                        _selectedItem = null;
                        _currentHighlightedItem = null;
                      });
                      widget.onProductSelected?.call(null);
                    }

                    if (_overlaySearchController.text != value) {
                      _overlaySearchController.text = value;
                    }

                    if (widget.headerSearchController != null &&
                        widget.headerSearchController != widget.controller &&
                        widget.headerSearchController!.text != value) {
                      widget.headerSearchController!.text = value;
                    }
                    _triggerSearch(value);
                  },
                  onFieldSubmitted: (_) {
                    if (_currentSuggestions.isEmpty) {
                      _closeOverlay();
                      widget.onSubmit?.call();
                    } else if (_highlightedIndex >= 0 &&
                        _highlightedIndex < _currentSuggestions.length) {
                      _handleItemSelection(
                          _currentSuggestions[_highlightedIndex]);
                    } else if (_currentSuggestions.isNotEmpty) {
                      _handleItemSelection(_currentSuggestions.first);
                    } else {
                      _closeOverlay();
                      widget.onSubmit?.call();
                    }
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    suffixIconConstraints: const BoxConstraints(),
                    suffixIcon: _buildSuffixIcon(),
                    isDense: true,
                    hintText: widget.hintText,
                  ),
                ),
              ),
            ),
            if (widget.bloc != null)
              BlocListener<B, S>(
                bloc: widget.bloc,
                listener: _onBlocStateChanged,
                child: const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}