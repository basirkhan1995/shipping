import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/HR/hr.dart';
import 'package:shipping/Routes/Home/View/Products/products.dart';
import 'package:shipping/Routes/Home/View/Settings/View/Company/bloc/company_settings_menu_bloc.dart';
import 'package:shipping/Routes/Home/View/Settings/bloc/settings_tab_bloc.dart';
import 'package:shipping/Routes/Home/View/Shipments/shipments.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/all_stakeholder.dart';
import 'package:shipping/Routes/Home/View/Transactions/transactions.dart';
import 'package:shipping/Routes/Home/View/Transfer/transfer.dart';
import '../../../../Features/Other/responsive_widget.dart';
import '../../Features/Widgets/generic_menu.dart';
import '../../l10n/app_localizations.dart';
import '../Auth/bloc/auth_bloc.dart';
import '../Auth/features/com_logo.dart';
import 'View/Dashboard/dashboard.dart';
import 'View/Finance/finance.dart';
import 'View/Report/report.dart';
import 'View/Settings/Visibility/bloc/settings_visible_bloc.dart';
import 'View/Settings/settings.dart';
import 'View/Stock/Orders/Ui/orders.dart';
import 'bloc/menu_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileView(),
      tablet: _TabletView(),
      desktop: _DesktopView(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _MobileView extends StatelessWidget {
  const _MobileView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Mobile'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TABLET
// ═══════════════════════════════════════════════════════════════════
class _TabletView extends StatelessWidget {
  const _TabletView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Tablet'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _DesktopView extends StatelessWidget {
  const _DesktopView();

  @override
  Widget build(BuildContext context) {

    final currentTab = context.select((MenuBloc bloc) => bloc.state.tabs);
    final visibility = context.watch<SettingsVisibleBloc>().state;
    final menuItems = [
      MenuDefinition(
        value: MenuName.dashboard,
        label: AppLocalizations.of(context)!.dashboard,
        screen: const DashboardView(),
        icon: Icons.add_home_outlined,
      ),
      MenuDefinition(
        value: MenuName.finance,
        label: AppLocalizations.of(context)!.finance,
        screen: const FinanceView(),
        icon: Icons.monetization_on_rounded,
      ),
      MenuDefinition(
        value: MenuName.hr,
        label: AppLocalizations.of(context)!.hr,
        screen: const HrTabView(),
        icon: Icons.person,
      ),
      MenuDefinition(
        value: MenuName.transactions,
        label: AppLocalizations.of(context)!.transactions,
        screen: const TransactionsView(),
        icon: Icons.line_axis_rounded,
      ),
      MenuDefinition(
        value: MenuName.stakeholders,
        label: AppLocalizations.of(context)!.stakeholders,
        screen: const StakeholderView(),
        icon: Icons.people,
      ),
      if(visibility.orders)...[
        MenuDefinition(
          value: MenuName.stock,
          label: AppLocalizations.of(context)!.stock,
          screen: const OrdersView(),
          icon: Icons.shopify_rounded,
        ),
        MenuDefinition(
          value: MenuName.products,
          label: AppLocalizations.of(context)!.products,
          screen: const ProductsView(),
          icon: Icons.production_quantity_limits_rounded,
        ),
      ],

    if(visibility.shipping)
      MenuDefinition(
        value: MenuName.shipment,
        label: AppLocalizations.of(context)!.shipment,
        screen: const ShipmentsView(),
        icon: Icons.transform_rounded,
      ),
      if(visibility.moneyTransfer)
      MenuDefinition(
        value: MenuName.transfer,
        label: AppLocalizations.of(context)!.transfer,
        screen: const TransferView(),
        icon: Icons.attach_money_rounded,
      ),
      MenuDefinition(
        value: MenuName.settings,
        label: AppLocalizations.of(context)!.settings,
        screen: const SettingsView(),
        icon: Icons.settings_outlined,
      ),
      MenuDefinition(
        value: MenuName.report,
        label: AppLocalizations.of(context)!.report,
        screen: const ReportView(),
        icon: Icons.insert_drive_file_outlined,
      ),
    ];

    if (menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_accounts_rounded,
              size: 48,
              color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: .3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.accessDenied,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please contact administrator",
              style: TextStyle(
                fontSize: 14,
                color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: .4),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: GenericMenuWithScreen<MenuName>(
          key: const Key('main_menu'),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          selectedValue: currentTab,
          onChanged: (val) {
            if (currentTab != val) {
              context.read<MenuBloc>().add(MenuOnChangedEvent(val));
            }
          },
          items: menuItems,
          selectedColor: Theme.of(context).colorScheme.primary.withAlpha(23),
          selectedTextColor:
          Theme.of(context).colorScheme.primary.withAlpha(230),
          unselectedTextColor: Theme.of(context).colorScheme.secondary,

          // ── Company logo + name at the top of the sidebar ──
          menuHeaderBuilder: (isExpanded) =>
              _CompanyHeader(isExpanded: isExpanded),
        ),
      ),
    );
  }
}

/// Header shown at the top of the desktop sidebar: company logo + name.
class _CompanyHeader extends StatelessWidget {
  final bool isExpanded;

  const _CompanyHeader({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthBloc>().state;
    final company =
    authState is AuthenticatedState ? authState.loginData.company : null;

    final companyName = company?.comName ?? 'Company';
    final logo = company?.comLogo;

    // Wider avatar: 75px expanded, 34px collapsed.

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 8 : 0,
        vertical: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Logo on top ──
          _HomeLogo(logo: logo, size: 44),

          // ── Name below (hidden when collapsed) ──
          if (isExpanded) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: (){
                context.read<MenuBloc>().add(MenuOnChangedEvent(MenuName.settings));
                context.read<SettingsTabBloc>().add(SettingsOnChangeEvent(SettingsTabName.company));
                context.read<CompanySettingsMenuBloc>().add(CompanySettingsOnChangedEvent(CompanySettingsMenuName.profile));
              },
              child: Text(
                companyName,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeLogo extends StatelessWidget {
  final String? logo;
  final double size;

  const _HomeLogo({required this.logo, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = CompanyLogoUtils.resolve(logo);

    switch (result.kind) {
    // ── http(s):// URL → let Flutter's image cache handle it ──
      case CompanyLogoKind.network:
        return ClipOval(
          child: Image.network(
            result.url!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _fallback(scheme),
          ),
        );

    // ── data: URL or raw base64 → decoded bytes ──
      case CompanyLogoKind.memory:
        return ClipOval(
          child: Image.memory(
            result.bytes!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _fallback(scheme),
          ),
        );

    // ── empty / malformed / unsupported ──
      case CompanyLogoKind.fallback:
        return _fallback(scheme);
    }
  }

  Widget _fallback(ColorScheme scheme) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: scheme.primaryContainer,
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.business_outlined,
      size: size * 0.55,
      color: scheme.onPrimaryContainer,
    ),
  );
}