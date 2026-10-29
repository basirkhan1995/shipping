import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../l10n/app_localizations.dart';
import '../../zdropdown.dart';

class PageOrientationHelper {
  static const List<pw.PageOrientation> availableOrientations = [
    pw.PageOrientation.portrait,
    pw.PageOrientation.landscape,
  ];

  static String getDisplayName(pw.PageOrientation orientation,context) {
    return orientation == pw.PageOrientation.portrait
        ? AppLocalizations.of(context)!.portrait
        : AppLocalizations.of(context)!.landscape;
  }
}


class PageOrientationDropdown extends StatefulWidget {
  final Function(pw.PageOrientation) onOrientationSelected;
  final pw.PageOrientation? initialOrientation;

  const PageOrientationDropdown({
    super.key,
    required this.onOrientationSelected,
    this.initialOrientation,
  });

  @override
  State<PageOrientationDropdown> createState() => _PageOrientationDropdownState();
}

class _PageOrientationDropdownState extends State<PageOrientationDropdown> {
  late pw.PageOrientation _selectedOrientation;

  @override
  void initState() {
    super.initState();
    _selectedOrientation = widget.initialOrientation ?? pw.PageOrientation.portrait;
  }

  @override
  Widget build(BuildContext context) {
    return ZDropdown<pw.PageOrientation>(
      title: AppLocalizations.of(context)!.orientation,
      items: PageOrientationHelper.availableOrientations,
      initialValue: PageOrientationHelper.getDisplayName(_selectedOrientation,context),
      itemLabel: (orientation) => PageOrientationHelper.getDisplayName(orientation,context),
      onItemSelected: (selected) {
        setState(() {
          _selectedOrientation = selected;
        });
        widget.onOrientationSelected(selected);
      },
    );
  }
}
