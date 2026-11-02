import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import 'bloc/employee_bloc.dart';
import 'feature/department_drop.dart';
import 'feature/payment_method_drop.dart';
import 'feature/salary_cal_drop.dart';
import 'model/emp_model.dart';

class EmployeeFormDialog extends StatefulWidget {
  final EmployeeModel? existing;
  const EmployeeFormDialog({super.key, this.existing});

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _accountCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _fingerprintCtrl;
  late final TextEditingController _hireDateCtrl;
  late final TextEditingController _endDateCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _lastNameCtrl;

  late EmpDepartment _department;
  late EmpPaymentMethod _paymentMethod;
  late EmpSalaryCalcBase _salaryBase;
  late int _status;

  String? _error;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    _emailCtrl = TextEditingController(text: e?.empEmail ?? e?.perEmail ?? '');
    _accountCtrl =
        TextEditingController(text: e?.empSalAccount?.toString() ?? '');
    _positionCtrl = TextEditingController(text: e?.empPosition ?? '');
    _salaryCtrl = TextEditingController(text: e?.empSalary ?? '');
    _taxCtrl = TextEditingController(text: e?.empTaxInfo ?? '');
    _fingerprintCtrl = TextEditingController(text: e?.empFingerprint ?? '');
    _hireDateCtrl = TextEditingController(
      text: e?.empHireDate == null ? '' : _fmtDate(e!.empHireDate!),
    );
    _endDateCtrl = TextEditingController(text: e?.empEndDate ?? '');
    _phoneCtrl = TextEditingController(text: e?.perPhone ?? '');
    _nameCtrl = TextEditingController(text: e?.perName ?? '');
    _lastNameCtrl = TextEditingController(text: e?.perLastName ?? '');

    _department = e == null
        ? EmpDepartment.values.first
        : EmpDepartment.fromDatabaseValue(e.empDepartment ?? '');
    _paymentMethod = e == null
        ? EmpPaymentMethod.monthly
        : EmpPaymentMethod.fromDatabaseValue(e.empPmntMethod ?? '');
    _salaryBase = e == null
        ? EmpSalaryCalcBase.monthly
        : EmpSalaryCalcBase.fromDatabaseValue(e.empSalCalcBase ?? '');
    _status = e?.empStatus ?? 1;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _accountCtrl.dispose();
    _positionCtrl.dispose();
    _salaryCtrl.dispose();
    _taxCtrl.dispose();
    _fingerprintCtrl.dispose();
    _hireDateCtrl.dispose();
    _endDateCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
      TextEditingController ctrl, {
        required bool endDate,
      }) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(ctrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      setState(() => ctrl.text = _fmtDate(picked));
    }
  }

  static String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-"
          "${d.month.toString().padLeft(2, '0')}-"
          "${d.day.toString().padLeft(2, '0')}";

  EmployeeModel _buildPayload() {
    return EmployeeModel(
      empId: widget.existing?.empId,
      empPersonal: widget.existing?.empPersonal ?? widget.existing?.perId,
      empSalAccount: int.tryParse(_accountCtrl.text.trim()),
      empEmail: _emailCtrl.text.trim(),
      empHireDate: DateTime.tryParse(_hireDateCtrl.text.trim()),
      empDepartment: _department.toDatabaseValue(),
      empPosition: _positionCtrl.text.trim(),
      empSalCalcBase: _salaryBase.toDatabaseValue(),
      empPmntMethod: _paymentMethod.toDatabaseValue(),
      empSalary: _salaryCtrl.text.trim(),
      empTaxInfo: _taxCtrl.text.trim(),
      empFingerprint: _fingerprintCtrl.text.trim(),
      empStatus: _status,
      empEndDate: _status == 1 ? null : _endDateCtrl.text.trim(),
      perId: widget.existing?.perId,
      perName: widget.existing?.perName,
      perLastName: widget.existing?.perLastName,
      perPhone: widget.existing?.perPhone,
      perEmail: widget.existing?.perEmail,
      empImage: widget.existing?.empImage,
      isDriver: widget.existing?.isDriver,
    );
  }

  void _submit() {
    final tr = AppLocalizations.of(context)!;
    setState(() => _error = null);

    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = tr.fieldRequired);
      return;
    }
    if (_positionCtrl.text.trim().isEmpty) {
      setState(() => _error = tr.fieldRequired);
      return;
    }
    if (_salaryCtrl.text.trim().isEmpty ||
        double.tryParse(_salaryCtrl.text.trim()) == null) {
      setState(() => _error = tr.salaryMustBeNumber);
      return;
    }

    setState(() => _submitting = true);

    final payload = _buildPayload();
    if (_isEdit) {
      context.read<EmployeeBloc>().add(UpdateEmployeeEvent(payload));
    } else {
      context.read<EmployeeBloc>().add(AddEmployeeEvent(payload));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return BlocListener<EmployeeBloc, EmployeeState>(
      listenWhen: (p, c) =>
      c is EmployeeSavedState || c is EmployeeErrorState,
      listener: (context, state) {
        if (state is EmployeeSavedState) {
          if (mounted) Navigator.of(context).pop(true);
        } else if (state is EmployeeErrorState) {
          if (mounted) {
            setState(() {
              _submitting = false;
              _error = _translateError(tr, state.message);
            });
          }
        }
      },
      child: ZFormDialog(
        title: _isEdit ? tr.editEmployee : tr.addEmployee,
        icon: _isEdit ? Icons.edit_outlined : Icons.person_add_alt_1,
        errorMessage: _error,           // ← banner now shows
        isButtonEnabled: !_submitting,  // ← disabled while submitting
        actionLabel: Text(_isEdit ? tr.update : tr.save),
        onAction: _submit,
        width: 680,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: name / last name
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: tr.firstName,
                      controller: _nameCtrl,
                      readOnly: true,
                      isEnabled: false,
                      autoFocus: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: tr.lastName,
                      controller: _lastNameCtrl,
                      readOnly: true,
                      isEnabled: false,
                      autoFocus: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2: email / phone
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: tr.email,
                      controller: _emailCtrl,
                      isRequired: true,
                      keyboardType: TextInputType.emailAddress,
                      autoFocus: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: tr.phone,
                      controller: _phoneCtrl,
                      readOnly: true,
                      isEnabled: false,
                      autoFocus: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 3: position / account
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: tr.position,
                      controller: _positionCtrl,
                      isRequired: true,
                      autoFocus: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: tr.salaryAccount,
                      controller: _accountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormat: [FilteringTextInputFormatter.digitsOnly],
                      autoFocus: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 4: department / payment method
              Row(
                children: [
                  Expanded(
                    child: DepartmentDropdown(
                      selectedDepartment: _department,
                      onDepartmentSelected: (d) =>
                          setState(() => _department = d),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PaymentMethodDropdown(
                      selectedMethod: _paymentMethod,
                      onSelected: (m) => setState(() => _paymentMethod = m),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 5: salary base / salary
              Row(
                children: [
                  Expanded(
                    child: SalaryCalcBaseDropdown(
                      selectedBase: _salaryBase,
                      onSelected: (b) => setState(() => _salaryBase = b),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: tr.salary,
                      controller: _salaryCtrl,
                      isRequired: true,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      inputFormat: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      autoFocus: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 6: hire date / end date (tap to pick)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _pickDate(_hireDateCtrl, endDate: false),
                      child: IgnorePointer(
                        child: ZTextFieldEntitled(
                          title: tr.hireDate,
                          controller: _hireDateCtrl,
                          readOnly: true,
                          trailing:
                          const Icon(Icons.calendar_month, size: 18),
                          autoFocus: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _status == 0
                          ? () => _pickDate(_endDateCtrl, endDate: true)
                          : null,
                      child: IgnorePointer(
                        child: ZTextFieldEntitled(
                          title: tr.endDate,
                          controller: _endDateCtrl,
                          readOnly: true,
                          isEnabled: _status == 0,
                          trailing:
                          const Icon(Icons.calendar_month, size: 18),
                          autoFocus: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 7: TIN / fingerprint
              Row(
                children: [
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: tr.taxInfo,
                      controller: _taxCtrl,
                      autoFocus: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZTextFieldEntitled(
                      title: tr.fingerprint,
                      controller: _fingerprintCtrl,
                      autoFocus: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status toggle (edit only)
              if (_isEdit)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _status == 1 ? tr.active : tr.inactive,
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: _status == 1,
                  onChanged: (v) => setState(() => _status = v ? 1 : 0),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _translateError(AppLocalizations tr, String msg) {
    switch (msg) {
      case 'alreadyEmployed':
      case 'exist':
        return tr.alreadyEmployed;
      case 'empty':
        return tr.fieldRequired;
      default:
        return msg;
    }
  }
}