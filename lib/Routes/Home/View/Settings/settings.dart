import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/Settings/View/Company/company_tab.dart';
import '../../../../Features/Other/responsive_widget.dart';
import '../../../../Features/Widgets/tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
import 'View/About/about.dart';
import 'View/Backup/backup.dart';
import 'View/System/system.dart';
import 'bloc/settings_tab_bloc.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile:  _MobileView(),
      tablet:  _TabletView(),
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
        child: Text('Settings'),
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
    return Scaffold(
      body: Center(
        child: Text(AppLocalizations.of(context)!.settings),
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
    // // ── Who is logged in?
    // final authState = context.select((AuthBloc b) => b.state);
    // final isAdmin = authState is AuthenticatedState &&
    //     authState.loginData.usrRole?.toUpperCase() == 'ADMIN';

    final tabs = <ZTabItem<SettingsTabName>>[
      ZTabItem(
        value: SettingsTabName.system,
        label: AppLocalizations.of(context)!.generalSettings,
        screen: const SystemView(),
      ),
      ZTabItem(
        value: SettingsTabName.company,
        label: AppLocalizations.of(context)!.company,
        screen: const CompanyTabsView(),
      ),

      ZTabItem(
        value: SettingsTabName.backup,
        label: AppLocalizations.of(context)!.backup,
        screen: const BackupView(),
      ),
      ZTabItem(
        value: SettingsTabName.about,
        label: AppLocalizations.of(context)!.aboat,
        screen: const AboutView(),
      ),
    ];

    return BlocBuilder<SettingsTabBloc, SettingsTabState>(
      builder: (context, blocState) {
        final availableValues = tabs.map((tab) => tab.value).toList();

        // If the currently-selected tab is hidden (e.g. an admin logged out
        // and a non-admin logged in), fall back to the first available tab.
        final selected = availableValues.contains(blocState.tabs)
            ? blocState.tabs
            : availableValues.first;

        return ZTabContainer<SettingsTabName>(
          tabs: tabs,
          selectedValue: selected,
          onChanged: (val) => context.read<SettingsTabBloc>().add(SettingsOnChangeEvent(val)),
          icon: Icons.settings,
          title: AppLocalizations.of(context)!.settings,
          description: AppLocalizations.of(context)!.settingsHint,
          style: ZTabStyle.rounded,
          tabBarPadding:
          const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          borderRadius: 0,
          selectedColor: Theme.of(context).colorScheme.primary,
          unselectedTextColor: Theme.of(context).colorScheme.secondary,
          selectedTextColor: Theme.of(context).colorScheme.surface,
        );
      },
    );
  }
}