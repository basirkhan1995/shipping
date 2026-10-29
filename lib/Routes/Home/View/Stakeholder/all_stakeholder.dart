import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/stk_form.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/View/StakeholderById/stk_profile.dart';
import '../../../../Features/Other/responsive_widget.dart';
import '../../../../Features/Widgets/zbutton.dart';
import '../../../../Features/Widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import 'bloc/stakeholder_bloc.dart';
import 'features/entity_card.dart';
import 'model/stk_model.dart';

// ═══════════════════════════════════════════════════════════════════
// Main view
// ═══════════════════════════════════════════════════════════════════
class StakeholderView extends StatelessWidget {
  const StakeholderView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _StakeholderMobile(),
      tablet: _StakeholderTablet(),
      desktop: _StakeholderDesktop(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared controller/logic
// ═══════════════════════════════════════════════════════════════════
class _StakeholderController {
  static void refresh(BuildContext context) {
    context.read<StakeholderBloc>().add(const GetStakeholdersEvent());
  }

  static void search(BuildContext context, String query) {
    context.read<StakeholderBloc>().add(SearchStakeholdersEvent(query));
  }

  /// Opens the stakeholder detail screen.
  ///
  /// The detail screen pops with `true` when a transaction (cash deposit,
  /// cash withdrawal, fund transfer) — or any other balance-affecting
  /// mutation — occurred. In that case we refresh the list so account
  /// totals shown on the cards are up-to-date when the user comes back.
  static Future<void> openView(
      BuildContext context, IndividualsModel model) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StakeholderByIdView(ind: model)),
    );
    if (changed == true && context.mounted) {
      context.read<StakeholderBloc>().add(const GetStakeholdersEvent());
    }
  }

  static Future<void> openAddDialog(BuildContext context) async {
    final result = await showDialog<IndividualsModel>(
      context: context,
      builder: (_) => const StakeholderFormDialog(),
    );
    if (result != null && context.mounted) {
      context.read<StakeholderBloc>().add(AddStakeholderEvent(result));
    }
  }

  static Future<void> openEditDialog(
      BuildContext context, IndividualsModel model) async {
    final result = await showDialog<IndividualsModel>(
      context: context,
      builder: (_) => StakeholderFormDialog(existing: model),
    );
    if (result != null && context.mounted) {
      context.read<StakeholderBloc>().add(UpdateStakeholderEvent(result));
    }
  }

  static Future<void> confirmDelete(
      BuildContext context, IndividualsModel model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete stakeholder'),
        content: Text(
            'Are you sure you want to delete "${model.fullName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted && model.perId != null) {
      context
          .read<StakeholderBloc>()
          .add(DeleteStakeholderEvent(model.perId!));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared snackbar listener
// ═══════════════════════════════════════════════════════════════════
class _StakeholderListener extends StatelessWidget {
  final Widget child;
  const _StakeholderListener({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<StakeholderBloc, StakeholderState>(
      listenWhen: (p, c) =>
      c is AddStakeholderSuccessState ||
          c is AddStakeholderFailureState ||
          c is UpdateStakeholderSuccessState ||
          c is UpdateStakeholderFailureState ||
          c is DeleteStakeholderSuccessState ||
          c is DeleteStakeholderFailureState,
      listener: (context, state) {
        String? message;
        Color? color;
        if (state is AddStakeholderSuccessState ||
            state is UpdateStakeholderSuccessState ||
            state is DeleteStakeholderSuccessState) {
          message = (state is AddStakeholderSuccessState)
              ? state.message
              : (state is UpdateStakeholderSuccessState)
              ? state.message
              : (state as DeleteStakeholderSuccessState).message;
          color = Theme.of(context).colorScheme.primary;
        } else if (state is AddStakeholderFailureState) {
          message = state.message;
          color = Theme.of(context).colorScheme.error;
        } else if (state is UpdateStakeholderFailureState) {
          message = state.message;
          color = Theme.of(context).colorScheme.error;
        } else if (state is DeleteStakeholderFailureState) {
          message = state.message;
          color = Theme.of(context).colorScheme.error;
        }

        if (message != null && color != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: color),
          );
          context
              .read<StakeholderBloc>()
              .add(const ClearStakeholderMessagesEvent());
        }
      },
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _StakeholderMobile extends StatelessWidget {
  const _StakeholderMobile();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return _StakeholderListener(
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.stakeholders),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _StakeholderController.refresh(context),
            ),
            IconButton(
              tooltip: 'Add',
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _StakeholderController.openAddDialog(context),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ReusableSearchBar(
                hintText: 'Search stakeholder',
                onChanged: (q) => _StakeholderController.search(context, q),
              ),
            ),
            Expanded(
              child: _StakeholderList(
                onTapView: (m) => _StakeholderController.openView(context, m),
                onTapEdit: (m) =>
                    _StakeholderController.openEditDialog(context, m),
                onTapDelete: (m) =>
                    _StakeholderController.confirmDelete(context, m),
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
class _StakeholderTablet extends StatelessWidget {
  const _StakeholderTablet();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return _StakeholderListener(
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.stakeholders),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _StakeholderController.refresh(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ZOutlineButton(
                label: const Text('Add'),
                icon: Icons.add,
                iconSize: 18,
                height: 36,
                onPressed: () =>
                    _StakeholderController.openAddDialog(context),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ReusableSearchBar(
                hintText: 'Search stakeholder',
                onChanged: (q) => _StakeholderController.search(context, q),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _StakeholderList(
                onTapView: (m) => _StakeholderController.openView(context, m),
                onTapEdit: (m) =>
                    _StakeholderController.openEditDialog(context, m),
                onTapDelete: (m) =>
                    _StakeholderController.confirmDelete(context, m),
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
class _StakeholderDesktop extends StatefulWidget {
  const _StakeholderDesktop();

  @override
  State<_StakeholderDesktop> createState() => _StakeholderDesktopState();
}

class _StakeholderDesktopState extends State<_StakeholderDesktop> {
  @override
  void initState() {
    context.read<StakeholderBloc>().add(GetStakeholdersEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return _StakeholderListener(
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
                    tr.stakeholders,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 420,
                    child: ReusableSearchBar(
                      height: 40,
                      padding: EdgeInsets.zero,
                      prefixIconSize: 20,
                      suffixIconSize: 16,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4),
                      hintText: 'Search stakeholder',
                      onChanged: (q) =>
                          _StakeholderController.search(context, q),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ZOutlineButton(
                    label: const Text('Refresh'),
                    icon: Icons.refresh,
                    iconSize: 18,
                    height: 45,
                    onPressed: () =>
                        _StakeholderController.refresh(context),
                  ),
                  const SizedBox(width: 8),
                  ZOutlineButton(
                    label: const Text('Add Stakeholder'),
                    icon: Icons.add,
                    isActive: true,
                    iconSize: 18,
                    height: 45,
                    onPressed: () =>
                        _StakeholderController.openAddDialog(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _StakeholderList(
                onTapView: (m) => _StakeholderController.openView(context, m),
                onTapEdit: (m) =>
                    _StakeholderController.openEditDialog(context, m),
                onTapDelete: (m) =>
                    _StakeholderController.confirmDelete(context, m),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// List — EntityWidget per row
// ═══════════════════════════════════════════════════════════════════
class _StakeholderList extends StatelessWidget {
  final ValueChanged<IndividualsModel> onTapView;
  final ValueChanged<IndividualsModel> onTapEdit;
  final ValueChanged<IndividualsModel> onTapDelete;

  const _StakeholderList({
    required this.onTapView,
    required this.onTapEdit,
    required this.onTapDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StakeholderBloc, StakeholderState>(
      builder: (context, state) {
        if (state is GetStakeholdersLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is GetStakeholdersFailureState) {
          return _ErrorView(
            message: state.message,
            onRetry: () => _StakeholderController.refresh(context),
          );
        }

        final stakeholders = _extractList(state);

        if (stakeholders.isEmpty) {
          return _EmptyView(
            onAdd: () => _StakeholderController.openAddDialog(context),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _StakeholderController.refresh(context),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: stakeholders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final stk = stakeholders[index];
              return EntityWidget(
                isEven: index.isEven,
                stakeholder: stk,
                onTap: () => onTapView(stk),
                onTapView: () => onTapView(stk),
                onTapEdit: () => onTapEdit(stk),
                onTapDelete: () => onTapDelete(stk),
              );
            },
          ),
        );
      },
    );
  }

  List<IndividualsModel> _extractList(StakeholderState state) {
    if (state is GetStakeholdersSuccessState) return state.stakeholders;
    if (state is AddStakeholderLoadingState) return state.stakeholders;
    if (state is AddStakeholderSuccessState) return state.stakeholders;
    if (state is UpdateStakeholderLoadingState) return state.stakeholders;
    if (state is UpdateStakeholderSuccessState) return state.stakeholders;
    if (state is DeleteStakeholderLoadingState) return state.stakeholders;
    if (state is DeleteStakeholderSuccessState) return state.stakeholders;
    return const [];
  }
}

// ═══════════════════════════════════════════════════════════════════
// Empty / error views
// ═══════════════════════════════════════════════════════════════════
class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 48, color: scheme.onSurface.withValues(alpha: .3)),
          const SizedBox(height: 12),
          Text(
            'No stakeholders found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: .6),
            ),
          ),
          const SizedBox(height: 8),
          ZOutlineButton(
            label: const Text('Add stakeholder'),
            icon: Icons.add,
            onPressed: onAdd,
          ),
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