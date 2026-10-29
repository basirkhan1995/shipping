import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/Settings/View/General/DefaultPermissions/features/per_utility.dart';
import 'package:shipping/Routes/Home/View/Settings/View/General/UserRole/bloc/user_role_bloc.dart';
import '../../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../../Features/Widgets/cover.dart';
import '../../../../../../../Features/Widgets/noData_widget.dart';
import '../../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../UserRole/add_edit_role.dart';
import '../UserRole/model/role_model.dart';
import 'bloc/permission_settings_bloc.dart';
import 'model/permission_settings_model.dart';

class PermissionSettingsView extends StatelessWidget {
  const PermissionSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddEditUserRoleSettingsView(),
          );
        },
      ),
      body: const ResponsiveLayout(
        mobile: _Mobile(),
        tablet: _Tablet(),
        desktop: _Desktop(),
      ),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();
  @override
  Widget build(BuildContext context) =>
      const _PermissionSettingsContent(layoutType: LayoutType.mobile);
}

class _Tablet extends StatelessWidget {
  const _Tablet();
  @override
  Widget build(BuildContext context) =>
      const _PermissionSettingsContent(layoutType: LayoutType.tablet);
}

class _Desktop extends StatelessWidget {
  const _Desktop();
  @override
  Widget build(BuildContext context) =>
      const _PermissionSettingsContent(layoutType: LayoutType.desktop);
}

enum LayoutType { mobile, tablet, desktop }

class PermissionCategory {
  final String name;
  final IconData icon;
  final List<String> permissionNames;

  const PermissionCategory({
    required this.name,
    required this.icon,
    required this.permissionNames,
  });
}

class _PermissionSettingsContent extends StatefulWidget {
  final LayoutType layoutType;
  const _PermissionSettingsContent({required this.layoutType});

  @override
  State<_PermissionSettingsContent> createState() =>
      _PermissionSettingsContentState();
}

class _PermissionSettingsContentState
    extends State<_PermissionSettingsContent> {
  final Map<int, Map<String, bool>> _localChanges = {};
  bool _hasChanges = false;
  List<UserRolePermissionSettingModel>? _originalRoles;
  String usrName = '';

  /// Memoized localization — avoids re-running the big mapper on
  /// every row × every frame.
  final Map<String, String> _labelCache = {};

  /// Flattened lookup: rsgName → roleId → bool. Rebuilt once per
  /// successful load. Cell rendering becomes O(1).
  final Map<String, Map<int, bool>> _permLookup = {};

  /// rsgName → total rows (for category counts).
  final Map<String, int> _permRoleCount = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        usrName = authState.loginData.usrName ?? '';
      }
      final settings = context.read<PermissionSettingsBloc>().state;
      if (settings is PermissionSettingsInitial) {
        context
            .read<PermissionSettingsBloc>()
            .add(LoadPermissionsSettingsEvent());
      }
    });
  }

  String _localize(String apiName) {
    final cached = _labelCache[apiName];
    if (cached != null) return cached;
    final resolved = PermissionMapper.localize(context, apiName);
    _labelCache[apiName] = resolved;
    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserRoleBloc, UserRoleState>(
      listenWhen: (p, c) => c is UserRoleSuccessState,
      listener: (context, _) {
        // Dialog wrote to UserRoleBloc — reload the settings bloc.
        context
            .read<PermissionSettingsBloc>()
            .add(LoadPermissionsSettingsEvent());
      },
      child: BlocBuilder<PermissionSettingsBloc, PermissionSettingsState>(
        builder: (context, state) {
          if (state is PermissionSettingsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PermissionSettingsErrorState) {
            return _buildErrorState(context, state);
          }
          if (state is PermissionSettingsLoadedState) {
            _originalRoles ??= state.permissions;
            _rebuildLookup(state.permissions);

            return Stack(
              children: [
                _buildContent(context, state.permissions),
                if (_hasChanges) _buildSaveBar(context),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Rebuild the O(1) lookup once per successful load, not per frame.
  void _rebuildLookup(List<UserRolePermissionSettingModel> roles) {
    _permLookup.clear();
    _permRoleCount.clear();
    for (final role in roles) {
      final perms = role.permissions;
      if (perms == null) continue;
      for (final p in perms) {
        final name = p.rsgName;
        if (name == null) continue;
        _permLookup.putIfAbsent(name, () => {})[role.rolId!] = p.rpStatus == 1;
        _permRoleCount[name] = (_permRoleCount[name] ?? 0) + 1;
      }
    }
  }

  List<PermissionCategory> _getPermissionCategories(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return [
      PermissionCategory(
        name: locale.dashboard,
        icon: Icons.add_home_outlined,
        permissionNames: const [
          'Dashboard',
          'Counts',
          'Exchange Rate Graph',
          'Daily Transactions Graph',
          'Daily Transaction Totals',
          'Digital Clock',
          'Exchange Rates',
          'Profit Loss Graph',
          'Reminder Notifications',
        ],
      ),
      PermissionCategory(
        name: locale.finance,
        icon: Icons.money,
        permissionNames: const [
          'Finance',
          'Currency Tab',
          'Currency',
          'GL Accounts',
          'Payroll',
          'EOY Operation',
          'Reminders',
        ],
      ),
      PermissionCategory(
        name: locale.journal,
        icon: Icons.menu_book_rounded,
        permissionNames: const [
          'Journal',
          'All Transactions',
          'Authorized Transaction',
          'Pending Transaction',
          'Cash Deposit',
          'Cash Withdraw',
          'Income Entry',
          'Expense Entry',
          'GL Debit',
          'GL Credit',
          'FT Single Account',
          'FT Multi Account',
          'FX Transactions',
        ],
      ),
      PermissionCategory(
        name: locale.stakeholders,
        icon: Icons.people,
        permissionNames: const [
          'Stakeholders',
          'Individuals',
          'Accounts',
          'Users',
        ],
      ),
      PermissionCategory(
        name: locale.hrTitle,
        icon: Icons.person,
        permissionNames: const [
          'HR - Human Resource',
          'Employees',
          'Attendance',
          'All Users',
          'Overview',
          'Permissions',
          'User Log',
        ],
      ),
      PermissionCategory(
        name: locale.transport,
        icon: Icons.local_shipping,
        permissionNames: const [
          'Transport',
          'Shipping',
          'Drivers',
          'Vehicles',
        ],
      ),
      PermissionCategory(
        name: locale.inventory,
        icon: Icons.inventory,
        permissionNames: const [
          'Inventory',
          'Orders Tab',
          'Estimate Tab',
          'Goods Shift Tab',
          'Adjustment Tab',
          'Purchase',
          'Sale',
          'Estimate',
          'Goods Shift',
          'Adjustment',
          'Find Invoice',
        ],
      ),
      PermissionCategory(
        name: locale.settings,
        icon: Icons.settings,
        permissionNames: const [
          'Settings',
          'General Tab',
          'System Settings',
          'Password Change',
          'User Profile',
          'Roles and Permissions',
          'Company Tab',
          'Profile',
          'Branches',
          'Storage',
          'Transaction Type',
          'Stock',
          'Products',
          'Category',
          'Backup',
          'About',
        ],
      ),
      PermissionCategory(
        name: locale.reports,
        icon: Icons.bar_chart,
        permissionNames: const [
          'Reports',
          'Account Statement Single Date',
          'GL Statement Single Date',
          'GL Statement Periodic Date',
          'Creditors',
          'Debtors',
          'Stock Availability',
          'Product Movement',
          'Purchase Invoices',
          'Sale Invoices',
          'Estimate',
          'Goods Shift',
          'Adjustment',
          'All Invoices',
          'Cash Balance All Branch',
          'Cash Balance Single Branch',
          'Exchange Rates',
          'Trial Balance',
          'Transaction Details',
          'Transactions Report',
          'All Balances',
          'Users',
          'User Role and Permission',
          'User Log',
          'Shippings',
          'Vehicles',
          'Drivers',
          'Stakeholders',
          'Employees',
          'Stakeholder Account',
          'GL Accounts',
          'Currencies',
          'Attendance',
          'Reminders',
          'Payroll',
          'Balance Sheet',
        ],
      ),
      PermissionCategory(
        name: locale.actions,
        icon: Icons.touch_app,
        permissionNames: const [
          'Create',
          'Read',
          'Update',
          'Delete',
        ],
      ),
    ];
  }

  bool _permissionExists(String permissionName) =>
      _permLookup.containsKey(permissionName);

  Widget _buildContent(
      BuildContext context, List<UserRolePermissionSettingModel> roles) {
    if (roles.isEmpty) return _buildEmptyState(context);

    final categories = _getPermissionCategories(context);

    switch (widget.layoutType) {
      case LayoutType.mobile:
        return _buildMobileLayout(context, roles, categories);
      case LayoutType.tablet:
      case LayoutType.desktop:
        return _buildDesktopLayout(context, roles, categories);
    }
  }

  // ── Mobile ─────────────────────────────────────────────

  Widget _buildMobileLayout(
      BuildContext context,
      List<UserRolePermissionSettingModel> roles,
      List<PermissionCategory> categories,
      ) {
    return Column(
      children: [
        _buildRoleCards(roles),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            scrollCacheExtent: ScrollCacheExtent.pixels(600), padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            // Recyclable list — each ExpansionTile keeps its own state.
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemBuilder: (context, index) {
              final category = categories[index];
              final available = category.permissionNames
                  .where(_permissionExists)
                  .toList(growable: false);
              if (available.isEmpty) return const SizedBox.shrink();
              return _buildMobileCategoryCard(
                context,
                category,
                available,
                roles,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCategoryCard(
      BuildContext context,
      PermissionCategory category,
      List<String> permissions,
      List<UserRolePermissionSettingModel> roles,
      ) {
    final color = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!;

    // Precompute the label list once per card build — not per row.
    final labels = [for (final p in permissions) _localize(p)];

    return ZCover(
      radius: 5,
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: color.primary.withValues(alpha: .1),
            child: Icon(category.icon, color: color.primary, size: 16),
          ),
          title: Text(
            category.name,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${permissions.length} ${locale.permissions}'),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (int i = 0; i < permissions.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, top: 8, bottom: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: color.primary,
                          ),
                        ),
                      ),
                    ),
                    for (final role in roles)
                      _buildMobilePermissionTile(
                        role: role,
                        permissionName: permissions[i],
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePermissionTile({
    required UserRolePermissionSettingModel role,
    required String permissionName,
  }) {
    final hasPermission = _getEffectivePermission(role, permissionName);
    final hasLocalChange = _localChanges[role.rolId]?.containsKey(permissionName) == true;

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      contentPadding: const EdgeInsets.only(left: 32, right: 8),
      onTap: () =>
          _onPermissionChanged(role.rolId!, permissionName, !hasPermission),
      leading: _buildBeautifulStatusIndicator(hasPermission, small: true),
      title: Text(
        role.rolName ?? 'Unknown',
        style: TextStyle(
          fontSize: 13,
          fontWeight: hasLocalChange ? FontWeight.bold : FontWeight.normal,
          color: hasLocalChange ? Colors.orange.shade800 : null,
        ),
      ),
      trailing: hasLocalChange
          ? Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.edit, color: Colors.white, size: 10),
      )
          : null,
    );
  }

  // ── Desktop / Tablet ───────────────────────────────────

  Widget _buildDesktopLayout(
      BuildContext context,
      List<UserRolePermissionSettingModel> roles,
      List<PermissionCategory> categories,
      ) {
    return Column(
      children: [
        _buildRoleCards(roles),
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildDesktopTable(context, roles, categories),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(
      BuildContext context,
      List<UserRolePermissionSettingModel> roles,
      List<PermissionCategory> categories,
      ) {
    final color = Theme.of(context).colorScheme;

    // Header + body in a Column.
    return Column(
      children: [
        Material(
          color: color.primary,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(3)),
          child: Row(
            children: [
              Container(
                width: 280,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                        color: color.surface.withValues(alpha: .3)),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.permissions.toUpperCase(),
                  style: TextStyle(
                    color: color.surface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              for (final role in roles)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                            color: color.surface.withValues(alpha: .3)),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            role.rolName?.toUpperCase() ?? 'UNKNOWN',
                            style: TextStyle(
                              color: color.surface,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                          if (_localChanges.containsKey(role.rolId))
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.edit,
                                  color: Colors.orange, size: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            // Repaint boundaries between categories.
            scrollCacheExtent: ScrollCacheExtent.pixels(800), addRepaintBoundaries: true,
            itemCount: categories.length,
            itemBuilder: (context, categoryIndex) {
              final category = categories[categoryIndex];
              final available = category.permissionNames
                  .where(_permissionExists)
                  .toList(growable: false);
              if (available.isEmpty) return const SizedBox.shrink();
              return _buildDesktopCategory(
                context,
                category,
                available,
                roles,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCategory(
      BuildContext context,
      PermissionCategory category,
      List<String> permissions,
      List<UserRolePermissionSettingModel> roles,
      ) {
    final color = Theme.of(context).colorScheme;
    final labels = [for (final p in permissions) _localize(p)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          color: color.primary.withValues(alpha: .1),
          child: Row(
            children: [
              Icon(category.icon, size: 18, color: color.primary),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${permissions.length}',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < permissions.length; i++)
          _buildDesktopRow(
            color: color,
            label: labels[i],
            permissionName: permissions[i],
            roles: roles,
            stripe: i.isEven,
          ),
      ],
    );
  }

  Widget _buildDesktopRow({
    required ColorScheme color,
    required String label,
    required String permissionName,
    required List<UserRolePermissionSettingModel> roles,
    required bool stripe,
  }) {
    final bg = stripe
        ? color.surface
        : color.surface.withValues(alpha: .6);

    return Material(
      color: bg,
      child: Row(
        children: [
          Container(
            width: 280,
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          for (final role in roles)
            Expanded(
              child: _buildDesktopCell(
                role: role,
                permissionName: permissionName,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopCell({
    required UserRolePermissionSettingModel role,
    required String permissionName,
    required ColorScheme color,
  }) {
    final hasPermission = _getEffectivePermission(role, permissionName);
    final hasLocalChange =
        _localChanges[role.rolId]?.containsKey(permissionName) == true;

    return GestureDetector(
      onTap: () =>
          _onPermissionChanged(role.rolId!, permissionName, !hasPermission),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        color: hasLocalChange ? Colors.orange.withValues(alpha: .05) : null,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildBeautifulStatusIndicator(hasPermission, small: true),
              if (hasLocalChange)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, color: color.surface, size: 8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared bits ────────────────────────────────────────

  Widget _buildRoleCards(List<UserRolePermissionSettingModel> roles) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: roles.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildRoleCard(roles[index], index),
        ),
      ),
    );
  }

  Widget _buildRoleCard(UserRolePermissionSettingModel role, int index) {
    final effectiveEnabled = _getEffectiveEnabledCount(role);
    final total = role.permissions?.length ?? 0;
    final hasChanges = _localChanges.containsKey(role.rolId);
    final color = Theme.of(context).colorScheme;
    final base = _getRoleColor(index);

    return GestureDetector(
      onTap: () => _showRoleActions(context, role),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [base, base.withValues(alpha: .7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: base.withValues(alpha: .3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        role.rolName ?? 'Unknown',
                        style: TextStyle(
                          color: color.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasChanges)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit,
                            color: color.surface, size: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$effectiveEnabled / $total ${AppLocalizations.of(context)!.permissions}',
                  style: TextStyle(
                    color: color.surface.withValues(alpha: .8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeautifulStatusIndicator(bool hasPermission,
      {bool small = false}) {
    final size = small ? 25.0 : 33.0;
    final iconSize = small ? 17.0 : 18.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasPermission ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: hasPermission ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Icon(
        hasPermission ? Icons.check_circle : Icons.remove_circle,
        color: hasPermission ? Colors.green.shade700 : Colors.red.shade400,
        size: iconSize,
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, PermissionSettingsErrorState state) {
    return Center(
      child: NoDataWidget(
        title: 'Error',
        message: 'Failed to load permissions, try again later',
        onRefresh: () => context
            .read<PermissionSettingsBloc>()
            .add(LoadPermissionsSettingsEvent()),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: NoDataWidget(
        title: 'No Role found',
        message: 'Failed to load permissions, try again later',
        onRefresh: () => context
            .read<PermissionSettingsBloc>()
            .add(LoadPermissionsSettingsEvent()),
      ),
    );
  }

  Widget _buildSaveBar(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Positioned(
      bottom: 20,
      left: isMobile ? 16 : 0,
      right: isMobile ? 16 : 0,
      child: Center(
        child: Material(
          color: color.surface,
          elevation: 8,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 16 : 12,
            ),
            child: isMobile
                ? _buildMobileSaveBar(color)
                : _buildDesktopSaveBar(color),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSaveBar(ColorScheme color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info, color: Colors.blue.shade700),
        const SizedBox(width: 5),
        Text(
          'You have unsaved changes',
          style: TextStyle(
              color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        ZOutlineButton(
          onPressed: _cancelChanges,
          isActive: true,
          backgroundHover: color.error,
          label: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ZOutlineButton(
          onPressed: _saveAllChanges,
          isActive: true,
          label: const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildMobileSaveBar(ColorScheme color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.info, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You have unsaved changes',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ZOutlineButton(
                onPressed: _cancelChanges,
                isActive: true,
                backgroundHover: color.error,
                label: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ZOutlineButton(
                onPressed: _saveAllChanges,
                isActive: true,
                label: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── State ──────────────────────────────────────────────

  void _onPermissionChanged(
      int roleId, String permissionName, bool newValue) {
    setState(() {
      _localChanges.putIfAbsent(roleId, () => {});
      _localChanges[roleId]![permissionName] = newValue;
      _hasChanges = true;
    });
  }

  void _cancelChanges() {
    setState(() {
      _localChanges.clear();
      _hasChanges = false;
    });
  }

  void _saveAllChanges() {
    if (!_hasChanges || _originalRoles == null) return;

    final updates = <PermissionActions>[];
    _localChanges.forEach((roleId, changes) {
      changes.forEach((permissionName, newStatus) {
        final permission = _originalRoles!
            .firstWhere((r) => r.rolId == roleId,
            orElse: () => UserRolePermissionSettingModel(rolId: roleId))
            .permissions
            ?.firstWhere((p) => p.rsgName == permissionName,
            orElse: () => UsrPermission(rsgName: permissionName));
        if (permission?.rpId != null) {
          updates.add(PermissionActions(
            rpId: permission!.rpId!,
            rpStatus: newStatus ? 1 : 0,
          ));
        }
      });
    });

    if (updates.isEmpty) return;

    context.read<PermissionSettingsBloc>().add(
      UpdatePermissionsSettingsEvent(
        PermissionActionModel(usrName: usrName, permissions: updates),
      ),
    );

    setState(() {
      _localChanges.clear();
      _hasChanges = false;
    });
  }

  bool _getEffectivePermission(
      UserRolePermissionSettingModel role, String permissionName) {
    final change =
    _localChanges[role.rolId]?[permissionName];
    if (change != null) return change;
    // O(1) instead of `firstWhere` per cell.
    return _permLookup[permissionName]?[role.rolId] ?? false;
  }

  // ── Bottom sheet — Material, not Container(decoration) ──

  void _showRoleActions(
      BuildContext context, UserRolePermissionSettingModel role) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final radius =
    const BorderRadius.vertical(top: Radius.circular(10));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // The sheet itself is now the Material — no DecoratedBox between
      // Material and the four ListTiles. Assertion gone.
      builder: (sheetContext) => Material(
        color: color.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.privacy_tip_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        role.rolName ?? tr.roleActions,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                _sheetTile(
                  sheetContext,
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                  label: tr.grantAll,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _enableAllForRole(role.rolId!);
                  },
                ),
                const Divider(),
                _sheetTile(
                  sheetContext,
                  icon: Icons.cancel,
                  iconColor: Colors.red,
                  label: tr.revokeAll,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _disableAllForRole(role.rolId!);
                  },
                ),
                const Divider(),
                _sheetTile(
                  sheetContext,
                  icon: Icons.restore,
                  iconColor: Colors.orange,
                  label: tr.restoreDefault,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _resetRoleChanges(role.rolId!);
                  },
                ),
                const Divider(),
                _sheetTile(
                  sheetContext,
                  icon: Icons.edit_calendar_rounded,
                  iconColor: Colors.green,
                  label: tr.edit,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    final model = UserRoleModel(
                      rolId: role.rolId,
                      rolName: role.rolName,
                      rolStatus: role.rolStatus,
                    );
                    showDialog(
                      context: context,
                      builder: (_) =>
                          AddEditUserRoleSettingsView(model: model),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetTile(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String label,
        required VoidCallback onTap,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
      leading: Icon(icon, color: iconColor),
      title: Text(label),
      onTap: onTap,
    );
  }

  void _enableAllForRole(int roleId) {
    final role =
    _originalRoles?.firstWhere((r) => r.rolId == roleId, orElse: () =>
        UserRolePermissionSettingModel(rolId: roleId));
    if (role?.permissions == null) return;
    for (final p in role!.permissions!) {
      if (p.rsgName != null) {
        _onPermissionChanged(roleId, p.rsgName!, true);
      }
    }
  }

  void _disableAllForRole(int roleId) {
    final role =
    _originalRoles?.firstWhere((r) => r.rolId == roleId, orElse: () =>
        UserRolePermissionSettingModel(rolId: roleId));
    if (role?.permissions == null) return;
    for (final p in role!.permissions!) {
      if (p.rsgName != null) {
        _onPermissionChanged(roleId, p.rsgName!, false);
      }
    }
  }

  void _resetRoleChanges(int roleId) {
    setState(() {
      _localChanges.remove(roleId);
      _hasChanges = _localChanges.isNotEmpty;
    });
  }

  int _getEffectiveEnabledCount(UserRolePermissionSettingModel role) {
    if (!_localChanges.containsKey(role.rolId)) {
      return role.permissions?.where((p) => p.rpStatus == 1).length ?? 0;
    }
    final changes = _localChanges[role.rolId]!;
    return role.permissions?.fold<int>(0, (sum, p) {
      final on =
          changes[p.rsgName] ?? p.rpStatus == 1;
      return sum + (on ? 1 : 0);
    }) ??
        0;
  }

  Color _getRoleColor(int index) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.lime,
      Colors.deepOrange,
    ];
    return colors[index % colors.length];
  }
}