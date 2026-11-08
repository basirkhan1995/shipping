import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../Features/Other/responsive_widget.dart';
import '../../../../Features/Widgets/tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import '../../../Auth/model/user_model.dart';
import 'View/Attendance/attendance.dart';
import 'View/Employees/employees.dart';
import 'View/Users/users.dart';
import 'bloc/hrtab_bloc.dart';

class HrTabView extends StatelessWidget {
  const HrTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(),
      tablet: _Desktop(),
      desktop: _Desktop(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: BlocBuilder<HrTabBloc, HrTabState>(
          builder: (context, tabState) {
            final tabs = _buildTabs(context, login);

            // Nothing the user can access → show a friendly empty state
            // instead of crashing on `.first` of an empty list.
            if (tabs.isEmpty) {
              return _NoAccessView(
                title: AppLocalizations.of(context)!.hr,
              );
            }

            final availableValues = tabs.map((t) => t.value).toList();
            final selected = availableValues.contains(tabState.tabs)
                ? tabState.tabs
                : availableValues.first;

            return ZTabContainer<HrTabName>(
              tabs: tabs,
              selectedValue: selected,
              onChanged: (val) =>
                  context.read<HrTabBloc>().add(HrOnchangeEvent(val)),
              style: ZTabStyle.rounded,
              tabBarPadding: const EdgeInsets.symmetric(horizontal: 8),
              borderRadius: 0,
              selectedColor: Theme.of(context).colorScheme.primary,
              unselectedTextColor: Theme.of(context).colorScheme.secondary,
              selectedTextColor: Theme.of(context).colorScheme.surface,
              tabContainerColor: Theme.of(context).colorScheme.surface,
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;

    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = state.loginData;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: BlocBuilder<HrTabBloc, HrTabState>(
          builder: (context, tabState) {
            final tabs = _buildTabs(context, login);

            // Nothing the user can access → show a friendly empty state.
            if (tabs.isEmpty) {
              return _NoAccessView(
                title: AppLocalizations.of(context)!.hr,
              );
            }

            final availableValues = tabs.map((t) => t.value).toList();
            final selected = availableValues.contains(tabState.tabs)
                ? tabState.tabs
                : availableValues.first;

            return ZTabContainer<HrTabName>(
              title: AppLocalizations.of(context)!.hr,
              description: AppLocalizations.of(context)!.hrTitle,
              tabs: tabs,
              selectedValue: selected,
              onChanged: (val) =>
                  context.read<HrTabBloc>().add(HrOnchangeEvent(val)),
              style: ZTabStyle.rounded,
              tabBarPadding: const EdgeInsets.symmetric(horizontal: 8),
              borderRadius: 0,
              selectedColor: Theme.of(context).colorScheme.primary,
              unselectedTextColor: Theme.of(context).colorScheme.secondary,
              selectedTextColor: Theme.of(context).colorScheme.surface,
              tabContainerColor: Theme.of(context).colorScheme.surface,
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared — tab list builder (identical for mobile and desktop)
// ═══════════════════════════════════════════════════════════════════
List<ZTabItem<HrTabName>> _buildTabs(
    BuildContext context,
    LoginData login,
    ) {
  return <ZTabItem<HrTabName>>[
    if (login.hasPermission(36) ?? false)
      ZTabItem(
        value: HrTabName.employees,
        label: AppLocalizations.of(context)!.employees,
        screen: const EmployeesView(),
      ),
    if (login.hasPermission(37) ?? false)
      ZTabItem(
        value: HrTabName.attendance,
        label: AppLocalizations.of(context)!.attendance,
        screen: const AttendanceView(),
      ),
    if (login.hasPermission(38) ?? false)
      ZTabItem(
        value: HrTabName.users,
        label: AppLocalizations.of(context)!.users,
        screen: const UsersView(),
      ),
  ];
}

// ═══════════════════════════════════════════════════════════════════
// Friendly "no access" view
// ═══════════════════════════════════════════════════════════════════
class _NoAccessView extends StatelessWidget {
  final String title;
  const _NoAccessView({required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tr.noPermissionMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}