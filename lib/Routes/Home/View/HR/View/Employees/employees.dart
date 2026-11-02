import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import '../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../Features/Widgets/shimmer.dart';
import '../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../l10n/app_localizations.dart';
import 'add_edit_employee.dart';
import 'bloc/employee_bloc.dart';
import 'feature/employee_widget.dart';
import 'model/emp_model.dart';

class EmployeesView extends StatelessWidget {
  const EmployeesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _EmployeeMobile(),
      tablet: _EmployeeTablet(),
      desktop: _EmployeeDesktop(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Controller
// ═══════════════════════════════════════════════════════════════════
class _EmployeeController {
  static void refresh(BuildContext context) {
    context.read<EmployeeBloc>().add(const LoadEmployeeEvent());
  }

  static void search(BuildContext context, String query) {
    context.read<EmployeeBloc>().add(SearchEmployeesEvent(query));
  }

  static Future<void> openAddDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<EmployeeBloc>(),
        child: const EmployeeFormDialog(),
      ),
    );
  }

  static Future<void> openEditDialog(
      BuildContext context, EmployeeModel model) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<EmployeeBloc>(),
        child: EmployeeFormDialog(existing: model),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Listener — MUST listen to EmployeeSavedState, not EmployeeSuccessState
// ═══════════════════════════════════════════════════════════════════
class _EmployeeListener extends StatelessWidget {
  final Widget child;
  const _EmployeeListener({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmployeeBloc, EmployeeState>(
      listenWhen: (p, c) =>
      c is EmployeeSavedState || c is EmployeeErrorState,
      listener: (context, state) {
        if (state is EmployeeSavedState) {
          ToastManager.show(
            context: context,
            message: state.message,
            type: ToastType.success,
          );
          // Refresh list from server after dialog closes.
          context.read<EmployeeBloc>().add(const LoadEmployeeEvent());
        } else if (state is EmployeeErrorState) {
          // Only surface *top-level* errors (not inside the dialog) here.
          ToastManager.show(
            context: context,
            message: state.message,
            type: ToastType.error,
          );
          context
              .read<EmployeeBloc>()
              .add(const ClearEmployeeMessagesEvent());
        }
      },
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _EmployeeMobile extends StatelessWidget {
  const _EmployeeMobile();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return _EmployeeListener(
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.employees),
          actions: [
            IconButton(
              tooltip: tr.refresh,
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _EmployeeController.refresh(context),
            ),
            IconButton(
              tooltip: tr.addEmployee,
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _EmployeeController.openAddDialog(context),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ReusableSearchBar(
                hintText: tr.search,
                onChanged: (q) => _EmployeeController.search(context, q),
              ),
            ),
            const Expanded(child: _EmployeeList()),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TABLET
// ═══════════════════════════════════════════════════════════════════
class _EmployeeTablet extends StatelessWidget {
  const _EmployeeTablet();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return _EmployeeListener(
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.employees),
          actions: [
            IconButton(
              tooltip: tr.refresh,
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _EmployeeController.refresh(context),
            ),
            IconButton(
              tooltip: tr.addEmployee,
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _EmployeeController.openAddDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ReusableSearchBar(
                hintText: tr.search,
                onChanged: (q) => _EmployeeController.search(context, q),
              ),
            ),
            const SizedBox(height: 8),
            const Expanded(child: _EmployeeList()),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _EmployeeDesktop extends StatelessWidget {
  const _EmployeeDesktop();

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return _EmployeeListener(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        tr.employees.toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tr.employeeHint,
                        style: const TextStyle(
                          letterSpacing: 1.3,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 350,
                    child: ReusableSearchBar(
                      height: 40,
                      padding: EdgeInsets.zero,
                      prefixIconSize: 20,
                      suffixIconSize: 16,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4),
                      hintText: tr.searchEmployees,
                      onChanged: (q) =>
                          _EmployeeController.search(context, q),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ZOutlineButton(
                    label: Text(tr.refresh),
                    icon: Icons.refresh,
                    iconSize: 18,
                    height: 45,
                    onPressed: () =>
                        _EmployeeController.refresh(context),
                  ),
                  const SizedBox(width: 8),
                  ZOutlineButton(
                    label: Text(tr.addEmployee),
                    icon: Icons.add,
                    isActive: true,
                    iconSize: 18,
                    height: 45,
                    onPressed: () =>
                        _EmployeeController.openAddDialog(context),
                  ),
                ],
              ),
            ),
            const Expanded(child: _EmployeeList()),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// List — only EmployeeLoadedState carries the list
// ═══════════════════════════════════════════════════════════════════
class _EmployeeList extends StatelessWidget {
  const _EmployeeList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeBloc, EmployeeState>(
      builder: (context, state) {
        if (state is EmployeeLoadingState) {
          return UniversalShimmer.accountList(
            itemCount: 10,
            useAlternatingColors: true,
          );
        }
        // Error with no data at all (first load failed)
        if (state is EmployeeErrorState) {
          return _ErrorView(
            message: state.message,
            onRetry: () => _EmployeeController.refresh(context),
          );
        }

        final employees = _extractList(state);

        if (employees.isEmpty) {
          return const _EmptyView();
        }

        return RefreshIndicator(
          onRefresh: () async => _EmployeeController.refresh(context),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final emp = employees[index];
              return EmployeeWidget(
                isEven: index.isEven,
                employee: emp,
                onTapEdit: () =>
                    _EmployeeController.openEditDialog(context, emp),
              );
            },
          ),
        );
      },
    );
  }

  // Only EmployeeLoadedState has `.employees` now.
  List<EmployeeModel> _extractList(EmployeeState state) {
    if (state is EmployeeLoadedState) return state.employees;
    return const [];
  }
}

// ═══════════════════════════════════════════════════════════════════
// Empty / error views
// ═══════════════════════════════════════════════════════════════════
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.badge_outlined,
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
    final tr = AppLocalizations.of(context)!;
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
              label: Text(tr.tryAgain),
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}