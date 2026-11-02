import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import '../../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../../Features/Widgets/search_field.dart';
import '../../../../../../../Features/Widgets/shimmer.dart';
import '../../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../../l10n/app_localizations.dart';
import 'attendance_form.dart';
import 'bloc/attendance_bloc.dart';
import 'model/attendance_model.dart';

class AttendanceView extends StatelessWidget {
  final String? usrName;
  const AttendanceView({super.key, this.usrName});

  @override
  Widget build(BuildContext context) {
    return _AttendanceListener(
      child: ResponsiveLayout(
        mobile: _AttendanceMobile(usrName: usrName ?? ''),
        tablet: _AttendanceTablet(usrName: usrName ?? ''),
        desktop: _AttendanceDesktop(usrName: usrName ?? ''),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Controller
// ═══════════════════════════════════════════════════════════════════
class _AttendanceController {
  static void refresh(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    context.read<AttendanceBloc>().add(const LoadAttendanceEvent());
    ToastManager.show(
      context: context,
      message: tr.refresh,
      type: ToastType.success,
    );
  }

  static void filterByDate(BuildContext context, String date) {
    context.read<AttendanceBloc>().add(LoadAttendanceEvent(date: date));
  }

  static void clearFilter(BuildContext context) {
    context.read<AttendanceBloc>().add(const LoadAttendanceEvent());
  }

  static Future<void> openAddDialog(
      BuildContext context, String usrName) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final bloc = context.read<AttendanceBloc>();

    final saved = await showDialog<bool>(
      context: navigator.context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AttendanceAddDialog(usrName: usrName),
      ),
    );
    if (!context.mounted) return;
    if (saved == true) {
      bloc.add(const LoadAttendanceEvent());
    }
  }

  static Future<void> openEditDialog(
      BuildContext context, AttendanceModel model, String usrName) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final bloc = context.read<AttendanceBloc>();

    final saved = await showDialog<bool>(
      context: navigator.context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AttendanceEditDialog(record: model, usrName: usrName),
      ),
    );
    if (!context.mounted) return;
    if (saved == true) {
      bloc.add(const LoadAttendanceEvent());
    }
  }

  static Future<void> confirmDelete(
      BuildContext context, AttendanceModel row, String usrName) async {
    if (row.emaID == null) {
      ToastManager.show(
        context: context,
        message: 'Attendance record not found.',
        type: ToastType.error,
      );
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    final bloc = context.read<AttendanceBloc>();

    final ok = await showDialog<bool>(
      context: navigator.context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete attendance'),
        content: Text(
          'Delete the attendance row for '
              '"${row.fullName ?? ''}" on ${row.emaDate ?? ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (ok == true) {
      bloc.add(DeleteAttendanceEvent(row.emaID!, usrName: usrName));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Listener — toasts success / error
// ═══════════════════════════════════════════════════════════════════
class _AttendanceListener extends StatelessWidget {
  final Widget child;
  const _AttendanceListener({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listenWhen: (p, c) =>
      c is AttendanceSavedState || c is AttendanceErrorState,
      listener: (context, state) {
        if (state is AttendanceSavedState) {
          ToastManager.show(
            context: context,
            message: state.message,
            type: ToastType.success,
          );
        } else if (state is AttendanceErrorState) {
          ToastManager.show(
            context: context,
            message: state.message,
            type: ToastType.error,
          );
          context
              .read<AttendanceBloc>()
              .add(const ClearAttendanceMessagesEvent());
        }
      },
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _AttendanceMobile extends StatelessWidget {
  final String usrName;
  const _AttendanceMobile({required this.usrName});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.attendance),
        actions: [
          IconButton(
            tooltip: tr.refresh,
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _AttendanceController.refresh(context),
          ),
          IconButton(
            tooltip: 'Add attendance',
            icon: const Icon(Icons.add, size: 20),
            onPressed: () =>
                _AttendanceController.openAddDialog(context, usrName),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _DateFilterBar(usrName: usrName, expand: true),
          ),
          Expanded(
            child: _AttendanceList(usrName: usrName, isMobile: true),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TABLET
// ═══════════════════════════════════════════════════════════════════
class _AttendanceTablet extends StatelessWidget {
  final String usrName;
  const _AttendanceTablet({required this.usrName});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.attendance),
        actions: [
          IconButton(
            tooltip: tr.refresh,
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _AttendanceController.refresh(context),
          ),
          IconButton(
            tooltip: 'Add attendance',
            icon: const Icon(Icons.add, size: 20),
            onPressed: () =>
                _AttendanceController.openAddDialog(context, usrName),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _DateFilterBar(usrName: usrName, expand: true),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _AttendanceList(usrName: usrName, isMobile: false),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _AttendanceDesktop extends StatelessWidget {
  final String usrName;
  const _AttendanceDesktop({required this.usrName});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
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
                  children: [
                    Text(
                      tr.attendance.toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'TRACK EMPLOYEE CHECK-IN / CHECK-OUT',
                      style: TextStyle(
                        letterSpacing: 1.3,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // ← FIX: bounded width so the inner Row never sees
                //        unbounded constraints. `expand: false` makes
                //        `_DateFilterBar` size to its children only.
                SizedBox(
                  width: 280,
                  child: _DateFilterBar(
                    usrName: usrName,
                    compact: true,
                    expand: false,
                  ),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  label: Text(tr.refresh),
                  icon: Icons.refresh,
                  iconSize: 18,
                  height: 45,
                  onPressed: () => _AttendanceController.refresh(context),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  label: const Text('Add attendance'),
                  icon: Icons.add,
                  isActive: true,
                  iconSize: 18,
                  height: 45,
                  onPressed: () =>
                      _AttendanceController.openAddDialog(context, usrName),
                ),
              ],
            ),
          ),
          Expanded(
            child: _AttendanceList(usrName: usrName, isMobile: false),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Date filter bar
//
//   `expand: true`  → fills available width (used inside Column body)
//   `expand: false` → sizes to its children (used inside desktop header
//                     where the parent is a Row giving unbounded width)
//
//   The inner Row never uses `Flexible` on the search bar when the
//   parent can hand down unbounded width — that was the source of the
//   "RenderFlex children have non-zero flex but incoming width
//   constraints are unbounded" assertion.
// ═══════════════════════════════════════════════════════════════════
class _DateFilterBar extends StatefulWidget {
  final String usrName;
  final bool compact;
  final bool expand;
  const _DateFilterBar({
    required this.usrName,
    this.compact = false,
    this.expand = true,
  });

  @override
  State<_DateFilterBar> createState() => _DateFilterBarState();
}

class _DateFilterBarState extends State<_DateFilterBar> {
  String? _date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget searchBar = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(_date ?? '') ?? now,
          firstDate: DateTime(now.year - 3),
          lastDate: DateTime(now.year + 1),
        );
        if (!context.mounted) return;
        if (picked != null) {
          final s = '${picked.year.toString().padLeft(4, '0')}-'
              '${picked.month.toString().padLeft(2, '0')}-'
              '${picked.day.toString().padLeft(2, '0')}';
          setState(() => _date = s);
          _AttendanceController.filterByDate(context, s);
        }
      },
      child: AbsorbPointer(
        child: ReusableSearchBar(
          hintText: _date == null ? 'Filter by date…' : _date!,
          height: 40,
          padding: EdgeInsets.zero,
          prefixIconSize: 20,
          suffixIconSize: 16,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          onChanged: (_) {},
        ),
      ),
    );

    return Row(
      mainAxisSize:
      widget.expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (widget.expand)
          Expanded(child: searchBar)
        else
          SizedBox(
            width: widget.compact ? 260 : 320,
            child: searchBar,
          ),
        if (_date != null) ...[
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Clear date filter',
            icon: Icon(Icons.close, size: 18, color: scheme.error),
            onPressed: () {
              setState(() => _date = null);
              _AttendanceController.clearFilter(context);
            },
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// List
// ═══════════════════════════════════════════════════════════════════
class _AttendanceList extends StatelessWidget {
  final String usrName;
  final bool isMobile;
  const _AttendanceList({required this.usrName, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state is AttendanceLoadingState) {
          return UniversalShimmer.accountList(
            itemCount: 10,
            useAlternatingColors: true,
          );
        }

        final records = state is AttendanceLoadedState
            ? state.records
            : <AttendanceModel>[];

        if (state is AttendanceErrorState && records.isEmpty) {
          return _ErrorView(
            message: state.message,
            onRetry: () => _AttendanceController.refresh(context),
          );
        }

        if (records.isEmpty) {
          return const _EmptyView();
        }

        return RefreshIndicator(
          onRefresh: () async => _AttendanceController.refresh(context),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: records.length + 1,
            separatorBuilder: (_, i) => i == 0
                ? const SizedBox(height: 4)
                : const SizedBox(height: 6),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _HeaderRow(isMobile: isMobile);
              }
              final row = records[index - 1];
              return _AttendanceRow(
                row: row,
                isMobile: isMobile,
                onEdit: () => _AttendanceController.openEditDialog(
                    context, row, usrName),
                onDelete: () => _AttendanceController.confirmDelete(
                    context, row, usrName),
              );
            },
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Header row
// ═══════════════════════════════════════════════════════════════════
class _HeaderRow extends StatelessWidget {
  final bool isMobile;
  const _HeaderRow({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.3,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: isMobile ? 4 : 3,
            child: Text(isMobile ? 'Employee' : 'EMPLOYEE', style: style),
          ),
          if (!isMobile)
            Expanded(
              flex: 2,
              child: Text('DATE', style: style),
            ),
          Expanded(
            flex: 2,
            child: Text(isMobile ? 'In' : 'CHECK-IN', style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(isMobile ? 'Out' : 'CHECK-OUT', style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(isMobile ? 'Hrs' : 'HOURS', style: style),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Attendance row
// ═══════════════════════════════════════════════════════════════════
class _AttendanceRow extends StatelessWidget {
  final AttendanceModel row;
  final bool isMobile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AttendanceRow({
    required this.row,
    required this.isMobile,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor(BuildContext context, String? status) {
    final scheme = Theme.of(context).colorScheme;
    switch ((status ?? '').toLowerCase()) {
      case 'present':
        return const Color(0xFF22C55E);
      case 'late':
        return const Color(0xFFF59E0B);
      case 'leave':
        return const Color(0xFF3B82F6);
      case 'absent':
      default:
        return scheme.error;
    }
  }

  String _shortTime(String? t) {
    if (t == null || t.isEmpty) return '--:--';
    return t.length >= 5 ? t.substring(0, 5) : t;
  }

  String _hours(String? hours, double? numeric) {
    if (numeric != null) return numeric.toStringAsFixed(1);
    if (hours == null) return '0.0';
    final d = double.tryParse(hours);
    return d == null ? hours : d.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final statusColor = _statusColor(context, row.emaStatus);

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: isMobile ? 4 : 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.fullName ?? '—',
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isMobile && (row.empPosition ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          row.empPosition!,
                          style: text.bodySmall?.copyWith(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        row.emaStatus ?? '—',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                Expanded(
                  flex: 2,
                  child: Text(
                    row.emaDate ?? '—',
                    style: text.bodySmall?.copyWith(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: Text(
                  _shortTime(row.emaCheckedIn),
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _shortTime(row.emaCheckedOut),
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: Text(
                  _hours(null, row.emaWorkHours),
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: PopupMenuButton<String>(
                  tooltip: 'Actions',
                  padding: EdgeInsets.zero,
                  splashRadius: 16,
                  icon: Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      height: 40,
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 10),
                          Text('Edit',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      height: 40,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 16, color: scheme.error),
                          const SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(
                                fontSize: 13, color: scheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
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
// Empty / error views
// ═══════════════════════════════════════════════════════════════════
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined,
              size: 48, color: scheme.onSurface.withValues(alpha: .3)),
          const SizedBox(height: 12),
          Text(
            'No attendance records',
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