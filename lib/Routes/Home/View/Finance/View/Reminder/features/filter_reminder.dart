import 'package:flutter/material.dart';
import 'package:shipping/l10n/app_localizations.dart';

import '../../../../../../../Features/zdropdown.dart';


enum FilterType { all, overdue, today, upcoming }

extension FilterTypeExt on FilterType {
  String label(BuildContext context) {
    switch (this) {
      case FilterType.all:
        return "All"; // or localize
      case FilterType.overdue:
        return "Overdue";
      case FilterType.today:
        return "Today";
      case FilterType.upcoming:
        return "Upcoming";
    }
  }
}

class FilterRemindersDropdown extends StatelessWidget {
  final List<FilterType> selectedFilters;
  final Function(List<FilterType>) onFiltersChanged;

  const FilterRemindersDropdown({
    super.key,
    required this.selectedFilters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ZDropdown<FilterType>(
      title: AppLocalizations.of(context)!.filterByStatus,
      items: FilterType.values,
      multiSelect: true,
      selectedItems: selectedFilters,
      onMultiSelectChanged: onFiltersChanged,
      itemLabel: (f) => f.label(context),
      onItemSelected: (FilterType value) {  },
    );
  }
}
