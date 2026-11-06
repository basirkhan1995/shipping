import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/Bloc/localizations_bloc.dart';

// =====================================================================
// MenuHeightMode
// =====================================================================
/// How [GenericMenuWithScreen]'s sidebar computes its height.
enum MenuHeightMode {
  /// Stretches to the full available height of the parent.
  /// Requires a bounded height from the parent (e.g. inside a `Row`
  /// whose parent is `Expanded` / `SizedBox` / `Scaffold.body`).
  full,

  /// Shrinks to fit its children (header + items + footer).
  /// Safe inside a `Column` or `SingleChildScrollView`.
  content,

  /// Uses an explicit pixel height from [GenericMenuWithScreen.menuFixedHeight].
  /// Must be finite.
  fixed,
}

// =====================================================================
// GenericMenuItem
// =====================================================================
class GenericMenuItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final String label;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final double borderRadius;
  final double? fontSize;
  final bool isExpanded;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const GenericMenuItem({
    super.key,
    required this.isSelected,
    required this.onTap,
    this.fontSize,
    this.icon,
    required this.label,
    this.isExpanded = true,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.transparent,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.black,
    this.borderRadius = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    this.margin = const EdgeInsets.symmetric(horizontal: 1),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = isSelected
        ? scheme.outline.withValues(alpha: 0.08)
        : unselectedColor;

    return Padding(
      padding: padding,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            hoverColor:
            scheme.primary.withValues(alpha: isSelected ? 0 : 0.05),
            highlightColor: scheme.primary.withValues(alpha: 0.05),
            splashColor: Colors.transparent,
            child: Stack(
              children: [
                // ── Fluent selection indicator (left/right bar)
                Positioned.fill(
                  child: Align(
                    alignment: context
                        .read<LocalizationBloc>()
                        .state
                        .languageCode ==
                        'en'
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: isSelected ? 10 : 18,
                        end: isSelected ? 18 : 10,
                      ),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutExpo,
                      builder: (context, height, child) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: isSelected ? 3.5 : 2,
                          height: isSelected ? height : 10,
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Item content
                Padding(
                  padding: padding,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: isExpanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      if (icon != null)
                        Icon(
                          icon,
                          size: 25,
                          color: isSelected
                              ? selectedTextColor
                              : unselectedTextColor,
                        ),

                      if (isExpanded && icon != null) const SizedBox(width: 6),

                      if (isExpanded)
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontSize: fontSize ?? 16,
                              color: isSelected
                                  ? selectedTextColor
                                  : unselectedTextColor,
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                letterSpacing: 1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
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

// =====================================================================
// GenericMenuWithScreen
// =====================================================================
class GenericMenuWithScreen<T> extends StatefulWidget {
  final double? menuWidth;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final List<MenuDefinition<T>> items;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final double borderRadius;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// 🔹 External control for default expanded/collapsed state
  final bool isExpanded;

  /// 🔹 Optional header
  final Widget Function(bool isExpanded)? menuHeaderBuilder;

  /// 🔹 Optional footer
  final Widget Function(bool isExpanded)? menuFooterBuilder;

  /// 🔹 Widget to show when no items are available
  final Widget? emptyStateWidget;

  /// 🔹 How the sidebar computes its height.
  ///
  /// * [MenuHeightMode.full] (default) — stretches to the parent's height.
  /// * [MenuHeightMode.content] — wraps children; safe inside a `Column`
  ///   or `SingleChildScrollView`.
  /// * [MenuHeightMode.fixed] — uses [menuFixedHeight]; must be finite.
  final MenuHeightMode menuHeightMode;

  /// 🔹 Only consulted when [menuHeightMode] == [MenuHeightMode.fixed].
  final double? menuFixedHeight;

  const GenericMenuWithScreen({
    super.key,
    this.menuWidth,
    required this.selectedValue,
    required this.onChanged,
    required this.items,
    this.menuHeaderBuilder,
    this.menuFooterBuilder,
    this.emptyStateWidget,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.transparent,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.black,
    this.borderRadius = 3,
    this.fontSize,
    this.padding,
    this.margin,
    this.isExpanded = true,
    this.menuHeightMode = MenuHeightMode.full,
    this.menuFixedHeight,
  });

  @override
  State<GenericMenuWithScreen<T>> createState() =>
      _GenericMenuWithScreenState<T>();
}

class _GenericMenuWithScreenState<T> extends State<GenericMenuWithScreen<T>> {
  late double minScreenSize;
  late double maxScreenSize;

  late bool isMenuExpanded;

  @override
  void initState() {
    super.initState();
    minScreenSize = 60;
    maxScreenSize = widget.menuWidth ?? 210;

    isMenuExpanded = widget.isExpanded;
    _fixInvalidSelection();
  }

  @override
  void didUpdateWidget(GenericMenuWithScreen<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fixInvalidSelection();
  }

  // ── Height resolution ───────────────────────────────────────────────
  /// Value passed to `AnimatedContainer.height`.
  ///
  /// - [MenuHeightMode.full]    → `double.infinity` (stretch to parent)
  /// - [MenuHeightMode.content] → `null`             (size to children)
  /// - [MenuHeightMode.fixed]   → [menuFixedHeight]  (must be finite)
  double? get _resolvedMenuHeight {
    switch (widget.menuHeightMode) {
      case MenuHeightMode.full:
        return double.infinity;
      case MenuHeightMode.content:
        return null;
      case MenuHeightMode.fixed:
        assert(
        widget.menuFixedHeight != null && widget.menuFixedHeight!.isFinite,
        'menuFixedHeight must be a finite value when menuHeightMode is fixed',
        );
        return widget.menuFixedHeight;
    }
  }

  /// True only in content mode — controls `Column.mainAxisSize` and
  /// `Expanded` vs `Flexible` for the inner list / empty-state.
  bool get _isContentMode =>
      widget.menuHeightMode == MenuHeightMode.content;

  void _fixInvalidSelection() {
    if (widget.items.isEmpty) return;

    final isValid =
    widget.items.any((item) => item.value == widget.selectedValue);

    if (!isValid) {
      final firstAvailableValue = widget.items.first.value;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(firstAvailableValue);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 Handle empty items case - show empty state
    if (widget.items.isEmpty) {
      return Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isMenuExpanded ? maxScreenSize : minScreenSize,
            height: _resolvedMenuHeight,
            margin: widget.margin ??
                const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              border: Border.all(
                color:
                Theme.of(context).colorScheme.primary.withValues(alpha: .1),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 3,
                  spreadRadius: 2,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: .03),
                ),
              ],
              borderRadius: BorderRadius.circular(5),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            child: Column(
              mainAxisSize: _isContentMode ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          icon: Icon(isMenuExpanded
                              ? Icons.chevron_left
                              : Icons.chevron_right),
                          onPressed: () {
                            setState(() {
                              isMenuExpanded = !isMenuExpanded;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.menuHeaderBuilder != null) ...[
                  widget.menuHeaderBuilder!(isMenuExpanded),
                  const SizedBox(height: 8),
                ],

                _isContentMode
                    ? Flexible(
                  child: Center(
                    child: widget.emptyStateWidget ??
                        (isMenuExpanded
                            ? Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_open_rounded,
                              size: 32,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: .3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No menu items available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: .5),
                              ),
                            ),
                          ],
                        )
                            : const SizedBox.shrink()),
                  ),
                )
                    : Expanded(
                  child: Center(
                    child: widget.emptyStateWidget ??
                        (isMenuExpanded
                            ? Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_open_rounded,
                              size: 32,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: .3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No menu items available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: .5),
                              ),
                            ),
                          ],
                        )
                            : const SizedBox.shrink()),
                  ),
                ),

                if (widget.menuFooterBuilder != null)
                  widget.menuFooterBuilder!(isMenuExpanded),
              ],
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .1),
                ),
                borderRadius: BorderRadius.circular(5),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Center(
                child: widget.emptyStateWidget ??
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: .3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No content available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: .5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your permissions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: .4),
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ],
      );
    }

    final isValid = widget.items.any(
          (item) => item.value == widget.selectedValue,
    );

    if (!isValid) {
      _fixInvalidSelection();
      return const Center(
        child: SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final selectedItem = widget.items.firstWhere(
          (e) => e.value == widget.selectedValue,
      orElse: () => widget.items.first,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔷 Sidebar
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isMenuExpanded ? maxScreenSize : minScreenSize,
              clipBehavior: Clip.hardEdge,
              height: _resolvedMenuHeight,
              margin: widget.margin ??
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .1),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 3,
                    spreadRadius: 2,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: .03),
                  ),
                ],
                borderRadius: BorderRadius.circular(5),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 0.0, vertical: 2),
                child: Column(
                  mainAxisSize:
                  _isContentMode ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    /// Toggle arrow
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: (){
                              setState(() {
                                isMenuExpanded = !isMenuExpanded;
                              });
                            },
                            child: Container(
                              padding: EdgeInsetsGeometry.all(3),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: .06),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Icon(isMenuExpanded
                                    ? Icons.chevron_left
                                    : Icons.chevron_right,size: 20,),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Header
                    if (widget.menuHeaderBuilder != null) ...[
                      widget.menuHeaderBuilder!(isMenuExpanded),
                      const SizedBox(height: 8),
                    ],

                    /// Menu list
                    _isContentMode
                        ? Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: widget.items.map((item) {
                          return GenericMenuItem(
                            isSelected:
                            item.value == widget.selectedValue,
                            onTap: () {
                              widget.onChanged(item.value);
                            },
                            label: item.label,
                            icon: item.icon,
                            fontSize: widget.fontSize,
                            isExpanded: isMenuExpanded,
                            padding: widget.padding ??
                                const EdgeInsets.symmetric(
                                    horizontal: 5.0, vertical: 5),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 2.0, vertical: 3),
                            borderRadius: widget.borderRadius,
                            selectedColor: widget.selectedColor,
                            unselectedColor: widget.unselectedColor,
                            selectedTextColor: widget.selectedTextColor,
                            unselectedTextColor:
                            widget.unselectedTextColor,
                          );
                        }).toList(),
                      ),
                    )
                        : Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: widget.items.map((item) {
                          return GenericMenuItem(
                            isSelected:
                            item.value == widget.selectedValue,
                            onTap: () {
                              widget.onChanged(item.value);
                            },
                            label: item.label,
                            icon: item.icon,
                            fontSize: widget.fontSize,
                            isExpanded: isMenuExpanded,
                            padding: widget.padding ??
                                const EdgeInsets.symmetric(
                                    horizontal: 5.0, vertical: 5),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 2.0, vertical: 3),
                            borderRadius: widget.borderRadius,
                            selectedColor: widget.selectedColor,
                            unselectedColor: widget.unselectedColor,
                            selectedTextColor: widget.selectedTextColor,
                            unselectedTextColor:
                            widget.unselectedTextColor,
                          );
                        }).toList(),
                      ),
                    ),

                    /// Footer
                    if (widget.menuFooterBuilder != null)
                      widget.menuFooterBuilder!(isMenuExpanded),
                  ],
                ),
              ),
            ),

            /// 🔷 Main content
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                child: selectedItem.screen,
              ),
            ),
          ],
        );
      },
    );
  }
}

class MenuDefinition<T> {
  final T value;
  final String label;
  final Widget screen;
  final IconData? icon;

  MenuDefinition({
    required this.value,
    required this.label,
    required this.screen,
    this.icon,
  });
}