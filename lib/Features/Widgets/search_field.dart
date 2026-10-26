// lib/widgets/reusable_search_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shipping/l10n/app_localizations.dart';

/// A fully reusable, debounced search bar widget.
///
/// Features:
/// - Debounced text input (configurable duration)
/// - Optional clear button
/// - Fully themeable
/// - Customizable hint, icons, padding, border radius, height, content padding
/// - Optional controller injection (for external control)
/// - Optional focus node injection
/// - Text and icons always vertically centered
///
/// Example:
/// ```dart
/// ReusableSearchBar(
///   hintText: 'Search stakeholder',
///   height: 40,
///   contentPadding: EdgeInsets.symmetric(horizontal: 4),
///   onChanged: (query) => _filterList(query),
/// )
/// ```
class ReusableSearchBar extends StatefulWidget {
  /// Callback fired after the debounce duration when the text changes.
  final ValueChanged<String> onChanged;

  /// Optional callback fired immediately on every keystroke.
  final ValueChanged<String>? onChangedImmediate;

  /// Callback fired when the search action (keyboard) is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Placeholder text.
  final String? hintText;

  /// Debounce duration before [onChanged] is fired.
  final Duration debounceDuration;

  /// Optional external controller.
  final TextEditingController? controller;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Outer padding around the search bar.
  final EdgeInsetsGeometry padding;

  /// Border radius of the container.
  final double borderRadius;

  /// Whether to show the clear (cancel) button when text is non-empty.
  final bool showClearButton;

  /// Tooltip for the clear button.
  final String clearButtonTooltip;

  /// Leading search icon (set to null to hide).
  final IconData? searchIcon;

  /// Icon used for the clear button (set to null to use default cancel icon).
  final IconData? clearIcon;

  /// Background color override.
  final Color? backgroundColor;

  /// Border color override.
  final Color? borderColor;

  /// Text style override.
  final TextStyle? textStyle;

  /// Hint text style override.
  final TextStyle? hintStyle;

  /// Whether to autofocus the field.
  final bool autofocus;

  /// Enables/disables the field.
  final bool enabled;

  /// Text input action.
  final TextInputAction textInputAction;

  /// Optional custom leading widget (overrides [searchIcon]).
  final Widget? prefix;

  /// Optional custom trailing widget (overrides built-in clear button).
  final Widget? suffix;

  /// 👇 NEW: Fixed height of the search container.
  /// When null, the height is derived from the text field's intrinsic size.
  final double? height;

  /// 👇 NEW: Inner padding of the [TextField] (content padding).
  /// Defaults to a small symmetric padding; increase/decrease as needed.
  final EdgeInsetsGeometry? contentPadding;

  /// 👇 NEW: Size of the leading search icon.
  final double prefixIconSize;

  /// 👇 NEW: Size of the clear (suffix) icon.
  final double suffixIconSize;

  const ReusableSearchBar({
    super.key,
    required this.onChanged,
    this.onChangedImmediate,
    this.onSubmitted,
    this.hintText,
    this.debounceDuration = const Duration(milliseconds: 350),
    this.controller,
    this.focusNode,
    this.padding = const EdgeInsets.fromLTRB(0, 0, 0, 0),
    this.borderRadius = 5,
    this.showClearButton = true,
    this.clearButtonTooltip = 'Clear search',
    this.searchIcon = Icons.search_rounded,
    this.clearIcon = Icons.cancel_rounded,
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
    this.hintStyle,
    this.autofocus = false,
    this.enabled = true,
    this.textInputAction = TextInputAction.search,
    this.prefix,
    this.suffix,
    this.height,
    this.contentPadding,
    this.prefixIconSize = 22,
    this.suffixIconSize = 18,
  });

  @override
  State<ReusableSearchBar> createState() => _ReusableSearchBarState();
}

class _ReusableSearchBarState extends State<ReusableSearchBar> {
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;
  Timer? _debounce;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;

    _focusNode = widget.focusNode ?? FocusNode();
    _ownsFocusNode = widget.focusNode == null;

    _ctrl.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onControllerChanged);
    if (_ownsController) _ctrl.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onChanged(String v) {
    widget.onChangedImmediate?.call(v);

    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged(v);
    });

    setState(() {});
  }

  void _onSubmitted(String v) {
    _debounce?.cancel();
    widget.onChanged(v);
    widget.onSubmitted?.call(v);
  }

  void _clear() {
    _debounce?.cancel();
    _ctrl.clear();
    widget.onChanged('');
    widget.onChangedImmediate?.call('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final resolvedBackground =
        widget.backgroundColor ?? scheme.surfaceContainerLowest;
    final resolvedBorder = widget.borderColor ??
        scheme.outlineVariant.withValues(alpha: 0.5);
    final resolvedHintStyle = widget.hintStyle ??
        TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7));

    // Inner content padding — small default that plays nicely with [height].
    final resolvedContentPadding = widget.contentPadding ??
        const EdgeInsets.symmetric(horizontal: 4, vertical: 10);

    final effectivePrefix = widget.prefix ??
        (widget.searchIcon == null
            ? null
            : Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Icon(
            widget.searchIcon,
            size: widget.prefixIconSize,
            color: scheme.onSurfaceVariant,
          ),
        ));

    final effectiveSuffix = widget.suffix ??
        (!widget.showClearButton || _ctrl.text.isEmpty
            ? null
            : Center(
          widthFactor: 1,
          heightFactor: 1,
          child: IconButton(
            icon: Icon(
              widget.clearIcon ?? Icons.cancel_rounded,
              size: widget.suffixIconSize,
              color:
              scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            tooltip: widget.clearButtonTooltip,
            onPressed: _clear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ));

    // The TextField is vertically centered inside the Container so it stays
    // centered regardless of the fixed [height].
    final textField = Center(
      child: TextField(
        controller: _ctrl,
        focusNode: _focusNode,
        onChanged: _onChanged,
        onSubmitted: _onSubmitted,
        textInputAction: widget.textInputAction,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        style: widget.textStyle,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: widget.hintText ?? AppLocalizations.of(context)!.search,
          hintStyle: resolvedHintStyle,
          prefixIcon: effectivePrefix,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 36,
          ),
          suffixIcon: effectiveSuffix,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 36,
          ),
          border: InputBorder.none,
          contentPadding: resolvedContentPadding,
          isDense: true,
        ),
      ),
    );

    return Padding(
      padding: widget.padding,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: resolvedBackground,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: resolvedBorder),
        ),
        // Clip so the centered text field cannot overflow the fixed height.
        clipBehavior: widget.height != null ? Clip.antiAlias : Clip.none,
        child: textField,
      ),
    );
  }
}