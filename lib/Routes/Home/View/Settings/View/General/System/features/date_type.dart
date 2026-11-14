import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../Features/Other/zdropdown.dart';
import '../../../../../../../../l10n/app_localizations.dart';
import '../../../../Visibility/bloc/settings_visible_bloc.dart';

String getDateTypeLabel(DateType type) {
  switch (type) {
    case DateType.hijriShamsi:
      return 'Hijri Shamsi';
    case DateType.gregorian:
      return 'gregorian';
  }
}


class DateTypeDrop extends StatefulWidget {
  const DateTypeDrop({super.key});

  @override
  State<DateTypeDrop> createState() => _DateTypeDropState();
}

class _DateTypeDropState extends State<DateTypeDrop> {
  DateType? selectedDateType;
  String getDateTypeLabel(DateType type) {
    switch (type) {
      case DateType.hijriShamsi:
        return AppLocalizations.of(context)!.shamsi;
      case DateType.gregorian:
        return AppLocalizations.of(context)!.gregorian;
    }
  }
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsVisibleBloc, SettingsVisibilityState>(
      builder: (context, state) {
        return SizedBox(
          width: 330,
          child: ZDropdown<DateType>(
            title: AppLocalizations.of(context)!.systemDate,
            items: DateType.values, /// [hijriShamsi, gregorian]
            selectedItem: state.dateType,
            itemLabel: getDateTypeLabel,
            onItemSelected: (type) {
              setState(() {
                selectedDateType = type;
                context.read<SettingsVisibleBloc>().add(UpdateSettingsEvent(dateType: selectedDateType));
              });
            },
          ),
        );
      },
    );
  }

}




