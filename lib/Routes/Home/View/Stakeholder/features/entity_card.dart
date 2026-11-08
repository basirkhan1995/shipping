import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/extensions.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../Features/Other/image_helper.dart';
import '../../../../Auth/bloc/auth_bloc.dart';
import '../View/Security/verify_lock.dart';
import '../model/stk_model.dart';

class EntityWidget extends StatelessWidget {
  final StakeholdersModel stakeholder;

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

    final rowBg = isEven ? scheme.surface : scheme.surfaceContainerHighest;

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
              // ── Avatar (with lock badge) ──
              _avatarWithBadge(scheme),

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
                              size: 11, color: scheme.onSurfaceVariant),
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
                              size: 11, color: scheme.onSurfaceVariant),
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

              // ── Balances (masked if locked) ──
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
                  color: hasActive ? const Color(0xFF22C55E) : scheme.error,
                ),
              ),
              const SizedBox(width: 6),

              // ── Menu ──
              _menu(context, scheme, AppLocalizations.of(context)!),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar with lock badge stacked on the corner ─────────────────
  Widget _avatarWithBadge(ColorScheme scheme) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Avatar
          Hero(
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
          ),

          // Lock badge on the bottom-right corner
          if (stakeholder.isLocked)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: scheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 2),
                ),
                child: Icon(
                  Icons.lock,
                  size: 9,
                  color: scheme.onError,
                ),
              ),
            ),
        ],
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

  // ── Balances stacked; masked when locked ─────────────────────────
  Widget _balanceStack(
      Map<String, double> balances,
      ColorScheme scheme,
      TextTheme textTheme,
      ) {
    final masked = stakeholder.isLocked;

    if (balances.isEmpty) {
      return Text(
        masked ? 'Hidden' : 'No balance',
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
                if (masked) ...[
                  Icon(Icons.lock, size: 10, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text(
                    '••••••',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                ] else
                  Text(
                    e.value.toAmount(),
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

  // ── Admin-only lock/unlock permission ────────────────────────────
  bool _canManageLock(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthenticatedState) return false;

    final role = auth.loginData.usrRole?.toLowerCase();
    return role == 'super' || role == 'admin' || role == 'ceo';
  }

  Future<void> _handleLockTap(
      BuildContext context, {
        required bool lock,
      }) async {
    final perID = stakeholder.perId;
    if (perID == null) return;

    await LockVerifyDialog.show(
      context,
      perID: perID,
      stakeholderName: stakeholder.fullName,
      mode: lock ? LockVerifyMode.lock : LockVerifyMode.unlock,
    );
  }

  // ── ⋯ menu ────────────────────────────────────────────────────────
  Widget _menu(
      BuildContext context,
      ColorScheme scheme,
      AppLocalizations tr,
      ) {
    final canLock = _canManageLock(context);

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
          case 'lock':
            _handleLockTap(context, lock: true);
            break;
          case 'unlock':
            _handleLockTap(context, lock: false);
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'view',
          height: 40,
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 16),
              const SizedBox(width: 10),
              Text(tr.view, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          height: 40,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 16),
              const SizedBox(width: 10),
              Text(tr.edit, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        if (canLock) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: stakeholder.isLocked ? 'unlock' : 'lock',
            height: 40,
            child: Row(
              children: [
                Icon(
                  stakeholder.isLocked
                      ? Icons.lock_open_outlined
                      : Icons.lock_outline,
                  size: 16,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  stakeholder.isLocked ? tr.unlock : tr.lock,
                  style: TextStyle(fontSize: 13, color: scheme.primary),
                ),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          height: 40,
          child: const _DeleteMenuItem(),
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