import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/cover.dart';
import 'package:shipping/Features/Widgets/section.dart';
import 'package:shipping/Routes/Home/View/Settings/View/General/System/features/theme_toggle.dart';
import 'package:shipping/l10n/app_localizations.dart';

import '../../../../../../../../l10n/locale_selector.dart';
import '../../../Visibility/bloc/settings_visible_bloc.dart';
import 'features/date_type.dart';
import 'features/label_check.dart';

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
      body: BlocBuilder<SettingsVisibleBloc, SettingsVisibilityState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  // Force segmented Android style
                  ThemeSelectorWidget(
                    width: 330,
                    style: ThemeSelectorStyle.toggle,
                    usePlatformDefault: false,
                  ),

                  LocaleSelector(width: 330, title: tr.language),

                  DateTypeDrop(),
                  SizedBox(height: 10),

                  SectionTitle(title: tr.invoiceSettings),

                  ZCover(
                      radius: 8,
                      padding: EdgeInsets.all(10),
                      child: Column(
                    children: [

                      ///Orders..............................................
                      LabeledCheckbox(
                        title: tr.inventory,
                        value: state.orders,
                        onChanged: (e) {
                          context.read<SettingsVisibleBloc>().add(
                            UpdateSettingsEvent(orders: e),
                          );
                        },
                      ),
                      bulletPoint(tr.inventoryHint),

                      ///Invoice Batch
                      LabeledCheckbox(
                        title: tr.invoiceBatch,
                        value: state.isWholeSale,
                        onChanged: (e) {
                          context.read<SettingsVisibleBloc>().add(
                            UpdateSettingsEvent(isWholeSale: e),
                          );
                        },
                      ),
                      bulletPoint(tr.invoiceBatchHint),

                      /// Profit & Loss
                      LabeledCheckbox(
                        title: tr.profit,
                        value: state.benefit,
                        onChanged: (e) {
                          context.read<SettingsVisibleBloc>().add(
                            UpdateSettingsEvent(benefit: e),
                          );
                        },
                      ),
                      bulletPoint(tr.invoiceProfitHint),


                    ],
                  )),

                  SectionTitle(title: tr.shippingAndTransfer),

                  ZCover(
                      radius: 8,
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [

                          ///Orders..............................................
                          LabeledCheckbox(
                            title: tr.shipping,
                            value: state.shipping,
                            onChanged: (e) {
                              context.read<SettingsVisibleBloc>().add(
                                UpdateSettingsEvent(shipping: e),
                              );
                            },
                          ),
                          bulletPoint(tr.shippingHint),

                          ///Invoice Batch
                          LabeledCheckbox(
                            title: tr.transfer,
                            value: state.moneyTransfer,
                            onChanged: (e) {
                              context.read<SettingsVisibleBloc>().add(
                                UpdateSettingsEvent(moneyTransfer: e),
                              );
                            },
                          ),
                          bulletPoint(tr.moneyTransferHint),

                        ],
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 5,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(50)
            ),
          ),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
