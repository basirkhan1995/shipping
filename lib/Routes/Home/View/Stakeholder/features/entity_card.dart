import 'package:flutter/material.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../Features/Other/image_helper.dart';
import '../model/stk_model.dart';

class EntityWidget extends StatelessWidget {
  final IndividualsModel stakeholder;

  /// Alternate row background based on index parity.
  final bool isEven;

  final VoidCallback? onTap;
  final VoidCallback? onTapView;
  final VoidCallback? onTapEdit;
  final VoidCallback? onTapDelete;

  const EntityWidget({
    super.key,
    required this.stakeholder,
    this.isEven = true,
    this.onTap,
    this.onTapView,
    this.onTapEdit,
    this.onTapDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final rowBg = isEven
        ? scheme.surface
        : scheme.surfaceContainerHighest;

    final balances = stakeholder.balancesByCurrency;
    final hasActive = stakeholder.hasActiveAccount;
    final fullName =
    stakeholder.fullName.isEmpty ? '—' : stakeholder.fullName;

    return Material(
      color: rowBg,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                        if (stakeholder.perPhone != null &&
                            stakeholder.perPhone!.isNotEmpty) ...[
                          Icon(Icons.phone_outlined,
                              size: 11,
                              color: scheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            stakeholder.perPhone!,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (stakeholder.perEmail != null &&
                            stakeholder.perEmail!.isNotEmpty) ...[
                          Icon(Icons.email_outlined,
                              size: 11,
                              color: scheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              stakeholder.perEmail!,
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

              // ── City ──
              if (stakeholder.addCity != null &&
                  stakeholder.addCity!.isNotEmpty)
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          stakeholder.addCity!,
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

              // ── Balances ──
              Expanded(
                flex: 4,
                child: _balanceStack(balances, scheme, textTheme),
              ),
              const SizedBox(width: 8),
              // ── Status dot ──
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasActive
                      ? const Color(0xFF22C55E)
                      : scheme.error,
                ),
              ),

              const SizedBox(width: 6),

              // ── Menu ──
              _menu(scheme,AppLocalizations.of(context)!),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar with Hero ──────────────────────────────────────────────
  Widget _avatar(ColorScheme scheme) {
    return Hero(
      tag: 'stakeholder_img_${stakeholder.perId}',
      flightShuttleBuilder: _buildHeroShuttle,
      child: ImageHelper.stakeholderProfile(
        imageName: stakeholder.imageProfile,
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
    // Preserve the circular shape during flight.
    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: (toHeroContext.widget as Hero).child,
      ),
    );
  }

  // ── Balances stacked, one line per currency ──────────────────────
  Widget _balanceStack(
      Map<String, double> balances,
      ColorScheme scheme,
      TextTheme textTheme,
      ) {
    if (balances.isEmpty) {
      return Text(
        'No balance',
        style: textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final entries = balances.entries.toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatAmount(e.value),
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  e.key,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
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

  // ── ⋯ menu ────────────────────────────────────────────────────────
  Widget _menu(ColorScheme scheme,AppLocalizations tr) {
    return PopupMenuButton<String>(
      tooltip: 'Options',
      padding: EdgeInsets.zero,
      splashRadius: 14,
      icon: Icon(Icons.more_horiz, size: 18, color: scheme.onSurfaceVariant),
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
          height: 40,
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16),
              SizedBox(width: 10),
              Text(tr.view, style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: 10),
              Text(tr.edit, style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 40,
          child: _DeleteMenuItem(),
        ),
      ],
    );
  }
}

class _DeleteMenuItem extends StatelessWidget {
  const _DeleteMenuItem();

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Row(
      children: [
        Icon(Icons.delete_outline, size: 16, color: error),
        const SizedBox(width: 10),
        Text(
          AppLocalizations.of(context)!.delete,
          style: TextStyle(fontSize: 13, color: error),
        ),
      ],
    );
  }
}