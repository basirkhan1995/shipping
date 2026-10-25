import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/Finance/View/Currencies/currencies.dart';
import 'package:shipping/Routes/Home/View/Finance/View/EOY/eoy.dart';
import '../../../../Features/Other/responsive_widget.dart';
import '../../../../Features/Widgets/tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../Auth/bloc/auth_bloc.dart';
import 'View/ExchangeRate/Ui/exchange_rate.dart';
import 'View/GlAccounts/gl_accounts.dart';
import 'View/Payroll/payroll.dart';
import 'View/Reminder/reminder.dart';
import 'bloc/financial_tab_bloc.dart';


class FinanceView extends StatelessWidget {
  const FinanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(mobile: _Mobile(), tablet: _Desktop(), desktop: _Desktop());
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    return Scaffold(

      body: BlocBuilder<FinanceTabBloc, FinanceTabState>(
        builder: (context, state) {
          final tabs = <ZTabItem<FinanceTabName>>[
          //  if (login.hasPermission(11) ?? false)...[
              ZTabItem(
                value: FinanceTabName.currencies,
                label: AppLocalizations.of(context)!.currencyTitle,
                screen: const CurrenciesView(),
              ),

            ZTabItem(
              value: FinanceTabName.exchangeRate,
              label: AppLocalizations.of(context)!.fxRate,
              screen: ExchangeRateView(newRateButton: true),
            ),
           // if (login.hasPermission(14) ?? false)...[
              ZTabItem(
                value: FinanceTabName.glAccounts,
                label: "GL Accounts",
                screen: const GlAccountsView(),
              ),


          //  if (login.hasPermission(15) ?? false)...[
              ZTabItem(
                value: FinanceTabName.payroll,
                label: "Payroll",
                screen: const PayrollView(),
              ),


           // if (login.hasPermission(16) ?? false) ...[
              ZTabItem(
                value: FinanceTabName.endOfYear,
                label: "Fiscal Year",
                screen: const EoyView(),
              ),

           // if (login.hasPermission(17) ?? false) ...[
              ZTabItem(
                value: FinanceTabName.reminder,
                label: "reminders",
                screen: const ReminderView(),
              ),
            ];

          if (tabs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 50,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  Text(
                    "deniedPermissionMessage",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    "deniedPermissionMessage",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final availableValues = tabs.map((tab) => tab.value).toList();
          final selected = availableValues.contains(state.tab)
              ? state.tab
              : availableValues.first;

          return ZTabContainer<FinanceTabName>(
            /// Tab data
            tabs: tabs,
            selectedValue: selected,
            title: AppLocalizations.of(context)!.finance,
            description: "Manage finance",

            /// Bloc update
            onChanged: (val) => context.read<FinanceTabBloc>().add(
              FinanceOnChangedEvent(val),
            ),

            /// Colors and style
            style: ZTabStyle.rounded,
            tabBarPadding: EdgeInsets.symmetric(horizontal: 5,vertical: 5),
            borderRadius: 0,
            selectedColor: Theme.of(context).colorScheme.primary,
            unselectedTextColor: Theme.of(context).colorScheme.secondary,
            selectedTextColor: Theme.of(context).colorScheme.surface,
            tabContainerColor: Theme.of(context).colorScheme.surface,
          );
        },
      ),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    if (state is! AuthenticatedState) {
      return const SizedBox();
    }
    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BlocBuilder<FinanceTabBloc, FinanceTabState>(
          builder: (context, state) {
            final tabs = <ZTabItem<FinanceTabName>>[
           //   if (login.hasPermission(11) ?? false)...[
                ZTabItem(
                  value: FinanceTabName.currencies,
                  label: "Currency",
                  screen: const CurrenciesView(),
                ),

              ZTabItem(
                value: FinanceTabName.exchangeRate,
                label: "Exchange Rate",
                screen: ExchangeRateView(newRateButton: true,settingButton: true),
              ),


          //   if (login.hasPermission(14) ?? false)...[
                ZTabItem(
                  value: FinanceTabName.glAccounts,
                  label: "glAccounts",
                  screen: const GlAccountsView(),
                ),


           //   if (login.hasPermission(17) ?? false) ...[
                ZTabItem(
                  value: FinanceTabName.reminder,
                  label: "reminders",
                  screen: const ReminderView(),
                ),
              ];

            if (tabs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 50,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    Text(
                      "deniedPermissionTitle",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      "deniedPermissionMessage",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            final availableValues = tabs.map((tab) => tab.value).toList();
            final selected = availableValues.contains(state.tab)
                ? state.tab
                : availableValues.first;

            return ZTabContainer<FinanceTabName>(
              /// Tab data
              tabs: tabs,
              selectedValue: selected,

              /// Bloc update
              onChanged: (val) => context.read<FinanceTabBloc>().add(
                FinanceOnChangedEvent(val),
              ),

              /// Colors and style
              style: ZTabStyle.rounded,
              tabBarPadding: EdgeInsets.symmetric(horizontal: 5,vertical: 5),
              borderRadius: 0,
              selectedColor: Theme.of(context).colorScheme.primary,
              unselectedTextColor: Theme.of(context).colorScheme.secondary,
              selectedTextColor: Theme.of(context).colorScheme.surface,
              tabContainerColor: Theme.of(context).colorScheme.surface,
            );
          },
        ),
      ),
    );
  }
}