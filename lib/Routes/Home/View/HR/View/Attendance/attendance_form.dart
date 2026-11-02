import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../Employees/bloc/employee_bloc.dart';
import '../Employees/model/emp_model.dart';
import 'bloc/attendance_bloc.dart';
import 'model/attendance_model.dart';

// ═══════════════════════════════════════════════════════════════════
// ADD dialog
// ═══════════════════════════════════════════════════════════════════
enum _AddMode { single, multiple, all }

class AttendanceAddDialog extends StatefulWidget {
  final String usrName;
  const AttendanceAddDialog({super.key, required this.usrName});

  @override
  State<AttendanceAddDialog> createState() => _AttendanceAddDialogState();
}

class _AttendanceAddDialogState extends State<AttendanceAddDialog> {
  _AddMode _mode = _AddMode.single;
  String? _date;
  String _status = 'Present';
  TimeOfDay? _in;
  TimeOfDay? _out;
  int? _empId;

  final Map<int, ({TimeOfDay? inT, TimeOfDay? outT, String status})> _rows = {};

  String? _error;
  bool _submitting = false;

  static const _statuses = ['Present', 'Absent', 'Late', 'Leave'];

  String _time24(TimeOfDay? t) => t == null
      ? '00:00:00'
      : '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date ?? '') ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _date = '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay? init) => showTimePicker(
    context: context,
    initialTime: init ?? const TimeOfDay(hour: 8, minute: 0),
  );

  void _submit() {
    if (_submitting) return;
    setState(() => _error = null);

    if (_date == null) {
      setState(() => _error = 'Please select a date.');
      return;
    }
    if (_mode == _AddMode.single && _empId == null) {
      setState(() => _error = 'Please pick an employee.');
      return;
    }
    if (_mode == _AddMode.multiple && _rows.isEmpty) {
      setState(() => _error = 'Please add at least one employee.');
      return;
    }
    if ((_mode == _AddMode.single || _mode == _AddMode.all) &&
        _status != 'Absent' &&
        (_in == null || _out == null)) {
      setState(() => _error = 'Please pick check-in and check-out.');
      return;
    }

    setState(() => _submitting = true);

    if (_mode == _AddMode.multiple) {
      final records = _rows.entries.map((e) => {
        'emaEmployee': e.key,
        'emaCheckedIn': e.value.status == 'Absent'
            ? '00:00:00'
            : _time24(e.value.inT),
        'emaCheckedOut': e.value.status == 'Absent'
            ? '00:00:00'
            : _time24(e.value.outT),
        'emaStatus': e.value.status,
      }).toList();

      context.read<AttendanceBloc>().add(AddAttendanceEvent(
        mode: 'multiple',
        usrName: widget.usrName,
        emaDate: _date!,
        records: records,
      ));
    } else if (_mode == _AddMode.all) {
      context.read<AttendanceBloc>().add(AddAttendanceEvent(
        mode: 'all',
        usrName: widget.usrName,
        emaDate: _date!,
        emaCheckedIn:
        _status == 'Absent' ? '00:00:00' : _time24(_in),
        emaCheckedOut:
        _status == 'Absent' ? '00:00:00' : _time24(_out),
        emaStatus: _status,
      ));
    } else {
      context.read<AttendanceBloc>().add(AddAttendanceEvent(
        mode: 'single',
        usrName: widget.usrName,
        emaDate: _date!,
        emaEmployee: _empId,
        emaCheckedIn:
        _status == 'Absent' ? '00:00:00' : _time24(_in),
        emaCheckedOut:
        _status == 'Absent' ? '00:00:00' : _time24(_out),
        emaStatus: _status,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    String fmt(TimeOfDay? t) => t == null
        ? '--:--'
        : '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';

    return BlocListener<AttendanceBloc, AttendanceState>(
      listenWhen: (p, c) =>
      c is AttendanceSavedState || c is AttendanceErrorState,
      listener: (context, state) {
        if (state is AttendanceSavedState) {
          if (mounted) Navigator.of(context).pop(true);
        } else if (state is AttendanceErrorState) {
          if (mounted) {
            setState(() {
              _submitting = false;
              _error = state.message;
            });
          }
        }
      },
      child: ZFormDialog(
        title: 'Add attendance',
        icon: Icons.event_available_outlined,
        errorMessage: _error,
        isButtonEnabled: !_submitting,
        actionLabel: _submitting
            ? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.surface,
          ),
        )
            : Text(tr.save),
        onAction: _submit,
        width: 720,
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Mode selector ───────────────────────────────────
              SegmentedButton<_AddMode>(
                segments: const [
                  ButtonSegment(
                    value: _AddMode.single,
                    icon: Icon(Icons.person, size: 16),
                    label: Text('Single'),
                  ),
                  ButtonSegment(
                    value: _AddMode.multiple,
                    icon: Icon(Icons.group, size: 16),
                    label: Text('Multiple'),
                  ),
                  ButtonSegment(
                    value: _AddMode.all,
                    icon: Icon(Icons.groups, size: 16),
                    label: Text('All Active'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() {
                  _mode = s.first;
                  _error = null;
                }),
              ),
              const SizedBox(height: 12),

              // ── Date + Status ───────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _pickDate,
                      child: IgnorePointer(
                        child: ZTextFieldEntitled(
                          title: 'Date',
                          controller: TextEditingController(
                            text: _date ?? '',
                          ),
                          readOnly: true,
                          trailing: const Icon(
                            Icons.calendar_month,
                            size: 18,
                          ),
                          autoFocus: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _statuses
                          .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s),
                      ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Single: employee + in/out ────────────────────────
              if (_mode == _AddMode.single) ...[
                BlocBuilder<EmployeeBloc, EmployeeState>(
                  builder: (context, state) {
                    final list = state is EmployeeLoadedState
                        ? state.employees
                        : const <EmployeeModel>[];
                    return DropdownButtonFormField<int>(
                      initialValue: _empId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Employee',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: list
                          .where((e) => e.empId != null)
                          .map((e) => DropdownMenuItem<int>(
                        value: e.empId,
                        child: Text(
                          '${e.perName ?? ''} '
                              '${e.perLastName ?? ''} '
                              '(${e.empPosition ?? ''})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _empId = v),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _status == 'Absent'
                            ? null
                            : () async {
                          final t = await _pickTime(_in);
                          if (t != null && mounted) {
                            setState(() => _in = t);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Check-in',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          child: Text(fmt(_in)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _status == 'Absent'
                            ? null
                            : () async {
                          final t = await _pickTime(_out);
                          if (t != null && mounted) {
                            setState(() => _out = t);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Check-out',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          child: Text(fmt(_out)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ── All active: banner + in/out ──────────────────────
              if (_mode == _AddMode.all) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                    scheme.primaryContainer.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will insert an attendance row for every '
                              'active employee on the selected date. '
                              'Employees who already have a row for that '
                              'date will be skipped.',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _status == 'Absent'
                            ? null
                            : () async {
                          final t = await _pickTime(_in);
                          if (t != null && mounted) {
                            setState(() => _in = t);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Check-in',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          child: Text(fmt(_in)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _status == 'Absent'
                            ? null
                            : () async {
                          final t = await _pickTime(_out);
                          if (t != null && mounted) {
                            setState(() => _out = t);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Check-out',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          child: Text(fmt(_out)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Multiple: employee selection grid ────────────────
              if (_mode == _AddMode.multiple) ...[
                Row(
                  children: [
                    Text(
                      'Employees (${_rows.length} selected)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDialog<Set<int>>(
                          context: context,
                          useRootNavigator: true,
                          builder: (_) => _EmployeeMultiSelectDialog(
                            initial: _rows.keys.toSet(),
                          ),
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _rows.removeWhere(
                                    (k, _) => !picked.contains(k));
                            for (final id in picked) {
                              _rows.putIfAbsent(
                                id,
                                    () => (
                                inT: const TimeOfDay(hour: 8, minute: 0),
                                outT:
                                const TimeOfDay(hour: 16, minute: 0),
                                status: 'Present',
                                ),
                              );
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.group_add, size: 16),
                      label: const Text('Pick employees'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _rows.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No employees selected yet.\n'
                            'Use "Pick employees" to add rows.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                      : BlocBuilder<EmployeeBloc, EmployeeState>(
                    builder: (context, state) {
                      final list = state is EmployeeLoadedState
                          ? state.employees
                          : const <EmployeeModel>[];
                      final ids = _rows.keys.toList();
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: ids.length,
                        separatorBuilder: (_, _) =>
                        const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final id = ids[i];
                          final r = _rows[id]!;
                          final emp = list.firstWhere(
                                (e) => e.empId == id,
                            orElse: () => EmployeeModel(empId: id),
                          );
                          return _multiRowTile(
                              context, emp, id, r);
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _multiRowTile(
      BuildContext context,
      EmployeeModel emp,
      int id,
      ({TimeOfDay? inT, TimeOfDay? outT, String status}) r,
      ) {
    final scheme = Theme.of(context).colorScheme;

    String fmt(TimeOfDay? t) => t == null
        ? '--:--'
        : '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '${emp.perName ?? ''} ${emp.perLastName ?? ''}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 100,
            child: DropdownButtonFormField<String>(
              initialValue: r.status,
              isDense: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: OutlineInputBorder(),
              ),
              items: _statuses
                  .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s,
                    style: const TextStyle(fontSize: 12)),
              ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _rows[id] =
                  (inT: r.inT, outT: r.outT, status: v);
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: r.status == 'Absent'
                ? null
                : () async {
              final t = await _pickTime(r.inT);
              if (t != null && mounted) {
                setState(() {
                  _rows[id] =
                  (inT: t, outT: r.outT, status: r.status);
                });
              }
            },
            child: Container(
              width: 72,
              padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                fmt(r.inT),
                style: TextStyle(
                  fontSize: 12,
                  color: r.status == 'Absent'
                      ? scheme.outline
                      : scheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: r.status == 'Absent'
                ? null
                : () async {
              final t = await _pickTime(r.outT);
              if (t != null && mounted) {
                setState(() {
                  _rows[id] =
                  (inT: r.inT, outT: t, status: r.status);
                });
              }
            },
            child: Container(
              width: 72,
              padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                fmt(r.outT),
                style: TextStyle(
                  fontSize: 12,
                  color: r.status == 'Absent'
                      ? scheme.outline
                      : scheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Remove',
            icon: Icon(Icons.close, size: 16, color: scheme.error),
            onPressed: () {
              setState(() => _rows.remove(id));
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Multi-select employee picker
// ═══════════════════════════════════════════════════════════════════
class _EmployeeMultiSelectDialog extends StatefulWidget {
  final Set<int> initial;
  const _EmployeeMultiSelectDialog({required this.initial});

  @override
  State<_EmployeeMultiSelectDialog> createState() =>
      _EmployeeMultiSelectDialogState();
}

class _EmployeeMultiSelectDialogState
    extends State<_EmployeeMultiSelectDialog> {
  late final Set<int> _picked = {...widget.initial};
  final TextEditingController _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeBloc, EmployeeState>(
      builder: (context, state) {
        final all = state is EmployeeLoadedState
            ? state.employees
            : const <EmployeeModel>[];
        final list = all
            .where((e) => e.empId != null)
            .where((e) {
          if (_q.isEmpty) return true;
          final hay =
          '${e.perName ?? ''} ${e.perLastName ?? ''} '
              '${e.empPosition ?? ''}'.toLowerCase();
          return hay.contains(_q.toLowerCase());
        })
            .toList();

        return AlertDialog(
          title: const Text('Pick employees'),
          content: SizedBox(
            width: 420,
            height: 460,
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 18),
                    hintText: 'Search…',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _q = v),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final e = list[i];
                      final id = e.empId!;
                      return CheckboxListTile(
                        value: _picked.contains(id),
                        dense: true,
                        title: Text(
                          '${e.perName ?? ''} ${e.perLastName ?? ''}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          e.empPosition ?? '',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _picked.add(id);
                          } else {
                            _picked.remove(id);
                          }
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_picked),
              child: Text('Select (${_picked.length})'),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EDIT dialog
// ═══════════════════════════════════════════════════════════════════
class AttendanceEditDialog extends StatefulWidget {
  final AttendanceModel record;
  final String usrName;
  const AttendanceEditDialog({
    super.key,
    required this.record,
    required this.usrName,
  });

  @override
  State<AttendanceEditDialog> createState() =>
      _AttendanceEditDialogState();
}

class _AttendanceEditDialogState extends State<AttendanceEditDialog> {
  late String _status;
  TimeOfDay? _in;
  TimeOfDay? _out;
  String? _error;
  bool _submitting = false;

  static const _statuses = ['Present', 'Absent', 'Late', 'Leave'];

  @override
  void initState() {
    super.initState();
    _status = widget.record.emaStatus ?? 'Present';
    _in = _parseTime(widget.record.emaCheckedIn);
    _out = _parseTime(widget.record.emaCheckedOut);
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _time24(TimeOfDay? t) => t == null
      ? '00:00:00'
      : '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:00';

  Future<TimeOfDay?> _pickTime(TimeOfDay? init) => showTimePicker(
    context: context,
    initialTime: init ?? const TimeOfDay(hour: 8, minute: 0),
  );

  void _submit() {
    if (_submitting) return;
    setState(() => _error = null);

    if (_status != 'Absent' && (_in == null || _out == null)) {
      setState(() => _error = 'Please pick check-in and check-out.');
      return;
    }

    setState(() => _submitting = true);

    final rec = {
      'emaID': widget.record.emaID,
      'emaEmployee': widget.record.emaEmployee,
      'emaCheckedIn': _status == 'Absent' ? '00:00:00' : _time24(_in),
      'emaCheckedOut':
      _status == 'Absent' ? '00:00:00' : _time24(_out),
      'emaStatus': _status,
    };

    context.read<AttendanceBloc>().add(UpdateAttendanceEvent(
      usrName: widget.usrName,
      records: [rec],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    String fmt(TimeOfDay? t) => t == null
        ? '--:--'
        : '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';

    return BlocListener<AttendanceBloc, AttendanceState>(
      listenWhen: (p, c) =>
      c is AttendanceSavedState || c is AttendanceErrorState,
      listener: (context, state) {
        if (state is AttendanceSavedState) {
          if (mounted) Navigator.of(context).pop(true);
        } else if (state is AttendanceErrorState) {
          if (mounted) {
            setState(() {
              _submitting = false;
              _error = state.message;
            });
          }
        }
      },
      child: ZFormDialog(
        title: 'Edit attendance',
        icon: Icons.edit_calendar_outlined,
        errorMessage: _error,
        isButtonEnabled: !_submitting,
        actionLabel: _submitting
            ? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.surface,
          ),
        )
            : Text(tr.update),
        onAction: _submit,
        width: 460,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.record.fullName ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${widget.record.empPosition ?? ''}  ·  '
                    '${widget.record.emaDate ?? ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _statuses
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s),
                ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _status == 'Absent'
                          ? null
                          : () async {
                        final t = await _pickTime(_in);
                        if (t != null && mounted) {
                          setState(() => _in = t);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Check-in',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: Text(fmt(_in)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _status == 'Absent'
                          ? null
                          : () async {
                        final t = await _pickTime(_out);
                        if (t != null && mounted) {
                          setState(() => _out = t);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Check-out',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: Text(fmt(_out)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}