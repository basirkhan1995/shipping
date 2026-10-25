import 'package:flutter/material.dart';

import '../../../../../../../Features/zdropdown.dart';
import '../../../../../../../l10n/app_localizations.dart';


enum DueType {
  payable,
  receivable;

  /// Value stored in database
  String toDatabaseValue() {
    switch (this) {
      case DueType.payable:
        return "Payable";
      case DueType.receivable:
        return "Receivable";
    }
  }

  /// Convert database value back to enum
  static DueType fromDatabaseValue(String value) {
    switch (value.toLowerCase()) {
      case "payable":
        return DueType.payable;
      case "receivable":
        return DueType.receivable;
      default:
        return DueType.payable; // Default fallback
    }
  }
}

class DueTypeTranslator {
  /// UI Translation only
  static String getTranslatedDueType(BuildContext context, DueType type) {
    final t = AppLocalizations.of(context)!;

    switch (type) {
      case DueType.payable:
        return t.payableDue;
      case DueType.receivable:
        return t.receivableDue;
    }
  }

  static String getTranslatedDueTypeFromDb(BuildContext context, String dbValue) {
    try {
      final type = DueType.fromDatabaseValue(dbValue);
      return getTranslatedDueType(context, type);
    } catch (e) {
      return dbValue; // Return original if conversion fails
    }
  }
}

class DueTypeDropdown extends StatefulWidget {
  final String selectedDueType;
  final bool isEnable;
  final Function(DueType) onDueTypeSelected;

  const DueTypeDropdown({
    super.key,
    this.isEnable = false,
    required this.selectedDueType,
    required this.onDueTypeSelected,
  });

  @override
  State<DueTypeDropdown> createState() => _DueTypeDropdownState();
}

class _DueTypeDropdownState extends State<DueTypeDropdown> {
  late DueType _selectedDueType;

  @override
  void initState() {
    super.initState();

    // Initialize with the database string
    _selectedDueType = _getInitialDueType();

    // Notify parent of initial selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDueTypeSelected(_selectedDueType);
    });
  }

  DueType _getInitialDueType() {
    if (widget.selectedDueType.isNotEmpty) {
      try {
        return DueType.fromDatabaseValue(widget.selectedDueType);
      } catch (e) {
        return DueType.values.first;
      }
    }
    return DueType.values.first;
  }

  @override
  void didUpdateWidget(covariant DueTypeDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedDueType != oldWidget.selectedDueType) {
      setState(() {
        _selectedDueType = _getInitialDueType();
      });
    }
  }

  void _handleSelected(DueType type) {
    setState(() => _selectedDueType = type);
    widget.onDueTypeSelected(type);
  }

  @override
  Widget build(BuildContext context) {
    return ZDropdown<DueType>(
      disableAction: widget.isEnable,
      title: AppLocalizations.of(context)!.dueType,
      items: DueType.values.toList(),
      itemLabel: (type) => DueTypeTranslator.getTranslatedDueType(context, type),
      selectedItem: _selectedDueType,
      onItemSelected: _handleSelected,
      leadingBuilder: (type) => _getDueTypeIcon(type),
    );
  }

  Widget _getDueTypeIcon(DueType type) {
    final icon = switch (type) {
      DueType.payable => Icons.arrow_upward_rounded,
      DueType.receivable => Icons.arrow_downward_rounded,
    };

    return Icon(
      icon,
      size: 20,
      color: type == DueType.payable ? Colors.red : Colors.green,
    );
  }
}