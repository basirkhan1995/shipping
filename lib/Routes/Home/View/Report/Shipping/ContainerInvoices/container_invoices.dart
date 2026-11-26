import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../../Features/Widgets/toast.dart';
import '../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../l10n/Bloc/localizations_bloc.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/features/com_logo.dart';
import '../../../Settings/Visibility/bloc/settings_visible_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../../Stakeholder/model/stk_model.dart';
import '../InvoicePrint/bloc/invoice_print_bloc.dart';
import '../InvoicePrint/model/inv_print_model.dart';
import '../InvoicePrint/PDF/print_pdf.dart';
import 'PDF/cont_invoices_print.dart';
import 'bloc/container_invoices_bloc.dart';
import 'model/cont_invoices_model.dart';

class ContainerInvoicesView extends StatelessWidget {
  final int? initialAccountNumber;
  const ContainerInvoicesView({super.key, this.initialAccountNumber});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(initialAccountNumber: initialAccountNumber),
      tablet: _Tablet(initialAccountNumber: initialAccountNumber),
      desktop: _Desktop(initialAccountNumber: initialAccountNumber),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared mixin: company hydration + preview dialog + batch dialog
// ═══════════════════════════════════════════════════════════════════
mixin _CompanyHydrator<T extends StatefulWidget> on State<T> {
  final company = ReportModel();
  Uint8List _companyLogo = Uint8List(0);

  void hydrateCompany(AuthState authState) {
    if (authState is! AuthenticatedState) return;
    final auth = authState.loginData;
    company.comName = auth.company?.comName ?? "";
    company.comAddress = auth.company?.comAddress ?? "";
    company.compPhone = auth.company?.comPhone ?? "";
    company.comEmail = auth.company?.comEmail ?? "";
    company.comWhatsApp = auth.company?.comWhatsapp ?? "";
    company.comWebsite = auth.company?.comWebsite ?? "";
    company.comFacebook = auth.company?.comFb ?? "";
    company.comInstagram = auth.company?.comInsta ?? "";
    company.statementDate = DateTime.now().toFullDateTime;
    company.slogan = auth.company?.comDetails ?? "";
    final base64Logo = auth.company?.comLogo;
    _companyLogo = CompanyLogoUtils.safeBytes(base64Logo) ?? Uint8List(0);
    company.comLogo = _companyLogo.isEmpty ? null : _companyLogo;
  }

  void showPreview(BuildContext context, ShippingInvoice invoice) {
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

  void showBatchDialog(BuildContext context, ContainerInvoices data) {
    final visibilityState = context.read<SettingsVisibleBloc>().state;
    final lang = context.read<LocalizationBloc>().state.languageCode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool busy = false;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text(
                '${data.count} invoices • '
                    '${data.containerNo ?? data.sequenceNo ?? ""}',
              ),
              content: SizedBox(
                width: 460,
                height: 380,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: data.invoices.length,
                        separatorBuilder: (_, _) =>
                        const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final inv = data.invoices[i];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            title: Text(
                              inv.customer.accountName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${inv.customer.accountNo} • '
                                  '${inv.items.length} items • '
                                  '${inv.totals.totalRent.toStringAsFixed(2)} '
                                  '${inv.totals.currency ?? ""}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                    if (busy) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text(
                        'Generating PDFs…',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                    context
                        .read<ContainerInvoicesBloc>()
                        .add(const ContainerInvoicesReset());
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text('Cancel'),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('Share ALL'),
                  onPressed: busy
                      ? null
                      : () async {
                    setDialogState(() => busy = true);
                    try {
                      await ContainerInvoicesPrintSettings().shareBatch(
                        infoList: data.invoices,
                        language: lang,
                        company: company
                            .copyWith(visible: visibilityState),
                      );
                      if (dialogCtx.mounted) {
                        ToastManager.show(
                          context: dialogCtx,
                          message:
                          'Shared ${data.invoices.length} invoices via system share sheet.',
                          type: ToastType.success,
                        );
                      }
                    } catch (e) {
                      if (dialogCtx.mounted) {
                        ToastManager.show(
                          context: dialogCtx,
                          message: 'Share failed: $e',
                          type: ToastType.error,
                        );
                      }
                    } finally {
                      if (dialogCtx.mounted) {
                        setDialogState(() => busy = false);
                      }
                    }
                  },
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('Save ALL'),
                  onPressed: busy
                      ? null
                      : () async {
                    setDialogState(() => busy = true);
                    final folder = data.containerNo ??
                        data.sequenceNo ??
                        'container';
                    try {
                      final paths =
                      await ContainerInvoicesPrintSettings()
                          .saveBatch(
                        infoList: data.invoices,
                        language: lang,
                        company: company
                            .copyWith(visible: visibilityState),
                        containerFolder: folder,
                      );

                      if (dialogCtx.mounted && paths.isNotEmpty) {
                        final firstPath = paths.first;
                        final saveFolder = firstPath.substring(
                          0,
                          firstPath
                              .lastIndexOf(Platform.pathSeparator),
                        );
                        _showSavedDialog(
                          dialogCtx,
                          folderPath: saveFolder,
                          fileCount: paths.length,
                        );
                      }
                    } catch (e) {
                      if (dialogCtx.mounted) {
                        ToastManager.show(
                          context: dialogCtx,
                          message: 'Save failed: $e',
                          type: ToastType.error,
                        );
                      }
                    } finally {
                      if (dialogCtx.mounted) {
                        setDialogState(() => busy = false);
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows the exact folder path where the PDFs were saved,
  /// plus a "Copy path" button and (on desktop) "Open folder".
  void _showSavedDialog(
      BuildContext context, {
        required String folderPath,
        required int fileCount,
      }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text('Saved $fileCount PDFs'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location:'),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                folderPath,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy path'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: folderPath));
              if (ctx.mounted) {
                ToastManager.show(
                  context: ctx,
                  message: 'Path copied to clipboard',
                  type: ToastType.success,
                );
              }
            },
          ),
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
            TextButton.icon(
              icon: const Icon(Icons.folder_open, size: 16),
              label: const Text('Open folder'),
              onPressed: () => _openFolder(folderPath),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Opens the folder in the OS file browser (desktop only).
  void _openFolder(String path) {
    try {
      if (Platform.isWindows) {
        Process.run('explorer', [path]);
      } else if (Platform.isMacOS) {
        Process.run('open', [path]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [path]);
      }
    } catch (_) {
      // ignore — path is already shown + copyable
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════
class _Desktop extends StatefulWidget {
  final int? initialAccountNumber;
  const _Desktop({this.initialAccountNumber});

  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> with _CompanyHydrator {
  final accountController = TextEditingController();
  final containerController = TextEditingController();
  final sequenceController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final accountFocus = FocusNode();
  final containerFocus = FocusNode();
  final sequenceFocus = FocusNode();
  int? accNumber;

  @override
  void initState() {
    super.initState();
    context.read<InvoicePrintBloc>().add(const InvoicePrintReset());
    context.read<ContainerInvoicesBloc>().add(const ContainerInvoicesReset());

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

  void _generateBatch() {
    final cNo = containerController.text.trim();
    final sNo = sequenceController.text.trim();

    if (cNo.isEmpty && sNo.isEmpty) {
      ToastManager.show(
        context: context,
        title: "Warning",
        message: "Enter container no or sequence no.",
        type: ToastType.warning,
      );
      return;
    }

    context.read<ContainerInvoicesBloc>().add(
      ContainerInvoicesRequested(
        ContainerInvoiceRequest(
          containerNo: cNo.isEmpty ? null : cNo,
          sequenceNo: sNo.isEmpty ? null : sNo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        BlocListener<InvoicePrintBloc, InvoicePrintState>(
          listener: (context, state) {
            if (state is InvoicePrintSuccess) {
              if (state.invoice.items.isEmpty) {
                ToastManager.show(
                  context: context,
                  message: "No items found for this customer.",
                  type: ToastType.warning,
                );
                return;
              }
              showPreview(context, state.invoice);
            } else if (state is InvoicePrintFailure) {
              ToastManager.show(
                context: context,
                message: state.message,
                type: ToastType.error,
              );
            }
          },
        ),
        BlocListener<ContainerInvoicesBloc, ContainerInvoicesState>(
          listener: (context, state) {
            if (state is ContainerInvoicesSuccess) {
              showBatchDialog(context, state.data);
            } else if (state is ContainerInvoicesFailure) {
              ToastManager.show(
                context: context,
                message: state.message,
                type: ToastType.error,
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Text(tr.shipmentInvoice),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            hydrateCompany(authState);

            return BlocBuilder<InvoicePrintBloc, InvoicePrintState>(
              builder: (context, singleState) {
                final singleLoading = singleState is InvoicePrintLoading;

                return BlocBuilder<ContainerInvoicesBloc,
                    ContainerInvoicesState>(
                  builder: (context, batchState) {
                    final batchLoading =
                    batchState is ContainerInvoicesLoading;
                    final anyLoading = singleLoading || batchLoading;

                    return Form(
                      key: formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 350,
                                    child: GenericTextField<
                                        StkAccountModel,
                                        StkAccountsBloc,
                                        StkAccountsState>(
                                      focusNode: accountFocus,
                                      showAllOnFocus: true,
                                      controller: accountController,
                                      title: tr.accounts,
                                      hintText: tr.accNameOrNumber,
                                      isRequired: true,
                                      bloc: context.read<StkAccountsBloc>(),
                                      fetchAllFunction: (bloc) => bloc.add(
                                          const LoadStkAccountsEvent()),
                                      searchFunction: (bloc, query) => bloc
                                          .add(LoadStkAccountsEvent(
                                          query: query)),
                                      validator: (value) =>
                                      (value == null || value.isEmpty)
                                          ? tr.required(tr.accounts)
                                          : null,
                                      itemBuilder: (context, account) =>
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            child: Text(
                                              "${account.accNumber} | ${account.accName}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge,
                                            ),
                                          ),
                                      itemToString: (acc) =>
                                      "${acc.accNumber} | ${acc.accName}",
                                      stateToLoading: (s) =>
                                      s is StkAccountsLoadingState,
                                      loadingBuilder: (_) => const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 3),
                                      ),
                                      stateToItems: (s) =>
                                      s is StkAccountsLoadedState
                                          ? s.accounts
                                          .where((a) =>
                                      a.accCategory == 8)
                                          .toList()
                                          : const <StkAccountModel>[],
                                      onSelected: (value) {
                                        setState(() =>
                                        accNumber = value.accNumber);
                                        containerFocus.requestFocus();
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
                                      onFieldSubmitted: (_) =>
                                          sequenceFocus.requestFocus(),
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
                                    isActive:
                                    !anyLoading && accNumber != null,
                                    icon: Icons.picture_as_pdf,
                                    label: singleLoading
                                        ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                        : Text(tr.printPdf),
                                    onPressed:
                                    (!anyLoading && accNumber != null)
                                        ? _generate
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  ZOutlineButton(
                                    height: 47,
                                    isActive: !anyLoading,
                                    icon: Icons.picture_as_pdf_outlined,
                                    label: batchLoading
                                        ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                        : const Text("Print ALL"),
                                    onPressed:
                                    !anyLoading ? _generateBatch : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: Center(
                                child: anyLoading
                                    ? const CircularProgressIndicator()
                                    : NoDataWidget(
                                  title: tr.shipmentInvoice,
                                  message: tr.shippingPrintHint,
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
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TABLET
// ═══════════════════════════════════════════════════════════════════
class _Tablet extends StatefulWidget {
  final int? initialAccountNumber;
  const _Tablet({this.initialAccountNumber});

  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> with _CompanyHydrator {
  final accountController = TextEditingController();
  final containerController = TextEditingController();
  final sequenceController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  int? accNumber;

  @override
  void initState() {
    super.initState();
    context.read<InvoicePrintBloc>().add(const InvoicePrintReset());
    context.read<ContainerInvoicesBloc>().add(const ContainerInvoicesReset());

    final preset = widget.initialAccountNumber;
    if (preset != null) {
      accNumber = preset;
      accountController.text = preset.toString();
    }
  }

  @override
  void dispose() {
    accountController.dispose();
    containerController.dispose();
    sequenceController.dispose();
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

  void _generateBatch() {
    final cNo = containerController.text.trim();
    final sNo = sequenceController.text.trim();

    if (cNo.isEmpty && sNo.isEmpty) {
      ToastManager.show(
        context: context,
        title: "Warning",
        message: "Enter container no or sequence no.",
        type: ToastType.warning,
      );
      return;
    }

    context.read<ContainerInvoicesBloc>().add(
      ContainerInvoicesRequested(
        ContainerInvoiceRequest(
          containerNo: cNo.isEmpty ? null : cNo,
          sequenceNo: sNo.isEmpty ? null : sNo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        BlocListener<InvoicePrintBloc, InvoicePrintState>(
          listener: (context, state) {
            if (state is InvoicePrintSuccess) {
              if (state.invoice.items.isEmpty) {
                ToastManager.show(
                  context: context,
                  message: "No items found for this customer.",
                  type: ToastType.warning,
                );
                return;
              }
              showPreview(context, state.invoice);
            } else if (state is InvoicePrintFailure) {
              ToastManager.show(
                context: context,
                message: state.message,
                type: ToastType.error,
              );
            }
          },
        ),
        BlocListener<ContainerInvoicesBloc, ContainerInvoicesState>(
          listener: (context, state) {
            if (state is ContainerInvoicesSuccess) {
              showBatchDialog(context, state.data);
            } else if (state is ContainerInvoicesFailure) {
              ToastManager.show(
                context: context,
                message: state.message,
                type: ToastType.error,
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Text(tr.shipmentInvoice),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            hydrateCompany(authState);

            return BlocBuilder<InvoicePrintBloc, InvoicePrintState>(
              builder: (context, singleState) {
                final singleLoading = singleState is InvoicePrintLoading;

                return BlocBuilder<ContainerInvoicesBloc,
                    ContainerInvoicesState>(
                  builder: (context, batchState) {
                    final batchLoading =
                    batchState is ContainerInvoicesLoading;
                    final anyLoading = singleLoading || batchLoading;

                    return Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GenericTextField<StkAccountModel,
                                StkAccountsBloc, StkAccountsState>(
                              showAllOnFocus: true,
                              controller: accountController,
                              title: tr.accounts,
                              hintText: tr.accNameOrNumber,
                              isRequired: true,
                              bloc: context.read<StkAccountsBloc>(),
                              fetchAllFunction: (bloc) =>
                                  bloc.add(const LoadStkAccountsEvent()),
                              searchFunction: (bloc, query) => bloc
                                  .add(LoadStkAccountsEvent(query: query)),
                              validator: (value) =>
                              (value == null || value.isEmpty)
                                  ? tr.required(tr.accounts)
                                  : null,
                              itemBuilder: (context, account) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 5),
                                child: Text(
                                  "${account.accNumber} | ${account.accName}",
                                  style:
                                  Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              itemToString: (acc) =>
                              "${acc.accNumber} | ${acc.accName}",
                              stateToLoading: (s) =>
                              s is StkAccountsLoadingState,
                              loadingBuilder: (_) => const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 3),
                              ),
                              stateToItems: (s) =>
                              s is StkAccountsLoadedState
                                  ? s.accounts
                                  .where(
                                      (a) => a.accCategory == 8)
                                  .toList()
                                  : const <StkAccountModel>[],
                              onSelected: (value) => setState(
                                      () => accNumber = value.accNumber),
                              noResultsText: tr.noDataFound,
                              showClearButton: true,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ZTextFieldEntitled(
                                    controller: containerController,
                                    title: tr.containerNo,
                                    hint: "GCLE332423",
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ZTextFieldEntitled(
                                    controller: sequenceController,
                                    title: tr.sequence,
                                    hint: "360",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ZOutlineButton(
                                      isActive: !anyLoading &&
                                          accNumber != null,
                                      icon: Icons.picture_as_pdf,
                                      label: singleLoading
                                          ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child:
                                        CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                          : Text(tr.printPdf),
                                      onPressed: (!anyLoading &&
                                          accNumber != null)
                                          ? _generate
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: ZOutlineButton(
                                      isActive: !anyLoading,
                                      icon: Icons.picture_as_pdf_outlined,
                                      label: batchLoading
                                          ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child:
                                        CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                          : const Text("Print ALL"),
                                      onPressed: !anyLoading
                                          ? _generateBatch
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            if (anyLoading)
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              )
                            else
                              NoDataWidget(
                                title: tr.shipmentInvoice,
                                message: tr.shippingPrintHint,
                                enableAction: false,
                              ),
                          ],
                        ),
                      ),
                    );
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

// ═══════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════
class _Mobile extends StatefulWidget {
  final int? initialAccountNumber;
  const _Mobile({this.initialAccountNumber});

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> with _CompanyHydrator {
  final accountController = TextEditingController();
  final containerController = TextEditingController();
  final sequenceController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  int? accNumber;

  @override
  void initState() {
    super.initState();
    context.read<InvoicePrintBloc>().add(const InvoicePrintReset());
    context.read<ContainerInvoicesBloc>().add(const ContainerInvoicesReset());

    final preset = widget.initialAccountNumber;
    if (preset != null) {
      accNumber = preset;
      accountController.text = preset.toString();
    }
  }

  @override
  void dispose() {
    accountController.dispose();
    containerController.dispose();
    sequenceController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
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

  void _generateBatch() {
    final cNo = containerController.text.trim();
    final sNo = sequenceController.text.trim();

    if (cNo.isEmpty && sNo.isEmpty) {
      ToastManager.show(
        context: context,
        title: "Warning",
        message: "Enter container no or sequence no.",
        type: ToastType.warning,
      );
      return;
    }

    context.read<ContainerInvoicesBloc>().add(
      ContainerInvoicesRequested(
        ContainerInvoiceRequest(
          containerNo: cNo.isEmpty ? null : cNo,
          sequenceNo: sNo.isEmpty ? null : sNo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        BlocListener<InvoicePrintBloc, InvoicePrintState>(
          listener: (context, state) {
            if (state is InvoicePrintSuccess) {
              if (state.invoice.items.isEmpty) {
                ToastManager.show(
                  context: context,
                  message: "No items found for this customer.",
                  type: ToastType.warning,
                );
                return;
              }
              showPreview(context, state.invoice);
            } else if (state is InvoicePrintFailure) {
              ToastManager.show(
                context: context,
                message: state.message,
                type: ToastType.error,
              );
            }
          },
        ),
        BlocListener<ContainerInvoicesBloc, ContainerInvoicesState>(
          listener: (context, state) {
            if (state is ContainerInvoicesSuccess) {
              showBatchDialog(context, state.data);
            } else if (state is ContainerInvoicesFailure) {
              ToastManager.show(
                context: context,
                message: state.message,
                type: ToastType.error,
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(tr.shipmentInvoice),
          titleSpacing: 0,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            hydrateCompany(authState);

            return BlocBuilder<InvoicePrintBloc, InvoicePrintState>(
              builder: (context, singleState) {
                final singleLoading = singleState is InvoicePrintLoading;

                return BlocBuilder<ContainerInvoicesBloc,
                    ContainerInvoicesState>(
                  builder: (context, batchState) {
                    final batchLoading =
                    batchState is ContainerInvoicesLoading;
                    final anyLoading = singleLoading || batchLoading;

                    return Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            GenericTextField<StkAccountModel,
                                StkAccountsBloc, StkAccountsState>(
                              showAllOnFocus: true,
                              controller: accountController,
                              title: tr.accounts,
                              hintText: tr.accNameOrNumber,
                              isRequired: true,
                              bloc: context.read<StkAccountsBloc>(),
                              fetchAllFunction: (bloc) =>
                                  bloc.add(const LoadStkAccountsEvent()),
                              searchFunction: (bloc, query) => bloc
                                  .add(LoadStkAccountsEvent(query: query)),
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
                                  style:
                                  Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              itemToString: (acc) =>
                              "${acc.accNumber} | ${acc.accName}",
                              stateToLoading: (state) =>
                              state is StkAccountsLoadingState,
                              loadingBuilder: (context) => const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 3),
                              ),
                              stateToItems: (state) {
                                if (state is! StkAccountsLoadedState) {
                                  return const <StkAccountModel>[];
                                }
                                return state.accounts
                                    .where((a) => a.accCategory == 8)
                                    .toList();
                              },
                              onSelected: (value) => setState(
                                      () => accNumber = value.accNumber),
                              noResultsText: tr.noDataFound,
                              showClearButton: true,
                            ),
                            const SizedBox(height: 12),
                            ZTextFieldEntitled(
                              controller: containerController,
                              title: tr.containerNo,
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
                                isActive:
                                !anyLoading && accNumber != null,
                                onPressed:
                                (!anyLoading && accNumber != null)
                                    ? _generate
                                    : null,
                                icon: Icons.picture_as_pdf,
                                label: singleLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                                    : const Text("PDF / PRINT"),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ZOutlineButton(
                                isActive: !anyLoading,
                                onPressed:
                                !anyLoading ? _generateBatch : null,
                                icon: Icons.picture_as_pdf_outlined,
                                label: batchLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                                    : const Text("PRINT ALL (container)"),
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
                                  "then tap PDF / PRINT to preview one invoice,\n"
                                  "or PRINT ALL to generate for every customer.",
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
                    );
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