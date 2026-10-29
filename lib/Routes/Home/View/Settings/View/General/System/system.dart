import 'package:flutter/material.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Routes/Home/View/Settings/View/General/Security/change_password.dart';
import 'package:shipping/Routes/Home/View/Settings/View/General/System/theme_toggle.dart';
import '../../../../../../../../l10n/locale_selector.dart';

class SystemView extends StatelessWidget {
  const SystemView({super.key});

  @override
  Widget build(BuildContext context) {
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
                    title: "Theme",
                    style: ThemeSelectorStyle.toggle,
                    usePlatformDefault: false,
                  ),

                  LocaleSelector(
                    width: 330,
                    title: "Language",
                  ),


                  SizedBox(height: 10),
                  ZOutlineButton(
                    width: 330,
                      icon: Icons.lock_open_rounded,
                      onPressed: (){
                        showDialog(context: context, builder: (context){
                          return PasswordSettingsView();
                        });
                      },
                      label: Text("Change Password"))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
