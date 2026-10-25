import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Auth/bloc/auth_bloc.dart';
import 'package:shipping/Routes/Auth/login.dart';
import 'package:shipping/Routes/Home/View/Finance/View/Currencies/bloc/currencies_bloc.dart';
import 'package:shipping/Routes/Home/View/Finance/View/EOY/bloc/eoy_bloc.dart';
import 'package:shipping/Routes/Home/View/Finance/View/ExchangeRate/bloc/exchange_rate_bloc.dart';
import 'package:shipping/Routes/Home/View/Finance/View/GlAccounts/GlCategories/bloc/gl_category_bloc.dart';
import 'package:shipping/Routes/Home/View/Finance/View/GlAccounts/bloc/gl_accounts_bloc.dart';
import 'package:shipping/Routes/Home/View/Finance/View/Reminder/bloc/reminder_bloc.dart';
import 'package:shipping/Routes/Home/View/Finance/bloc/financial_tab_bloc.dart';
import 'package:shipping/Routes/Home/View/Settings/View/Company/Branch/Ui/BranchLimits/bloc/branch_limit_bloc.dart';
import 'package:shipping/Routes/Home/View/Settings/View/Company/Branch/bloc/brc_tab_bloc.dart';
import 'package:shipping/Routes/Home/View/Settings/View/Company/Branches/bloc/branch_bloc.dart';
import 'package:shipping/Routes/Home/View/Settings/View/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'package:shipping/Routes/Home/View/Settings/View/Company/Storage/bloc/storage_bloc.dart';
import 'package:shipping/Routes/Home/View/Settings/View/Company/bloc/company_settings_menu_bloc.dart';
import 'package:shipping/Routes/Home/View/Settings/Visibility/bloc/settings_visible_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/bloc/stakeholder_bloc.dart';
import 'package:shipping/Routes/Home/View/Transactions/bloc/transactions_bloc.dart';
import 'Routes/Home/View/Settings/bloc/settings_tab_bloc.dart';
import 'Routes/Home/View/Stakeholder/View/StakeholderById/bloc/stakeholder_by_id_bloc.dart';
import 'Routes/Home/bloc/menu_bloc.dart';
import 'Services/api_services.dart';
import 'Services/localization_services.dart';
import 'Services/repository.dart';
import 'Themes/Bloc/themes_bloc.dart';
import 'Themes/Ui/theme.dart';
import 'l10n/Bloc/localizations_bloc.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => Repositories(ApiServices()),
      child: MultiBlocProvider(
        providers: [

          ///Settings and other
          BlocProvider(create: (_) => ThemeBloc()),
          BlocProvider(create: (_) => LocalizationBloc()),
          BlocProvider(create: (_) => MenuBloc()),
          BlocProvider(create: (_) => SettingsTabBloc()),
          BlocProvider(create: (_) => FinanceTabBloc()),
          BlocProvider(create: (_) => BranchTabBloc()),
          BlocProvider(create: (_) => CompanySettingsMenuBloc()),
          BlocProvider(create: (_) => SettingsVisibleBloc()..add(LoadSettingsEvent())),
          
          ///Auth
          BlocProvider(create: (_) => AuthBloc(Repositories(ApiServices()))),

          ///Stakeholders
          BlocProvider(create: (_) => StakeholderBloc(Repositories(ApiServices()))..add(GetStakeholdersEvent())),
          BlocProvider(create: (_) => StakeholderByIdBloc(Repositories(ApiServices()))),
          BlocProvider(create: (_) => StkAccountsBloc(Repositories(ApiServices()))),

          ///Currencies
          BlocProvider(create: (_) => CurrenciesBloc(Repositories(ApiServices()))..add(LoadCurrenciesEvent())),
          BlocProvider(create: (_) => TransactionsBloc(Repositories(ApiServices()))..add(LoadTransactionsEvent())),
          BlocProvider(create: (_) => ExchangeRateBloc(Repositories(ApiServices()))),
          ///GL Accounts
          BlocProvider(create: (_) => GlAccountsBloc(Repositories(ApiServices()))..add(LoadGlAccountEvent())),
          BlocProvider(create: (_) => GlCategoryBloc(Repositories(ApiServices()))),
          BlocProvider(create: (_) => ReminderBloc(Repositories(ApiServices()))),

          ///Company Bloc
          BlocProvider(create: (_) => CompanyProfileBloc(Repositories(ApiServices()))..add(LoadCompanyProfileEvent())),
          BlocProvider(create: (_) => StorageBloc(Repositories(ApiServices()))..add(LoadStorageEvent())),
          BlocProvider(create: (_) => BranchBloc(Repositories(ApiServices()))..add(LoadBranchesEvent())),
          BlocProvider(create: (_) => BranchLimitBloc(Repositories(ApiServices()))),
          BlocProvider(create: (_) => EoyBloc(Repositories(ApiServices()))..add(LoadPLEvent())),


        ],
        child: BlocBuilder<LocalizationBloc, Locale>(
          builder: (context, locale) {
            return BlocBuilder<ThemeBloc, ThemeMode>(
              builder: (context, themeMode) {
                final theme = AppThemes(TextTheme.of(context));
                return MaterialApp(
                  themeMode: themeMode,
                  locale: locale,
                  title: 'ZShipping',
                  darkTheme: theme.dark(),
                  theme: theme.light(),
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates:
                  AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: LoginView(),
                  builder: (context, child) {
                    localizationService.update(AppLocalizations.of(context)!);
                    return child!;
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}


