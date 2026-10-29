import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/model/stk_model.dart';

import '../../../../../../../Features/Date/z_generic_date.dart';
import '../../../../../../../Features/Date/z_range_picker.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../Features/Other/generic_textfield.dart';
import '../../../../../Features/Other/responsive_widget.dart';
import '../../../../../Features/Widgets/cover.dart';
import '../../../../../Features/Widgets/extensions.dart';
import '../../../../../Features/Widgets/noData_widget.dart';
import '../../../../../Features/Widgets/utils.dart';
import '../../../../../Features/Widgets/zbutton.dart';
import '../../../../../l10n/Bloc/localizations_bloc.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../Auth/bloc/auth_bloc.dart';
import '../../Settings/View/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../Settings/Visibility/bloc/settings_visible_bloc.dart';
import '../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import 'PDF/account_excel.dart';
import 'PDF/pdf.dart';
import 'bloc/acc_statement_bloc.dart';
import 'features/whatsapp_helper.dart';
import 'model/stmt_model.dart';

class AccountStatementView extends StatelessWidget {
  final int? initialAccountNumber;
  const AccountStatementView({super.key, this.initialAccountNumber});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(initialAccountNumber),
      tablet: _Mobile(initialAccountNumber),
      desktop: _Desktop(initialAccountNumber),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _Mobile extends StatefulWidget {
  final int? initialAccountNumber;
  const _Mobile(this.initialAccountNumber);

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  final accountController = TextEditingController();
  int? accNumber;
  String? myLocale;
  final formKey = GlobalKey<FormState>();
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  String fromDate = DateTime.now()
      .subtract(const Duration(days: 7))
      .toDateTime;
  String toDate = DateTime.now().toDateTime;

  List<StmtRecord> records = [];
  AccountStatementModel? accountStatementModel;

  @override
  void initState() {
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<AccStatementBloc>().add(ResetAccStmtEvent());

    final preset = widget.initialAccountNumber;
    if (preset != null) {
      accNumber = preset;
      accountController.text = preset.toString();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AccStatementBloc>().add(
          LoadAccountStatementEvent(
            accountNumber: preset,
            fromDate: fromDate,
            toDate: toDate,
          ),
        );
      });
    }

    super.initState();
  }

  void _generateAndShowPDF(BuildContext context) {
    if (formKey.currentState!.validate() && accNumber != null) {
      setState(() {
        records = [];
        accountStatementModel = null;
      });

      context.read<AccStatementBloc>().add(
        LoadAccountStatementEvent(
          accountNumber: accNumber!,
          fromDate: fromDate,
          toDate: toDate,
        ),
      );
    } else {
      ToastManager.show(
        context: context,
        title: "Warning",
        message: "Statement message",
        type: ToastType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(tr.accountStatement),
        titleSpacing: 0,
      ),
      body: BlocBuilder<CompanyProfileBloc, CompanyProfileState>(
        builder: (context, state) {
          if (state is CompanyProfileLoadedState) {
            company.comName = state.company.comName ?? "";
            company.comAddress = state.company.addName ?? "";
            company.compPhone = state.company.comPhone ?? "";
            company.comEmail = state.company.comEmail ?? "";
            company.startDate = fromDate;
            company.endDate = toDate;
            company.statementDate = DateTime.now().toFullDateTime;

            final base64Logo = state.company.comLogo;
            if (base64Logo != null && base64Logo.isNotEmpty) {
              try {
                _companyLogo = base64Decode(base64Logo);
                company.comLogo = _companyLogo;
              } catch (e) {
                _companyLogo = Uint8List(0);
              }
            }
          }

          return BlocConsumer<AccStatementBloc, AccStatementState>(
            listener: (context, state) {
              if (state is AccStatementLoadedState) {
                final statementDetails = state.accStatementDetails;

                setState(() {
                  accountStatementModel = statementDetails;
                  records = statementDetails.records ?? [];
                });

                if (records.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) => PrintPreviewDialog<AccountStatementModel>(
                      data: accountStatementModel!,
                      company: company,
                      buildPreview: ({
                        required data,
                        required language,
                        required orientation,
                        required pageFormat,
                      }) {
                        return AccountStatementPrintSettings().printPreview(
                          company: company,
                          language: language,
                          orientation: orientation,
                          pageFormat: pageFormat,
                          info: accountStatementModel!,
                        );
                      },
                      onPrint: ({
                        required data,
                        required language,
                        required orientation,
                        required pageFormat,
                        required selectedPrinter,
                        required copies,
                        required pages,
                      }) {
                        return AccountStatementPrintSettings().printDocument(
                          statement: [accountStatementModel!],
                          company: company,
                          language: language,
                          orientation: orientation,
                          pageFormat: pageFormat,
                          selectedPrinter: selectedPrinter,
                          info: accountStatementModel!,
                          copies: copies,
                          pages: pages,
                        );
                      },
                      onSave: ({
                        required data,
                        required language,
                        required orientation,
                        required pageFormat,
                      }) {
                        return AccountStatementPrintSettings().createDocument(
                          statement: [accountStatementModel!],
                          company: company,
                          language: language,
                          orientation: orientation,
                          pageFormat: pageFormat,
                          info: accountStatementModel!,
                        );
                      },
                    ),
                  );
                } else {
                  ToastManager.show(context: context, message: "No Transactions found", type: ToastType.error);
                }
              } else if (state is AccStatementErrorState) {
                ToastManager.show(context: context, message: state.message, type: ToastType.error);
              }
            },
            builder: (context, state) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // Account Selection
                      GenericTextField<StakeholderAccount, StkAccountsBloc, StkAccountsState>(
                        showAllOnFocus: true,
                        controller: accountController,
                        title: tr.accounts,
                        hintText: tr.accNameOrNumber,
                        isRequired: true,
                        bloc: context.read<StkAccountsBloc>(),
                        fetchAllFunction: (bloc) => bloc.add(
                          const LoadStkAccountsEvent(),
                        ),
                        searchFunction: (bloc, query) => bloc.add(
                          LoadStkAccountsEvent(query: query),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr.required(tr.accounts);
                          }
                          return null;
                        },
                        itemBuilder: (context, account) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${account.accNumber} | ${account.accName}",
                                style:
                                Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        itemToString: (acc) =>
                        "${acc.accNumber} | ${acc.accName}",
                        stateToLoading: (state) =>
                        state is StkAccountsLoadingState,
                        loadingBuilder: (context) => const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        stateToItems: (state) {
                          if (state is StkAccountsLoadedState) {
                            return state.accounts;
                          }
                          return [];
                        },
                        onSelected: (value) {
                          setState(() {
                            accNumber = value.accNumber;
                          });
                        },
                        noResultsText: tr.noDataFound,
                        showClearButton: true,
                      ),

                      const SizedBox(height: 12),

                      // Date Range
                      Column(
                        children: [
                          ZDatePicker(
                            label: tr.fromDate,
                            value: fromDate,
                            onDateChanged: (v) {
                              setState(() {
                                fromDate = v;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          ZDatePicker(
                            label: tr.toDate,
                            value: toDate,
                            onDateChanged: (v) {
                              setState(() {
                                toDate = v;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Generate PDF Button
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ZOutlineButton(
                          isActive: (state is AccStatementLoadingState ||
                              accNumber == null)
                              ? false
                              : true,
                          onPressed: (state is AccStatementLoadingState ||
                              accNumber == null)
                              ? null
                              : () => _generateAndShowPDF(context),
                          icon: Icons.picture_as_pdf,
                          label: state is AccStatementLoadingState
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Text("PDF"),
                        ),
                      ),

                      if (accountStatementModel != null &&
                          records.isNotEmpty) ...[
                        const SizedBox(height: 16),

                        // Quick Summary Card
                        ZCover(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                ListTile(
                                  visualDensity: const VisualDensity(
                                      vertical: -4, horizontal: -4),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  title: Text(
                                    "Account Summary",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  subtitle: Text(
                                      accountStatementModel?.accName ?? ""),
                                ),
                                const Divider(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(tr.currentBalance),
                                      Text(
                                        accountStatementModel?.curBalance
                                            .toAmount() ??
                                            "0",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(tr.availableBalance),
                                      Text(
                                        accountStatementModel?.avilBalance
                                            .toAmount() ??
                                            "0",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Share buttons
                        Row(
                          children: [
                            Expanded(
                              child: ZOutlineButton(
                                onPressed: () {
                                  final helper = WhatsAppShareHelper(context);
                                  helper.shareViaWhatsApp(
                                    accountNumber: accNumber.toString(),
                                    signatory:
                                    accountStatementModel?.signatory ??
                                        "",
                                    accountName:
                                    accountStatementModel?.accName ?? "",
                                    currentBalance: accountStatementModel
                                        ?.curBalance.toDoubleAmount(),
                                    availableBalance: accountStatementModel
                                        ?.avilBalance.toDoubleAmount(),
                                    currencySymbol:
                                    accountStatementModel?.actCurrency ??
                                        "",
                                  );
                                },
                                isActive: true,
                                icon: Icons.message,
                                label: const Text("Share"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ZOutlineButton(
                                onPressed: () {
                                  _generateAndShowPDF(context);
                                },
                                icon: Icons.refresh,
                                label: const Text("Regenerate"),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Transaction count and info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Transactions",
                                style:
                                Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                "${records.length}",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),

                        // Add some bottom padding for better scrolling experience
                        const SizedBox(height: 20),
                      ],

                      // Hint text — only show when no data
                      if (accountStatementModel == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.print,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withAlpha(100),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Select an account and date range,\nthen tap the PDF button to generate statement",
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _Desktop extends StatefulWidget {
  final int? initialAccountNumber;
  const _Desktop(this.initialAccountNumber);

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  final Map<String, bool> _copiedStates = {};
  final accountController = TextEditingController();
  int? accNumber;
  String? myLocale;
  final formKey = GlobalKey<FormState>();
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();
  late String fromDate;
  late String toDate;

  List<AccountStatementModel> records = [];
  AccountStatementModel? accountStatementModel;

  Future<void> _copyToClipboard(String reference, BuildContext context) async {
    await Utils.copyToClipboard(reference);
    setState(() {
      _copiedStates[reference] = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedStates.remove(reference);
        });
      }
    });
  }

  @override
  void initState() {
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final todayOfMonth = DateTime(now.year, now.month, now.day);

    fromDate = startOfMonth.toApiStartDate();
    toDate = todayOfMonth.toApiEndDate();

    context.read<AccStatementBloc>().add(ResetAccStmtEvent());

    final preset = widget.initialAccountNumber;
    if (preset != null) {
      accNumber = preset;
      accountController.text = preset.toString();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AccStatementBloc>().add(
          LoadAccountStatementEvent(
            accountNumber: preset,
            fromDate: fromDate,
            toDate: toDate,
          ),
        );
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    const double dateWith = 100;
    const double refWidth = 220;
    const double amountWidth = 140;
    const double balanceWidth = 160;

    return Scaffold(
      appBar: AppBar(
        title: Text("Account Statement"),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthenticatedState) {
            final auth = state.loginData;
            company.comName = auth.company?.comName ?? "";
            company.comAddress = auth.company?.comAddress ?? "";
            company.compPhone = auth.company?.comPhone ?? "";
            company.comEmail = auth.company?.comEmail ?? "";
            company.startDate = fromDate;
            company.endDate = toDate;
            company.statementDate = DateTime.now().toFullDateTime;
            final base64Logo = auth.company?.comLogo;
            if (base64Logo != null && base64Logo.isNotEmpty) {
              try {
                _companyLogo = base64Decode(base64Logo);
                company.comLogo = _companyLogo;
              } catch (e) {
                _companyLogo = Uint8List(0);
              }
            }
          }

          return Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [


                  // ── Filter row ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 350,
                              child:  // Account Selection
                              GenericTextField<StakeholderAccount, StkAccountsBloc, StkAccountsState>(
                                showAllOnFocus: true,
                                controller: accountController,
                                title: tr.accounts,
                                hintText: tr.accNameOrNumber,
                                isRequired: true,
                                bloc: context.read<StkAccountsBloc>(),
                                fetchAllFunction: (bloc) => bloc.add(
                                  const LoadStkAccountsEvent(),
                                ),
                                searchFunction: (bloc, query) => bloc.add(
                                  LoadStkAccountsEvent(query: query),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return tr.required(tr.accounts);
                                  }
                                  return null;
                                },
                                itemBuilder: (context, account) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 5,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${account.accNumber} | ${account.accName}",
                                        style:
                                        Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                                itemToString: (acc) =>
                                "${acc.accNumber} | ${acc.accName}",
                                stateToLoading: (state) =>
                                state is StkAccountsLoadingState,
                                loadingBuilder: (context) => const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 3),
                                ),
                                stateToItems: (state) {
                                  if (state is StkAccountsLoadedState) {
                                    return state.accounts;
                                  }
                                  return [];
                                },
                                onSelected: (value) {
                                  setState(() {
                                    accNumber = value.accNumber;
                                  });
                                },
                                noResultsText: tr.noDataFound,
                                showClearButton: true,
                              ),
                            ),
                            SizedBox(
                              width: 275,
                              child: ZRangeDatePicker(
                                label: tr.selectDate,
                                initialStartDate: DateTime.tryParse(fromDate),
                                initialEndDate: DateTime.tryParse(toDate),
                                startValue: fromDate,
                                endValue: toDate,
                                onStartDateChanged: (startDate) {
                                  setState(() {
                                    fromDate = startDate;
                                  });
                                },
                                onEndDateChanged: (endDate) {
                                  setState(() {
                                    toDate = endDate;
                                  });
                                  onSubmit();
                                },
                                minYear: 2000,
                                maxYear: 2100,
                              ),
                            ),
                          ],
                        ),
                        // ── Toolbar ────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  ZOutlineButton(
                                    icon: Icons.document_scanner_outlined,
                                    backgroundHover: Colors.green,
                                    onPressed: () {
                                      if (accountStatementModel != null &&
                                          accountStatementModel!.records != null &&
                                          accountStatementModel!
                                              .records!.isNotEmpty) {
                                        AccountStatementExcelService.exportToExcel(
                                          accountStatement: accountStatementModel!,
                                          fromDate: fromDate,
                                          toDate: toDate,
                                          fileName:
                                          'Account_Statement_${accountStatementModel!.accNumber}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
                                          context: context,
                                        );
                                      } else {
                                        ToastManager.show(
                                          context: context,
                                          title: "No Data",
                                          message:
                                          "Please load account statement first.",
                                          type: ToastType.warning,
                                        );
                                      }
                                    },
                                    label: const Text("EXCEL"),
                                  ),
                                  const SizedBox(width: 8),
                                  ZOutlineButton(
                                    icon: Icons.picture_as_pdf,
                                    label: const Text("PDF"),
                                    onPressed: _onPrint,
                                  ),
                                  const SizedBox(width: 8),
                                  ZOutlineButton(
                                    icon: Icons.message,
                                    onPressed: () {
                                      final helper = WhatsAppShareHelper(context);
                                      helper.shareViaWhatsApp(
                                        accountNumber: accNumber.toString(),
                                        signatory:
                                        accountStatementModel?.signatory ?? "",
                                        accountName:
                                        accountStatementModel?.accName ?? "",
                                        currentBalance: accountStatementModel
                                            ?.curBalance.toDoubleAmount(),
                                        availableBalance: accountStatementModel
                                            ?.avilBalance.toDoubleAmount(),
                                        currencySymbol:
                                        accountStatementModel?.actCurrency ??
                                            "",
                                      );
                                    },
                                    label: Text(tr.share),
                                  ),
                                  const SizedBox(width: 8),
                                  ZOutlineButton(
                                    isActive: true,
                                    icon: Icons.call_to_action_outlined,
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        onSubmit();
                                      }
                                    },
                                    label: Text(tr.submit),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Column headers ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: dateWith,
                          child: Text(
                            tr.date,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        SizedBox(
                          width: refWidth,
                          child: Text(
                            tr.reference,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tr.narration,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        SizedBox(
                          width: amountWidth,
                          child: Text(
                            textAlign: myLocale == "en"
                                ? TextAlign.right
                                : TextAlign.left,
                            tr.debit,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        SizedBox(
                          width: amountWidth,
                          child: Text(
                            textAlign: myLocale == "en"
                                ? TextAlign.right
                                : TextAlign.left,
                            tr.credit,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        SizedBox(
                          width: balanceWidth,
                          child: Text(
                            textAlign: myLocale == "en"
                                ? TextAlign.right
                                : TextAlign.left,
                            tr.balance,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 15),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),
                  Divider(
                    endIndent: 10,
                    indent: 10,
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  // ── Rows ───────────────────────────────────
                  Expanded(
                    child: BlocBuilder<AccStatementBloc, AccStatementState>(
                      builder: (context, state) {
                        if (state is AccStatementLoadingState) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (state is AccStatementErrorState) {
                          return Center(child: Text(state.message));
                        }
                        if (state is AccStatementLoadedState) {
                          final records =
                              state.accStatementDetails.records;
                          accountStatementModel =
                              state.accStatementDetails;
                          if (records == null || records.isEmpty) {
                            return const Center(
                                child: Text("No transactions found"));
                          }

                          return ListView.builder(
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final stmt = records[index];
                              final isCopied = _copiedStates[
                              stmt.trnReference ?? ""] ??
                                  false;
                              final reference = stmt.trnReference ?? "";

                              final Color bg =
                              stmt.trdNarration == "Opening Balance" ||
                                  stmt.trdNarration ==
                                      "Closing Balance"
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                  .colorScheme
                                  .secondary;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: index.isOdd
                                      ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.05)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: dateWith,
                                      child: Text(
                                        stmt.trnEntryDate
                                            ?.toFormattedDate() ??
                                            "",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ),
                                    SizedBox(
                                      width: refWidth,
                                      child: Row(
                                        children: [
                                          if (stmt.trnReference != null &&
                                              stmt.trnReference!
                                                  .isNotEmpty) ...[
                                            SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () =>
                                                      _copyToClipboard(
                                                          reference, context),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      4),
                                                  hoverColor: Theme.of(
                                                      context)
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: .05),
                                                  child: AnimatedContainer(
                                                    duration:
                                                    const Duration(
                                                        milliseconds:
                                                        100),
                                                    decoration: BoxDecoration(
                                                      color: isCopied
                                                          ? Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withAlpha(25)
                                                          : Colors
                                                          .transparent,
                                                      border: Border.all(
                                                        color: isCopied
                                                            ? Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            : Theme.of(context)
                                                            .colorScheme
                                                            .outline
                                                            .withValues(
                                                            alpha:
                                                            .3),
                                                        width: 1,
                                                      ),
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(4),
                                                    ),
                                                    child: Center(
                                                      child: AnimatedSwitcher(
                                                        duration:
                                                        const Duration(
                                                            milliseconds:
                                                            300),
                                                        child: Icon(
                                                          isCopied
                                                              ? Icons.check
                                                              : Icons
                                                              .content_copy,
                                                          key: ValueKey<bool>(
                                                              isCopied),
                                                          size: 15,
                                                          color: isCopied
                                                              ? Theme.of(
                                                              context)
                                                              .colorScheme
                                                              .primary
                                                              : Theme.of(
                                                              context)
                                                              .colorScheme
                                                              .outline
                                                              .withValues(
                                                              alpha:
                                                              .6),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Expanded(
                                            child: Text(
                                                stmt.trnReference.toString()),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        stmt.trdNarration ?? "",
                                        style: TextStyle(color: bg),
                                      ),
                                    ),
                                    SizedBox(
                                      width: amountWidth,
                                      child: Text(
                                        textAlign: myLocale == "en"
                                            ? TextAlign.right
                                            : TextAlign.left,
                                        "${stmt.debit?.toAmount()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(fontSize: 15),
                                      ),
                                    ),
                                    SizedBox(
                                      width: amountWidth,
                                      child: Text(
                                        textAlign: myLocale == "en"
                                            ? TextAlign.right
                                            : TextAlign.left,
                                        "${stmt.credit?.toAmount()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(fontSize: 15),
                                      ),
                                    ),
                                    SizedBox(
                                      width: balanceWidth,
                                      child: Text(
                                        textAlign: myLocale == "en"
                                            ? TextAlign.right
                                            : TextAlign.left,
                                        "${stmt.total?.toAmount()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                          color: bg,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 15,
                                      child: Text(
                                        stmt.status ?? "",
                                        textAlign: myLocale == "en"
                                            ? TextAlign.right
                                            : TextAlign.left,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                        return Center(
                          child: NoDataWidget(
                            title: tr.accountStatement,
                            message: "accountStatementMessage",
                            enableAction: false,
                          ),
                        );
                      },
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

  void onSubmit() {
    if (accNumber == null) {
      ToastManager.show(
        context: context,
        title: "NO Account Selected",
        message: "Please select an account.",
        type: ToastType.info,
      );
    } else {
      context.read<AccStatementBloc>().add(
        LoadAccountStatementEvent(
          accountNumber: accNumber!,
          fromDate: fromDate.toApiStartDate(),
          toDate: toDate.toApiEndDate(),
        ),
      );
    }
  }

  void _onPrint() {
    if (formKey.currentState!.validate()) {
      final visibilityState = context.read<SettingsVisibleBloc>().state;
      showDialog(
        context: context,
        builder: (_) => PrintPreviewDialog<AccountStatementModel>(
          data: accountStatementModel!,
          company: company.copyWith(visible: visibilityState),
          buildPreview: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
          }) {
            return AccountStatementPrintSettings().printPreview(
              company: company.copyWith(visible: visibilityState),
              language: language,
              orientation: orientation,
              pageFormat: pageFormat,
              info: accountStatementModel!,
            );
          },
          onPrint: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
            required selectedPrinter,
            required copies,
            required pages,
          }) {
            return AccountStatementPrintSettings().printDocument(
              statement: records,
              company: company.copyWith(visible: visibilityState),
              language: language,
              orientation: orientation,
              pageFormat: pageFormat,
              selectedPrinter: selectedPrinter,
              info: accountStatementModel!,
              copies: copies,
              pages: pages,
            );
          },
          onSave: ({
            required data,
            required language,
            required orientation,
            required pageFormat,
          }) {
            return AccountStatementPrintSettings().createDocument(
              statement: records,
              company: company.copyWith(visible: visibilityState),
              language: language,
              orientation: orientation,
              pageFormat: pageFormat,
              info: accountStatementModel!,
            );
          },
        ),
      );
    } else {
      ToastManager.show(context: context, message: "Account Statement Message", type: ToastType.warning);
    }
  }
}