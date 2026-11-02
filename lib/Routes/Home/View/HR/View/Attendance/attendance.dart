import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import '../../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../../Features/Widgets/shimmer.dart';
import '../../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../Features/Date/zdate_picker.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import 'attendance_form.dart';
import 'bloc/attendance_bloc.dart';
import 'model/attendance_model.dart';

class AttendanceView extends StatelessWidget {
  final String? usrName;
  const AttendanceView({super.key, this.usrName});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final resolvedUser = usrName?.trim().isNotEmpty == true
        ? usrName!.trim()
        : authState is AuthenticatedState
        ? (authState.loginData.usrName ?? '').trim()
        : '';

    return _AttendanceListener(
      child: ResponsiveLayout(
        mobile: _AttendanceMobile(usrName: resolvedUser),
        tablet: _AttendanceTablet(usrName: resolvedUser),
        desktop: _AttendanceDesktop(usrName: resolvedUser),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Controller
// ═══════════════════════════════════════════════════════════════════
class _AttendanceController {
  static void refresh(BuildContext context) {
    context.read<AttendanceBloc>().add(const LoadAttendanceEvent());
  }

  static void filterByDate(BuildContext context, String date) {
    context.read<AttendanceBloc>().add(LoadAttendanceEvent(date: date));
  }

  static void clearFilter(BuildContext context) {
    context.read<AttendanceBloc>().add(const LoadAttendanceEvent());
  }

  static String _resolveUser(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      final name = (authState.loginData.usrName ?? '').trim();
      if (name.isNotEmpty) return name;
    }
    return '';
  }

  static Future<void> openAddDialog(
      BuildContext context, String usrName) async {
    final who =
    usrName.trim().isNotEmpty ? usrName.trim() : _resolveUser(context);
    if (who.isEmpty) {
      ToastManager.show(
        context: context,
        message: 'No active user — please sign in again.',
        type: ToastType.error,
      );
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    final bloc = context.read<AttendanceBloc>();

    await showDialog<bool>(
      context: navigator.context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AttendanceAddDialog(usrName: who),
      ),
    );
  }

  static Future<void> openEditDialog(
      BuildContext context, AttendanceModel model, String usrName) async {
    final who =
    usrName.trim().isNotEmpty ? usrName.trim() : _resolveUser(context);
    if (who.isEmpty) {
      ToastManager.show(
        context: context,
        message: 'No active user — please sign in again.',
        type: ToastType.error,
      );
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    final bloc = context.read<AttendanceBloc>();

    await showDialog<bool>(
      context: navigator.context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AttendanceEditDialog(record: model, usrName: who),
      ),
    );
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

    final who =
    usrName.trim().isNotEmpty ? usrName.trim() : _resolveUser(context);
    if (who.isEmpty) {
      ToastManager.show(
        context: context,
        message: 'No active user — please sign in again.',
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

    if (ok == true) {
      bloc.add(DeleteAttendanceEvent(row.emaID!, usrName: who));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Listener
// ═══════════════════════════════════════════════════════════════════
class _AttendanceListener extends StatelessWidget {
  final Widget child;
  const _AttendanceListener({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listenWhen: (p, c) =>
      (c is AttendanceSavedState && p is! AttendanceSavedState) ||
          (c is AttendanceErrorState && p is! AttendanceErrorState),
      listener: (context, state) {
        if (!context.mounted) return;

        if (state is AttendanceSavedState) {
          ToastManager.show(
            context: context,
            message: state.message,
            type: ToastType.success,
          );
          Future.microtask(() {
            if (context.mounted) {
              context
                  .read<AttendanceBloc>()
                  .add(const ClearAttendanceMessagesEvent());
            }
          });
        } else if (state is AttendanceErrorState) {
          ToastManager.show(
            context: context,
            message: state.message,
            type: ToastType.error,
          );
          Future.microtask(() {
            if (context.mounted) {
              context
                  .read<AttendanceBloc>()
                  .add(const ClearAttendanceMessagesEvent());
            }
          });
        }
      },
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _AttendanceMobile extends StatefulWidget {
  final String usrName;
  const _AttendanceMobile({required this.usrName});

  @override
  State<_AttendanceMobile> createState() => _AttendanceMobileState();
}

class _AttendanceMobileState extends State<_AttendanceMobile> {
  String? _date;

  void _clearFilter() {
    setState(() => _date = null);
    _AttendanceController.clearFilter(context);
  }

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
          if (_date != null)
          IconButton(
            tooltip: 'Clear filter',
            icon: const Icon(Icons.filter_alt_off, size: 20),
            onPressed: _clearFilter,
          ),
          IconButton(
            tooltip: 'Add attendance',
            icon: const Icon(Icons.add, size: 20),
            onPressed: () =>
                _AttendanceController.openAddDialog(context, widget.usrName),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _DateFilterBar(
              usrName: widget.usrName,
              expand: true,
              initialDate: _date,
              onDatePicked: (v) => setState(() => _date = v),
            ),
          ),
          Expanded(
            child: _AttendanceList(
              usrName: widget.usrName,
              isMobile: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TABLET
// ═══════════════════════════════════════════════════════════════════
class _AttendanceTablet extends StatefulWidget {
  final String usrName;
  const _AttendanceTablet({required this.usrName});

  @override
  State<_AttendanceTablet> createState() => _AttendanceTabletState();
}

class _AttendanceTabletState extends State<_AttendanceTablet> {
  String? _date;

  void _clearFilter() {
    setState(() => _date = null);
    _AttendanceController.clearFilter(context);
  }

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
          if (_date != null)
          IconButton(
            tooltip: 'Clear filter',
            icon: const Icon(Icons.filter_alt_off, size: 20),
            onPressed: _clearFilter,
          ),
          IconButton(
            tooltip: 'Add attendance',
            icon: const Icon(Icons.add, size: 20),
            onPressed: () =>
                _AttendanceController.openAddDialog(context, widget.usrName),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _DateFilterBar(
              usrName: widget.usrName,
              expand: true,
              initialDate: _date,
              onDatePicked: (v) => setState(() => _date = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _AttendanceList(
              usrName: widget.usrName,
              isMobile: false,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _AttendanceDesktop extends StatefulWidget {
  final String usrName;
  const _AttendanceDesktop({required this.usrName});

  @override
  State<_AttendanceDesktop> createState() => _AttendanceDesktopState();
}

class _AttendanceDesktopState extends State<_AttendanceDesktop> {
  String? _date;

  void _clearFilter() {
    setState(() => _date = null);
    _AttendanceController.clearFilter(context);
  }

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
                      style: TextStyle(letterSpacing: 1.3, fontSize: 10),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  child: _DateFilterBar(
                    usrName: widget.usrName,
                    compact: true,
                    expand: false,
                    initialDate: _date,
                    onDatePicked: (v) => setState(() => _date = v),
                  ),
                ),
                const SizedBox(width: 8),
                ZOutlineButton(
                  label: Text(tr.refresh),
                  icon: Icons.refresh,
                  iconSize: 18,
                  height: 48,
                  onPressed: () => _AttendanceController.refresh(context),
                ),

                if (_date != null)...[
                  const SizedBox(width: 8),
                  ZOutlineButton(
                    label: const Text('Clear filter'),
                    isActive: true,
                    backgroundHover: Theme.of(context).colorScheme.error,
                    icon: Icons.filter_alt_off,
                    iconSize: 18,
                    height: 48,
                    onPressed: _clearFilter,
                  ),
                ],

                const SizedBox(width: 8),
                ZOutlineButton(
                  label: const Text('Add attendance'),
                  icon: Icons.add,
                  isActive: true,
                  iconSize: 18,
                  height: 48,
                  onPressed: () => _AttendanceController.openAddDialog(
                      context, widget.usrName),
                ),
              ],
            ),
          ),
          Expanded(
            child: _AttendanceList(
              usrName: widget.usrName,
              isMobile: false,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Date filter bar — fully controlled
// ═══════════════════════════════════════════════════════════════════
class _DateFilterBar extends StatefulWidget {
  final String usrName;
  final bool compact;
  final bool expand;
  final String? initialDate;
  final ValueChanged<String?> onDatePicked;

  const _DateFilterBar({
    required this.usrName,
    required this.onDatePicked,
    this.initialDate,
    this.compact = false,
    this.expand = true,
  });

  @override
  State<_DateFilterBar> createState() => _DateFilterBarState();
}

class _DateFilterBarState extends State<_DateFilterBar> {
  String? _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void didUpdateWidget(covariant _DateFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != _date) {
      setState(() => _date = widget.initialDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Widget datePicker = GenericDatePicker(
      // Changing the key forces the picker to rebuild and reset
      // its internal visual state when the parent clears it.
      key: ValueKey(_date ?? 'no-date'),
      label: '',
      height: 40,
      initialGregorianDate: _date,
      onDateChanged: (value) {
        if (value.isEmpty || value == _date) return;
        setState(() => _date = value);
        widget.onDatePicked(value);
        _AttendanceController.filterByDate(context, value);
      },
      padding: EdgeInsets.zero,
      gregorianTextStyle: TextStyle(
        fontSize: 12,
        color: scheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      shamsiTextStyle: TextStyle(
        fontSize: 10,
        color: scheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );

    return Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (widget.expand)
          Expanded(child: datePicker)
        else
          SizedBox(
            width: widget.compact ? 170 : 175,
            child: datePicker,
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// List
// ═══════════════════════════════════════════════════════════════════
class _AttendanceList extends StatefulWidget {
  final String usrName;
  final bool isMobile;
  const _AttendanceList({required this.usrName, required this.isMobile});

  @override
  State<_AttendanceList> createState() => _AttendanceListState();
}

class _AttendanceListState extends State<_AttendanceList> {
  List<AttendanceModel> _cached = const [];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listenWhen: (p, c) => c is AttendanceLoadedState,
      listener: (context, state) {
        if (state is AttendanceLoadedState) {
          setState(() => _cached = state.records);
        }
      },
      builder: (context, state) {
        if (state is AttendanceLoadingState && _cached.isEmpty) {
          return UniversalShimmer.accountList(
            itemCount: 10,
            useAlternatingColors: true,
          );
        }

        final records =
        state is AttendanceLoadedState ? state.records : _cached;

        if (state is AttendanceErrorState && records.isEmpty) {
          return _ErrorView(
            message: state.message,
            onRetry: () => _AttendanceController.refresh(context),
          );
        }

        if (records.isEmpty) return const _EmptyView();

        return RefreshIndicator(
          onRefresh: () async => _AttendanceController.refresh(context),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: records.length + 1,
            separatorBuilder: (_, i) =>
            i == 0 ? const SizedBox(height: 4) : const SizedBox(height: 6),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _HeaderRow(isMobile: widget.isMobile);
              }
              final row = records[index - 1];
              return _AttendanceRow(
                row: row,
                isMobile: widget.isMobile,
                onEdit: () => _AttendanceController.openEditDialog(
                    context, row, widget.usrName),
                onDelete: () => _AttendanceController.confirmDelete(
                    context, row, widget.usrName),
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
          if (!isMobile) Expanded(flex: 2, child: Text('DATE', style: style)),
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
          Expanded(
            flex: 2,
            child: Text(isMobile ? 'State' : 'STATUS', style: style),
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

  Color _completionColor() =>
      row.emaCompleted ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);

  String _shortTime(String? t) {
    if (t == null || t.isEmpty) return '--:--';
    return t.length >= 5 ? t.substring(0, 5) : t;
  }

  String _hours(double? hours) {
    if (hours == null) return '—';
    return hours.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final statusColor = _statusColor(context, row.emaStatus);
    final completionColor = _completionColor();

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
                        child: Wrap(
                          children: [
                            Text(
                              row.empPosition!,
                              style: text.bodySmall?.copyWith(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(width: 4),

                            Text(
                              "• ${row.emaStatus}",
                              style: text.bodySmall?.copyWith(
                                fontSize: 11,
                                color: statusColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                  row.emaCheckedOut == null
                      ? '--:--'
                      : _shortTime(row.emaCheckedOut),
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    color: row.emaCheckedOut == null
                        ? completionColor
                        : scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  row.emaCompleted ? _hours(row.emaWorkHours) : '—',
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(
                      row.emaCompleted ? Icons.check_circle : Icons.timelapse,
                      size: 14,
                      color: completionColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        row.emaCompleted ? 'Completed' : 'Incomplete',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: completionColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
                          Text('Edit', style: TextStyle(fontSize: 13)),
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
                            style: TextStyle(fontSize: 13, color: scheme.error),
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
          Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: scheme.onSurface.withValues(alpha: .3),
          ),
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