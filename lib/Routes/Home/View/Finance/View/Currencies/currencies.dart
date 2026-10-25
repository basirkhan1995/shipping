import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flag/flag.dart';
import '../../../../../../../../../Features/Widgets/search_field.dart';
import 'package:flutter/services.dart';

import '../../../../../../Features/Other/global_shortcut.dart';
import '../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../Features/Widgets/alert_dialog.dart';
import '../../../../../../Features/Widgets/cover.dart';
import '../../../../../../Features/Widgets/shimmer.dart';
import '../../../../../../Features/Widgets/zbutton.dart';
import 'add_edit_ccy.dart';
import 'bloc/currencies_bloc.dart';

class CurrenciesView extends StatelessWidget {
  const CurrenciesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        mobile: _Mobile(), tablet: _Desktop(), desktop: _Desktop());
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _Mobile extends StatefulWidget {
  const _Mobile();

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  final searchController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrenciesBloc>().add(LoadCurrenciesEvent());
    });
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 &&
        _scrollController.position.userScrollDirection ==
            ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward ||
        _scrollController.offset < 50) {
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle = textTheme.titleSmall?.copyWith(color: color.surface);

    final shortcuts = {
      const SingleActivator(LogicalKeyboardKey.f1): onAdd,
      const SingleActivator(LogicalKeyboardKey.f5): onRefresh,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(
          0,
          _isFabVisible ? 0 : 100,
          0,
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: FloatingActionButton(
            onPressed: onAdd,
            child: const Icon(Icons.add),
          ),
        ),
      ),
      body: GlobalShortcuts(
        shortcuts: shortcuts,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ReusableSearchBar(
                controller: searchController,
                onChanged: (e) {
                  setState(() {});
                },
              ),
            ),

            const SizedBox(height: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: .9),
              ),
              child: Row(
                children: [
                  SizedBox(width: 50, child: Text("Flag", style: titleStyle)),
                  SizedBox(
                    width: 60,
                    child: Text("Code", style: titleStyle),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 70,
                    child: Text("Symbol", style: titleStyle),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 60,
                    child: Text("Status", style: titleStyle),
                  ),
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<CurrenciesBloc, CurrenciesState>(
                builder: (context, state) {
                  if (state is CurrenciesLoadingState) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (state is CurrenciesErrorState) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () {
                        context
                            .read<CurrenciesBloc>()
                            .add(LoadCurrenciesEvent());
                      },
                    );
                  }
                  if (state is CurrenciesLoadedState) {
                    final query = searchController.text.toLowerCase().trim();
                    final filteredCcy = state.all.where((item) {
                      final ccyCode = item.ccyCode?.toLowerCase() ?? '';
                      final ccyName = item.ccyName?.toLowerCase() ?? '';
                      return ccyCode.contains(query) ||
                          ccyName.contains(query);
                    }).toList();

                    if (filteredCcy.isEmpty) {
                      return const _EmptyView(
                        message: 'No currencies found',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: onRefresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: filteredCcy.length,
                        itemBuilder: (context, index) {
                          final ccy = filteredCcy[index];
                          return InkWell(
                            hoverColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: .05),
                            highlightColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: .05),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AddEditCurrencyView(currency: ccy);
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: index.isOdd
                                    ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: .05)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 30,
                                    child: Flag.fromString(
                                      ccy.ccyCountryCode ?? "",
                                      height: 20,
                                      width: 30,
                                      borderRadius: 2,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      ccy.ccyCode ?? "",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  const Spacer(),
                                  ZCover(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Text(
                                      ccy.ccySymbol ?? "",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  SizedBox(
                                    width: 70,
                                    child: Checkbox(
                                      visualDensity: const VisualDensity(
                                          vertical: -4),
                                      value: ccy.ccyStatus == 1,
                                      onChanged: (e) {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return ZAlertDialog(
                                              title: 'Are you sure?',
                                              content:
                                              'Change the active status of this currency?',
                                              onYes: () {
                                                context
                                                    .read<CurrenciesBloc>()
                                                    .add(UpdateCcyStatusEvent(
                                                  ccyCode: ccy.ccyCode!,
                                                  status: e ?? false,
                                                ));
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onRefresh() async {
    context.read<CurrenciesBloc>().add(LoadCurrenciesEvent());
  }

  void onAdd() {
    showDialog(
      context: context,
      builder: (context) {
        return AddEditCurrencyView();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _Desktop extends StatefulWidget {
  const _Desktop();

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final searchController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrenciesBloc>().add(LoadCurrenciesEvent());
    });
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    TextStyle? titleStyle =
    textTheme.titleSmall?.copyWith(color: color.surface);

    final shortcuts = {
      const SingleActivator(LogicalKeyboardKey.f1): onAdd,
      const SingleActivator(LogicalKeyboardKey.f5): onRefresh,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GlobalShortcuts(
        shortcuts: shortcuts,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'All Currencies',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: ReusableSearchBar(
                      controller: searchController,
                      onChanged: (e) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      ZOutlineButton(
                        toolTip: 'F5',
                        width: 110,
                        icon: Icons.refresh,
                        label: const Text('Refresh'),
                        onPressed: onRefresh,
                      ),
                      const SizedBox(width: 8),
                      ZOutlineButton(
                        toolTip: 'F1',
                        isActive: true,
                        width: 110,
                        label: const Text('New'),
                        onPressed: onAdd,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: .9),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text("Flag", style: titleStyle),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text("Code", style: titleStyle),
                  ),
                  SizedBox(
                    width: 220,
                    child: Text("Name", style: titleStyle),
                  ),
                  SizedBox(
                    width: 170,
                    child: Text("Local Name", style: titleStyle),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 70,
                    child: Text("Symbol", style: titleStyle),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 60,
                    child: Text("Status", style: titleStyle),
                  ),
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<CurrenciesBloc, CurrenciesState>(
                builder: (context, state) {
                  if (state is CurrenciesLoadingState) {
                    return UniversalShimmer.dataList(
                      itemCount: 15,
                      numberOfColumns: 5,
                    );
                  }
                  if (state is CurrenciesErrorState) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () {
                        context
                            .read<CurrenciesBloc>()
                            .add(LoadCurrenciesEvent());
                      },
                    );
                  }
                  if (state is CurrenciesLoadedState) {
                    final query = searchController.text.toLowerCase().trim();
                    final filteredCcy = state.all.where((item) {
                      final ccyCode = item.ccyCode?.toLowerCase() ?? '';
                      final ccyName = item.ccyName?.toLowerCase() ?? '';
                      return ccyCode.contains(query) ||
                          ccyName.contains(query);
                    }).toList();

                    if (filteredCcy.isEmpty) {
                      return const _EmptyView(
                        message: 'No currencies found',
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredCcy.length,
                      itemBuilder: (context, index) {
                        final ccy = filteredCcy[index];
                        return InkWell(
                          hoverColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: .05),
                          highlightColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: .05),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AddEditCurrencyView(currency: ccy);
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: index.isOdd
                                  ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: .05)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Flag.fromString(
                                    ccy.ccyCountryCode ?? "",
                                    height: 20,
                                    width: 30,
                                    borderRadius: 2,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    ccy.ccyCode ?? "",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    ccy.ccyName ?? "",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                SizedBox(
                                  width: 190,
                                  child: Text(
                                    ccy.ccyLocalName ?? "",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                const Spacer(),
                                ZCover(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5),
                                  child: Text(
                                    ccy.ccySymbol ?? "",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                const SizedBox(width: 30),
                                SizedBox(
                                  width: 70,
                                  child: Checkbox(
                                    visualDensity: const VisualDensity(
                                        vertical: -4),
                                    value: ccy.ccyStatus == 1,
                                    onChanged: (e) {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return ZAlertDialog(
                                            title: 'Are you sure?',
                                            content:
                                            'Change the active status of this currency?',
                                            onYes: () {
                                              context
                                                  .read<CurrenciesBloc>()
                                                  .add(UpdateCcyStatusEvent(
                                                ccyCode: ccy.ccyCode!,
                                                status: e ?? false,
                                              ));
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onRefresh() {
    context.read<CurrenciesBloc>().add(LoadCurrenciesEvent());
  }

  void onAdd() {
    showDialog(
      context: context,
      builder: (context) {
        return AddEditCurrencyView();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Inline empty / error views (replaces NoDataWidget)
// ═══════════════════════════════════════════════════════════════════
class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 48, color: scheme.onSurface.withValues(alpha: .3)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: .6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 44, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ZOutlineButton(
              label: const Text('Try again'),
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}