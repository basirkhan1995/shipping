import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef LoadingBuilder = Widget Function(BuildContext context);
typedef ItemBuilder<T> = Widget Function(BuildContext context, T item);
typedef ItemToString<T> = String Function(T item);
typedef OnItemSelected<T> = void Function(T item);
typedef BlocSearchFunction<B> = void Function(B bloc, String query);
typedef BlocFetchAllFunction<B> = void Function(B bloc);
typedef OnFieldSubmitFunction = void Function({required String name});

class GenericUnderlineTextfield<T, B extends BlocBase<S>, S> extends StatefulWidget {
  final LoadingBuilder? loadingBuilder;
  final bool Function(S state)? stateToLoading;
  final ValueChanged<String>? onSubmitted;
  final double? width;
  final TextEditingController? controller;
  final String? hintText;
  final String title;
  final bool compactMode;
  final Widget? trailing;
  final Widget? end;
  final IconData? icon;
  final bool isRequired;
  final FormFieldValidator? validator;
  final ValueChanged<String>? onChanged;
  final OnItemSelected<T>? onSelected;
  final ItemBuilder<T> itemBuilder;
  final ItemToString<T> itemToString;
  final B? bloc;
  final BlocSearchFunction<B>? searchFunction;
  final BlocFetchAllFunction<B>? fetchAllFunction;
  final String? Function(T)? itemValidator;
  final String noResultsText;
  final List<T> Function(S state) stateToItems;
  final EdgeInsetsGeometry? padding;
  final FocusNode? focusNode;
  final bool showClearButton;
  final OnFieldSubmitFunction? onBarcodeSubmitted;
  final bool showAllOnFocus;
  final bool enabled;

  const GenericUnderlineTextfield({
    super.key,
    required this.controller,
    required this.title,
    this.onBarcodeSubmitted,
    required this.itemBuilder,
    required this.itemToString,
    required this.stateToItems,
    this.focusNode,
    this.enabled = true,
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
    this.onSubmitted,
    this.isRequired = false,
    this.onChanged,
    this.validator,
    this.width,
    this.itemValidator,
    this.noResultsText = 'No results found',
    this.padding,
    this.showClearButton = true,
    this.showAllOnFocus = true,
  }) : assert(bloc != null || searchFunction == null, 'If searchFunction is provided, bloc must also be provided');

  @override
  State<GenericUnderlineTextfield<T, B, S>> createState() => _GenericUnderlineTextfieldState<T, B, S>();
}

class _GenericUnderlineTextfieldState<T, B extends BlocBase<S>, S> extends State<GenericUnderlineTextfield<T, B, S>> {
  int _highlightedIndex = -1;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _fieldKey = GlobalKey();
  List<T> _currentSuggestions = [];
  Timer? _debounce;
  late FocusNode _focusNode;
  bool _firstFocus = true;
  bool _isFocused = false;
  final FocusNode _keyboardListenerFocusNode = FocusNode(skipTraversal: true);

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();

    _focusNode.addListener(_onFocusChange);

    widget.controller?.addListener(_onControllerChanged);
  }

  void _onFocusChange() {
    if (!mounted) return;

    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus) {
      if (widget.showAllOnFocus && _firstFocus && widget.bloc != null && widget.fetchAllFunction != null) {
        widget.fetchAllFunction!(widget.bloc!);
        _firstFocus = false;
      }

      if (_currentSuggestions.isNotEmpty) {
        _showOverlay(_currentSuggestions);
      }
    } else {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant GenericUnderlineTextfield<T, B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _keyboardListenerFocusNode.dispose();
    widget.controller?.removeListener(_onControllerChanged);
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
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

  void _showOverlay(List<T> items) {
    _removeOverlay();

    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null || !mounted) return;
    final position = renderBox.localToGlobal(Offset.zero, ancestor: overlay);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + renderBox.size.height + 11,
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
          child: _buildSuggestionsList(items),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildSuggestionsList(List<T> items) {
    if (items.isEmpty) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            widget.noResultsText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () {
              widget.controller?.text = widget.itemToString(item);
              widget.onSelected?.call(item);
              widget.onChanged?.call(widget.itemToString(item));
              _removeOverlay();
              _focusNode.unfocus();
            },
            child: Container(
              color: index == _highlightedIndex
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: .1)
                  : Colors.transparent,
              child: widget.itemBuilder(context, item),
            ),
          );
        },
      ),
    );
  }

  String? _customValidator(String? value) {
    if (widget.isRequired && (value == null || value.isEmpty)) {
      // return AppLocalizations.of(context)!.required(widget.title);
      return widget.title;
    }
    // Don’t force value to match suggestions, allow free text
    return null;
  }

  Widget? _buildSuffixIcon() {
    final isBlocLoading = widget.bloc != null &&
        widget.stateToLoading != null &&
        widget.stateToLoading!(widget.bloc!.state);

    final shouldShowLoading = isBlocLoading && _isFocused;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shouldShowLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: widget.loadingBuilder?.call(context) ??
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
          ),
        if (widget.showClearButton && !shouldShowLoading)
          IconButton(
            constraints: const BoxConstraints(),
            splashRadius: 2,
            icon: Icon(Icons.clear, size: 16, color: Theme.of(context).colorScheme.secondary),
            onPressed: () {
              widget.controller?.clear();
              widget.onChanged?.call('');
              if (mounted) {
                setState(() {
                  _currentSuggestions = [];
                  _firstFocus = true;
                });
              }
              _removeOverlay();
            },
          ),
        if (widget.trailing != null) widget.trailing!,
      ],
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_currentSuggestions.isNotEmpty && _overlayEntry != null && mounted) {
        setState(() {
          _highlightedIndex =
              (_highlightedIndex + 1) % _currentSuggestions.length;
        });
        _refreshOverlay();
      }
      return KeyEventResult.handled; // ✅ handled arrow down
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_currentSuggestions.isNotEmpty && _overlayEntry != null && mounted) {
        setState(() {
          _highlightedIndex = (_highlightedIndex - 1 + _currentSuggestions.length) %
              _currentSuggestions.length;
        });
        _refreshOverlay();
      }
      return KeyEventResult.handled; // ✅ handled arrow up
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 &&
          _highlightedIndex < _currentSuggestions.length &&
          _overlayEntry != null) {
        final selectedItem = _currentSuggestions[_highlightedIndex];
        widget.controller?.text = widget.itemToString(selectedItem);
        widget.onSelected?.call(selectedItem);
        widget.onChanged?.call(widget.itemToString(selectedItem));
        _removeOverlay();
        _focusNode.unfocus();
      }
      return KeyEventResult.handled; // ✅ handled enter
    }

    // ✅ Let all other keys (letters, numbers, backspace, etc.) reach the text field
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
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  key: _fieldKey,
                  controller: widget.controller,
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _highlightedIndex = -1;
                      });
                    }

                    if (_debounce?.isActive ?? false) _debounce!.cancel();

                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      if (!mounted) return;

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
                    });
                  },
                  validator: widget.validator ?? _customValidator,
                  onFieldSubmitted: (value) {
                    final input = value.trim();

                    // Call the barcode submitted handler
                    widget.onBarcodeSubmitted?.call(name: input);

                    // Also try to find in current suggestions for non-barcode cases
                    if (_currentSuggestions.isNotEmpty) {
                      T? match;
                      try {
                        match = _currentSuggestions.firstWhere(
                              (item) => widget.itemToString(item).toLowerCase() == input.toLowerCase(),
                        );
                      } catch (e) {
                        // No match found
                        match = null;
                      }

                      if (match != null) {
                        widget.controller?.text = widget.itemToString(match);
                        widget.onChanged?.call(widget.itemToString(match));
                        widget.onSelected?.call(match);
                        _removeOverlay();
                      }
                    }
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    suffixIconConstraints: const BoxConstraints(),
                    suffixIcon: _buildSuffixIcon(),
                    isDense: true,
                  ),
                ),
              ),
            ),

            if (widget.end != null) widget.end!,
            if (widget.bloc != null)
              BlocListener<B, S>(
                bloc: widget.bloc,
                listener: (context, state) {
                  final items = widget.stateToItems(state);
                  if (mounted) {
                    setState(() {
                      _currentSuggestions = items;
                    });
                  }
                  if (_focusNode.hasFocus) {
                    _showOverlay(items);
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