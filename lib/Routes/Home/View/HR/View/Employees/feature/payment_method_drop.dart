import 'package:flutter/material.dart';

import '../../../../../../../Features/Other/zdropdown.dart';
import '../../../../../../../l10n/app_localizations.dart';

enum EmpPaymentMethod {
  monthly,
  daily;

  String toDatabaseValue() {
    switch (this) {
      case EmpPaymentMethod.monthly: return "Monthly";
      case EmpPaymentMethod.daily: return "Daily";
    }
  }

  static EmpPaymentMethod fromDatabaseValue(String value) {
    switch (value) {
      case "Monthly": return EmpPaymentMethod.monthly;
      case "Daily": return EmpPaymentMethod.daily;
      default: return EmpPaymentMethod.monthly;
    }
  }
}

/// Translator for EmpPaymentMethod
class PaymentMethodTranslator {
  static String getTranslated(BuildContext context, EmpPaymentMethod method) {
    final t = AppLocalizations.of(context)!;

    switch (method) {
      case EmpPaymentMethod.monthly: return t.monthly;
      case EmpPaymentMethod.daily: return t.daily;
    }
  }

  static String getTranslatedFromDb(BuildContext context, String value) {
    final method = EmpPaymentMethod.fromDatabaseValue(value);
    return getTranslated(context, method);
  }

  static List<Map<String, dynamic>> getTranslatedList(BuildContext context) {
    return EmpPaymentMethod.values.map((method) {
      return {
        "method": method,
        "translatedName": getTranslated(context, method),
        "dbValue": method.toDatabaseValue(),
      };
    }).toList();
  }
}

class PaymentMethodDropdown extends StatefulWidget {
  final EmpPaymentMethod? selectedMethod;
  final Function(EmpPaymentMethod) onSelected;

  const PaymentMethodDropdown({
    super.key,
    this.selectedMethod,
    required this.onSelected,
  });

  @override
  State<PaymentMethodDropdown> createState() => _PaymentMethodDropdownState();
}

class _PaymentMethodDropdownState extends State<PaymentMethodDropdown> {
  late EmpPaymentMethod _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.selectedMethod ?? EmpPaymentMethod.monthly;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelected(_selectedMethod);
    });
  }

  @override
  void didUpdateWidget(covariant PaymentMethodDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMethod != null &&
        widget.selectedMethod != _selectedMethod) {
      setState(() => _selectedMethod = widget.selectedMethod!);
    }
  }

  void _handleSelected(EmpPaymentMethod method) {
    setState(() => _selectedMethod = method);
    widget.onSelected(method);
  }

  @override
  Widget build(BuildContext context) {
    return ZDropdown<EmpPaymentMethod>(
      title: AppLocalizations.of(context)!.paymentMethod,
      items: EmpPaymentMethod.values.toList(),
      itemLabel: (method) =>
          PaymentMethodTranslator.getTranslated(context, method),
      selectedItem: _selectedMethod,
      onItemSelected: _handleSelected,
      leadingBuilder: (method) => _getIcon(method),
    );
  }

  Widget _getIcon(EmpPaymentMethod method) {
    final icon = switch (method) {
      EmpPaymentMethod.monthly => Icons.payments_rounded,
      EmpPaymentMethod.daily => Icons.today_rounded,
    };
    return Icon(icon, size: 20);
  }
}
