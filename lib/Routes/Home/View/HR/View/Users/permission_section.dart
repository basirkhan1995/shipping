import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../../../l10n/app_localizations.dart';

/// Inline permissions editor for the Edit User dialog.
///
/// Layout:
///  - Cards are distributed into N columns by their estimated height
///    (masonry) so short cards don't leave huge gaps under tall ones.
///  - The whole block lives inside a bounded, scrollable surface so
///    the dialog's Save button stays reachable even with ~120 rows.
class PermissionsSection extends StatelessWidget {
  final Map<int, bool> permissions;
  final Map<int, bool> roleCeiling;
  final Map<int, bool> pendingChanges;
  final void Function(int rsgID, bool enabled) onChanged;

  const PermissionsSection({
    super.key,
    required this.permissions,
    required this.roleCeiling,
    required this.pendingChanges,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final categories = <_Category>[
      _Category(tr.dashboard, Icons.dashboard, const [1, 2, 3, 4, 5, 6, 7, 8, 9]),
      _Category(tr.finance, Icons.attach_money, const [10, 11, 12, 13, 14, 15, 16, 17]),
      _Category(tr.journal, Icons.book,
          const [18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30]),
      _Category(tr.stakeholders, Icons.people, const [31, 32, 33, 34]),
      _Category(tr.hrTitle, Icons.person, const [35, 36, 37, 38, 39, 40, 41]),
      // _Category(tr.transport, Icons.local_shipping, const [42, 43, 44, 45]),
      // _Category(tr.inventory, Icons.inventory, const [51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61]),
      _Category(tr.settings, Icons.settings,
          const [62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77]),
      _Category(tr.report, Icons.bar_chart, const [
        78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94,
        95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108,
        109, 110, 111, 112, 113,
      ]),
      _Category("Actions", Icons.touch_app, const [116, 117, 118, 119]),
    ];

    // Pre-compute visible ids per category (only ids present in the
    // user's permission set are rendered).
    final visibleCategories = <_Category>[
      for (final cat in categories)
        if (cat.ids
            .any((id) => roleCeiling.containsKey(id) || permissions.containsKey(id)))
          cat,
    ];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(tr.permissions,
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              if (pendingChanges.isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pendingChanges.length} changed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Masonry grid inside a bounded scroll ──────────────
          LayoutBuilder(builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1000
                ? 3
                : constraints.maxWidth > 620
                ? 2
                : 1;

            // Max visible height for the permissions block.
            final maxHeight = math.min(420.0, constraints.maxWidth * .55);

            final columnWidgets = _distributeToColumns(
              visibleCategories,
              crossAxisCount,
              permissions,
              roleCeiling,
              pendingChanges,
              onChanged,
            );

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < columnWidgets.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: columnWidgets[i],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Greedy masonry: each category goes into the currently shortest
  /// column. Height is estimated as `rowHeight * rowCount + header`.
  List<List<Widget>> _distributeToColumns(
      List<_Category> cats,
      int columns,
      Map<int, bool> permissions,
      Map<int, bool> roleCeiling,
      Map<int, bool> pendingChanges,
      void Function(int, bool) onChanged,
      ) {
    const rowHeight = 30.0; // matches _PermissionRow height
    const headerHeight = 36.0;
    const gap = 12.0;

    final columnHeights = List<double>.filled(columns, 0);
    final columnWidgets = List.generate(columns, (_) => <Widget>[]);

    for (final cat in cats) {
      final visibleIds = cat.ids
          .where((id) =>
      roleCeiling.containsKey(id) || permissions.containsKey(id))
          .toList();
      if (visibleIds.isEmpty) continue;

      final estimated =
          headerHeight + visibleIds.length * rowHeight + gap;

      // Shortest column
      int target = 0;
      for (int i = 1; i < columns; i++) {
        if (columnHeights[i] < columnHeights[target]) target = i;
      }

      columnWidgets[target].add(
        Padding(
          padding: const EdgeInsets.only(bottom: gap),
          child: _CategoryCard(
            category: cat,
            visibleIds: visibleIds,
            permissions: permissions,
            roleCeiling: roleCeiling,
            pendingChanges: pendingChanges,
            onChanged: onChanged,
          ),
        ),
      );
      columnHeights[target] += estimated;
    }

    return columnWidgets;
  }
}

class _Category {
  final String name;
  final IconData icon;
  final List<int> ids;
  const _Category(this.name, this.icon, this.ids);
}

class _CategoryCard extends StatelessWidget {
  final _Category category;
  final List<int> visibleIds;
  final Map<int, bool> permissions;
  final Map<int, bool> roleCeiling;
  final Map<int, bool> pendingChanges;
  final void Function(int, bool) onChanged;

  const _CategoryCard({
    required this.category,
    required this.visibleIds,
    required this.permissions,
    required this.roleCeiling,
    required this.pendingChanges,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onCount =
        visibleIds.where((id) => permissions[id] == true).length;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: .4)),
              ),
            ),
            child: Row(
              children: [
                Icon(category.icon, size: 14, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$onCount/${visibleIds.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          for (final id in visibleIds)
            _PermissionRow(
              rsgID: id,
              currentValue: permissions[id] ?? false,
              roleAllows: roleCeiling[id] ?? false,
              isPending: pendingChanges.containsKey(id),
              onChanged: (v) => onChanged(id, v),
            ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final int rsgID;
  final bool currentValue;
  final bool roleAllows;
  final bool isPending;
  final ValueChanged<bool> onChanged;

  const _PermissionRow({
    required this.rsgID,
    required this.currentValue,
    required this.roleAllows,
    required this.isPending,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Fixed height keeps masonry estimates accurate.
    return SizedBox(
      height: 30,
      child: InkWell(
        onTap: roleAllows ? () => onChanged(!currentValue) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color:
            isPending ? scheme.primary.withValues(alpha: .06) : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Checkbox(
                  visualDensity: const VisualDensity(
                      horizontal: -4, vertical: -4),
                  materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
                  value: currentValue,
                  onChanged: roleAllows
                      ? (v) {
                    if (v != null) onChanged(v);
                  }
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _nameFor(rsgID),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                    isPending ? FontWeight.w600 : FontWeight.w500,
                    color: roleAllows
                        ? scheme.onSurface
                        : scheme.onSurface.withValues(alpha: .4),
                  ),
                ),
              ),
              if (isPending)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.pending,
                      size: 12, color: scheme.primary),
                ),
              const SizedBox(width: 4),
              _StatusDot(active: currentValue),
            ],
          ),
        ),
      ),
    );
  }

  static String _nameFor(int id) {
    const names = <int, String>{
      1: 'Dashboard', 2: 'Counts', 3: 'Exchange Rate Graph',
      4: 'Daily Transactions Graph', 5: 'Daily Transaction Totals',
      6: 'Digital Clock', 7: 'Exchange Rates', 8: 'Profit Loss Graph',
      9: 'Reminder Notifications',
      10: 'Finance', 11: 'Currency Tab', 12: 'Currency',
      13: 'Exchange rates', 14: 'GL Accounts', 15: 'Payroll',
      16: 'EOY Operation', 17: 'Reminders',
      18: 'Journal', 19: 'All Transactions', 20: 'Authorized Transaction',
      21: 'Pending Transaction', 22: 'Cash Deposit', 23: 'Cash Withdraw',
      24: 'Income Entry', 25: 'Expense Entry', 26: 'GL Debit',
      27: 'GL Credit', 28: 'FT Single Account', 29: 'FT Multi Account',
      30: 'FX Transactions',
      31: 'Stakeholders', 32: 'New Individual', 33: 'Accounts',
      34: 'Users', 35: 'HR', 36: 'Employees', 37: 'Attendance',
      38: 'All Users', 39: 'Overview', 40: 'Permissions',
      41: 'User Log', 42: 'Transport', 43: 'Shipping', 44: 'Drivers',
      45: 'Vehicles',
      51: 'Inventory', 52: 'Orders Tab', 53: 'Estimate Tab',
      54: 'Goods Shift Tab', 55: 'Adjustment Tab', 56: 'Purchase',
      57: 'Sale', 58: 'Estimate', 59: 'Goods Shift', 60: 'Adjustment',
      61: 'Find Invoice',
      62: 'Settings', 63: 'General Tab', 64: 'System Settings',
      65: 'Password Change', 66: 'User Profile',
      67: 'Roles and Permissions', 68: 'Company Tab', 69: 'Profile',
      70: 'Branches', 71: 'Storage', 72: 'Transaction Type', 73: 'Stock',
      74: 'Products', 75: 'Category', 76: 'Backup', 77: 'About',
      78: 'Reports', 79: 'Account Statement Single Date',
      80: 'GL Statement Single Date', 81: 'GL Statement Periodic Date',
      82: 'Creditors', 83: 'Debtors', 84: 'Stock Availability',
      85: 'Product Movement', 86: 'Purchase Invoices',
      87: 'Sale Invoices', 88: 'Estimate', 89: 'Goods Shift',
      90: 'Adjustment', 91: 'All Invoices', 92: 'Cash Balance All Branch',
      93: 'Cash Balance Single Branch', 94: 'Exchange Rates',
      95: 'Trial Balance', 96: 'Transaction Details',
      97: 'Transactions Report', 98: 'All Balances', 99: 'Users',
      100: 'User Role and Permission', 101: 'User Log',
      102: 'Shippings', 103: 'Vehicles', 104: 'Drivers',
      105: 'Stakeholders', 106: 'Employees', 107: 'Stakeholders Account',
      108: 'GL Accounts', 109: 'Currencies', 110: 'Attendance',
      111: 'Reminders', 112: 'Payroll', 113: 'Balance Sheet',
      116: 'Create', 117: 'Read', 118: 'Update', 119: 'Delete',
    };
    return names[id] ?? 'Permission #$id';
  }
}

class _StatusDot extends StatelessWidget {
  final bool active;
  const _StatusDot({required this.active});

  @override
  Widget build(BuildContext context) {
    final c = active ? Colors.green : Colors.red;
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}