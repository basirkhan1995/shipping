import 'package:flutter/material.dart';

import '../../../../../../../Features/zdropdown.dart';
import '../../../../../../../l10n/app_localizations.dart';

enum EmpSalaryCalcBase {
  monthly,
  hourly;

  String toDatabaseValue() {
    switch (this) {
      case EmpSalaryCalcBase.monthly: return "Monthly";
      case EmpSalaryCalcBase.hourly: return "Hourly";
    }
  }

  static EmpSalaryCalcBase fromDatabaseValue(String value) {
    switch (value) {
      case "Monthly": return EmpSalaryCalcBase.monthly;
      case "Hourly": return EmpSalaryCalcBase.hourly;
      default: return EmpSalaryCalcBase.monthly;
    }
  }
}

/// Translator for EmpSalaryCalcBase
class SalaryCalcBaseTranslator {
  static String getTranslated(BuildContext context, EmpSalaryCalcBase base) {
    final t = AppLocalizations.of(context)!;

    switch (base) {
      case EmpSalaryCalcBase.monthly: return t.monthly;
      case EmpSalaryCalcBase.hourly: return t.hourly;
    }
  }

  static String getTranslatedFromDb(BuildContext context, String value) {
    final base = EmpSalaryCalcBase.fromDatabaseValue(value);
    return getTranslated(context, base);
  }

  static List<Map<String, dynamic>> getTranslatedList(BuildContext context) {
    return EmpSalaryCalcBase.values.map((base) {
      return {
        "base": base,
        "translatedName": getTranslated(context, base),
        "dbValue": base.toDatabaseValue(),
      };
    }).toList();
  }
}


/// ===============================================================
///  DROPDOWN: Salary Calculation Base
/// ===============================================================

class SalaryCalcBaseDropdown extends StatefulWidget {
  final EmpSalaryCalcBase? selectedBase;
  final Function(EmpSalaryCalcBase) onSelected;

  const SalaryCalcBaseDropdown({
    super.key,
    this.selectedBase,
    required this.onSelected,
  });

  @override
  State<SalaryCalcBaseDropdown> createState() => _SalaryCalcBaseDropdownState();
}

class _SalaryCalcBaseDropdownState extends State<SalaryCalcBaseDropdown> {
  late EmpSalaryCalcBase _selectedBase;

  @override
  void initState() {
    super.initState();
    _selectedBase = widget.selectedBase ?? EmpSalaryCalcBase.monthly;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelected(_selectedBase);
    });
  }

  @override
  void didUpdateWidget(covariant SalaryCalcBaseDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedBase != null &&
        widget.selectedBase != _selectedBase) {
      setState(() => _selectedBase = widget.selectedBase!);
    }
  }

  void _handleSelected(EmpSalaryCalcBase base) {
    setState(() => _selectedBase = base);
    widget.onSelected(base);
  }

  @override
  Widget build(BuildContext context) {
    return ZDropdown<EmpSalaryCalcBase>(
      title: AppLocalizations.of(context)!.salaryBased,
      items: EmpSalaryCalcBase.values.toList(),
      itemLabel: (base) => SalaryCalcBaseTranslator.getTranslated(context, base),
      selectedItem: _selectedBase,
      onItemSelected: _handleSelected,
      leadingBuilder: (base) => _getIcon(base),
    );
  }

  Widget _getIcon(EmpSalaryCalcBase base) {
    final icon = switch (base) {
      EmpSalaryCalcBase.monthly => Icons.calendar_month_rounded,
      EmpSalaryCalcBase.hourly => Icons.access_time_rounded,
    };
    return Icon(icon, size: 20);
  }
}

