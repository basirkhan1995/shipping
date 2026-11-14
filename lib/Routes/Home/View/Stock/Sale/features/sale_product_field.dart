import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Date/shamsi_converter.dart';

import '../../../../../../Features/Widgets/extensions.dart';
import '../../../../../../Features/Widgets/section.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../Settings/Visibility/bloc/settings_visible_bloc.dart';

typedef LoadingBuilder = Widget Function(BuildContext context);
typedef ItemToString<T> = String Function(T item);
typedef OnProductSelected<T> = void Function(T? product);
typedef BlocSearchFunction<B> = void Function(B bloc, String query);
typedef BlocFetchAllFunction<B> = void Function(B bloc);
typedef BlocFetchByIdFunction<B> = void Function(B bloc, int productId);
typedef ProductListItemBuilder<T> = Widget Function(BuildContext context, T product);
typedef ProductDetailsBuilder<T> = Widget Function(BuildContext context, T product);

/// Optional generic that lets callers feed "recent sales" rows into the
/// details panel. Leave it null and the section is not rendered.
typedef RecentSalesProvider<T> = List<dynamic> Function(T product);

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

  final String? Function(T) getProductId;
  final String? Function(T) getProductName;
  final String? Function(T) getProductCode;
  final int? Function(T) getStorageId;
  final String? Function(T) getStorageName;
  final String? Function(T) getAvailable;
  final int? Function(T) getBatch;
  final String? Function(T) getAveragePrice;
  final String? Function(T) getRecentPrice;
  final String? Function(T) getLandedPrice;
  final String? Function(T) getSellPrice;

  final String? Function(T)? getProductUnit;
  final String? Function(T)? getProductBrand;
  final String? Function(T)? getProductModel;
  final String? Function(T)? getProductMadeIn;
  final String? Function(T)? getProductGrade;
  final String? Function(T)? getProductColor;
  final String? Function(T)? getProductDetails;

  /// Callback to pull recent sale transactions out of the product model.
  /// Each element is expected to expose:
  ///   [0] date (String?), [1] customer (String?), [2] qty (int?),
  ///   [3] unitPrice (num?), [4] amount (num?), [5] currency (String?).
  /// A small record type can be used instead — see `_RecentSaleView`.
  final RecentSalesProvider<T>? getRecentSales;

  final ProductListItemBuilder<T>? customListItemBuilder;
  final ProductDetailsBuilder<T>? customDetailsBuilder;

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
    required this.searchFunction,
    required this.getBatch,
    required this.fetchAllFunction,
    required this.stateToItems,
    required this.itemToString,
    required this.onProductSelected,
    required this.getProductId,
    required this.getProductName,
    required this.getProductCode,
    required this.getStorageId,
    required this.getLandedPrice,
    required this.getStorageName,
    required this.getAvailable,
    required this.getAveragePrice,
    required this.getRecentPrice,
    required this.getSellPrice,
    this.focusNode,
    this.getProductUnit,
    this.onSubmit,
    this.getProductBrand,
    this.getProductModel,
    this.getProductMadeIn,
    this.getProductGrade,
    this.getProductColor,
    this.getProductDetails,
    this.getRecentSales,
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
    this.fetchByIdFunction,
    this.autoSelectInitialProduct = true,
  });

  @override
  State<ProductSearchField<T, B, S>> createState() => _ProductSearchFieldState<T, B, S>();
}

class _ProductSearchFieldState<T, B extends BlocBase<S>, S> extends State<ProductSearchField<T, B, S>> {
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

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onMainControllerChanged);
    _overlaySearchController.addListener(_onOverlaySearchChanged);

    if (widget.headerSearchController != null && widget.headerSearchController != widget.controller) {
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
      _keyboardListenerFocusNode.requestFocus();
      _initializeFromProductId();
    });
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    widget.controller.removeListener(_onMainControllerChanged);
    _overlaySearchController.removeListener(_onOverlaySearchChanged);

    if (widget.headerSearchController != null && widget.headerSearchController != widget.controller) {
      widget.headerSearchController!.removeListener(_onHeaderSearchChanged);
    }

    _debounce?.cancel();
    _loadingTimeout?.cancel();
    _removeOverlay();
    _scrollController.dispose();
    _overlaySearchController.dispose();
    super.dispose();
  }

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
          setState(() {
            _isLoading = false;
          });
          _loadingTimeout = null;
          _refreshOverlay();
        }
      });
    }

    setState(() {
      _isLoading = loading;
    });

    _refreshOverlay();
  }
  bool _isSearching = false;
  void _triggerSearch(String query) {
    _debounce?.cancel();
    _loadingTimeout?.cancel();

    if (_selectedItem != null && query != widget.itemToString(_selectedItem as T)) {
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
      _removeOverlay();
      _isSearching = false;
      return;
    }

    _currentSearchQuery = query;

    if (_effectiveFocusNode.hasFocus) {
      _showOverlay();
    }

    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      if (query == _currentSearchQuery && query.isNotEmpty && widget.searchFunction != null) {
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
    setState(() {
      _highlightedIndex = -1;
      _currentHighlightedItem = null;
    });
    if (shouldResetFocus) {
      _effectiveFocusNode.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _keyboardListenerFocusNode.requestFocus();
        }
      });
    }
  }

  void _onFocusChange() {
    if (!mounted) return;

    if (_effectiveFocusNode.hasFocus) {
      if (widget.showAllOnFocus && _firstFocus && widget.fetchAllFunction != null) {
        _isSearching = false;
        widget.fetchAllFunction!(widget.bloc!);
        _firstFocus = false;
      }

      if ((_currentSuggestions.isNotEmpty || _isLoading || widget.controller.text.isNotEmpty || widget.openOverlayOnFocus) &&
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

    final double itemPosition;

    if (_scrollController.position.hasContentDimensions) {
      final totalContentHeight = _scrollController.position.maxScrollExtent + viewportHeight;
      final approximateItemHeight = _currentSuggestions.isNotEmpty
          ? totalContentHeight / _currentSuggestions.length
          : 72.0;

      itemPosition = _highlightedIndex * approximateItemHeight;
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

  void _showOverlay() {
    if (_overlayEntry != null) {
      _refreshOverlay();
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (renderBox == null || overlay == null || !mounted) return;

    final overlayWidth = overlay.size.width;
    final overlayHeight = overlay.size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const double panelWidthPercentage = 0.85;
    const double panelHeightPercentage = 0.93;

    double panelWidth = screenWidth * panelWidthPercentage;
    double panelHeight = screenHeight * panelHeightPercentage;

    const double maxPanelWidth = 1400;
    const double maxPanelHeight = 900;
    const double minPanelWidth = 800;
    const double minPanelHeight = 500;

    panelWidth = panelWidth.clamp(minPanelWidth, maxPanelWidth);
    panelHeight = panelHeight.clamp(minPanelHeight, maxPanelHeight);
    final tr = AppLocalizations.of(context)!;
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, color: Theme.of(context).colorScheme.outline);
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
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: .5),
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
                    padding: EdgeInsets.all(4),
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
                                        icon: Icon(Icons.clear),
                                        padding: const EdgeInsets.all(0.0),
                                        visualDensity: VisualDensity(horizontal: -3,vertical: -3),
                                        isSelected: true,
                                        onPressed: (){
                                          _closeOverlay();
                                        },
                                      ),
                                      SizedBox(width: 5),
                                      Wrap(
                                        spacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Icon(Icons.shopify_rounded,size: 24,),
                                          Text(tr.products.toUpperCase(),style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: .3
                                          )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context).colorScheme.outline.withValues(alpha: .1),
                                      ),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _overlaySearchController,
                                    autofocus: true,
                                    showCursor: true,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!.search,
                                      prefixIcon: Icon(Icons.search,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 25,
                                      ),
                                      suffixIcon: _overlaySearchController.text.isNotEmpty
                                          ? IconButton(
                                        icon: Icon(Icons.clear,
                                          color: Theme.of(context).colorScheme.outline,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _overlaySearchController.clear();
                                          _triggerSearch('');
                                        },
                                      )
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(3),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(3),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(3),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 1,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    ),
                                    onSubmitted: (_) {
                                      if (_highlightedIndex >= 0 && _highlightedIndex < _currentSuggestions.length) {
                                        _handleItemSelection(_currentSuggestions[_highlightedIndex]);
                                      } else if (_currentSuggestions.isNotEmpty) {
                                        _handleItemSelection(_currentSuggestions.first);
                                      }
                                    },
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(tr.productName, style: titleStyle?.copyWith(fontSize: 16))),
                                      SizedBox(width: 125, child: Text(tr.storage, textAlign: TextAlign.start, style: titleStyle)),
                                      SizedBox(width: 80, child: Text(tr.unit, textAlign: TextAlign.center, style: titleStyle)),
                                      SizedBox(width: 120, child: Text(tr.stock, textAlign: TextAlign.center, style: titleStyle)),
                                      if(visibility.isWholeSale)
                                        SizedBox(width: 100, child: Text(tr.batchTitle, textAlign: TextAlign.center, style: titleStyle)),
                                      SizedBox(width: 100, child: Text(tr.unitPrice, textAlign: TextAlign.end, style: titleStyle)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _isLoading
                                      ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                                        const SizedBox(height: 16),
                                        Text(
                                          AppLocalizations.of(context)!.loading,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                      : _currentSuggestions.isEmpty
                                      ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Padding(
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
                                        )
                                      ],
                                    ),
                                  )
                                      : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: _currentSuggestions.length,
                                    itemBuilder: (context, index) {
                                      final item = _currentSuggestions[index];
                                      final isHighlighted = index == _highlightedIndex;
                                      final isRTL = Directionality.of(context) == TextDirection.rtl;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isHighlighted
                                              ? Theme.of(context).colorScheme.primary.withValues(alpha: .08)
                                              : Colors.transparent,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                              width: 0.5,
                                            ),
                                            left: isHighlighted && !isRTL
                                                ? BorderSide(
                                              color: Theme.of(context).colorScheme.primary,
                                              width: 3,
                                            )
                                                : BorderSide.none,
                                            right: isHighlighted && isRTL
                                                ? BorderSide(
                                              color: Theme.of(context).colorScheme.primary,
                                              width: 3,
                                            )
                                                : BorderSide.none,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () => _handleItemSelection(item),
                                          onHover: (hovered) {
                                            if (hovered && mounted) {
                                              setState(() {
                                                _highlightedIndex = index;
                                                _currentHighlightedItem = item;
                                              });
                                              _refreshOverlay();
                                            }
                                          },
                                          child: widget.customListItemBuilder != null
                                              ? widget.customListItemBuilder!(context, item)
                                              : _buildDefaultListItem(item),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_currentHighlightedItem != null && !_isLoading && _currentSuggestions.isNotEmpty)
                          Container(
                            width: 380,
                            height: double.infinity,
                            margin: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildProductDetailsPanel(),
                            ),
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

  Widget _buildProductDetailsPanel() {
    return SingleChildScrollView(
      child: widget.customDetailsBuilder != null
          ? widget.customDetailsBuilder!(context, _currentHighlightedItem as T)
          : _buildDefaultDetails(_currentHighlightedItem as T),
    );
  }

  Widget _buildDefaultListItem(T product) {
    final visibility = context.read<SettingsVisibleBloc>().state;
    Color? fontColor = widget.getAvailable(product).toDoubleAmount() <= 0 ? Colors.red : null;
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.getProductName(product) ?? '',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17,color: fontColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 125,
          child: Text(
            widget.getStorageName(product) ?? '0',
            textAlign: TextAlign.start,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        SizedBox(
          width: 80,
          child: Text(
            widget.getProductUnit!(product) ?? '0',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),

        SizedBox(
          width: 120,
          child: Text(
            widget.getAvailable(product) ?? '0',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: _getAvailabilityColor(widget.getAvailable(product) ?? '0'),
            ),
          ),
        ),
        if(visibility.isWholeSale)
          SizedBox(
            width: 100,
            child: Text(
              widget.getBatch(product).toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        SizedBox(
          width: 100,
          child: Text(
            widget.getSellPrice(product).toAmount(),
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
                          widget.getProductName(product) ?? '',
                          style: TextStyle(fontSize: context.scaledFont(0.03), fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              widget.getProductCode(product) ?? 'N/A',
                              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline),
                            ),
                            Text(
                              widget.getProductUnit?.call(product) ?? 'N/A',
                              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline),
                            ),
                            Container(
                              margin: EdgeInsets.all(5),
                              height: 15,
                              width: 1.5,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.outline.withAlpha(60),
                              ),
                            ),
                            Text(
                              "#${tr.productId} - ${widget.getProductId.call(product) ?? 'N/A'}",
                              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline),
                            ),
                            Container(
                              margin: EdgeInsets.all(5),
                              height: 15,
                              width: 1.5,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.outline.withAlpha(60),
                              ),
                            ),
                            Text(
                              "#${tr.batchTitle} - ${widget.getBatch(product)?.toString() ?? 'N/A'}",
                              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline),
                            ),
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
        const SizedBox(height: 8),
        _buildDetailCard(tr.pricing, [
          _buildDetailItem(Icons.trending_up, tr.avgPurchasePrice, widget.getAveragePrice(product).toAmount(decimal: 2), currency: baseCurrency),
          _buildDetailItem(Icons.history, tr.recentPurchasePrice, widget.getRecentPrice(product).toAmount(decimal: 2), currency: baseCurrency),
          _buildDetailItem(Icons.money, tr.landedCost, widget.getLandedPrice(product).toAmount(decimal: 2), currency: baseCurrency),
          _buildDetailItem(Icons.attach_money, tr.sellPrice, widget.getSellPrice(product).toAmount(decimal: 2), color: Theme.of(context).colorScheme.primary, isLast: true, isBold: true, currency: baseCurrency),
        ]),

        // ── NEW: recent sales section (only rendered when data is provided)
        if (widget.getRecentSales != null) ...[
          const SizedBox(height: 8),
          _buildRecentSalesCard(product),
        ],

        const SizedBox(height: 8),
        if (widget.getProductDetails != null && widget.getProductDetails!(product) != null && widget.getProductDetails!(product)!.isNotEmpty)
          _buildDetailCard(tr.productDetails, [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.getProductDetails!(product) ?? '',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ]),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Recent Sales
  // ─────────────────────────────────────────────────────────────

  /// Renders the recent sales list. The provider must return rows shaped like
  /// `_RecentSaleView` (or anything with `date`, `customer`, `qty`,
  /// `unitPrice`, `amount`, `currency`).
  Widget _buildRecentSalesCard(T product) {
    final tr = AppLocalizations.of(context)!;
    final rows = widget.getRecentSales!(product);

    if (rows.isEmpty) {
      return _buildDetailCard(tr.recentSales, [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              tr.noDataFound,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
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

      // Header row
      Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 1,
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 70, child: Text(tr.date, style: headerStyle)),
            Expanded(child: Text(tr.customer, style: headerStyle)),
            SizedBox(width: 35, child: Text(tr.qty, textAlign: TextAlign.center, style: headerStyle)),
            SizedBox(width: 100, child: Text(tr.unitPrice, textAlign: TextAlign.end, style: headerStyle)),
          ],
        ),
      ),
      // Data rows
      ...rows.map((row) => _buildRecentSaleRow(row, cellStyle)),
    ]);
  }

  Widget _buildRecentSaleRow(dynamic row, TextStyle cellStyle) {
    final date = row.date as String? ?? '';
    final customer = row.customer as String? ?? '';
    final qty = (row.quantity as int?) ?? 0;
    final visibility = context.watch<SettingsVisibleBloc>().state;
    final isGre = visibility.dateType == DateType.gregorian;
    // Local (account-currency) unit price and currency
    final unitLocal = (row.localSalePrice as num?) ?? 0;
    final localCurrency = row.currency as String? ?? '';

    // Fallback to base values if local fields are missing (older data)
    final unitBase = (row.originalSalePrice as num?) ?? 0;
    final displayUnit = unitLocal > 0 ? unitLocal : unitBase;
    final displayCurrency = localCurrency.isNotEmpty
        ? localCurrency
        : (baseCurrency ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: .5,
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
             isGre? date.toFormattedDate() : date.shamsiDateString,
              style: cellStyle.copyWith(fontSize: 11,fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              customer,
              style: cellStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              qty.toString(),
              textAlign: TextAlign.center,
              style: cellStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              "${displayUnit.toDouble().toAmount()} $displayCurrency",
              textAlign: TextAlign.end,
              style: cellStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
      IconData icon,
      String label,
      String value, {
        String? currency,
        Color? color,
        bool isBold = false,
        bool isLast = false,
      }) {
    final displayValue = currency != null && currency.isNotEmpty ? "$value $currency" : value;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3,horizontal: 4),
      decoration: BoxDecoration(
          border: isLast
              ? null : Border(
              bottom: BorderSide(
                  width: 1,
                  color: Theme.of(context).colorScheme.surfaceContainer
              )
          )
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary.withValues(alpha: .8)),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: Text(label, style: TextStyle(fontSize: 13,color: Theme.of(context).colorScheme.outline)),
          ),
          Expanded(
            child: Text(
              displayValue,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: .01),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title),
          const SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  void _handleItemSelection(T item) {
    final selectedProductName = widget.itemToString(item);

    _isSyncingFromMain = true;
    _isSyncingFromOverlay = true;
    _isSyncingFromHeader = true;

    widget.controller.text = selectedProductName;
    _overlaySearchController.text = selectedProductName;

    if (widget.headerSearchController != null && widget.headerSearchController != widget.controller) {
      widget.headerSearchController!.text = selectedProductName;
    }

    _isSyncingFromMain = false;
    _isSyncingFromOverlay = false;
    _isSyncingFromHeader = false;

    setState(() {
      _selectedItem = item;
      _currentHighlightedItem = item;
      final selectedIndex = _currentSuggestions.indexWhere(
            (element) => widget.itemToString(element) == widget.itemToString(item),
      );
      if (selectedIndex >= 0) {
        _highlightedIndex = selectedIndex;
      }
    });

    widget.onProductSelected?.call(item);
    _closeOverlay();
    widget.onSubmit?.call();
  }

  Widget? _buildSuffixIcon() {
    return widget.showClearButton && widget.controller.text.isNotEmpty
        ? IconButton(
      constraints: const BoxConstraints(),
      splashRadius: 2,
      icon: Icon(Icons.clear, size: 16, color: Theme.of(context).colorScheme.secondary),
      onPressed: () {
        _isSyncingFromMain = true;
        _isSyncingFromOverlay = true;
        _isSyncingFromHeader = true;

        widget.controller.clear();
        _overlaySearchController.clear();

        if (widget.headerSearchController != null && widget.headerSearchController != widget.controller) {
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
      if (_overlayEntry != null) {
        _closeOverlay();
        return KeyEventResult.handled;
      }
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
          _highlightedIndex = (_highlightedIndex + 1) % _currentSuggestions.length;
          _currentHighlightedItem = _currentSuggestions[_highlightedIndex];
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToHighlightedItem();
          }
        });
        _refreshOverlay();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_currentSuggestions.isNotEmpty && mounted) {
        setState(() {
          _highlightedIndex = (_highlightedIndex - 1 + _currentSuggestions.length) % _currentSuggestions.length;
          _currentHighlightedItem = _currentSuggestions[_highlightedIndex];
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToHighlightedItem();
          }
        });
        _refreshOverlay();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _currentSuggestions.length) {
        final selectedItem = _currentSuggestions[_highlightedIndex];
        _handleItemSelection(selectedItem);
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

  @override
  Widget build(BuildContext context) {
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
                      setState(() {
                        _highlightedIndex = -1;
                      });
                    }

                    if (_selectedItem != null && value != widget.itemToString(_selectedItem as T)) {
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
                    } else if (_highlightedIndex >= 0 && _highlightedIndex < _currentSuggestions.length) {
                      _handleItemSelection(_currentSuggestions[_highlightedIndex]);
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
                listener: (context, state) {
                  _loadingTimeout?.cancel();

                  final items = widget.stateToItems(state);
                  final isLoading = widget.stateToLoading != null && widget.stateToLoading!(state);

                  if (mounted) {
                    setState(() {
                      if (_isSearching || _isInitializing) {
                        _currentSuggestions = items;
                      } else if (!_isSearching && _isInitializing) {
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
                        }
                        else if (items.isNotEmpty && _highlightedIndex >= items.length) {
                          _highlightedIndex = items.length - 1;
                          _currentHighlightedItem = items[_highlightedIndex];
                        }
                        else if (items.isEmpty) {
                          _highlightedIndex = -1;
                          _currentHighlightedItem = null;
                        }
                        else if (items.isNotEmpty && _highlightedIndex >= 0 && _highlightedIndex < items.length) {
                          _currentHighlightedItem = items[_highlightedIndex];
                        }
                        else if (items.isNotEmpty) {
                          _highlightedIndex = 0;
                          _currentHighlightedItem = items[0];
                        }

                        if (_selectedItem != null && items.isNotEmpty) {
                          final selectedIndex = items.indexWhere(
                                (item) => widget.itemToString(item) == widget.itemToString(_selectedItem as T),
                          );
                          if (selectedIndex >= 0) {
                            _highlightedIndex = selectedIndex;
                            _currentHighlightedItem = items[selectedIndex];
                          }
                        }

                        _isSearching = false;
                      }
                    });

                    if (!isLoading && _currentSuggestions.isNotEmpty && _highlightedIndex >= 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _scrollToHighlightedItem();
                        }
                      });
                    }

                    _refreshOverlay();
                  }

                  final hasText = widget.controller.text.isNotEmpty;
                  if (_effectiveFocusNode.hasFocus && (hasText || isLoading || widget.openOverlayOnFocus)) {
                    _showOverlay();
                  }
                },
                child: const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}