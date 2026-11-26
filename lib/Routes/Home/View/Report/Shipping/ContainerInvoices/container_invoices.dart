import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/utils.dart';
import '../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../Features/Other/form_dialog.dart';
import '../../../../../../Features/Other/generic_textfield.dart';
import '../../../../../../Features/Other/responsive_widget.dart';
import '../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../Features/Widgets/no_data_widget.dart';
import '../../../../../../Features/Widgets/toast.dart';
import '../../../../../../Features/Widgets/zbutton.dart';
import '../../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../../Services/repository.dart';
import '../../../../../../l10n/Bloc/localizations_bloc.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../Auth/features/com_logo.dart';
import '../../../Settings/Visibility/bloc/settings_visible_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import '../../../Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import '../../../Stakeholder/model/stk_model.dart';
import 'PDF/cont_invoices_print.dart';
import 'bloc/container_invoices_bloc.dart';
import 'model/cont_invoices_model.dart';

class ContainerInvoicesView extends StatelessWidget {
  final int? initialAccountNumber;
  const ContainerInvoicesView({super.key, this.initialAccountNumber});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ContainerInvoicesBloc>(
      create: (_) => ContainerInvoicesBloc(context.read<Repositories>()),
      child: ResponsiveLayout(
        mobile: _Mobile(initialAccountNumber: initialAccountNumber),
        tablet: _Tablet(initialAccountNumber: initialAccountNumber),
        desktop: _Desktop(initialAccountNumber: initialAccountNumber),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared mixin: company hydration + preview + batch dialog
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
          return ContainerInvoicesPrintSettings().printPreview(
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
          return ContainerInvoicesPrintSettings().printDocument(
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
          return ContainerInvoicesPrintSettings().createDocument(
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
    final tr = AppLocalizations.of(context)!;

    bool busy = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return ZFormDialog(
              title:
              '${data.count} ${tr.invoices} • ${data.containerNo} - ${data.sequenceNo}',
              icon: Icons.receipt_long,
              width: 720,
              isLoading: busy,
              errorMessage: error,
              onAction: null,
              isActionTrue: false, // we render our own bottom actions
              child: SizedBox(
                height: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Table header ──────────────────────────────
                    _batchTableHeader(tr, lang),
                    // ── Rows ──────────────────────────────────────
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(dialogCtx)
                                .colorScheme
                                .outline
                                .withValues(alpha: .3),
                          ),
                        ),
                        child: ListView.separated(
                          itemCount: data.invoices.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            thickness: .5,
                            color: Theme.of(dialogCtx)
                                .colorScheme
                                .outline
                                .withValues(alpha: .2),
                          ),
                          itemBuilder: (_, i) {
                            final inv = data.invoices[i];
                            return _batchRow(inv, i, dialogCtx, lang);
                          },
                        ),
                      ),
                    ),
                    // ── Bottom action bar ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ZOutlineButton(
                            label: Text(tr.cancel),
                            height: 38,
                            width: 120,
                            backgroundHover:
                            Theme.of(dialogCtx).colorScheme.error,
                            onPressed: busy
                                ? null
                                : () {
                              context
                                  .read<ContainerInvoicesBloc>()
                                  .add(const ContainerInvoicesReset());
                              Navigator.pop(dialogCtx);
                            },
                          ),
                          Row(
                            spacing: 8,
                            children: [
                              ZOutlineButton(
                                label: Text(tr.share),
                                icon: Icons.share,
                                height: 38,
                                width: 140,
                                disable: busy,
                                onPressed: busy
                                    ? null
                                    : () async {
                                  setDialogState(() {
                                    busy = true;
                                    error = null;
                                  });
                                  try {
                                    await ContainerInvoicesPrintSettings()
                                        .shareBatch(
                                      infoList: data.invoices,
                                      language: lang,
                                      company: company.copyWith(
                                          visible: visibilityState),
                                    );
                                    if (dialogCtx.mounted) {
                                      ToastManager.show(
                                        context: dialogCtx,
                                        message:
                                        'Shared ${data.invoices.length} invoices.',
                                        type: ToastType.success,
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => error = '$e');
                                  } finally {
                                    if (dialogCtx.mounted) {
                                      setDialogState(() => busy = false);
                                    }
                                  }
                                },
                              ),
                              ZOutlineButton(
                                label: Text(tr.save),
                                icon: Icons.save_alt,
                                height: 38,
                                width: 140,
                                isActive: !busy,
                                backgroundHover:
                                Theme.of(dialogCtx).colorScheme.primary,
                                disable: busy,
                                onPressed: busy
                                    ? null
                                    : () async {
                                  setDialogState(() {
                                    busy = true;
                                    error = null;
                                  });
                                  final folder = data.containerNo ??
                                      data.sequenceNo ??
                                      'container';
                                  try {
                                    final paths =
                                    await ContainerInvoicesPrintSettings()
                                        .saveBatch(
                                      infoList: data.invoices,
                                      language: lang,
                                      company: company.copyWith(
                                          visible: visibilityState),
                                      containerFolder: folder,
                                    );
                                    if (dialogCtx.mounted &&
                                        paths.isNotEmpty) {
                                      final firstPath = paths.first;
                                      final saveFolder =
                                      firstPath.substring(
                                        0,
                                        firstPath.lastIndexOf(
                                            Platform.pathSeparator),
                                      );
                                      _showSavedDialog(
                                        dialogCtx,
                                        folderPath: saveFolder,
                                        fileCount: paths.length,
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => error = '$e');
                                  } finally {
                                    if (dialogCtx.mounted) {
                                      setDialogState(() => busy = false);
                                    }
                                  }
                                },
                              ),
                            ],
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
    );
  }

// ── Header row for the batch list ─────────────────────────────
  Widget _batchTableHeader(AppLocalizations tr, String lang) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: .08),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: .4),
            width: .5,
          ),
        ),
      ),
      child: Row(
        children: [
          _hCell('#', 40, center: true),
          _hCell(tr.account, 130),
          _hCell(tr.customer, null),
          _hCell(tr.noItems, 70, center: true),
          _hCell(tr.qty, 70, center: true),
          _hCell(tr.rent, 110, center: true),
        ],
      ),
    );
  }

  Widget _hCell(String text, double? w, {bool center = false}) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return w == null ? Expanded(child: child) : SizedBox(width: w, child: child);
  }

  Widget _batchRow(
      ShippingInvoice inv,
      int index,
      BuildContext context,
      String lang,
      ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      color: index.isOdd
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: .25)
          : null,
      child: Row(
        children: [
          _dCell('${index + 1}', 40, center: true),
          _dCell('${inv.customer.accountNo}', 130),
          _dCell(inv.customer.accountName ?? '', null,align: TextAlign.start,
          ),
          _dCell('${inv.items.length}', 70, center: true),
          _dCell('${inv.totals.qty}', 70, center: true),
          _dCell(
            '${inv.totals.totalRent.toStringAsFixed(2)} ${Utils.ccy(type: inv.totals.currency??"", locale: AppLocalizations.of(context)!)}',
            110,
            center: true,
            emphasize: true,
            color: scheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _dCell(
      String text,
      double? w, {
        bool center = false,
        bool emphasize = false,
        TextAlign align = TextAlign.start,
        Color? color,
      }) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: center ? TextAlign.center : align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
          color: color,
        ),
      ),
    );
    return w == null ? Expanded(child: child) : SizedBox(width: w, child: child);
  }

  void _showSavedDialog(BuildContext context, {required String folderPath, required int fileCount}) {
    final tr = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return ZFormDialog(
          title: 'Saved $fileCount PDF${fileCount == 1 ? "" : "s"}',
          icon: Icons.check_circle,
          width: 560,
          isActionTrue: false, // we render our own footer row
          onAction: null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                tr.location,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(dialogCtx)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: .5),
                  border: Border.all(
                    color: Theme.of(dialogCtx)
                        .colorScheme
                        .outline
                        .withValues(alpha: .35),
                    width: .5,
                  ),
                ),
                child: SelectableText(
                  folderPath,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      ZOutlineButton(
                        label: Text(tr.copyPath),
                        icon: Icons.copy,
                        iconSize: 16,
                        height: 38,
                        width: 130,
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: folderPath));
                          if (dialogCtx.mounted) {
                            ToastManager.show(
                              context: dialogCtx,
                              message: 'Path copied to clipboard',
                              type: ToastType.success,
                            );
                          }
                        },
                      ),
                      if (Platform.isWindows ||
                          Platform.isMacOS ||
                          Platform.isLinux)
                        ZOutlineButton(
                          label: Text(tr.openInExplorer),
                          icon: Icons.folder_open,
                          iconSize: 16,
                          height: 38,
                          width: 140,
                          onPressed: () => _openFolder(folderPath),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  void _openFolder(String path) {
    try {
      if (Platform.isWindows) {
        Process.run('explorer', [path]);
      } else if (Platform.isMacOS) {
        Process.run('open', [path]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [path]);
      }
    } catch (_) {}
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

  // ── Preview ONE customer ───────────────────────────────────
  void _previewOne() {
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

    context.read<ContainerInvoicesBloc>().add(
      ContainerInvoicesRequested(
        ContainerInvoiceRequest(
          containerNo: cNo.isEmpty ? null : cNo,
          sequenceNo: sNo.isEmpty ? null : sNo,
        ),
        previewAccountNo: accNumber,
      ),
    );
  }

  // ── Batch ALL customers ────────────────────────────────────
  void _printAll() {
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
        BlocListener<ContainerInvoicesBloc, ContainerInvoicesState>(
          listener: (context, state) {
            if (state is ContainerInvoicePreviewReady) {
              showPreview(context, state.invoice);
            } else if (state is ContainerInvoicesSuccess) {
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

            return BlocBuilder<ContainerInvoicesBloc,
                ContainerInvoicesState>(
              builder: (context, state) {
                final loading = state is ContainerInvoicesLoading;

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
                                  fetchAllFunction: (bloc) =>
                                      bloc.add(const LoadStkAccountsEvent()),
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
                                  onFieldSubmitted: (_) => _previewOne(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ZOutlineButton(
                                height: 47,
                                isActive: true,
                                icon: Icons.picture_as_pdf,
                                label: loading
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : Text(tr.printSingleInvioce),
                                onPressed:
                                (!loading && accNumber != null)
                                    ? _previewOne
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              ZOutlineButton(
                                height: 47,
                                icon: Icons.picture_as_pdf_outlined,
                                label: loading
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                                    : Text(tr.allInviocePrint),
                                onPressed: !loading ? _printAll : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Center(
                            child: loading
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

  void _previewOne() {
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
    context.read<ContainerInvoicesBloc>().add(
      ContainerInvoicesRequested(
        ContainerInvoiceRequest(
          containerNo: cNo.isEmpty ? null : cNo,
          sequenceNo: sNo.isEmpty ? null : sNo,
        ),
        previewAccountNo: accNumber,
      ),
    );
  }

  void _printAll() {
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
        BlocListener<ContainerInvoicesBloc, ContainerInvoicesState>(
          listener: (context, state) {
            if (state is ContainerInvoicePreviewReady) {
              showPreview(context, state.invoice);
            } else if (state is ContainerInvoicesSuccess) {
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

            return BlocBuilder<ContainerInvoicesBloc,
                ContainerInvoicesState>(
              builder: (context, state) {
                final loading = state is ContainerInvoicesLoading;

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
                          searchFunction: (bloc, query) =>
                              bloc.add(LoadStkAccountsEvent(query: query)),
                          validator: (value) =>
                          (value == null || value.isEmpty)
                              ? tr.required(tr.accounts)
                              : null,
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
                          stateToLoading: (s) =>
                          s is StkAccountsLoadingState,
                          loadingBuilder: (_) => const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          stateToItems: (s) =>
                          s is StkAccountsLoadedState
                              ? s.accounts
                              .where((a) => a.accCategory == 8)
                              .toList()
                              : const <StkAccountModel>[],
                          onSelected: (value) =>
                              setState(() => accNumber = value.accNumber),
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
                                  isActive:
                                  !loading && accNumber != null,
                                  icon: Icons.picture_as_pdf,
                                  label: loading
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                      : Text(tr.printPdf),
                                  onPressed:
                                  (!loading && accNumber != null)
                                      ? _previewOne
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ZOutlineButton(
                                  isActive: !loading,
                                  icon: Icons.picture_as_pdf_outlined,
                                  label: loading
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                      : const Text("Print ALL"),
                                  onPressed: !loading ? _printAll : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        if (loading)
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

  void _previewOne() {
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
    context.read<ContainerInvoicesBloc>().add(
      ContainerInvoicesRequested(
        ContainerInvoiceRequest(
          containerNo: cNo.isEmpty ? null : cNo,
          sequenceNo: sNo.isEmpty ? null : sNo,
        ),
        previewAccountNo: accNumber,
      ),
    );
  }

  void _printAll() {
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
        BlocListener<ContainerInvoicesBloc, ContainerInvoicesState>(
          listener: (context, state) {
            if (state is ContainerInvoicePreviewReady) {
              showPreview(context, state.invoice);
            } else if (state is ContainerInvoicesSuccess) {
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

            return BlocBuilder<ContainerInvoicesBloc,
                ContainerInvoicesState>(
              builder: (context, state) {
                final loading = state is ContainerInvoicesLoading;

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
                          searchFunction: (bloc, query) =>
                              bloc.add(LoadStkAccountsEvent(query: query)),
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
                            isActive: !loading && accNumber != null,
                            onPressed: (!loading && accNumber != null)
                                ? _previewOne
                                : null,
                            icon: Icons.picture_as_pdf,
                            label: loading
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
                            isActive: !loading,
                            onPressed: !loading ? _printAll : null,
                            icon: Icons.picture_as_pdf_outlined,
                            label: loading
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
                            color:
                            Theme.of(context).colorScheme.outline,
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
      ),
    );
  }
}