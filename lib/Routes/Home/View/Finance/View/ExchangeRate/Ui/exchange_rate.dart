import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../../Features/Widgets/cover.dart';
import '../../../../../../../Features/Widgets/extensions.dart';
import '../../../../../../../l10n/Bloc/localizations_bloc.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../bloc/menu_bloc.dart';
import '../../../bloc/financial_tab_bloc.dart';
import '../bloc/exchange_rate_bloc.dart';
import '../model/ex_rate_model.dart';
import 'add_rate.dart';

class ExchangeRateView extends StatelessWidget {
  final bool newRateButton;
  final bool settingButton;
  final double? width;

  const ExchangeRateView({
    super.key,
    this.newRateButton = false,
    this.settingButton = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(
        newRateButton: newRateButton,
        settingButton: settingButton,
        width: width,
      ),
      tablet: _Desktop(
        newRateButton: newRateButton,
        settingButton: settingButton,
        width: width,
      ),
      desktop: _Desktop(
        newRateButton: newRateButton,
        settingButton: settingButton,
        width: width,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Helper: current base currency from AuthBloc (fallback empty)
// ═══════════════════════════════════════════════════════════════════
String _baseCurrency(BuildContext context) {
  try {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthenticatedState) {
      return auth.loginData.company?.comLocalCcy ?? '';
    }
  } catch (_) {}
  return '';
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _Desktop extends StatefulWidget {
  final bool newRateButton;
  final bool settingButton;
  final double? width;

  const _Desktop({
    required this.newRateButton,
    required this.settingButton,
    this.width,
  });

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _refresh() {
    if (!mounted) return;
    context
        .read<ExchangeRateBloc>()
        .add(LoadExchangeRateEvent(_baseCurrency(context)));
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AddRateView(baseCcy: _baseCurrency(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final currentLocale =
        context.read<LocalizationBloc>().state.languageCode;
    final color = Theme.of(context).colorScheme;

    return Container(
      width: widget.width ?? double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 3),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.outline.withValues(alpha: .3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Text(
                  locale.fxRate,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),

                // Refresh (always)
                _CircleActionButton(
                  tooltip: locale.refresh,
                  icon: Icons.refresh,
                  onPressed: _refresh,
                  isActive: true,
                ),

                if (widget.newRateButton) ...[
                  const SizedBox(width: 6),
                  _CircleActionButton(
                    tooltip: locale.newKeyword,
                    icon: Icons.add,
                    onPressed: _openAddDialog,
                    isActive: true,
                  ),
                ],

                if (widget.settingButton) ...[
                  const SizedBox(width: 6),
                  _CircleActionButton(
                    tooltip: locale.settings,
                    icon: Icons.settings,
                    onPressed: () {
                      context
                          .read<MenuBloc>()
                          .add(MenuOnChangedEvent(MenuName.finance));
                      context.read<FinanceTabBloc>().add(
                          FinanceOnChangedEvent(FinanceTabName.exchangeRate));
                    },
                    isActive: true,
                  ),
                ],
              ],
            ),
          ),


          // ── Column header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(locale.currencyTitle,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                Text(locale.rate,
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          Divider(
            indent: 5,
            endIndent: 5,
            color: color.primary.withValues(alpha: 0.09),
          ),

          // ── Body
          BlocConsumer<ExchangeRateBloc, ExchangeRateState>(
            listener: (context, state) {
              if (state is ExchangeRateSuccessState) {
                _refresh();
              }
            },
            builder: (context, state) {
              if (state is ExchangeRateErrorState) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (state is ExchangeRateLoadingState) {
                return const Padding(
                  padding: EdgeInsets.all(10),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is ExchangeRateLoadedState) {
                if (state.rates.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: Text("No rate")),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.rates.length,
                  itemBuilder: (context, index) {
                    final ccy = state.rates[index];
                    return _RateRow(
                      rate: ccy,
                      isOdd: index.isOdd,
                      locale: currentLocale,
                      baseCcy: _baseCurrency(context),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _Mobile extends StatefulWidget {
  final bool newRateButton;
  final bool settingButton;
  final double? width;

  const _Mobile({
    required this.newRateButton,
    required this.settingButton,
    this.width,
  });

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _refresh() {
    if (!mounted) return;
    context
        .read<ExchangeRateBloc>()
        .add(LoadExchangeRateEvent(_baseCurrency(context)));
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AddRateView(baseCcy: _baseCurrency(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final currentLocale =
        context.read<LocalizationBloc>().state.languageCode;
    final color = Theme.of(context).colorScheme;

    return Container(
      width: widget.width ?? double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 3),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.outline.withValues(alpha: .3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Text(locale.rate,
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                ZCover(
                  child: IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                if (widget.newRateButton) ...[
                  const SizedBox(width: 5),
                  ZCover(
                    child: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _openAddDialog,
                    ),
                  ),
                ],
                if (widget.settingButton) ...[
                  const SizedBox(width: 5),
                  ZCover(
                    child: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        context
                            .read<MenuBloc>()
                            .add(MenuOnChangedEvent(MenuName.finance));
                        context.read<FinanceTabBloc>().add(
                            FinanceOnChangedEvent(FinanceTabName.exchangeRate));
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 5),

          // ── Column header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(locale.currencyTitle,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                Text(locale.rate,
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          Divider(
            indent: 5,
            endIndent: 5,
            color: color.primary.withValues(alpha: 0.09),
          ),

          // ── Body
          BlocConsumer<ExchangeRateBloc, ExchangeRateState>(
            listener: (context, state) {
              if (state is ExchangeRateSuccessState) {
                _refresh();
              }
            },
            builder: (context, state) {
              if (state is ExchangeRateErrorState) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (state is ExchangeRateLoadingState) {
                return const Padding(
                  padding: EdgeInsets.all(10),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is ExchangeRateLoadedState) {
                if (state.rates.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: Text("No rate")),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.rates.length,
                  itemBuilder: (context, index) {
                    final ccy = state.rates[index];
                    return _RateRow(
                      rate: ccy,
                      isOdd: index.isOdd,
                      locale: currentLocale,
                      baseCcy: _baseCurrency(context),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared row
// ═══════════════════════════════════════════════════════════════════
class _RateRow extends StatelessWidget {
  final ExchangeRateModel rate;
  final bool isOdd;
  final String locale;
  final String baseCcy;

  const _RateRow({
    required this.rate,
    required this.isOdd,
    required this.locale,
    required this.baseCcy,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Material(
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        splashColor: color.primary.withValues(alpha: .2),
        hoverColor: color.primary.withValues(alpha: .09),
        onTap: () => showDialog(
          context: context,
          builder: (_) => AddRateView(rate: rate, baseCcy: baseCcy),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: isOdd
                ? color.primary.withValues(alpha: .05)
                : Colors.transparent,
          ),
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Flag.fromString(
                        rate.fromCode ?? '',
                        height: 20,
                        width: 30,
                        borderRadius: 2,
                        fit: BoxFit.fill,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                      child: Text(
                        '1',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ZCover(
                      margin:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
                      child: SizedBox(
                        width: 35,
                        child: Text(
                          rate.crFrom ?? '',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                      child: Text(
                        '=',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  (rate.crExchange ?? '').toExchangeRate(),
                  textAlign:
                  locale == 'en' ? TextAlign.right : TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ZCover(
                margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 3),
                child: SizedBox(
                  width: 35,
                  child: Text(
                    rate.crTo ?? '',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              SizedBox(
                width: 30,
                child: Flag.fromString(
                  rate.toCode ?? '',
                  height: 20,
                  width: 30,
                  borderRadius: 2,
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;

  const _CircleActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    // Base look: subtle tinted background (inactive) vs. primary-tinted
    // (active). Same hue family as ZOutlineButton so the row still reads
    // as one coherent action group.
    final bg = isActive
        ? color.outline.withValues(alpha: .07)
        : color.surfaceContainerHighest.withValues(alpha: .5);
    final fg = isActive ? color.primary : color.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: fg),
          ),
        ),
      ),
    );
  }
}