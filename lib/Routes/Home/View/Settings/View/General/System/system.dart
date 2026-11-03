import 'package:flutter/material.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Routes/Home/View/Settings/View/General/Security/change_password.dart';
import 'package:shipping/Routes/Home/View/Settings/View/General/System/theme_toggle.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../../../../l10n/locale_selector.dart';
import 'features/date_type.dart';

class SystemView extends StatelessWidget {
  const SystemView({super.key});

  @override
  Widget build(BuildContext context) {
    // final Map<String, String> dateFormats = {
    //   //Date
    //   'yyyy-MM-dd': '2025-05-28',
    //   'dd-MM-yyyy': '28-05-2025',
    //   'MM/dd/yyyy': '05/28/2025',
    //   'dd MMM yyyy': '28 May, 2025',
    //   //Date With Time
    //   'dd-MM-yyyy HH:mm': '28-05-2025 14:30',
    // };
    final tr = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  // Force segmented Android style
                  ThemeSelectorWidget(
                    width: 330,
                    title: tr.theme,
                    style: ThemeSelectorStyle.toggle,
                    usePlatformDefault: false,
                  ),

                  LocaleSelector(
                    width: 330,
                    title: tr.language,
                  ),

                  DateTypeDrop(),
                  SizedBox(height: 10),
                  ZOutlineButton(
                    width: 330,
                      icon: Icons.lock_open_rounded,
                      onPressed: (){
                        showDialog(context: context, builder: (context){
                          return PasswordSettingsView();
                        });
                      },
                      label: Text(tr.changePassowrd))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
