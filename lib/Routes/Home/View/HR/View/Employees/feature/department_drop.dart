import 'package:flutter/material.dart';

import '../../../../../../../Features/Other/zdropdown.dart';
import '../../../../../../../l10n/app_localizations.dart';

/// =======================
///   Department ENUM
/// =======================

enum EmpDepartment {
  executiveManagement,
  hr,
  operation,
  finance,
  it,
  audit,
  procurement,
  marketing,
  sales,
  customerService,
  legal;

  String toDatabaseValue() {
    switch (this) {
      case EmpDepartment.executiveManagement: return "Executive Management";
      case EmpDepartment.hr: return "HR";
      case EmpDepartment.operation: return "Operation";
      case EmpDepartment.finance: return "Finance";
      case EmpDepartment.it: return "IT";
      case EmpDepartment.audit: return "Audit";
      case EmpDepartment.procurement: return "Procurement";
      case EmpDepartment.marketing: return "Marketing";
      case EmpDepartment.sales: return "Estimate";
      case EmpDepartment.customerService: return "Customer Service";
      case EmpDepartment.legal: return "Legal";
    }
  }

  static EmpDepartment fromDatabaseValue(String value) {
    switch (value) {
      case "Executive Management": return EmpDepartment.executiveManagement;
      case "HR": return EmpDepartment.hr;
      case "Operation": return EmpDepartment.operation;
      case "Finance": return EmpDepartment.finance;
      case "IT": return EmpDepartment.it;
      case "Audit": return EmpDepartment.audit;
      case "Procurement": return EmpDepartment.procurement;
      case "Marketing": return EmpDepartment.marketing;
      case "Estimate": return EmpDepartment.sales;
      case "Customer Service": return EmpDepartment.customerService;
      case "Legal": return EmpDepartment.legal;
      default: return EmpDepartment.operation;
    }
  }
}

/// =======================
/// Department Translator
/// =======================

class DepartmentTranslator {
  static String getTranslatedDepartment(BuildContext context, EmpDepartment dep) {
    final t = AppLocalizations.of(context)!;

    switch (dep) {
      case EmpDepartment.executiveManagement: return t.executiveManagement;
      case EmpDepartment.hr: return t.hr;
      case EmpDepartment.operation: return t.operation;
      case EmpDepartment.finance: return t.finance;
      case EmpDepartment.it: return t.it;
      case EmpDepartment.audit: return t.audit;
      case EmpDepartment.procurement: return t.procurement;
      case EmpDepartment.marketing: return t.marketing;
      case EmpDepartment.sales: return t.sales;
      case EmpDepartment.customerService: return t.customerService;
      case EmpDepartment.legal: return t.legal;
    }
  }

  static String getTranslatedDepartmentFromDb(
      BuildContext context, String dbValue) {
    final dep = EmpDepartment.fromDatabaseValue(dbValue);
    return getTranslatedDepartment(context, dep);
  }

  static List<Map<String, dynamic>> getTranslatedDepartmentList(
      BuildContext context) {
    return EmpDepartment.values.map((dep) {
      return {
        "department": dep,
        "translatedName": getTranslatedDepartment(context, dep),
        "databaseValue": dep.toDatabaseValue(),
      };
    }).toList();
  }
}

/// =======================
/// Department Dropdown UI
/// =======================

class DepartmentDropdown extends StatefulWidget {
  final EmpDepartment? selectedDepartment;
  final Function(EmpDepartment) onDepartmentSelected;

  const DepartmentDropdown({
    super.key,
    this.selectedDepartment,
    required this.onDepartmentSelected,
  });

  @override
  State<DepartmentDropdown> createState() => _DepartmentDropdownState();
}

class _DepartmentDropdownState extends State<DepartmentDropdown> {
  late EmpDepartment _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _selectedDepartment =
        widget.selectedDepartment ?? EmpDepartment.values.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDepartmentSelected(_selectedDepartment);
    });
  }

  @override
  void didUpdateWidget(covariant DepartmentDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDepartment != null &&
        widget.selectedDepartment != _selectedDepartment) {
      setState(() {
        _selectedDepartment = widget.selectedDepartment!;
      });
    }
  }

  void _handleSelected(EmpDepartment dep) {
    setState(() => _selectedDepartment = dep);
    widget.onDepartmentSelected(dep);
  }

  @override
  Widget build(BuildContext context) {
    return ZDropdown<EmpDepartment>(
      title: AppLocalizations.of(context)!.department,
      items: EmpDepartment.values.toList(),
      itemLabel: (dep) => DepartmentTranslator.getTranslatedDepartment(context, dep),
      selectedItem: _selectedDepartment,
      onItemSelected: _handleSelected,
      leadingBuilder: (dep) => _getDepartmentIcon(dep),
    );
  }

  Widget _getDepartmentIcon(EmpDepartment dep) {
    final icon = switch (dep) {
      EmpDepartment.executiveManagement => Icons.account_balance_rounded,
      EmpDepartment.hr => Icons.group_rounded,
      EmpDepartment.operation => Icons.settings_applications_rounded,
      EmpDepartment.finance => Icons.attach_money_rounded,
      EmpDepartment.it => Icons.computer_rounded,
      EmpDepartment.audit => Icons.fact_check_rounded,
      EmpDepartment.procurement => Icons.shopping_cart_rounded,
      EmpDepartment.marketing => Icons.campaign_rounded,
      EmpDepartment.sales => Icons.sell_rounded,
      EmpDepartment.customerService => Icons.support_agent_rounded,
      EmpDepartment.legal => Icons.gavel_rounded,
    };

    return Icon(icon, size: 20);
  }
}
