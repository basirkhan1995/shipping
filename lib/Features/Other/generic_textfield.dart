import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flag/flag_widget.dart';
import '../../Routes/Home/View/Finance/View/Currencies/bloc/currencies_bloc.dart';
import '../../Routes/Home/View/Finance/View/Currencies/model/ccy_model.dart';
import '../../l10n/app_localizations.dart';

typedef LoadingBuilder = Widget Function(BuildContext context);
typedef ItemBuilder<T> = Widget Function(BuildContext context, T item);
typedef ItemToString<T> = String Function(T item);
typedef OnItemSelected<T> = void Function(T item);
typedef BlocSearchFunction<B> = void Function(B bloc, String query);
typedef BlocFetchAllFunction<B> = void Function(B bloc);
typedef OnFieldSubmitFunction = void Function({required String name});

enum TextFieldStyle { roundedBorder, underline, noBorder }

// Local mirror of the ZTextField currency model so this file doesn't
// depend on `ztextfield.dart`.
class _CcyItem {
  final String code;
  final String symbol;
  final String? name;
  final Widget? flagIcon;
  final CurrenciesModel? originalModel;

  const _CcyItem({
    required this.code,
    required this.symbol,
    this.name,
    this.flagIcon,
    this.originalModel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _CcyItem && other.code == code);

  @override
  int get hashCode => code.hashCode;
}

class GenericTextField<T, B extends BlocBase<S>, S> extends StatefulWidget {
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  final LoadingBuilder? loadingBuilder;
  final bool Function(S state)? stateToLoading;
  final double? width;
  final double? height;
  final bool isEnabled;
  final TextEditingController? controller;
  final String? hintText;
  final String title;
  final bool compactMode;
  final Widget? trailing;
  final Widget? end;
  final IconData? icon;
  final bool isRequired;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final OnItemSelected<T>? onSelected;
  final OnFieldSubmitFunction? onSubmitted;
  final ItemBuilder<T> itemBuilder;
  final ItemToString<T> itemToString;
  final B? bloc;
  final BlocSearchFunction<B>? searchFunction;
  final BlocFetchAllFunction<B>? fetchAllFunction;
  final String? Function(T)? itemValidator;
  final String noResultsText;
  final List<T> Function(S state) stateToItems;
  final EdgeInsetsGeometry? padding;
  final bool readOnly;
  final bool showClearButton;
  final bool showAllOnFocus;
  final T? allOption;
  final bool showAllOption;
  final String allOptionText;
  final TextFieldStyle textFieldStyle;

  // ── Currency selector (built-in) ─────────────────────────────
  /// When `true`, an inline currency dropdown renders as the field's
  /// prefix, pulling from `CurrenciesBloc`. Use for GL endpoints where
  /// the account's currency is user-chosen, not fixed.
  final bool showCurrencySelector;

  /// Pre-select a currency code (e.g. baseCurrency or the leg's ccy).
  final String? selectedCurrencyCodeOverride;

  /// Fires when the user picks a different currency.
  final ValueChanged<CurrenciesModel?>? onCurrencySelectorChanged;

  /// Allow the user to change the currency. When false, the dropdown is
  /// still shown but disabled (e.g. stakeholder's fixed ccy).
  final bool isCurrencySelectorEnabled;

  /// Filter to currencies with `ccyStatus == currencyStatus` (default 1).
  final int? currencyStatus;

  /// Fixed width for the currency dropdown (default 110).
  final double currencySelectorWidth;

  const GenericTextField({
    super.key,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.isEnabled = true,
    this.height = 60,
    required this.controller,
    required this.title,
    this.onSubmitted,
    this.readOnly = false,
    required this.itemBuilder,
    required this.itemToString,
    required this.stateToItems,
    this.loadingBuilder,
    this.stateToLoading,
    this.bloc,
    this.searchFunction,
    this.fetchAllFunction,
    this.hintText,
    this.compactMode = true,
    this.onSelected,
    this.icon,
    this.trailing,
    this.end,
    this.isRequired = false,
    this.onChanged,
    this.validator,
    this.width,
    this.itemValidator,
    this.noResultsText = 'No results found',
    this.padding,
    this.showClearButton = true,
    this.showAllOnFocus = true,
    this.allOption,
    this.showAllOption = false,
    this.allOptionText = 'All',
    this.textFieldStyle = TextFieldStyle.roundedBorder,
    this.showCurrencySelector = false,
    this.selectedCurrencyCodeOverride,
    this.onCurrencySelectorChanged,
    this.isCurrencySelectorEnabled = true,
    this.currencyStatus = 1,
    this.currencySelectorWidth = 110,
  }) : assert(
  bloc != null || searchFunction == null,
  'If searchFunction is provided, bloc must also be provided',
  );

  @override
  State<GenericTextField<T, B, S>> createState() =>
      _GenericTextFieldState<T, B, S>();
}

class _GenericTextFieldState<T, B extends BlocBase<S>, S>
    extends State<GenericTextField<T, B, S>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _fieldKey = GlobalKey();

  late FocusNode _focusNode;

  late final FocusNode _keyboardListenerFocus =
  FocusNode(skipTraversal: true, debugLabel: 'GenericTextFieldKeys');

  List<T> _currentSuggestions = [];
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  static const double _itemHeight = 36;
  bool _showClear = false;
  bool _firstFocus = true;
  bool _isUserSearching = false;

  int _highlightedIndex = -1;

  // ── Currency state ───────────────────────────────────────────
  CurrenciesModel? _selectedCurrency;
  List<_CcyItem> _ccyItems = [];

  /// ✅ FIX: track the controller text the current `_selectedCurrency`
  /// was resolved for. When the account row changes (even to another row
  /// with the same currency code) we must re-resolve, otherwise the
  /// dropdown keeps showing the first match for that code (e.g. AFN).
  String? _resolvedForText;

  bool get _usingExternalFocusNode => widget.focusNode != null;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant GenericTextField<T, B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }

    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      if (!_usingExternalFocusNode) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }

    // ✅ FIX: re-resolve currency when:
    //   1. the caller changes the desired code, OR
    //   2. the selector is shown AND the controller text changed
    //      (i.e. a different account row was picked — possibly the
    //      same currency code, but a different account instance).
    final overrideChanged =
        oldWidget.selectedCurrencyCodeOverride !=
            widget.selectedCurrencyCodeOverride;

    final selectorToggled =
        oldWidget.showCurrencySelector != widget.showCurrencySelector;

    final accountTextChanged =
        oldWidget.controller?.text != widget.controller?.text;

    if (overrideChanged ||
        selectorToggled ||
        (widget.showCurrencySelector && accountTextChanged)) {
      _selectedCurrency = null;
      _resolvedForText = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (!_usingExternalFocusNode) _focusNode.dispose();
    _keyboardListenerFocus.dispose();
    _scrollController.dispose();
    widget.controller?.removeListener(_onControllerChanged);
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() => _showClear = widget.controller?.text.isNotEmpty == true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _scrollToHighlighted() {
    if (!_scrollController.hasClients || _highlightedIndex < 0) return;
    final targetOffset = _highlightedIndex * _itemHeight;
    final currentOffset = _scrollController.offset;
    final maxOffset = _scrollController.position.maxScrollExtent;
    final viewport = _scrollController.position.viewportDimension;
    final visibleTop = currentOffset;
    final visibleBottom = currentOffset + viewport;
    final itemTop = targetOffset;
    final itemBottom = targetOffset + _itemHeight;
    if (itemBottom > visibleBottom) {
      _scrollController.animateTo(
        (itemBottom - viewport).clamp(0, maxOffset),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    } else if (itemTop < visibleTop) {
      _scrollController.animateTo(
        itemTop.clamp(0, maxOffset),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  void _onFocusChange() {
    if (widget.readOnly) {
      _removeOverlay();
      return;
    }
    if (_focusNode.hasFocus) {
      if (!_keyboardListenerFocus.hasFocus) {
        _keyboardListenerFocus.requestFocus();
      }
      if (widget.showAllOnFocus &&
          _firstFocus &&
          widget.bloc != null &&
          widget.fetchAllFunction != null) {
        widget.fetchAllFunction!(widget.bloc!);
        _firstFocus = false;
      }
      if (_isUserSearching && _currentSuggestions.isNotEmpty) {
        _showOverlay();
      }
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_focusNode.hasFocus) _removeOverlay();
      });
    }
  }

  void _selectItem(T item) {
    final itemText = widget.itemToString(item);
    widget.controller?.text = itemText;
    widget.onSelected?.call(item);
    widget.onChanged?.call(itemText);
    _isUserSearching = false;
    _removeOverlay();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final allItems = _getAllItems();
    if (allItems.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < allItems.length - 1) {
          _highlightedIndex++;
        } else {
          _highlightedIndex = 0;
        }
      });
      _refreshOverlay();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlighted();
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex > 0) {
          _highlightedIndex--;
        } else {
          _highlightedIndex = allItems.length - 1;
        }
      });
      _refreshOverlay();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlighted();
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < allItems.length) {
        _selectItem(allItems[_highlightedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _removeOverlay();
    }
  }

  List<T> _getAllItems() {
    final items = [..._currentSuggestions];
    if (widget.showAllOption && widget.allOption != null) {
      items.insert(0, widget.allOption as T);
    }
    return items;
  }

  void _refreshOverlay() => _overlayEntry?.markNeedsBuild();

  void _showOverlay() {
    if (!_isUserSearching) return;
    if (_overlayEntry != null) {
      _refreshOverlay();
      return;
    }
    final renderBox =
    _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null) return;

    final position = renderBox.localToGlobal(Offset.zero, ancestor: overlay);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + renderBox.size.height + 4,
        width: renderBox.size.width,
        child: Material(
          elevation: 1,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
            side: BorderSide(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              width: 1,
            ),
          ),
          child: _buildSuggestionsList(),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildSuggestionsList() {
    final allItems = _getAllItems();
    if (allItems.isEmpty) {
      final isLoading = widget.bloc != null &&
          widget.stateToLoading != null &&
          widget.stateToLoading!(widget.bloc!.state);
      return SizedBox(
        height: widget.height,
        child: Center(
          child: isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(
            widget.noResultsText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: .7),
            ),
          ),
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        controller: _scrollController,
        padding: EdgeInsets.zero,
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final item = allItems[index];
          final isHighlighted = index == _highlightedIndex;
          return Material(
            color: isHighlighted
                ? Theme.of(context)
                .colorScheme
                .outline
                .withValues(alpha: .06)
                : Colors.transparent,
            child: InkWell(
              hoverColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: .04),
              highlightColor: Colors.transparent,
              onTap: () => _selectItem(item),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 10,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          width: 3,
                          height: isHighlighted ? 18 : 0,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: widget.itemBuilder(context, item),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String? _customValidator(String? value) {
    if (widget.isRequired && (value == null || value.isEmpty)) {
      return AppLocalizations.of(context)!.required(widget.title);
    }
    if (widget.itemValidator != null) {
      T? selectedItem;
      try {
        selectedItem = _currentSuggestions.firstWhere(
              (item) => widget.itemToString(item) == value,
        );
      } catch (_) {
        selectedItem = null;
      }
      if (selectedItem != null) return widget.itemValidator!(selectedItem);
    }
    if (value != null &&
        value.isNotEmpty &&
        !_currentSuggestions
            .any((item) => widget.itemToString(item) == value)) {
      return widget.title;
    }
    return null;
  }

  Widget? _buildSuffixIcon() {
    final isLoading = widget.bloc != null &&
        widget.stateToLoading != null &&
        widget.stateToLoading!(widget.bloc!.state);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: widget.loadingBuilder?.call(context) ??
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
          ),
        if (_showClear && widget.showClearButton && !isLoading)
          IconButton(
            splashRadius: 2,
            splashColor: Theme.of(context).colorScheme.primary.withAlpha(23),
            highlightColor:
            Theme.of(context).colorScheme.primary.withAlpha(23),
            hoverColor: Theme.of(context).colorScheme.primary.withAlpha(23),
            icon: Icon(
              Icons.clear,
              size: 14,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              widget.controller?.clear();
              widget.onChanged?.call('');
              setState(() {
                _currentSuggestions = [];
                _showClear = false;
                _firstFocus = true;
                _highlightedIndex = -1;
                _isUserSearching = false;
              });
              _removeOverlay();
            },
          ),
        if (widget.trailing != null) widget.trailing!,
      ],
    );
  }

  // ── Borders & padding ───────────────────────────────────────
  InputBorder _getEnabledBorder() {
    switch (widget.textFieldStyle) {
      case TextFieldStyle.roundedBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: .3),
          ),
        );
      case TextFieldStyle.underline:
        return const UnderlineInputBorder();
      case TextFieldStyle.noBorder:
        return const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        );
    }
  }

  InputBorder _getFocusedBorder() {
    switch (widget.textFieldStyle) {
      case TextFieldStyle.roundedBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        );
      case TextFieldStyle.underline:
        return UnderlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        );
      case TextFieldStyle.noBorder:
        return const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        );
    }
  }

  InputBorder _getErrorBorder() {
    switch (widget.textFieldStyle) {
      case TextFieldStyle.roundedBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        );
      case TextFieldStyle.underline:
        return const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        );
      case TextFieldStyle.noBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        );
    }
  }

  InputBorder _getDisabledBorder() {
    switch (widget.textFieldStyle) {
      case TextFieldStyle.roundedBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: .2),
          ),
        );
      case TextFieldStyle.underline:
        return const UnderlineInputBorder();
      case TextFieldStyle.noBorder:
        return const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        );
    }
  }

  EdgeInsets _getContentPadding() {
    switch (widget.textFieldStyle) {
      case TextFieldStyle.roundedBorder:
      case TextFieldStyle.underline:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case TextFieldStyle.noBorder:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    }
  }

  void _onFieldSubmittedInternal(String value) {
    widget.onFieldSubmitted?.call(value);
    final input = value.trim();
    widget.onSubmitted?.call(name: input);

    T? match;
    try {
      match = _currentSuggestions.firstWhere((item) {
        try {
          final dynamic dyn = item;
          final String? code = dyn.proCode?.toLowerCase();
          if (code != null && code == input.toLowerCase()) return true;
        } catch (_) {}
        return widget.itemToString(item) == input;
      });
    } catch (_) {
      match = null;
    }
    if (match != null) {
      widget.controller?.text = widget.itemToString(match);
      widget.onChanged?.call(widget.itemToString(match));
      widget.onSelected?.call(match);
      _isUserSearching = false;
      _removeOverlay();
    }
  }

  // ── Currency selector builder ───────────────────────────────
  List<_CcyItem> _convertCurrencies(List<CurrenciesModel> currencies) {
    return currencies.map((c) {
      return _CcyItem(
        code: c.ccyCode ?? '',
        symbol: c.ccySymbol ?? c.ccyCode ?? '',
        name: c.ccyName,
        originalModel: c,
        flagIcon: c.ccyCountryCode != null
            ? SizedBox(
          width: 18,
          height: 12,
          child: Flag.fromString(
            c.ccyCountryCode!,
            height: 12,
            width: 18,
            borderRadius: 2,
            fit: BoxFit.fill,
          ),
        )
            : null,
      );
    }).toList();
  }

  CurrenciesModel? _resolveDefaultCurrency(List<CurrenciesModel> currencies) {
    if (currencies.isEmpty) return null;
    final code = widget.selectedCurrencyCodeOverride;
    if (code != null && code.isNotEmpty) {
      try {
        return currencies.firstWhere((c) => c.ccyCode == code);
      } catch (_) {
        return currencies.first;
      }
    }
    return currencies.first;
  }

  Widget _buildCurrencySelector() {
    return BlocBuilder<CurrenciesBloc, CurrenciesState>(
      builder: (context, state) {
        if (state is CurrenciesInitial ||
            (state is CurrenciesLoadedState && state.active.isEmpty)) {
          context
              .read<CurrenciesBloc>()
              .add(LoadCurrenciesEvent(status: widget.currencyStatus ?? 1));
          return const SizedBox(
            width: 90,
            height: 20,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (state is! CurrenciesLoadedState) {
          return const SizedBox.shrink();
        }

        final currencies = state.active;
        if (currencies.isEmpty) return const SizedBox.shrink();

        _ccyItems = _convertCurrencies(currencies);

        // ✅ FIX: cache which controller text the current selection was
        // resolved for. If the account row changed (same code, different
        // row) we re-resolve against the new code instead of keeping the
        // first match for the old code.
        final currentText = widget.controller?.text ?? '';
        if (_selectedCurrency == null || _resolvedForText != currentText) {
          _selectedCurrency = _resolveDefaultCurrency(currencies);
          _resolvedForText = currentText;
        }

        final selectedItem = _ccyItems.firstWhere(
              (c) => c.code == _selectedCurrency!.ccyCode,
          orElse: () => _ccyItems.first,
        );

        final enabled =
            widget.isEnabled && widget.isCurrencySelectorEnabled;

        // Fixed width — never expands to eat the account text.
        // Divider is added in `build()` alongside this widget.
        return SizedBox(
          width: widget.currencySelectorWidth - 20, // leave room for padding
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_CcyItem>(
              value: selectedItem,
              isDense: true,
              isExpanded: false,
              selectedItemBuilder: (context) =>
                  _ccyItems.map(_buildCcyRow).toList(),
              items: _ccyItems
                  .map((c) => DropdownMenuItem<_CcyItem>(
                value: c,
                child: _buildCcyMenuRow(c),
              ))
                  .toList(),
              onChanged: enabled
                  ? (_CcyItem? picked) {
                if (picked == null) return;
                setState(() => _selectedCurrency = picked.originalModel);
                widget.onCurrencySelectorChanged
                    ?.call(picked.originalModel);
              }
                  : null,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
              elevation: 2,
            ),
          ),
        );
      },
    );
  }

  /// Compact row for the CLOSED dropdown state (fixed 110px).
  Widget _buildCcyRow(_CcyItem c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (c.flagIcon != null) ...[
          c.flagIcon!,
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            c.code,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Wider row for the OPENED menu — shows flag + symbol + code.
  Widget _buildCcyMenuRow(_CcyItem c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (c.flagIcon != null) ...[
          c.flagIcon!,
          const SizedBox(width: 6),
        ],
        Text(
          c.symbol,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(width: 4),
        Text(
          c.code,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.isRequired)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          ' *',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Container(
              decoration: widget.textFieldStyle == TextFieldStyle.noBorder
                  ? BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: .08),
                borderRadius: BorderRadius.circular(4),
              )
                  : null,
              child: KeyboardListener(
                focusNode: _keyboardListenerFocus,
                onKeyEvent: _handleKeyEvent,
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: TextFormField(
                    focusNode: _focusNode,
                    textInputAction: widget.textInputAction,
                    onFieldSubmitted: _onFieldSubmittedInternal,
                    key: _fieldKey,
                    controller: widget.controller,
                    enabled: widget.isEnabled,
                    readOnly: widget.readOnly,
                    validator: widget.validator ?? _customValidator,
                    onChanged: (value) {
                      if (widget.readOnly) return;
                      final hasQuery = value.trim().isNotEmpty;
                      setState(() {
                        _showClear = value.isNotEmpty;
                        _highlightedIndex = -1;
                        _isUserSearching = hasQuery;
                      });
                      if (!hasQuery) _removeOverlay();
                      if (_debounce?.isActive ?? false) _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 500),
                            () {
                          if (value.isNotEmpty &&
                              widget.bloc != null &&
                              widget.searchFunction != null) {
                            widget.searchFunction!(widget.bloc!, value);
                          } else if (value.isEmpty &&
                              widget.bloc != null &&
                              widget.fetchAllFunction != null) {
                            widget.fetchAllFunction!(widget.bloc!);
                          } else {
                            _currentSuggestions = [];
                            _removeOverlay();
                          }
                        },
                      );
                    },
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,

                      // ✅ Currency selector + vertical divider, both
                      //    rendered inside the field's prefix slot.
                      prefixIcon: widget.showCurrencySelector
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8,
                              right: 6,
                            ),
                            child: _buildCurrencySelector(),
                          ),
                          // Vertical divider between currency
                          // dropdown and the account text.
                          Container(
                            width: 1,
                            height: 20,
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.25),
                          ),
                          const SizedBox(width: 6),
                        ],
                      )
                          : widget.icon != null
                          ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        child: Icon(widget.icon, size: 18),
                      )
                          : null,
                      // Fixed total width for the whole prefix block
                      // (dropdown + gaps + divider + tail space).
                      prefixIconConstraints: widget.showCurrencySelector
                          ? BoxConstraints(
                        minWidth: 0,
                        maxWidth: widget.currencySelectorWidth + 24,
                        minHeight: 0,
                      )
                          : null,

                      suffixIcon: _buildSuffixIcon(),
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: .5),
                      ),
                      contentPadding: _getContentPadding(),
                      disabledBorder: _getDisabledBorder(),
                      enabledBorder: _getEnabledBorder(),
                      focusedBorder: _getFocusedBorder(),
                      focusedErrorBorder: _getErrorBorder(),
                      errorBorder: _getErrorBorder(),
                      errorStyle: const TextStyle(fontSize: 11),
                      fillColor:
                      widget.textFieldStyle == TextFieldStyle.noBorder
                          ? Colors.transparent
                          : null,
                      filled:
                      widget.textFieldStyle == TextFieldStyle.noBorder,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.end != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: widget.end,
              ),
            if (widget.bloc != null)
              BlocListener<B, S>(
                bloc: widget.bloc,
                listener: (context, state) {
                  if (widget.readOnly) return;
                  final items = widget.stateToItems(state);
                  setState(() {
                    _currentSuggestions = items;
                    if (_highlightedIndex >= items.length) {
                      _highlightedIndex = items.isEmpty ? -1 : 0;
                    }
                  });
                  if (_isUserSearching && _focusNode.hasFocus) {
                    _showOverlay();
                  } else {
                    _removeOverlay();
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