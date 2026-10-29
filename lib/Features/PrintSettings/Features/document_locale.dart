import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../zdropdown.dart';

class LanguageModel {
  final String code;
  final String name;

  LanguageModel(this.code, this.name);
}

class LanguageDropdown extends StatefulWidget {
  final Function(LanguageModel) onLanguageSelected;

  const LanguageDropdown({super.key, required this.onLanguageSelected});

  @override
  State<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  final List<LanguageModel> _languages = [
    LanguageModel('en', 'English'),
    LanguageModel('fa', 'فارسی'), // Persian
    LanguageModel('ar', 'پشتو'),  // Pashto
  ];

  LanguageModel? _selectedLanguage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Locale currentLocale = Localizations.localeOf(context);

      setState(() {
        _selectedLanguage = _languages.firstWhere(
              (lang) => lang.code == currentLocale.languageCode,
          orElse: () => _languages.first,
        );
      });

      widget.onLanguageSelected(_selectedLanguage!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return ZDropdown<LanguageModel>(
      title: locale.language,
      initialValue: _selectedLanguage?.name,
      items: _languages,
      itemLabel: (lang) => lang.name,
      onItemSelected: (lang) {
        setState(() {
          _selectedLanguage = lang;
        });
        widget.onLanguageSelected(lang);
      },
    );
  }
}
