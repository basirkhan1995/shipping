import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
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

  // ── Single-mode employee picker ────────────────────────────────
  int? _empId;
  final TextEditingController _empCtrl = TextEditingController();
  final FocusNode _empFocus = FocusNode(debugLabel: 'attendance-employee');

  // ── Multiple-mode rows ─────────────────────────────────────────
  final Map<int, ({TimeOfDay? inT, TimeOfDay? outT, String status})> _rows = {};

  String? _error;
  bool _submitting = false;

  static const _statuses = ['Present', 'Absent', 'Late', 'Leave'];

  @override
  void initState() {
    super.initState();
    // Seed with today so `initialDate: DateTime.tryParse(_date ?? '')`
    // is never null on the first build — this avoids ZDatePicker
    // re-triggering didUpdateWidget on every rebuild.
    final now = DateTime.now();
    _date =
    '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _empCtrl.dispose();
    _empFocus.dispose();
    super.dispose();
  }

  /// Safe setter — defers `setState` so it can never run while the widget
  /// tree is building. This is what prevents
  /// "setState() called during build" when ZDatePicker's didUpdateWidget
  /// echoes its `initialDate` back through `onDateChanged`.
  void _setDate(String v) {
    if (!mounted) return;
    if (v.isEmpty || v == _date) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (v == _date) return;
      setState(() => _date = v);
    });
  }

  String? _time24OrNull(TimeOfDay? t) => t == null
      ? null
      : '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:00';

  Future<TimeOfDay?> _pickTime(TimeOfDay? init) => showTimePicker(
    context: context,
    initialTime: init ?? const TimeOfDay(hour: 8, minute: 0),
  );

  void _applyEmployee(EmployeeModel e) {
    setState(() {
      _empId = e.empId;
      _empCtrl.text = _employeeLabel(e);
    });
  }

  static String _employeeLabel(EmployeeModel e) =>
      '${e.perName ?? ''} ${e.perLastName ?? ''}'.trim().isEmpty
          ? 'Employee #${e.empId}'
          : '${e.perName ?? ''} ${e.perLastName ?? ''}'.trim();

  Future<void> _openMultiSelect() async {
    final picked = await showDialog<Set<int>>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (_) => BlocProvider.value(
        value: context.read<EmployeeBloc>(),
        child: EmployeeMultiSelectDialog(initial: _rows.keys.toSet()),
      ),
    );
    if (picked == null || !mounted) return;

    setState(() {
      // Remove employees the user deselected.
      _rows.removeWhere((k, _) => !picked.contains(k));
      // Add new picks with a default open-shift row.
      for (final id in picked) {
        _rows.putIfAbsent(
          id,
              () => (
          inT: const TimeOfDay(hour: 8, minute: 0),
          outT: null,
          status: 'Present',
          ),
        );
      }
    });
  }

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
        _in == null) {
      setState(() => _error = 'Please pick a check-in time.');
      return;
    }
    if (_mode == _AddMode.multiple) {
      final missingIn = _rows.entries.any(
            (e) => e.value.status != 'Absent' && e.value.inT == null,
      );
      if (missingIn) {
        setState(
              () => _error = 'Every non-absent employee needs a check-in time.',
        );
        return;
      }
    }

    setState(() => _submitting = true);

    if (_mode == _AddMode.multiple) {
      final records = _rows.entries.map((e) {
        final isAbsent = e.value.status == 'Absent';
        return {
          'emaEmployee': e.key,
          'emaCheckedIn': isAbsent ? null : _time24OrNull(e.value.inT),
          'emaCheckedOut': isAbsent ? null : _time24OrNull(e.value.outT),
          'emaStatus': e.value.status,
        };
      }).toList();

      context.read<AttendanceBloc>().add(
        AddAttendanceEvent(
          mode: 'multiple',
          usrName: widget.usrName,
          emaDate: _date!,
          records: records,
        ),
      );
    } else if (_mode == _AddMode.all) {
      final isAbsent = _status == 'Absent';
      context.read<AttendanceBloc>().add(
        AddAttendanceEvent(
          mode: 'all',
          usrName: widget.usrName,
          emaDate: _date!,
          emaCheckedIn: isAbsent ? null : _time24OrNull(_in),
          emaCheckedOut: isAbsent ? null : _time24OrNull(_out),
          emaStatus: _status,
        ),
      );
    } else {
      final isAbsent = _status == 'Absent';
      context.read<AttendanceBloc>().add(
        AddAttendanceEvent(
          mode: 'single',
          usrName: widget.usrName,
          emaDate: _date!,
          emaEmployee: _empId,
          emaCheckedIn: isAbsent ? null : _time24OrNull(_in),
          emaCheckedOut: isAbsent ? null : _time24OrNull(_out),
          emaStatus: _status,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    InputDecoration denseField({
      required String label,
      required Color color,
    }) =>
        InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: color, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: color, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: color, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: Colors.red, width: 1.4),
          ),
        );
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Mode selector ───────────────────────────────────
              SegmentedButton<_AddMode>(
                style: const ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ZDatePicker(
                      label: 'Date',
                      initialDate: DateTime.tryParse(_date ?? ''),
                      // Deferred + deduped — never calls setState mid-build.
                      onDateChanged: _setDate,
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
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                      )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Single: employee picker + in/out ─────────────────
              if (_mode == _AddMode.single) ...[
                GenericTextField<EmployeeModel, EmployeeBloc, EmployeeState>(
                  focusNode: _empFocus,
                  textInputAction: TextInputAction.next,
                  controller: _empCtrl,
                  title: 'Employee',
                  hintText: 'Search employee…',
                  isRequired: true,
                  showAllOnFocus: true,
                  bloc: context.read<EmployeeBloc>(),
                  fetchAllFunction: (bloc) =>
                      bloc.add(const LoadEmployeeEvent()),
                  searchFunction: (bloc, query) =>
                      bloc.add(SearchEmployeesEvent(query)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr.fieldRequired;
                    }
                    return null;
                  },
                  itemBuilder: (context, e) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _employeeLabel(e),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        if ((e.empPosition ?? '').isNotEmpty)
                          Text(
                            e.empPosition!,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  itemToString: _employeeLabel,
                  stateToLoading: (state) => state is EmployeeLoadingState,
                  loadingBuilder: (context) => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  stateToItems: (state) {
                    if (state is EmployeeLoadedState) return state.employees;
                    return const [];
                  },
                  onSelected: _applyEmployee,
                  noResultsText: tr.noDataFound,
                  showClearButton: true,
                ),
                const SizedBox(height: 20),
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
                          decoration: denseField(
                            label: 'Check-in',
                            color: scheme.outline.withValues(alpha: .3), // ← your border color
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
                          decoration: denseField(
                            label: 'Check-out (optional)',
                            color: scheme.outline.withValues(alpha: .3),
                          ),
                          child: Text(fmt(_out)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_status != 'Absent' && _in != null && _out == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'No check-out selected — this row will be saved as '
                          'an OPEN shift (incomplete). You can add the checkout '
                          'later from the list.',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
              ],

              // ── All active ───────────────────────────────────────
              if (_mode == _AddMode.all) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: scheme.primary),
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
                            labelText: 'Check-out (optional)',
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

              // ── Multiple: pick-employees button + list ───────────
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
                      onPressed: _openMultiSelect,
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
                          return _multiRowTile(context, emp, id, r);
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
              _employeeLabel(emp),
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                border: OutlineInputBorder(),
              ),
              items: _statuses
                  .map(
                    (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 12)),
                ),
              )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _rows[id] = (inT: r.inT, outT: r.outT, status: v);
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
                  _rows[id] = (inT: t, outT: r.outT, status: r.status);
                });
              }
            },
            child: Container(
              width: 72,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
                  _rows[id] = (inT: r.inT, outT: t, status: r.status);
                });
              }
            },
            child: Container(
              width: 72,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: r.outT == null
                      ? const Color(0xFFF59E0B)
                      : scheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                fmt(r.outT),
                style: TextStyle(
                  fontSize: 12,
                  color: r.status == 'Absent'
                      ? scheme.outline
                      : (r.outT == null
                      ? const Color(0xFFF59E0B)
                      : scheme.onSurface),
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
// EDIT dialog — unchanged
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
  State<AttendanceEditDialog> createState() => _AttendanceEditDialogState();
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
    if (h == 0 && m == 0) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String? _time24OrNull(TimeOfDay? t) => t == null
      ? null
      : '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:00';

  Future<TimeOfDay?> _pickTime(TimeOfDay? init) => showTimePicker(
    context: context,
    initialTime: init ?? const TimeOfDay(hour: 8, minute: 0),
  );

  void _submit() {
    if (_submitting) return;
    setState(() => _error = null);

    if (_status != 'Absent' && _in == null) {
      setState(() => _error = 'Please pick a check-in time.');
      return;
    }

    setState(() => _submitting = true);

    final isAbsent = _status == 'Absent';
    final rec = {
      'emaID': widget.record.emaID,
      'emaEmployee': widget.record.emaEmployee,
      'emaCheckedIn': isAbsent ? null : _time24OrNull(_in),
      'emaCheckedOut': isAbsent ? null : _time24OrNull(_out),
      'emaStatus': _status,
    };

    context.read<AttendanceBloc>().add(
      UpdateAttendanceEvent(usrName: widget.usrName, records: [rec]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    InputDecoration denseField({
      required String label,
      required Color color,
    }) =>
        InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: color, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: color, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: color, width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide(color: Colors.red, width: 1.2),
          ),
        );
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
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    widget.record.emaCompleted
                        ? Icons.check_circle_outline
                        : Icons.timelapse,
                    size: 14,
                    color: widget.record.emaCompleted
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.record.emaCompleted
                        ? 'Completed'
                        : 'Incomplete — waiting for check-out',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.record.emaCompleted
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: denseField(
                  label: 'Status',
                  color: scheme.outline.withValues(alpha: .3), // ← your border color
                ),
                items: _statuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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
                        decoration: InputDecoration(
                          labelText: 'Check-out',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: _out != null
                              ? IconButton(
                            tooltip: 'Clear check-out',
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setState(() => _out = null),
                          )
                              : null,
                        ),
                        child: Text(fmt(_out)),
                      ),
                    ),
                  ),
                ],
              ),
              if (!widget.record.emaCompleted && _out == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Pick a check-out time and save to complete this shift.',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
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
// Multi-select employee picker — search + checkboxes + select-all
// ═══════════════════════════════════════════════════════════════════
class EmployeeMultiSelectDialog extends StatefulWidget {
  final Set<int> initial;
  final String? title;

  const EmployeeMultiSelectDialog({
    super.key,
    this.initial = const {},
    this.title,
  });

  @override
  State<EmployeeMultiSelectDialog> createState() =>
      _EmployeeMultiSelectDialogState();
}

class _EmployeeMultiSelectDialogState
    extends State<EmployeeMultiSelectDialog> {
  late final Set<int> _picked = {...widget.initial};
  final TextEditingController _search = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    final bloc = context.read<EmployeeBloc>();
    if (bloc.state is! EmployeeLoadedState) {
      bloc.add(const LoadEmployeeEvent());
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleAll(List<EmployeeModel> visible) {
    setState(() {
      final visibleIds = visible.map((e) => e.empId).whereType<int>().toSet();
      final allVisiblePicked = visibleIds.every(_picked.contains);
      if (allVisiblePicked) {
        _picked.removeAll(visibleIds);
      } else {
        _picked.addAll(visibleIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 460,
        height: 560,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.group_add, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    widget.title ?? 'Pick employees',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            BlocBuilder<EmployeeBloc, EmployeeState>(
              builder: (context, state) {
                final all = state is EmployeeLoadedState
                    ? state.employees
                    : const <EmployeeModel>[];
                final visible = _filter(all, _q);
                final visibleIds = visible
                    .map((e) => e.empId)
                    .whereType<int>()
                    .toSet();
                final allPicked =
                    visibleIds.isNotEmpty && visibleIds.every(_picked.contains);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, size: 18),
                          hintText: 'Search employees…',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onChanged: (v) => setState(() => _q = v),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: visible.isEmpty
                                ? null
                                : () => _toggleAll(visible),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: allPicked,
                                    tristate: true,
                                    onChanged: visible.isEmpty
                                        ? null
                                        : (_) => _toggleAll(visible),
                                  ),
                                  Text(
                                    allPicked ? 'Deselect all' : 'Select all',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_picked.length} selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<EmployeeBloc, EmployeeState>(
                builder: (context, state) {
                  if (state is EmployeeLoadingState) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final all = state is EmployeeLoadedState
                      ? state.employees
                      : const <EmployeeModel>[];
                  final visible = _filter(all, _q);

                  if (visible.isEmpty) {
                    return Center(
                      child: Text(
                        all.isEmpty
                            ? 'No employees found.'
                            : 'No employees match "$_q".',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = visible[i];
                      final id = e.empId;
                      if (id == null) return const SizedBox.shrink();
                      final isChecked = _picked.contains(id);
                      return CheckboxListTile(
                        value: isChecked,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          '${e.perName ?? ''} ${e.perLastName ?? ''}'.trim(),
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: (e.empPosition ?? '').isEmpty
                            ? null
                            : Text(
                          e.empPosition!,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _picked.add(id);
                            } else {
                              _picked.remove(id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _picked.clear()),
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_picked),
                    child: Text('Select (${_picked.length})'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<EmployeeModel> _filter(List<EmployeeModel> all, String q) {
    final query = q.trim().toLowerCase();
    return all.where((e) => e.empId != null).where((e) {
      if (query.isEmpty) return true;
      final hay = '${e.perName ?? ''} ${e.perLastName ?? ''} '
          '${e.empPosition ?? ''}'
          .toLowerCase();
      return hay.contains(query);
    }).toList();
  }
}