import 'package:flutter/material.dart';

import '../../../../../../../Features/zdropdown.dart';
import '../../../../../../../l10n/app_localizations.dart';

/// =======================
///   GL Account Category ENUM
/// =======================

enum GLAccountCategory {
  asset(1),
  liability(2),
  income(3),
  expense(4);

  final int dbValue;
  const GLAccountCategory(this.dbValue);

  static GLAccountCategory fromDbValue(int value) {
    switch (value) {
      case 1: return GLAccountCategory.asset;
      case 2: return GLAccountCategory.liability;
      case 3: return GLAccountCategory.income;
      case 4: return GLAccountCategory.expense;
      default: return GLAccountCategory.asset;
    }
  }
}


/// =======================
/// GL Category Translator
/// =======================

class GLCategoryTranslator {
  static String translate(BuildContext context, GLAccountCategory type) {
    final t = AppLocalizations.of(context)!;

    switch (type) {
      case GLAccountCategory.asset:
        return t.asset;
      case GLAccountCategory.liability:
        return t.liability;
      case GLAccountCategory.income:
        return t.income;
      case GLAccountCategory.expense:
        return t.expense;
    }
  }

  static List<Map<String, dynamic>> translatedList(BuildContext context) {
    return GLAccountCategory.values.map((type) {
      return {
        "category": type,
        "translatedName": translate(context, type),
        "dbValue": type.dbValue,
      };
    }).toList();
  }
}

/// =======================
/// GL Category Dropdown
/// =======================

class GLCategoryDropdown extends StatefulWidget {
  final int? selectedDbValue;
  final bool disableAction;
  final Function(int dbValue) onChanged;

  const GLCategoryDropdown({
    super.key,
    this.selectedDbValue,
    this.disableAction = false,
    required this.onChanged,
  });

  @override
  State<GLCategoryDropdown> createState() => _GLCategoryDropdownState();
}

class _GLCategoryDropdownState extends State<GLCategoryDropdown> {
  late GLAccountCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedDbValue != null
        ? GLAccountCategory.fromDbValue(widget.selectedDbValue!)
        : GLAccountCategory.asset;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(_selectedCategory.dbValue);
    });
  }

  void _onSelected(GLAccountCategory type) {
    setState(() => _selectedCategory = type);
    widget.onChanged(type.dbValue); //
  }

  @override
  Widget build(BuildContext context) {
    return ZDropdown<GLAccountCategory>(
      title: AppLocalizations.of(context)!.accountCategory,
      items: GLAccountCategory.values,
      selectedItem: _selectedCategory,
      disableAction: widget.disableAction,
      itemLabel: (type) =>
          GLCategoryTranslator.translate(context, type),
      onItemSelected: _onSelected,
      leadingBuilder: _iconBuilder,
    );
  }

  Widget _iconBuilder(GLAccountCategory type) {
    final icon = switch (type) {
      GLAccountCategory.asset => Icons.account_balance_wallet_rounded,
      GLAccountCategory.liability => Icons.credit_card_rounded,
      GLAccountCategory.income => Icons.trending_up_rounded,
      GLAccountCategory.expense => Icons.trending_down_rounded,
    };

    return Icon(icon, size: 20);
  }
}
