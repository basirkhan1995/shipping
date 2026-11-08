import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../../Stakeholder/bloc/stakeholder_bloc.dart';
import '../../../Stakeholder/model/stk_model.dart';
import '../../../Stakeholder/stk_form.dart';
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
  // ── Controllers ─────────────────────────────────────────────────
  late final TextEditingController _stakeholderCtrl;
  late final TextEditingController _accountCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _hireDateCtrl;
  late final TextEditingController _endDateCtrl;

  // ── Focus nodes (text fields only) ──────────────────────────────
  final fnStakeholder = FocusNode(debugLabel: 'stakeholder');
  final fnAccount = FocusNode(debugLabel: 'account');
  final fnPosition = FocusNode(debugLabel: 'position');
  final fnSalary = FocusNode(debugLabel: 'salary');
  final fnTaxInfo = FocusNode(debugLabel: 'taxInfo');

  // ── Dropdown selections ─────────────────────────────────────────
  late EmpDepartment _department;
  late EmpPaymentMethod _paymentMethod;
  late EmpSalaryCalcBase _salaryBase;
  late int _status;

  // ── Linked model picks ──────────────────────────────────────────
  StakeholdersModel? _selectedStakeholder;
  StkAccountModel? _selectedAccount;
  int? _perId;
  int? _accNumber;

  // ── Validation / server feedback ────────────────────────────────
  String? _error;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    _stakeholderCtrl = TextEditingController();
    _accountCtrl = TextEditingController(
      text: e?.empSalAccount?.toString() ?? '',
    );
    _positionCtrl = TextEditingController(text: e?.empPosition ?? '');
    _salaryCtrl = TextEditingController(text: e?.empSalary ?? '');
    _taxCtrl = TextEditingController(text: e?.empTaxInfo ?? '');
    _hireDateCtrl = TextEditingController(
      text: e?.empHireDate == null ? '' : _fmtDate(e!.empHireDate!),
    );
    _endDateCtrl = TextEditingController(text: e?.empEndDate ?? '');

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

    _perId = e?.empPersonal ?? e?.perId;
    _accNumber = e?.empSalAccount;

    if (_isEdit && _perId != null) {
      _stakeholderCtrl.text =
          '${e?.perName ?? ''} ${e?.perLastName ?? ''}'.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<StakeholderBloc>().add(GetStakeholderByIdEvent(_perId!));
        context
            .read<StkAccountsBloc>()
            .add(LoadStkAccountsEvent(perId: _perId));
      });
    }
  }

  @override
  void dispose() {
    _stakeholderCtrl.dispose();
    _accountCtrl.dispose();
    _positionCtrl.dispose();
    _salaryCtrl.dispose();
    _taxCtrl.dispose();
    _hireDateCtrl.dispose();
    _endDateCtrl.dispose();

    fnStakeholder.dispose();
    fnAccount.dispose();
    fnPosition.dispose();
    fnSalary.dispose();
    fnTaxInfo.dispose();

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

  void _applyStakeholder(StakeholdersModel s) {
    setState(() {
      _perId = s.perId;
      _selectedStakeholder = s;
      _accountCtrl.clear();
      _selectedAccount = null;
      _accNumber = null;
    });
    context.read<StkAccountsBloc>().add(LoadStkAccountsEvent(perId: _perId));
  }

  void _applyStakeholderById(StakeholdersModel s) {
    setState(() {
      _selectedStakeholder = s;
      _stakeholderCtrl.text =
          '${s.perName ?? ''} ${s.perLastName ?? ''}'.trim();
    });
  }

  void _applyAccount(StkAccountModel a) {
    setState(() {
      _selectedAccount = a;
      _accNumber = a.accNumber;
    });
  }

  EmployeeModel _buildPayload() {
    return EmployeeModel(
      empId: widget.existing?.empId,
      empPersonal: _perId,
      empSalAccount: _selectedAccount?.accNumber ?? _accNumber,
      // ── Email / fingerprint fields removed from the form:
      //    keep existing values on edit, null on add.
      empEmail: widget.existing?.empEmail,
      empFingerprint: widget.existing?.empFingerprint,
      empHireDate: DateTime.tryParse(_hireDateCtrl.text.trim()),
      empDepartment: _department.toDatabaseValue(),
      empPosition: _positionCtrl.text.trim(),
      empSalCalcBase: _salaryBase.toDatabaseValue(),
      empPmntMethod: _paymentMethod.toDatabaseValue(),
      empSalary: _salaryCtrl.text.trim(),
      empTaxInfo: _taxCtrl.text.trim(),
      empStatus: _status,
      empEndDate: _status == 1 ? null : _endDateCtrl.text.trim(),
      perId: _perId,
      perName: _selectedStakeholder?.perName ?? widget.existing?.perName,
      perLastName:
      _selectedStakeholder?.perLastName ?? widget.existing?.perLastName,
      perPhone: _selectedStakeholder?.perPhone ?? widget.existing?.perPhone,
      perEmail: _selectedStakeholder?.perEmail ?? widget.existing?.perEmail,
      empImage: widget.existing?.empImage,
      isDriver: widget.existing?.isDriver,
    );
  }

  void _submit() {
    if (_submitting) return;

    final tr = AppLocalizations.of(context)!;
    setState(() => _error = null);

    if (!_isEdit && _perId == null) {
      setState(() => _error = tr.required(tr.individuals));
      return;
    }
    if (_accNumber == null) {
      setState(() => _error = tr.required(tr.accounts));
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
      child: MultiBlocListener(
        listeners: [
          BlocListener<StakeholderBloc, StakeholderState>(
            listenWhen: (p, c) => c is GetStakeholderByIdSuccessState,
            listener: (context, state) {
              if (state is GetStakeholderByIdSuccessState) {
                _applyStakeholderById(state.stakeholder);
              }
            },
          ),
          BlocListener<StkAccountsBloc, StkAccountsState>(
            listenWhen: (p, c) =>
            c is StkAccountsLoadedState && _accNumber != null,
            listener: (context, state) {
              if (state is StkAccountsLoadedState && _accNumber != null) {
                for (final a in state.accounts) {
                  if (a.accNumber == _accNumber) {
                    _applyAccount(a);
                    _accountCtrl.text = '${a.accNumber} | ${a.accName}';
                    break;
                  }
                }
              }
            },
          ),
        ],
        child: ZFormDialog(
          title: _isEdit ? tr.editEmployee.toUpperCase() : tr.addEmployee.toUpperCase(),
          icon: _isEdit ? Icons.edit_outlined : Icons.person_add_alt_1,
          errorMessage: _error,
          isButtonEnabled: !_submitting,
          actionLabel: _submitting
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.surface,
            ),
          )
              : Text(_isEdit ? tr.update : tr.save),
          onAction: _submit,
          width: 680,
          child: FocusTraversalGroup(
            child: Form(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Stakeholder picker (add only) ─────────────
                    if (!_isEdit) ...[
                      GenericTextField<StakeholdersModel, StakeholderBloc,
                          StakeholderState>(
                        focusNode: fnStakeholder,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => fnAccount.requestFocus(),
                        showAllOnFocus: true,
                        controller: _stakeholderCtrl,
                        title: tr.individuals,
                        hintText: tr.individuals,
                        trailing: IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const StakeholderFormDialog(),
                            );
                          },
                          icon: const Icon(Icons.add),
                        ),
                        isRequired: true,
                        bloc: context.read<StakeholderBloc>(),
                        fetchAllFunction: (bloc) =>
                            bloc.add(const GetStakeholdersEvent()),
                        searchFunction: (bloc, query) =>
                            bloc.add(SearchStakeholdersEvent(query)),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr.required(tr.individuals);
                          }
                          return null;
                        },
                        itemBuilder: (context, s) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 8),
                          child: Text(
                            '${s.perName ?? ''} ${s.perLastName ?? ''}'.trim(),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        itemToString: (s) =>
                            '${s.perName ?? ''} ${s.perLastName ?? ''}'.trim(),
                        stateToLoading: (state) =>
                        state is GetStakeholdersLoadingState,
                        loadingBuilder: (context) => const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        stateToItems: (state) {
                          if (state is GetStakeholdersSuccessState) {
                            return state.stakeholders;
                          }
                          return const [];
                        },
                        onSelected: _applyStakeholder,
                        noResultsText: tr.noDataFound,
                        showClearButton: true,
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ── Account picker ────────────────────────────
                    GenericTextField<StkAccountModel, StkAccountsBloc,
                        StkAccountsState>(
                      focusNode: fnAccount,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => fnPosition.requestFocus(),
                      showAllOnFocus: true,
                      controller: _accountCtrl,
                      title: tr.accounts,
                      hintText: tr.accNameOrNumber,
                      isRequired: true,
                      bloc: context.read<StkAccountsBloc>(),
                      fetchAllFunction: (bloc) =>
                          bloc.add(LoadStkAccountsEvent(perId: _perId)),
                      searchFunction: (bloc, query) => bloc.add(
                          LoadStkAccountsEvent(perId: _perId, query: query)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr.required(tr.accounts);
                        }
                        return null;
                      },
                      itemBuilder: (context, a) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 8),
                        child: Text(
                          '${a.accNumber} | ${a.accName}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      itemToString: (a) => '${a.accNumber} | ${a.accName}',
                      stateToLoading: (state) =>
                      state is StkAccountsLoadingState,
                      loadingBuilder: (context) => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      stateToItems: (state) {
                        if (state is StkAccountsLoadedState) {
                          return state.accounts;
                        }
                        return const [];
                      },
                      onSelected: _applyAccount,
                      noResultsText: tr.noDataFound,
                      showClearButton: true,
                    ),
                    const SizedBox(height: 10),

                    // ── Position (full width) ─────────────────────
                    ZTextFieldEntitled(
                      focusNode: fnPosition,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => fnSalary.requestFocus(),
                      title: tr.position,
                      controller: _positionCtrl,
                      isRequired: true,
                      autoFocus: false,
                    ),
                    const SizedBox(height: 10),

                    // ── Department / payment method (no focus nodes) ─
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
                            onSelected: (m) =>
                                setState(() => _paymentMethod = m),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Salary base (no focus node) / salary ──────
                    Row(
                      children: [
                        Expanded(
                          child: SalaryCalcBaseDropdown(
                            selectedBase: _salaryBase,
                            onSelected: (b) =>
                                setState(() => _salaryBase = b),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ZTextFieldEntitled(
                            focusNode: fnSalary,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => fnTaxInfo.requestFocus(),
                            title: tr.salary,
                            controller: _salaryCtrl,
                            isRequired: true,
                            keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
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

                    // ── Hire / end date ───────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                _pickDate(_hireDateCtrl, endDate: false),
                            child: IgnorePointer(
                              child: ZTextFieldEntitled(
                                title: tr.hireDate,
                                controller: _hireDateCtrl,
                                readOnly: true,
                                trailing: const Icon(Icons.calendar_month,
                                    size: 18),
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
                                ? () =>
                                _pickDate(_endDateCtrl, endDate: true)
                                : null,
                            child: IgnorePointer(
                              child: ZTextFieldEntitled(
                                title: tr.endDate,
                                controller: _endDateCtrl,
                                readOnly: true,
                                isEnabled: _status == 0,
                                trailing: const Icon(Icons.calendar_month,
                                    size: 18),
                                autoFocus: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Tax info (full width) ─────────────────────
                    ZTextFieldEntitled(
                      focusNode: fnTaxInfo,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      title: tr.taxInfo,
                      controller: _taxCtrl,
                      autoFocus: false,
                    ),
                    const SizedBox(height: 12),

                    // ── Status toggle (edit only) ─────────────────
                    if (_isEdit)
                      SwitchListTile(
                        contentPadding: EdgeInsets.all(8),
                        title: Text(
                          _status == 1 ? tr.active : tr.inactive,
                          style: const TextStyle(fontSize: 15,fontWeight: FontWeight.bold),
                        ),
                        value: _status == 1,
                        onChanged: (v) =>
                            setState(() => _status = v ? 1 : 0),
                      ),
                  ],
                ),
              ),
            ),
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