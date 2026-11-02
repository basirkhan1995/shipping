import 'package:flutter/material.dart';
import 'package:shipping/l10n/app_localizations.dart';

import '../../../../../../../Features/Other/image_helper.dart';
import '../model/emp_model.dart';

class EmployeeWidget extends StatelessWidget {
  final EmployeeModel employee;
  final bool isEven;

  final VoidCallback? onTap;
  final VoidCallback? onTapView;
  final VoidCallback? onTapEdit;
  final VoidCallback? onTapDelete;

  const EmployeeWidget({
    super.key,
    required this.employee,
    this.isEven = true,
    this.onTap,
    this.onTapView,
    this.onTapEdit,
    this.onTapDelete,
  });

  bool get _anyMenuEnabled =>
      onTapView != null || onTapEdit != null || onTapDelete != null;

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
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatar(scheme),
              const SizedBox(width: 12),

              // ── Name + contact ────────────────────────────────
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

              // ── Position · Department ─────────────────────────
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

              // ── Salary ────────────────────────────────────────
              Expanded(
                flex: 3,
                child: _salaryStack(scheme, textTheme),
              ),
              const SizedBox(width: 8),

              // ── Status dot ────────────────────────────────────
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                  isActive ? const Color(0xFF22C55E) : scheme.error,
                ),
              ),
              const SizedBox(width: 6),

              _menu(scheme, AppLocalizations.of(context)!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(ColorScheme scheme) {
    return Hero(
      tag: 'employee_img_${employee.empId ?? employee.perId}',
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
              Flexible(
                child: Text(
                  display,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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

  Widget _menu(ColorScheme scheme, AppLocalizations tr) {
    return PopupMenuButton<String>(
      tooltip: "Options",
      padding: EdgeInsets.zero,
      splashRadius: 14,
      enabled: _anyMenuEnabled,
      icon: Icon(
        Icons.more_horiz,
        size: 18,
        color: _anyMenuEnabled
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
          enabled: onTapView != null,
          height: 40,
          child: _rowItem(
            icon: Icons.visibility_outlined,
            label: tr.view,
            color: onTapView != null
                ? scheme.onSurface
                : scheme.onSurface.withValues(alpha: .4),
            iconColor: onTapView != null
                ? scheme.onSurfaceVariant
                : scheme.onSurfaceVariant.withValues(alpha: .4),
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          enabled: onTapEdit != null,
          height: 40,
          child: _rowItem(
            icon: Icons.edit_outlined,
            label: tr.edit,
            color: onTapEdit != null
                ? scheme.onSurface
                : scheme.onSurface.withValues(alpha: .4),
            iconColor: onTapEdit != null
                ? scheme.onSurfaceVariant
                : scheme.onSurfaceVariant.withValues(alpha: .4),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          enabled: onTapDelete != null,
          height: 40,
          child: _rowItem(
            icon: Icons.delete_outline,
            label: tr.delete,
            color: onTapDelete != null
                ? scheme.error
                : scheme.error.withValues(alpha: .4),
            iconColor: onTapDelete != null
                ? scheme.error
                : scheme.error.withValues(alpha: .4),
          ),
        ),
      ],
    );
  }

  Widget _rowItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }

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