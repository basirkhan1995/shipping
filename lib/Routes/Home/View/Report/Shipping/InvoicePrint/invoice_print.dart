import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/PrintSettings/print_preview.dart';
import 'package:shipping/Features/PrintSettings/report_model.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import 'package:shipping/Features/Other/generic_textfield.dart';
import 'package:shipping/Features/Other/responsive_widget.dart';
import 'package:shipping/Features/Widgets/no_data_widget.dart';
import 'package:shipping/Features/Widgets/ztextfield.dart';
import 'package:shipping/l10n/app_localizations.dart';
import 'package:shipping/Routes/Auth/bloc/auth_bloc.dart';
import 'package:shipping/Routes/Auth/features/com_logo.dart';
import 'package:shipping/Routes/Home/View/Settings/Visibility/bloc/settings_visible_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/model/stk_model.dart';
import '../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../l10n/Bloc/localizations_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import 'PDF/print_pdf.dart';
import 'bloc/invoice_print_bloc.dart';
import 'model/inv_print_model.dart';

class ShpInvoiceView extends StatelessWidget {
  final int? initialAccountNumber;
  const ShpInvoiceView({super.key, this.initialAccountNumber});

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
  final containerController = TextEditingController();
  final sequenceController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  int? accNumber;
  String? myLocale;
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();

  @override
  void initState() {
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<InvoicePrintBloc>().add(const InvoicePrintReset());

    final preset = widget.initialAccountNumber;
    if (preset != null) {
      accNumber = preset;
      accountController.text = preset.toString();
    }
    super.initState();
  }

  Future<void> _generate(BuildContext context) async {
    if (!formKey.currentState!.validate() || accNumber == null) {
      ToastManager.show(
        context: context,
        title: "Warning",
        message: "Please select an account and one of container/seq.",
        type: ToastType.warning,
      );
      return;
    }

    final cNo = containerController.text.trim();
    final sNo = sequenceController.text.trim();

    if (cNo.isEmpty && sNo.isEmpty) {
      ToastManager.show(
        context: context,
        title: "Warning",
        message: "At least one of Container No or Sequence No is required.",
        type: ToastType.warning,
      );
      return;
    }

    context.read<InvoicePrintBloc>().add(
      InvoicePrintRequested(
        PrintInvoiceRequest(
          accountNo: accNumber.toString(),
          containerNo: cNo.isEmpty ? null : cNo,
          sequenceNo: sNo.isEmpty ? null : sNo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Shipping Invoice"),
        titleSpacing: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthenticatedState) {

            final auth = state.loginData;
            print("Hellooooooooooo : ${auth.company?.comSlogan ??""}");
            print("Hiiiiiiiiii : ${auth.company?.comDetails ??""}");
            company.comName = auth.company?.comName ?? "";
            company.comAddress = auth.company?.comAddress ?? "";
            company.compPhone = auth.company?.comPhone ?? "";
            company.comEmail = auth.company?.comEmail ?? "";
            company.comWhatsApp = auth.company?.comWhatsapp ?? "";
            company.comWebsite = auth.company?.comWebsite ?? "";
            company.comFacebook = auth.company?.comFb ?? "";
            company.comInstagram = auth.company?.comInsta ?? "";
            company.statementDate = DateTime.now().toFullDateTime;
            company.slogan = auth.company?.comSlogan ??"";
            final base64Logo = auth.company?.comLogo;
            _companyLogo = CompanyLogoUtils.safeBytes(base64Logo) ?? Uint8List(0);
            company.comLogo = _companyLogo.isEmpty ? null : _companyLogo;
          }

          return BlocConsumer<InvoicePrintBloc, InvoicePrintState>(
            listener: (context, state) {
              if (state is InvoicePrintSuccess) {
                final invoice = state.invoice;
                if (invoice.items.isEmpty) {
                  ToastManager.show(
                    context: context,
                    message: "No items found for this customer.",
                    type: ToastType.warning,
                  );
                  return;
                }
                _showPreview(context, invoice);
              } else if (state is InvoicePrintFailure) {
                ToastManager.show(
                  context: context,
                  message: state.message,
                  type: ToastType.error,
                );
              }
            },
            builder: (context, state) {
              final loading = state is InvoicePrintLoading;

              final tr = AppLocalizations.of(context)!;
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      GenericTextField<StkAccountModel, StkAccountsBloc, StkAccountsState>(
                        showAllOnFocus: true,
                        controller: accountController,
                        title: tr.accounts,
                        hintText: tr.accNameOrNumber,
                        isRequired: true,
                        bloc: context.read<StkAccountsBloc>(),
                        fetchAllFunction: (bloc) => bloc.add(const LoadStkAccountsEvent()),
                        searchFunction: (bloc, query) => bloc.add(LoadStkAccountsEvent(query: query)),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr.required(tr.accounts);
                          }
                          return null;
                        },
                        itemBuilder: (context, account) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 5),
                          child: Text(
                            "${account.accNumber} | ${account.accName}",
                            style: Theme.of(context).textTheme.bodyLarge,
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
                          if (state is! StkAccountsLoadedState) {
                            return const <StkAccountModel>[];
                          }
                          return state.accounts
                              .where((a) => a.accCategory == 8)
                              .toList();
                        },
                        onSelected: (value) =>
                            setState(() => accNumber = value.accNumber),
                        noResultsText: tr.noDataFound,
                        showClearButton: true,
                      ),
                      const SizedBox(height: 12),
                      ZTextFieldEntitled(
                        controller: containerController,
                        title: tr.accounts,
                        hint: "e.g. GCLE332423",
                      ),
                      const SizedBox(height: 12),
                      ZTextFieldEntitled(
                        controller: sequenceController,
                        title: tr.sequence,
                        hint: "e.g. 360",
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ZOutlineButton(
                          isActive: loading || accNumber == null,
                          onPressed: (loading || accNumber == null)
                              ? null
                              : () => _generate(context),
                          icon: Icons.picture_as_pdf,
                          label: loading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text("PDF / PRINT"),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withAlpha(100),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Select a customer, enter container no or seq no,\n"
                            "then tap PDF / PRINT to preview the invoice.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          height: 1.5,
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

  void _showPreview(BuildContext context, ShippingInvoice invoice) {
    final visibilityState = context.read<SettingsVisibleBloc>().state;
    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<ShippingInvoice>(
        data: invoice,
        company: company.copyWith(visible: visibilityState),
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return ShippingInvoicePrintSettings().printPreview(
            company: company.copyWith(visible: visibilityState),
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            info: invoice,
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
          return ShippingInvoicePrintSettings().printDocument(
            info: invoice,
            company: company.copyWith(visible: visibilityState),
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            selectedPrinter: selectedPrinter,
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
          return ShippingInvoicePrintSettings().createDocument(
            info: invoice,
            company: company.copyWith(visible: visibilityState),
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
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
  final accountController = TextEditingController();
  final containerController = TextEditingController();
  final sequenceController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final accountFocus   = FocusNode();
  final containerFocus = FocusNode();
  final sequenceFocus  = FocusNode();
  int? accNumber;
  String? myLocale;
  Uint8List _companyLogo = Uint8List(0);
  final company = ReportModel();

  @override
  void initState() {
    super.initState();
    myLocale = context.read<LocalizationBloc>().state.languageCode;
    context.read<InvoicePrintBloc>().add(const InvoicePrintReset());

    final preset = widget.initialAccountNumber;
    if (preset != null) {
      accNumber = preset;
      accountController.text = preset.toString();
    }

    accountFocus.addListener(_onFocusChanged);
    containerFocus.addListener(_onFocusChanged);
    sequenceFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});

  }

  @override
  void dispose() {
    accountController.dispose();
    containerController.dispose();
    sequenceController.dispose();

    accountFocus.dispose();
    containerFocus.dispose();
    sequenceFocus.dispose();

    super.dispose();
  }

  Future<void> _generate() async {
    if (!formKey.currentState!.validate() || accNumber == null) return;

    final cNo = containerController.text.trim();
    final sNo = sequenceController.text.trim();

    if (cNo.isEmpty && sNo.isEmpty) {
      ToastManager.show(
        context: context,
        title: "Warning",
        message: "At least one of Container No or Sequence No is required.",
        type: ToastType.warning,
      );
      return;
    }

    context.read<InvoicePrintBloc>().add(
      InvoicePrintRequested(
        PrintInvoiceRequest(
          accountNo: accNumber.toString(),
          containerNo: cNo.isEmpty ? null : cNo,
          sequenceNo: sNo.isEmpty ? null : sNo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(tr.shipmentInvoice),
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
            company.comWhatsApp = auth.company?.comWhatsapp ?? "";
            company.comWebsite = auth.company?.comWebsite ?? "";
            company.comFacebook = auth.company?.comFb ?? "";
            company.comInstagram = auth.company?.comInsta ?? "";
            company.statementDate = DateTime.now().toFullDateTime;
            company.slogan = auth.company?.comDetails ??"";
            final base64Logo = auth.company?.comLogo;
            _companyLogo = CompanyLogoUtils.safeBytes(base64Logo) ?? Uint8List(0);
            company.comLogo = _companyLogo.isEmpty ? null : _companyLogo;
          }

          return BlocConsumer<InvoicePrintBloc, InvoicePrintState>(
            listener: (context, state) {
              if (state is InvoicePrintSuccess) {
                final invoice = state.invoice;
                if (invoice.items.isEmpty) {
                  ToastManager.show(
                    context: context,
                    message: "No items found for this customer.",
                    type: ToastType.warning,
                  );
                  return;
                }
                _showPreview(context, invoice);
              } else if (state is InvoicePrintFailure) {
                ToastManager.show(
                  context: context,
                  message: state.message,
                  type: ToastType.error,
                );
              }
            },
            builder: (context, state) {
              final loading = state is InvoicePrintLoading;

              return Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 350,
                              child: GenericTextField<StkAccountModel, StkAccountsBloc, StkAccountsState>(
                                focusNode: accountFocus,
                                showAllOnFocus: true,
                                controller: accountController,
                                title: tr.accounts,
                                hintText: tr.accNameOrNumber,
                                isRequired: true,
                                bloc: context.read<StkAccountsBloc>(),
                                fetchAllFunction: (bloc) => bloc.add(const LoadStkAccountsEvent()),
                                searchFunction: (bloc, query) => bloc.add(LoadStkAccountsEvent(query: query)),
                                validator: (value) => (value == null || value.isEmpty)
                                    ? tr.required(tr.accounts)
                                    : null,
                                itemBuilder: (context, account) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                  child: Text("${account.accNumber} | ${account.accName}",
                                      style: Theme.of(context).textTheme.bodyLarge),
                                ),
                                itemToString: (acc) => "${acc.accNumber} | ${acc.accName}",
                                stateToLoading: (s) => s is StkAccountsLoadingState,
                                loadingBuilder: (_) => const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 3),
                                ),
                                stateToItems: (s) => s is StkAccountsLoadedState
                                    ? s.accounts.where((a) => a.accCategory == 8).toList()
                                    : const <StkAccountModel>[],
                                onSelected: (value) {
                                  setState(() => accNumber = value.accNumber);
                                  containerFocus.requestFocus();       // ← auto-advance
                                },
                                noResultsText: tr.noDataFound,
                                showClearButton: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 220,
                              child: ZTextFieldEntitled(
                                focusNode: containerFocus,
                                controller: containerController,
                                title: tr.containerNo,
                                hint: "GCLE332423",
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => sequenceFocus.requestFocus(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 160,
                              child: ZTextFieldEntitled(
                                focusNode: sequenceFocus,
                                controller: sequenceController,
                                title: tr.sequence,
                                hint: "360",
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _generate(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ZOutlineButton(
                              height: 47,
                              isActive: !loading && accNumber != null,
                              icon: Icons.picture_as_pdf,
                              label: loading
                                  ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : Text(tr.printPdf),
                              onPressed: (!loading && accNumber != null) ? _generate : null,
                            ),
                          ],
                        )
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Center(
                          child: state is InvoicePrintLoading
                              ? const CircularProgressIndicator()
                              : NoDataWidget(
                            title: tr.shipmentInvoice,
                            message:
                            tr.shippingPrintHint,
                            enableAction: false,
                          ),
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

  void _showPreview(BuildContext context, ShippingInvoice invoice) {
    final visibilityState = context.read<SettingsVisibleBloc>().state;

    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<ShippingInvoice>(
        data: invoice,
        company: company.copyWith(visible: visibilityState),
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return ShippingInvoicePrintSettings().printPreview(
            company: company.copyWith(visible: visibilityState),
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            info: invoice,
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
          return ShippingInvoicePrintSettings().printDocument(
            info: invoice,
            company: company.copyWith(visible: visibilityState),
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
            selectedPrinter: selectedPrinter,
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
          return ShippingInvoicePrintSettings().createDocument(
            info: invoice,
            company: company.copyWith(visible: visibilityState),
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
          );
        },
      ),
    );
  }
}