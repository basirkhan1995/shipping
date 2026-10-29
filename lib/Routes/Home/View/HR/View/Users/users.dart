import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../Features/Other/global_shortcut.dart';
import '../../../../../../Features/Other/image_helper.dart';
import '../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../Features/Widgets/noData_widget.dart';
import '../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/model/user_model.dart';
import 'add_user.dart';
import 'bloc/users_bloc.dart';
import 'model/user_model.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _UsersMobile(),
      tablet: _UsersTablet(),
      desktop: _UsersDesktop(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared controller
// ═══════════════════════════════════════════════════════════════════
class _UsersController {
  static void refresh(BuildContext context) {
    context.read<UsersBloc>().add(const LoadUsersEvent());
  }

  static Future<void> openAddDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const AddUserView(),
    );
    // Bloc's success handler already reloads — no extra dispatch here.
  }

  static Future<void> openEditDialog(
      BuildContext context,
      UsersModel user,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AddUserView(existing: user),
    );
  }

  /// Block / Unblock via the dedicated toggle event so the list
  /// stays visible (no UsersLoadingState → no row teardown).
  static Future<void> toggleStatus(
      BuildContext context,
      UsersModel user, {
        required String blockLabel,
        required String unblockLabel,
        required String cancelLabel,
      }) async {
    final isActive = user.usrStatus == 1;
    final actionLabel = isActive ? blockLabel : unblockLabel;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(actionLabel),
        content: Text('$actionLabel "${user.usrName ?? ''}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
              isActive ? Theme.of(ctx).colorScheme.error : null,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Attach the actor. The row's user object came from get_users()
    // and doesn't carry loggedInUser, so sending it as-is makes the
    // backend activity-log insert fail (ualUser is NOT NULL FK).
    final auth = context.read<AuthBloc>().state;
    final actor = auth is AuthenticatedState ? auth.loginData.usrName : '';
    if (actor!=null && actor.isEmpty) return;

    context.read<UsersBloc>().add(
      ToggleUserStatusEvent(
        user.copyWithStatus(isActive ? 0 : 1, actor: actor),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared listener — full reload only on Add/Edit success.
// Toggle uses ToggleUserStatusEvent, which never reaches this
// listener, so the list is not blanked.
// ═══════════════════════════════════════════════════════════════════
class _UsersListener extends StatelessWidget {
  final Widget child;
  const _UsersListener({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<UsersBloc, UsersState>(
      listenWhen: (p, c) => c is UserSuccessState,
      listener: (context, _) {
        context.read<UsersBloc>().add(const LoadUsersEvent());
      },
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared helpers
// ═══════════════════════════════════════════════════════════════════
bool _canAdd(BuildContext context) {
  final auth = context.watch<AuthBloc>().state;
  if (auth is! AuthenticatedState) return false;
  return auth.loginData.hasPermission(106) ?? false;
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _UsersMobile extends StatelessWidget {
  const _UsersMobile();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final canAdd = _canAdd(context);

    return _UsersListener(
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.users),
          actions: [
            IconButton(
              tooltip: tr.refresh,
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _UsersController.refresh(context),
            ),
            if (canAdd)
              IconButton(
                tooltip: tr.newKeyword,
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _UsersController.openAddDialog(context),
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: const _UsersSearchBar(),
            ),
            Expanded(
              child: _UsersList(
                canAdd: canAdd,
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TABLET
// ═══════════════════════════════════════════════════════════════════
class _UsersTablet extends StatelessWidget {
  const _UsersTablet();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final canAdd = _canAdd(context);

    return _UsersListener(
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.users),
          actions: [
            IconButton(
              tooltip: tr.refresh,
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _UsersController.refresh(context),
            ),
            if (canAdd)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ZOutlineButton(
                  label: Text(tr.newKeyword),
                  icon: Icons.add,
                  iconSize: 18,
                  height: 36,
                  onPressed: () => _UsersController.openAddDialog(context),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: const _UsersSearchBar(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _UsersList(
                canAdd: canAdd,
                dense: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _UsersDesktop extends StatelessWidget {
  const _UsersDesktop();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final canAdd = _canAdd(context);

    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.f1): () =>
          _UsersController.refresh(context),
      if (canAdd)
        const SingleActivator(LogicalKeyboardKey.f5): () =>
            _UsersController.openAddDialog(context),
    };

    return _UsersListener(
      child: GlobalShortcuts(
        shortcuts: shortcuts,
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      tr.users,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    const SizedBox(
                      width: 420,
                      child: _UsersSearchBar(compact: true),
                    ),
                    const SizedBox(width: 8),
                    ZOutlineButton(
                      label: Text(tr.refresh),
                      icon: Icons.refresh,
                      iconSize: 18,
                      height: 45,
                      toolTip: 'F1',
                      onPressed: () => _UsersController.refresh(context),
                    ),
                    if (canAdd) ...[
                      const SizedBox(width: 8),
                      ZOutlineButton(
                        label: Text(tr.newKeyword),
                        icon: Icons.add,
                        isActive: true,
                        iconSize: 18,
                        height: 45,
                        toolTip: 'F5',
                        onPressed: () =>
                            _UsersController.openAddDialog(context),
                      ),
                    ],
                  ],
                ),
              ),
              const Expanded(
                child: _UsersList(
                  canAdd: false, // resolved inside the list from AuthBloc
                  dense: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Search bar — pushes query to the nearest _UsersQuery scope
// ═══════════════════════════════════════════════════════════════════
class _UsersSearchBar extends StatefulWidget {
  final bool compact;
  const _UsersSearchBar({this.compact = false});

  @override
  State<_UsersSearchBar> createState() => _UsersSearchBarState();
}

class _UsersSearchBarState extends State<_UsersSearchBar> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return ReusableSearchBar(
      height: widget.compact ? 40 : null,
      controller: _ctrl,
      focusNode: _focus,
      contentPadding:
      widget.compact ? const EdgeInsets.symmetric(horizontal: 4) : null,
      hintText: tr.search,
      onChanged: (q) => _UsersQuery.of(context)?.update(q),
    );
  }
}

class _UsersQuery extends InheritedNotifier<ValueNotifier<String>> {
  const _UsersQuery({
    required ValueNotifier<String> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static _UsersQuery? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_UsersQuery>();

  void update(String q) => notifier!.value = q;
}

// ═══════════════════════════════════════════════════════════════════
// List
// ═══════════════════════════════════════════════════════════════════
class _UsersList extends StatefulWidget {
  final bool canAdd;
  final bool dense;
  const _UsersList({required this.canAdd, required this.dense});

  @override
  State<_UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<_UsersList> {
  final _query = ValueNotifier<String>('');

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return _UsersQuery(
      notifier: _query,
      child: ValueListenableBuilder<String>(
        valueListenable: _query,
        builder: (context, query, _) {
          return BlocBuilder<UsersBloc, UsersState>(
            // Keep the list visible during a toggle: UserStatusToggledState
            // and UsersLoadedState both render rows; only true LoadingState
            // shows the spinner.
            builder: (context, state) {
              if (state is UsersLoadingState && state is! UsersLoadedState) {
                // Show spinner only if we have no data yet — this branch
                // still shows on a fresh load. (Bloc emits a fresh
                // UsersLoadingState for a genuine reload.)
                return const Center(child: CircularProgressIndicator());
              }
              if (state is UsersErrorState) {
                return _ErrorView(
                  message: state.message,
                  onRetry: () => _UsersController.refresh(context),
                );
              }

              final users = state is UsersLoadedState
                  ? state.users
                  : const <UsersModel>[];

              if (users.isEmpty) {
                return _EmptyView(
                  canAdd: widget.canAdd,
                  onAdd: () => _UsersController.openAddDialog(context),
                );
              }

              final filtered = _filter(users, query);
              if (filtered.isEmpty) {
                return NoDataWidget(message: tr.noDataFound);
              }

              return RefreshIndicator(
                onRefresh: () async => _UsersController.refresh(context),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        widget.dense || constraints.maxWidth < 640;
                    final medium =
                        !compact && constraints.maxWidth < 1000;

                    return ListView.separated(
                      key: const PageStorageKey('users_list'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        12,
                        widget.dense ? 8 : 12,
                        12,
                        24,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                      const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final usr = filtered[index];
                        return _UserRow(
                          // Key by stable ID so rows aren't rebuilt
                          // unnecessarily and hover state resets safely.
                          key: ValueKey(
                            usr.usrId ?? usr.usrName ?? index,
                          ),
                          user: usr,
                          isEven: index.isEven,
                          compact: compact,
                          medium: medium,
                          activeLabel: tr.active,
                          blockedLabel: tr.blocked,
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<UsersModel> _filter(List<UsersModel> source, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((u) {
      final name = (u.usrName ?? '').toLowerCase();
      final full = (u.usrFullName ?? '').toLowerCase();
      final email = (u.usrEmail ?? '').toLowerCase();
      return name.contains(q) || full.contains(q) || email.contains(q);
    }).toList();
  }
}

// ═══════════════════════════════════════════════════════════════════
// A single user row
// ═══════════════════════════════════════════════════════════════════
class _UserRow extends StatefulWidget {
  final UsersModel user;
  final bool isEven;
  final bool compact;
  final bool medium;
  final String activeLabel;
  final String blockedLabel;

  const _UserRow({
    super.key,
    required this.user,
    required this.isEven,
    required this.compact,
    required this.medium,
    required this.activeLabel,
    required this.blockedLabel,
  });

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  /// Safe hover setter — skips if unmounted or unchanged.
  /// Fixes "setState() called after dispose" when the row is
  /// removed while the cursor is still over it (block/unblock reload).
  void _setHovered(bool value) {
    if (!mounted) return;
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = widget.user;
    final isActive = user.usrStatus == 1;
    final tr = AppLocalizations.of(context)!;
    final statusLabel = isActive ? widget.activeLabel : widget.blockedLabel;
    final statusColor = isActive ? Colors.green : scheme.error;
    final radius = BorderRadius.circular(10);

    final baseColor = widget.isEven
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainerHigh;
    final bg = _hovered
        ? Color.alphaBlend(scheme.primary.withValues(alpha: .06), baseColor)
        : baseColor;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: bg,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () {}, // TODO: push UserDetailsView when available
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 12 : 16,
              vertical: widget.compact ? 8 : 12,
            ),
            child: Row(
              children: [
                _Avatar(
                  photo: user.usrPhoto,
                  size: widget.compact ? 36 : 55,
                  statusColor: statusColor,
                  placeholderColor: scheme.primaryContainer,
                ),
                SizedBox(width: widget.compact ? 10 : 14),

                // Identity block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.usrName ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: widget.compact ? 13 : 14,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (user.usrRole != null && !widget.compact) ...[
                            const SizedBox(width: 8),
                            _MetaChip(
                              text: user.usrRole!,
                              color: scheme.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.usrFullName ?? user.usrEmail ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: widget.compact ? 11 : 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (!widget.compact) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (user.usrEmail != null) ...[
                              Icon(
                                Icons.email_outlined,
                                size: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  user.usrEmail!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                            if (user.usrBranch != null) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.apartment_outlined,
                                size: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.usrBranch.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Status pill
                if (!widget.compact) ...[
                  const SizedBox(width: 8),
                  _StatusPill(
                    label: statusLabel,
                    color: statusColor,
                  ),
                ],

                // Actions
                const SizedBox(width: 4),
                _RowActionsMenu(
                  isActive: isActive,
                  onEdit: () =>
                      _UsersController.openEditDialog(context, user),
                  onToggleStatus: () => _UsersController.toggleStatus(
                    context,
                    user,
                    blockLabel: tr.block,
                    unblockLabel: tr.unblock,
                    cancelLabel: tr.cancel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Isolated popup menu.
///
/// Key fix: uses `showMenu` via a `GestureDetector` so we control
/// when the route closes — before any state change that could tear
/// the row (and the menu's anchor) down.
class _RowActionsMenu extends StatefulWidget {
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const _RowActionsMenu({
    required this.isActive,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  State<_RowActionsMenu> createState() => _RowActionsMenuState();
}

class _RowActionsMenuState extends State<_RowActionsMenu> {
  OverlayEntry? _overlay;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
    _isOpen = false;
  }

  Future<void> _openMenu() async {
    if (_isOpen || !mounted) return;
    final scheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    final button = context.findRenderObject() as RenderBox?;
    if (button == null) return;

    Overlay.of(context);
    final position = RelativeRect.fromLTRB(
      button.localToGlobal(Offset.zero).dx - 160,
      button.localToGlobal(Offset.zero).dy + button.size.height,
      button.localToGlobal(Offset.zero).dx,
      button.localToGlobal(Offset.zero).dy,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: [
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
        PopupMenuItem(
          value: 'toggleStatus',
          height: 40,
          child: Row(
            children: [
              Icon(
                widget.isActive ? Icons.block : Icons.check_circle_outline,
                size: 16,
                color: widget.isActive ? scheme.error : Colors.green,
              ),
              const SizedBox(width: 10),
              Text(
                widget.isActive ? tr.block : tr.unblock,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isActive ? scheme.error : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!mounted || selected == null) return;

    // Menu is fully closed here → safe to dispatch any state change.
    switch (selected) {
      case 'edit':
        widget.onEdit();
        break;
      case 'toggleStatus':
        widget.onToggleStatus();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _openMenu,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.more_vert,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Small primitives
// ────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String? photo;
  final double size;
  final Color statusColor;
  final Color placeholderColor;

  const _Avatar({
    required this.photo,
    required this.size,
    required this.statusColor,
    required this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final image = ImageHelper.stakeholderProfile(
      imageName: photo,
      size: size,
      shapeStyle: ShapeStyle.circle,
      placeholderColor: placeholderColor,
      placeholderIcon: Icons.person,
      errorIcon: Icons.person,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          image,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MetaChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Empty / error views
// ═══════════════════════════════════════════════════════════════════
class _EmptyView extends StatelessWidget {
  final bool canAdd;
  final VoidCallback onAdd;
  const _EmptyView({required this.canAdd, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: scheme.onSurface.withValues(alpha: .3),
          ),
          const SizedBox(height: 12),
          Text(
            tr.noDataFound,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: .6),
            ),
          ),
          if (canAdd) ...[
            const SizedBox(height: 8),
            ZOutlineButton(
              label: Text(tr.newKeyword),
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 44, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ZOutlineButton(
              label: const Text('Try again'),
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}