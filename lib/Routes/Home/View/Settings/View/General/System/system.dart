import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/cover.dart';
import 'package:shipping/Features/Widgets/section.dart';
import 'package:shipping/Routes/Home/View/Settings/View/General/System/features/theme_toggle.dart';
import 'package:shipping/l10n/app_localizations.dart';
import '../../../../../../../../l10n/locale_selector.dart';
import '../../../Visibility/bloc/settings_visible_bloc.dart';
import 'features/customs_term.dart';
import 'features/date_type.dart';
import 'features/label_check.dart';

class SystemView extends StatelessWidget {
  const SystemView({super.key});

  @override
  Widget build(BuildContext context) {
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
                  ThemeSelectorWidget(
                    width: 330,
                    style: ThemeSelectorStyle.toggle,
                    usePlatformDefault: false,
                  ),

                  LocaleSelector(width: 330, title: tr.language),

                  DateTypeDrop(),
                  const SizedBox(height: 10),

                  SectionTitle(title: tr.invoiceSettings),

                  ZCover(
                    radius: 8,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        /// Inventory
                        LabeledCheckbox(
                          title: tr.stock,
                          value: state.orders,
                          onChanged: (e) {
                            context
                                .read<SettingsVisibleBloc>()
                                .add(UpdateSettingsEvent(orders: e));
                          },
                        ),
                        bulletPoint(tr.inventoryHint),

                        /// Invoice Batch
                        LabeledCheckbox(
                          title: tr.invoiceBatch,
                          value: state.isWholeSale,
                          onChanged: (e) {
                            context
                                .read<SettingsVisibleBloc>()
                                .add(UpdateSettingsEvent(isWholeSale: e));
                          },
                        ),
                        bulletPoint(tr.invoiceBatchHint),

                        /// Profit & Loss
                        LabeledCheckbox(
                          title: tr.profit,
                          value: state.benefit,
                          onChanged: (e) {
                            context
                                .read<SettingsVisibleBloc>()
                                .add(UpdateSettingsEvent(benefit: e));
                          },
                        ),
                        bulletPoint(tr.invoiceProfitHint),


                        /// Logo in prints
                        LabeledCheckbox(
                          title: tr.logoPrint,
                          value: state.showHideLogo,
                          onChanged: (e) {
                            context.read<SettingsVisibleBloc>().add(UpdateSettingsEvent(showHideLogo: e));
                          },
                        ),
                        bulletPoint(tr.logoPrintHint),

                        /// ── Terms and Conditions (toggle) ──
                        LabeledCheckbox(
                          title: tr.termsAndConditions,
                          value: state.termsAndConditions,
                          onChanged: (e) {
                            context
                                .read<SettingsVisibleBloc>()
                                .add(UpdateSettingsEvent(termsAndConditions: e));
                          },
                        ),
                        bulletPoint(tr.termsAndConditonsHint),

                        /// ── Custom text editor (NEW) ──
                        CustomTermsEditor(enabled: state.termsAndConditions),


                      ],
                    ),
                  ),

                  SectionTitle(title: tr.shippingAndTransfer),

                  ZCover(
                    radius: 8,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        LabeledCheckbox(
                          title: tr.shipping,
                          value: state.shipping,
                          onChanged: (e) {
                            context
                                .read<SettingsVisibleBloc>()
                                .add(UpdateSettingsEvent(shipping: e));
                          },
                        ),
                        bulletPoint(tr.shippingHint),

                        LabeledCheckbox(
                          title: tr.transfer,
                          value: state.moneyTransfer,
                          onChanged: (e) {
                            context
                                .read<SettingsVisibleBloc>()
                                .add(UpdateSettingsEvent(moneyTransfer: e));
                          },
                        ),
                        bulletPoint(tr.moneyTransferHint),
                      ],
                    ),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 5,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}