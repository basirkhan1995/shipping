import 'package:flutter/material.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../../../Features/Other/image_helper.dart';
import '../model/emp_model.dart';

class EmployeeWidget extends StatelessWidget {
  final EmployeeModel employee;

  /// Alternate row background based on index parity.
  final bool isEven;

  /// Postponed: view / edit / delete. Pass null to disable.
  final VoidCallback? onTap;
  final VoidCallback? onTapView;
  final VoidCallback? onTapEdit;
  final VoidCallback? onTapDelete;

  /// When false (default while postponed) the ⋯ menu items are greyed
  /// out and do nothing.
  final bool actionsEnabled;

  const EmployeeWidget({
    super.key,
    required this.employee,
    this.isEven = true,
    this.onTap,
    this.onTapView,
    this.onTapEdit,
    this.onTapDelete,
    this.actionsEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final rowBg = isEven ? scheme.surface : scheme.surfaceContainerHighest;

    final fullName = _fullName();
    final isActive = (employee.empStatus ?? 0) == 1;

    return Material(
      color: rowBg,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: actionsEnabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Avatar ──
              _avatar(scheme),

              const SizedBox(width: 12),

              // ── Name + contact ──
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fullName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (_phone().isNotEmpty) ...[
                          Icon(Icons.phone_outlined,
                              size: 11, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            _phone(),
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (_email().isNotEmpty) ...[
                          Icon(Icons.email_outlined,
                              size: 11, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              _email(),
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Position / Department (mirrors stakeholder "city" slot) ──
              if (_positionOrDepartment().isNotEmpty)
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(Icons.business_outlined,
                          size: 12, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _positionOrDepartment(),
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Salary (mirrors stakeholder "balances" slot) ──
              Expanded(
                flex: 3,
                child: _salaryStack(scheme, textTheme),
              ),
              const SizedBox(width: 8),

              // ── Status dot ──
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? const Color(0xFF22C55E) : scheme.error,
                ),
              ),

              const SizedBox(width: 6),

              // ── Menu ──
              _menu(scheme, AppLocalizations.of(context)!),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar with Hero (same tag pattern as EntityWidget) ────────────
  Widget _avatar(ColorScheme scheme) {
    return Hero(
      tag: 'employee_img_${employee.empId ?? employee.perId}',
      flightShuttleBuilder: _buildHeroShuttle,
      child: ImageHelper.stakeholderProfile(
        imageName: employee.empImage ?? '',
        size: 40,
        shapeStyle: ShapeStyle.circle,
        placeholderColor: scheme.primaryContainer,
        placeholderIcon: Icons.person,
        errorIcon: Icons.person,
      ),
    );
  }

  static Widget _buildHeroShuttle(
      BuildContext flightContext,
      Animation<double> animation,
      HeroFlightDirection direction,
      BuildContext fromHeroContext,
      BuildContext toHeroContext,
      ) {
    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: (toHeroContext.widget as Hero).child,
      ),
    );
  }

  // ── Salary stacked (one line, like _balanceStack) ─────────────────
  Widget _salaryStack(ColorScheme scheme, TextTheme textTheme) {
    final raw = employee.empSalary;
    if (raw == null || raw.trim().isEmpty) {
      return Text(
        'No salary',
        style: textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final parsed = double.tryParse(raw);
    final display = parsed == null ? raw : _formatAmount(parsed);
    final unit = (employee.empSalCalcBase ?? '').trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                display,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatAmount(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]}';
  }

  // ── ⋯ menu (disabled while postponed) ─────────────────────────────
  Widget _menu(ColorScheme scheme, AppLocalizations tr) {
    return PopupMenuButton<String>(
      tooltip: "options",
      padding: EdgeInsets.zero,
      splashRadius: 14,
      enabled: actionsEnabled,
      icon: Icon(
        Icons.more_horiz,
        size: 18,
        color: actionsEnabled
            ? scheme.onSurfaceVariant
            : scheme.onSurfaceVariant.withValues(alpha: .4),
      ),
      position: PopupMenuPosition.under,
      onSelected: (v) {
        switch (v) {
          case 'view':
            onTapView?.call();
            break;
          case 'edit':
            onTapEdit?.call();
            break;
          case 'delete':
            onTapDelete?.call();
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'view',
          enabled: actionsEnabled,
          height: 40,
          child: Row(
            children: [
              Icon(Icons.visibility_outlined,
                  size: 16,
                  color: _itemColor(scheme.onSurfaceVariant, scheme)),
              const SizedBox(width: 10),
              Text(tr.view,
                  style: TextStyle(
                      fontSize: 13,
                      color: _itemColor(scheme.onSurface, scheme))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          enabled: actionsEnabled,
          height: 40,
          child: Row(
            children: [
              Icon(Icons.edit_outlined,
                  size: 16,
                  color: _itemColor(scheme.onSurfaceVariant, scheme)),
              const SizedBox(width: 10),
              Text(tr.edit,
                  style: TextStyle(
                      fontSize: 13,
                      color: _itemColor(scheme.onSurface, scheme))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          enabled: actionsEnabled,
          height: 40,
          child: Row(
            children: [
              Icon(Icons.delete_outline,
                  size: 16, color: _itemColor(scheme.error, scheme)),
              const SizedBox(width: 10),
              Text(tr.delete,
                  style: TextStyle(
                      fontSize: 13,
                      color: _itemColor(scheme.error, scheme))),
            ],
          ),
        ),
      ],
    );
  }

  Color _itemColor(Color base, ColorScheme scheme) =>
      actionsEnabled ? base : base.withValues(alpha: .4);

  // ── Helpers ───────────────────────────────────────────────────────
  String _fullName() {
    final parts = [employee.perName, employee.perLastName]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? '—' : parts.join(' ');
  }

  String _email() => employee.empEmail ?? employee.perEmail ?? '';
  String _phone() => employee.perPhone ?? '';

  String _positionOrDepartment() {
    final parts = [employee.empPosition, employee.empDepartment]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.join(' · ');
  }
}