import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/HR/hr.dart';
import 'package:shipping/Routes/Home/View/Shipments/shipments.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/all_stakeholder.dart';
import 'package:shipping/Routes/Home/View/Transactions/transactions.dart';
import '../../../../Features/Other/responsive_widget.dart';
import '../../Features/Widgets/generic_menu.dart';
import '../../l10n/app_localizations.dart';
import '../Auth/bloc/auth_bloc.dart';
import 'View/Dashboard/dashboard.dart';
import 'View/Finance/finance.dart';
import 'View/Report/report.dart';
import 'View/Settings/settings.dart';
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
        icon: Icons.monetization_on_outlined,
      ),
      MenuDefinition(
        value: MenuName.hr,
        label: AppLocalizations.of(context)!.hr,
        screen: const HrView(),
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
      MenuDefinition(
        value: MenuName.shipment,
        label: AppLocalizations.of(context)!.shipment,
        screen: const ShipmentsView(),
        icon: Icons.local_shipping_outlined,
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
        icon: Icons.file_copy_outlined,
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.accessDenied,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please contact administrator",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4),
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
          selectedTextColor: Theme.of(context).colorScheme.primary.withAlpha(230),
          unselectedTextColor: Theme.of(context).colorScheme.secondary,

          // ── Company logo + name at the top of the sidebar ──
          menuHeaderBuilder: (isExpanded) => _CompanyHeader(isExpanded: isExpanded),
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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 8 : 0,
        vertical: 6,
      ),
      child: isExpanded
      // Expanded: logo + name side by side
          ? Row(
        children: [
          _CompanyLogo(logo: logo, scheme: scheme, radius: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              companyName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                height: 1.2,
              ),
            ),
          ),
        ],
      )
      // Collapsed: just the logo, centered
          : Center(
        child: _CompanyLogo(logo: logo, scheme: scheme, radius: 18),
      ),
    );
  }
}

/// Company logo with initials fallback.
class _CompanyLogo extends StatelessWidget {
  final String? logo;
  final ColorScheme scheme;
  final double radius;

  const _CompanyLogo({
    required this.logo,
    required this.scheme,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logo != null && logo!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      backgroundImage: hasLogo ? NetworkImage(logo!) : null,
      child: hasLogo
          ? null
          : Icon(
        Icons.business_outlined,
        size: radius * 0.9,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}