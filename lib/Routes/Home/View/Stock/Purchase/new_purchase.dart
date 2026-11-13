import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/View/StkAccount/bloc/stk_accounts_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/View/StkAccount/bloc/stk_accounts_event.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/View/StkAccount/bloc/stk_accounts_state.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/bloc/stakeholder_bloc.dart';
import 'package:shipping/Routes/Home/View/Stakeholder/model/stk_model.dart';
import '../../../../../../../Features/PrintSettings/print_preview.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../Features/Other/form_dialog.dart';
import '../../../../../Features/Other/generic_textfield.dart';
import '../../../../../Features/Other/responsive_widget.dart';
import '../../../../../Features/Widgets/alert_dialog.dart';
import '../../../../../Features/Widgets/cover.dart';
import '../../../../../Features/Widgets/extensions.dart';
import '../../../../../Features/Widgets/section.dart';
import '../../../../../Features/Widgets/shimmer.dart';
import '../../../../../Features/Widgets/toast.dart';
import '../../../../../Features/Widgets/z_generic_field.dart';
import '../../../../../Features/Widgets/zbutton.dart';
import '../../../../../Features/Widgets/ztextfield.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../Auth/bloc/auth_bloc.dart';
import '../../Finance/View/Currencies/model/ccy_model.dart';
import '../../Finance/View/ExchangeRate/bloc/exchange_rate_bloc.dart';
import '../../Products/bloc/products_bloc.dart';
import '../../Products/model/product_model.dart';
import '../../Settings/View/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import '../../Settings/View/Company/Storage/bloc/storage_bloc.dart';
import '../../Settings/View/Company/Storage/model/storage_model.dart';
import '../../Settings/Visibility/bloc/settings_visible_bloc.dart';
import '../Orders/bloc/orders_bloc.dart';
import '../Print/print.dart';
import '../Sale/features/amount_display.dart';
import 'bloc/purchase_invoice_bloc.dart';
import 'expense_section.dart';
import 'features/purchase_product_field.dart';
import 'features/underline_field.dart';
import 'model/purchase_invoice_items.dart';

class NewPurchaseOrderView extends StatelessWidget {
  final dynamic orderId;
  const NewPurchaseOrderView({super.key,this.orderId});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _DesktopPurchaseOrderView(orderId),
      desktop:  _DesktopPurchaseOrderView(orderId),
      tablet: _DesktopPurchaseOrderView(orderId),
    );
  }
}

class _DesktopPurchaseOrderView extends StatefulWidget {
  final dynamic orderId;
  const _DesktopPurchaseOrderView(this.orderId);

  @override
  State<_DesktopPurchaseOrderView> createState() => _DesktopPurchaseOrderViewState();
}
class _DesktopPurchaseOrderViewState extends State<_DesktopPurchaseOrderView> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _xRefController = TextEditingController();
  final TextEditingController _remark = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _supplierFocusNode = FocusNode();
  final FocusNode _accountFocusNode = FocusNode();
  final ScrollController _itemsScrollController = ScrollController();

  // These are references to FocusNodes owned by visible row states.
  // The parent never disposes them. Each _PurchaseItemRow owns/disposes its node.
  final Map<String, FocusNode> _productFocusRegistry = {};

  bool _focusNewRowAfterAdd = false;
  bool _shouldAutoFocusProduct = true;
  int? ordNumber;
  void _confirmDeleteOrder() {
    final tr = AppLocalizations.of(context)!;
    final purState = context.read<PurchaseInvoiceBloc>().state;
    if (purState is! PurchaseInvoiceLoaded) return;

    final ordId = purState.orderId;
    final ref = purState.reference;

    if (ordId == null || ordId <= 0) {
      ToastManager.show(
        context: context,
        title: tr.errorTitle,
        message: 'Cannot delete: order id missing',
        type: ToastType.error,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeletePurchaseConfirmDialog(
        ordId: ordId,
        ref: ref,
        usrName: _userName ?? '',
        orderName: 'Purchase',
        onDeleted: () {
          if (!mounted) return;
          ToastManager.show(
            context: context,
            title: tr.successTitle,
            message: 'Invoice deleted',
            type: ToastType.success,
          );
          // The Orders view handles list refresh / screen close via the
          // OrdersBloc listener, same as the sale flow.
        },
        onError: (msg) {
          if (!mounted) return;
          ToastManager.show(
            context: context,
            title: tr.errorTitle,
            message: msg,
            type: ToastType.error,
          );
        },
      ),
    );
  }
  void _showExpensesDialog(BuildContext context) {
    final state = context.read<PurchaseInvoiceBloc>().state;
    if (state is PurchaseInvoiceLoaded) {
      showDialog(
        context: context,
        builder: (context) => const ExpensesDialog(),
      );
    }
  }

  void _showPaymentDialog(PurchaseInvoiceLoaded state) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context,setState) {
            return PurchasePaymentDialog(state: state);
          }
      ),
    );
  }

  String? _userName;
  String? baseCurrency = "";
  int? signatory;
  void _updateControllersFromState(PurchaseInvoiceState state) {
    if (state is PurchaseInvoiceLoaded) {
      // Update exchange rate controller if needed
      if (state.exchangeRate != null && state.exchangeRate! > 0) {
        if (_exchangeRateController.text !=
            state.exchangeRate!.toStringAsFixed(4)) {
          _exchangeRateController.text = state.exchangeRate!.toStringAsFixed(4);
        }
      }

      // Update local amount controllers for each item
      for (var i = 0; i < state.items.length; i++) {
        final item = state.items[i];
        if (item.localAmount != null && item.localAmount! > 0) {
          final controller = _localeAmountControllers[item.rowId];
          if (controller != null &&
              controller.text != item.localAmount!.toAmount()) {
            controller.text = item.localAmount!.toAmount();
          }
        }
      }
    }
  }

  bool _needsLocalConversion(BuildContext context) {
    final state = context.read<PurchaseInvoiceBloc>().state;
    if (state is PurchaseInvoiceLoaded && state.supplierAccount != null) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        final baseCurrency = authState.loginData.company?.comLocalCcy ?? '';
        final accountCurrency = state.supplierAccount!.accCurrency ?? '';
        return baseCurrency.isNotEmpty &&
            accountCurrency.isNotEmpty &&
            baseCurrency != accountCurrency;
      }
    }
    return false;
  }

  final Map<String, TextEditingController> _purchasePriceControllers = {};
  final Map<String, TextEditingController> _costPriceControllers = {};
  final Map<String, TextEditingController> _sellPriceControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _localeAmountControllers = {};
  final Map<String, TextEditingController> _batchControllers = {};

  Timer? _debounce;

  void _onExchangeRateChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 2000), () {
      final rate = double.tryParse(value.replaceAll(',', ''));

      if (rate != null && rate > 0) {
        final state = context.read<PurchaseInvoiceBloc>().state;

        if (state is PurchaseInvoiceLoaded && state.supplierAccount != null) {
          if (state.exchangeRate != rate) {
            context.read<PurchaseInvoiceBloc>().add(
              UpdateExchangeRateManuallyEvent(
                rate: rate,
                fromCurrency: state.fromCurrency ?? baseCurrency ?? '',
                toCurrency:
                state.toCurrency ??
                    state.supplierAccount!.accCurrency ??
                    '',
              ),
            );
          }
        }
      }
    });
  }
  final company = ReportModel();
  bool _isEditMode = false;
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      baseCurrency = authState.loginData.company?.comLocalCcy;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _supplierFocusNode.requestFocus();
        }
      });
      final purchaseBloc = context.read<PurchaseInvoiceBloc>();
      final exchangeBloc = context.read<ExchangeRateBloc>();
      purchaseBloc.setExchangeRateBloc(exchangeBloc);
      purchaseBloc.setAuthBloc(context.read<AuthBloc>());
      final purState = purchaseBloc.state;
      if (purState is PurchaseInvoiceLoaded || purState is PurchaseInvoiceSaving) {
        final current = purState is PurchaseInvoiceSaving ? purState : (purState as PurchaseInvoiceLoaded);
        accountCcy = current.toCurrency;
      }
      _clearAllControllers();
      if (widget.orderId != null) {
        _isEditMode = true;
        purchaseBloc.add(LoadPurchaseInvoiceForEditEvent(
          orderId: widget.orderId,
          baseCurrency: baseCurrency ?? '',
        ));
      } else {
        purchaseBloc.add(InitializePurchaseInvoiceEvent());
      }
    });
  }

  @override
  void dispose() {
    _supplierFocusNode.dispose();
    _accountFocusNode.dispose();
    _itemsScrollController.dispose();

    _accountController.dispose();
    _personController.dispose();
    _xRefController.dispose();
    _remark.dispose();
    _exchangeRateController.dispose();

    _purchasePriceControllers.clear();
    _costPriceControllers.clear();
    _sellPriceControllers.clear();
    _qtyControllers.clear();
    _batchControllers.clear();
    _localeAmountControllers.clear();
    _productFocusRegistry.clear();

    super.dispose();
  }

  String? accountCcy = "";

  void _clearAllControllers() {
    _accountController.clear();
    _personController.clear();
    _xRefController.clear();
    _remark.clear();
    _exchangeRateController.clear();
  }

  /// Focus the first empty product row after an account is selected.
  /// FocusNodes remain owned by their row widgets; this map only holds references.
  void _focusFirstEmptyProduct() {
    if (!_shouldAutoFocusProduct || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_shouldAutoFocusProduct) return;

      final state = context.read<PurchaseInvoiceBloc>().state;
      if (state is! PurchaseInvoiceLoaded) return;

      for (final item in state.items) {
        if (item.productId.isEmpty) {
          final node = _productFocusRegistry[item.rowId];
          if (node != null) {
            if (node.canRequestFocus) {
              node.requestFocus();
            }
          }
          return;
        }
      }
    });
  }

  void _focusProductRow(int rowIndex) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final state = context.read<PurchaseInvoiceBloc>().state;
      if (state is! PurchaseInvoiceLoaded) return;
      if (rowIndex < 0 || rowIndex >= state.items.length) return;

      final rowId = state.items[rowIndex].rowId;
      final node = _productFocusRegistry[rowId];
      if (node != null && node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  void _focusNewlyAddedRowProduct() {
    if (!mounted || !_shouldAutoFocusProduct) return;

    final bloc = context.read<PurchaseInvoiceBloc>();

    // The new row is appended to the END of the ListView. With many rows,
    // Flutter may not build that row until it becomes visible. Therefore:
    //   1. wait for the BLoC state to rebuild the list
    //   2. scroll to the bottom
    //   3. wait for the new row to mount
    //   4. focus its Product field
    Future<void> focusAfterBuild() async {
      if (!mounted || !_shouldAutoFocusProduct) return;

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted || !_shouldAutoFocusProduct) return;

      if (_itemsScrollController.hasClients) {
        await _itemsScrollController.animateTo(
          _itemsScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }

      // Give ListView time to build the newly visible last row.
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || !_shouldAutoFocusProduct) return;

      var attempts = 0;
      while (mounted && _shouldAutoFocusProduct && attempts < 10) {
        final state = bloc.state;

        if (state is PurchaseInvoiceLoaded && state.items.isNotEmpty) {
          final newItem = state.items.last;
          final node = _productFocusRegistry[newItem.rowId];

          if (node != null && node.canRequestFocus) {
            node.requestFocus();
            return;
          }
        }

        attempts++;
        await Future.delayed(const Duration(milliseconds: 80));
      }
    }

    // Run after the state change has reached the widget tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusAfterBuild();
    });
  }

  void _addNewRowAndFocusFromParent() {
    if (!mounted) return;
    _shouldAutoFocusProduct = true;
    _focusNewRowAfterAdd = true;
    context.read<PurchaseInvoiceBloc>().add(AddNewPurchaseItemEvent());
  }

  void _resetForm() {
    _clearAllControllers();

    _shouldAutoFocusProduct = true;

    context.read<PurchaseInvoiceBloc>().add(
      ResetPurchaseInvoiceEvent(),
    );

    context.read<PurchaseInvoiceBloc>().add(
      InitializePurchaseInvoiceEvent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final purchaseState = context.watch<PurchaseInvoiceBloc>().state;
    final needsConversion = purchaseState is PurchaseInvoiceLoaded
        ? purchaseState.needsExchangeRate
        : false;

    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }

    final login = authState.loginData;
    _userName = login.usrName ?? "";

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState) {
          _userName = state.loginData.usrName ?? '';
        }
      },
      child: BlocListener<PurchaseInvoiceBloc, PurchaseInvoiceState>(
        listener: (context, state) {
          if (state is PurchaseInvoiceLoaded) {
            if (_focusNewRowAfterAdd) {
              _focusNewRowAfterAdd = false;
              _focusNewlyAddedRowProduct();
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateControllersFromState(state);
            });
          }
          if (state is PurchaseInvoiceError) {
            ToastManager.show(
              context: context,
              title: tr.failed,
              message: state.message,
              type: ToastType.error,
            );
          }

          if (state is PurchaseInvoiceSaved) {
            Navigator.of(context).pop();
            if (state.success) {
              String? savedInvoiceNumber = state.invoiceNumber;
              ToastManager.show(
                context: context,
                title: tr.successTitle,
                message: tr.successMsg,
                type: ToastType.success,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (savedInvoiceNumber != null && savedInvoiceNumber.isNotEmpty) {
                  _onPrint(invoiceNumber: savedInvoiceNumber);
                }
              });
            } else {
              ToastManager.show(
                context: context,
                title: tr.failed,
                message: "Failed to create invoice",
                type: ToastType.error,
              );
            }
          }
          if (state is PurchaseInvoiceLoaded && _isEditMode) {
            setState(() {
              ordNumber = state.orderId;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _shouldAutoFocusProduct = true;
              // Set supplier name
              if (state.supplier != null) {
                _personController.text =  '${state.supplier!.perName} ${state.supplier!.perLastName}';
                signatory = state.supplier!.perId;

                company.partyAddress = state.supplier!.addName;
                company.partyPhone = state.supplier!.perPhone;
                company.partyCity = state.supplier!.addCity;
                company.partyProvince = state.supplier!.addProvince;
              }

              // Set account
              if (state.supplierAccount != null) {
                _accountController.text = '${state.supplierAccount!.accNumber}';
              }

              // Set reference and remark
              _xRefController.text = state.xRef ?? '';
              _remark.text = state.remark ?? '';

              // Set exchange rate
              if (state.exchangeRate != null && state.exchangeRate! > 0) {
                _exchangeRateController.text = state.exchangeRate!.toStringAsFixed(4);
              }

              _isEditMode = false;
            });
          }
          if (state is PurchaseInvoiceInitial ||
              state is PurchaseInvoiceLoaded) {
            _updateControllersFromState(state);
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 20),
                widget.orderId == null ? tr.purchaseEntry : "${tr.update.toUpperCase()} ${tr.purchase.toUpperCase()} ${ordNumber??""}"),
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            titleSpacing: 0,
            actionsPadding: const EdgeInsets.symmetric(horizontal: 12),
            actions: [
              if (widget.orderId != null)
                BlocBuilder<OrdersBloc, OrdersState>(
                  builder: (context, ordersState) {
                    final deleting = ordersState is OrdersDeletingState &&
                        ordersState.orderId == ordNumber;
                    return ZOutlineButton(
                      icon: deleting ? null : Icons.delete_outline_rounded,
                      backgroundHover: Theme.of(context).colorScheme.error,
                      onPressed: deleting ? null : _confirmDeleteOrder,
                      label: deleting
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(tr.delete),
                    );
                  },
                ),
              if(widget.orderId ==null)...[
                const SizedBox(width: 8),
                ZOutlineButton(
                  icon: Icons.lock_reset_outlined,
                  onPressed: _resetForm,
                  label: Text(tr.newPurchase),
                ),
              ],
              const SizedBox(width: 8),
              ZOutlineButton(
                icon: Icons.outbond_outlined,
                onPressed: () => _showExpensesDialog(context),
                label: Text(tr.expenseEntry),
              ),
              const SizedBox(width: 8),
              ZOutlineButton(
                icon: Icons.print,
                onPressed:()=> _onPrint(invoiceNumber: ordNumber.toString()),

                label: Text(tr.print),
              ),
              const SizedBox(width: 8),
              BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                builder: (context, state) {
                  if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {

                    final current = state is PurchaseInvoiceSaving
                        ? state
                        : (state as PurchaseInvoiceLoaded);
                    final isSaving = state is PurchaseInvoiceSaving;
                    return ZOutlineButton(
                      isActive: true,
                      icon: widget.orderId == null ? Icons.save_rounded : Icons.refresh,
                      onPressed: (isSaving || !current.isFormValid)
                          ? null
                          : widget.orderId == null ? () => _saveInvoice(context, current) : ()=> _updateInvoice(context, current),
                      label: isSaving
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      )
                          : Text(widget.orderId == null? tr.save : tr.update),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
          body: Container(
            margin: EdgeInsets.all(15),
            child: Form(
              key: _formKey,
              child: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                builder: (context, state) {
                  // Check if we're in loading state
                  final isLoading = state is PurchaseInvoiceLoading ||
                      (state is PurchaseInvoiceLoaded &&
                          state.items.isEmpty &&
                          state.supplier == null &&
                          _isEditMode);

                  if (isLoading) {
                    // Show full shimmer while loading
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: UniversalShimmer.invoiceLoading(),
                    );
                  }

                  // Handle error state
                  if (state is PurchaseInvoiceError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${state.message}'),
                          const SizedBox(height: 16),
                          ZOutlineButton(
                            icon: Icons.refresh,
                            onPressed: () {
                              context.read<PurchaseInvoiceBloc>().add(InitializePurchaseInvoiceEvent());
                            },
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Handle loaded and saving states
                  return Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Supplier and Account Selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 3,
                              child: GenericTextField<StakeholdersModel, StakeholderBloc, StakeholderState>(
                                key: const ValueKey('person_field'),
                                controller: _personController,
                                focusNode: _supplierFocusNode,
                                title: tr.supplier,
                                hintText: tr.supplier,
                                isRequired: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return tr.required(tr.supplier);
                                  }
                                  return null;
                                },
                                bloc: context.read<StakeholderBloc>(),
                                fetchAllFunction: (bloc) => bloc.add(GetStakeholdersEvent()),
                                searchFunction: (bloc, query) => bloc.add(GetStakeholdersEvent(search: query)),
                                itemBuilder: (context, ind) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "${ind.perName ?? ''} ${ind.perLastName ?? ''}",
                                  ),
                                ),
                                itemToString: (individual) =>
                                "${individual.perName} ${individual.perLastName}",
                                stateToLoading: (state) =>
                                state is GetStakeholdersLoadingState,
                                stateToItems: (state) {
                                  if (state is GetStakeholdersSuccessState) {
                                    return state.stakeholders;
                                  }
                                  return [];
                                },
                                onSelected: (value) {
                                  _personController.text =
                                  "${value.perName} ${value.perLastName}";
                                  context.read<PurchaseInvoiceBloc>().add(
                                    SelectSupplierEvent(value),
                                  );
                                  context.read<StkAccountsBloc>().add(
                                    LoadStkAccountsEvent(perId: value.perId),
                                  );
                                  setState(() {
                                    signatory = value.perId;
                                  });

                                  // Disable product auto-focus
                                  _shouldAutoFocusProduct = false;
                                  // Add delay to ensure account data loads
                                  Future.delayed(const Duration(milliseconds: 300), () {
                                    if (mounted) {
                                      _accountFocusNode.requestFocus();
                                    }
                                  });
                                },
                                showClearButton: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                                builder: (context, state) {
                                  if (state is PurchaseInvoiceLoaded) {
                                    final current = state;
                                    return GenericTextField<StkAccountModel, StkAccountsBloc, StkAccountsState>(
                                      key: const ValueKey('account_field'),
                                      controller: _accountController,
                                      focusNode: _accountFocusNode,
                                      title: tr.accounts,
                                      hintText: tr.selectAccount,
                                      isRequired:
                                      current.paymentMode != PaymentMode.cash,
                                      validator: (value) {
                                        if (current.paymentMode !=
                                            PaymentMode.cash &&
                                            (value == null || value.isEmpty)) {
                                          return tr.selectCreditAccountMsg;
                                        }
                                        return null;
                                      },
                                      bloc: context.read<StkAccountsBloc>(),
                                      fetchAllFunction: (bloc) => bloc.add(
                                        LoadStkAccountsEvent(perId: signatory),
                                      ),
                                      searchFunction: (bloc, query) => bloc.add(
                                        LoadStkAccountsEvent(perId: signatory,query: query),
                                      ),
                                      itemBuilder: (context, account) => ListTile(
                                        visualDensity: const VisualDensity(
                                          vertical: -4,
                                          horizontal: -4,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                        ),
                                        title: Text(account.accName ?? ''),
                                        subtitle: Text('${account.accNumber}'),
                                        trailing: Text(
                                          "${tr.balance}: ${account.accBalance.toAmount()} ${account.accCurrency}",
                                        ),
                                      ),
                                      itemToString: (account) =>
                                      '${account.accName} (${account.accNumber})',
                                      stateToLoading: (state) =>
                                      state is StkAccountsLoadingState,
                                      stateToItems: (state) {
                                        if (state is StkAccountsLoadedState) {
                                          return state.accounts;
                                        }
                                        return [];
                                      },
                                      onSelected: (value) {
                                        _accountController.text =
                                        '${value.accName} (${value.accNumber})';
                                        setState(() {
                                          accountCcy = value.accCurrency;
                                        });
                                        context.read<PurchaseInvoiceBloc>().add(
                                          SelectSupplierAccountEvent(value),
                                        );
                                        _shouldAutoFocusProduct = true;
                                        _focusFirstEmptyProduct();
                                        final companyState = context.read<CompanyProfileBloc>().state;
                                        if (companyState
                                        is CompanyProfileLoadedState) {
                                          final baseCurr = companyState.company.comLocalCcy ??
                                              '';
                                          final accountCurrency =
                                              value.accCurrency ?? '';

                                          if (baseCurr.isNotEmpty && accountCurrency.isNotEmpty && baseCurr != accountCurrency) {
                                            context.read<PurchaseInvoiceBloc>().add(
                                              UpdateExchangeRateForInvoiceEvent(
                                                fromCurrency: baseCurr,
                                                toCurrency: accountCurrency,
                                              ),
                                            );
                                          } else {
                                            context.read<PurchaseInvoiceBloc>().add(
                                              UpdateExchangeRateManuallyEvent(
                                                rate: 1.0,
                                                fromCurrency: baseCurr,
                                                toCurrency: accountCurrency,
                                              ),
                                            );
                                          }
                                        }
                                        _exchangeRateController.clear();
                                      },
                                      showClearButton: true,
                                    );
                                  }
                                  return GenericTextField<StkAccountModel, StkAccountsBloc, StkAccountsState>(
                                    key: const ValueKey('account_field'),
                                    controller: _accountController,
                                    focusNode: _accountFocusNode,
                                    title: tr.accounts,
                                    hintText: tr.selectAccount,
                                    isRequired: false,
                                    bloc: context.read<StkAccountsBloc>(),
                                    fetchAllFunction: (bloc) => bloc.add(
                                      LoadStkAccountsEvent(),
                                    ),
                                    searchFunction: (bloc, query) => bloc.add(
                                      LoadStkAccountsEvent(
                                        query: query,
                                      ),
                                    ),
                                    itemBuilder: (context, account) => ListTile(
                                      title: Text(account.accName ?? ''),
                                      subtitle: Text(
                                        '${account.accNumber} - ${tr.balance}: ${account.accBalance.toAmount()}',
                                      ),
                                      trailing: Text(account.accCurrency ?? ""),
                                    ),
                                    itemToString: (account) =>
                                    '${account.accName} (${account.accNumber})',
                                    stateToLoading: (state) =>
                                    state is StkAccountsLoadingState,
                                    stateToItems: (state) {
                                      if (state is StkAccountsLoadedState) {
                                        return state.accounts;
                                      }
                                      return [];
                                    },
                                    onSelected: (value) {
                                      setState(() {
                                        accountCcy = value.accCurrency;
                                      });
                                      _accountController.text =
                                      '${value.accName} (${value.accNumber})';
                                      context.read<PurchaseInvoiceBloc>().add(
                                        SelectSupplierAccountEvent(value),
                                      );
                                      _shouldAutoFocusProduct = true;
                                      _focusFirstEmptyProduct();
                                    },
                                    showClearButton: true,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: ZTextFieldEntitled(
                                controller: _xRefController,
                                title: tr.invoiceNumber,
                              ),
                            ),
                            if (needsConversion) ...[
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 2,
                                child: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                                  builder: (context, state) {
                                    if (state is PurchaseInvoiceLoaded) {
                                      final isLoading = state.exchangeRate == null;
                                      return ZTextFieldEntitled(
                                        showClearButton: true,
                                        controller: _exchangeRateController,
                                        title: tr.exchangeRates,
                                        hint: isLoading
                                            ? "Loading rate..."
                                            : "Enter rate",
                                        inputFormat: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*\.?\d{0,6}'),
                                          ),
                                        ],
                                        onChanged: _onExchangeRateChanged,
                                        onFieldSubmitted: _onExchangeRateChanged,
                                        end: isLoading
                                            ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                            : null,
                                        isEnabled: !isLoading,
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            Expanded(
                              flex: 3,
                              child: ZTextFieldEntitled(
                                controller: _remark,
                                title: tr.remark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildItemsHeader(context),
                        const SizedBox(height: 8),
                        Expanded(
                          child: BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
                            builder: (context, state) {
                              if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
                                final current = state is PurchaseInvoiceSaving
                                    ? state
                                    : (state as PurchaseInvoiceLoaded);
                                return ListView.builder(
                                  controller: _itemsScrollController,
                                  itemCount: current.items.length,
                                  itemBuilder: (context, index) {
                                    final item = current.items[index];
                                    final isLastRow = index == current.items.length - 1;
                                    return _buildItemRow(
                                      item: item,
                                      rowIndex: index,
                                      isLastRow: isLastRow,
                                      context: context,
                                    );
                                  },
                                );
                              }
                              return const Center(child: CircularProgressIndicator());
                            },
                          ),
                        ),
                        _buildSummarySection(context),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsHeader(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final visibility = context.read<SettingsVisibleBloc>().state;
    final color = Theme.of(context).colorScheme;
    TextStyle? title = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(color: color.surface);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children:
        [
          const SizedBox(
            width: 40,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('#'),
            ),
          ),
          Expanded(child: Text(locale.products, style: title)),
          SizedBox(width: 100, child: Text(locale.qty)),
          if(visibility.isWholeSale)...[
            SizedBox(width: 100, child: Text(locale.batchTitle)),
            SizedBox(width: 100, child: Text(locale.totalQty)),
          ],
          SizedBox(
            width: 150,
            child: Text("${locale.unitPrice} ($baseCurrency)"),
          ),
          if (_needsLocalConversion(context))
            SizedBox(
              width: 150,
              child: Text(
                "${locale.unitPrice} ($accountCcy)",
              ),
            ),
          SizedBox(width: 150, child: Text(locale.sellPrice)),
          SizedBox(
            width: 150,
            child: Text("${locale.landedCost} ($baseCurrency)"),
          ),
          SizedBox(width: 180, child: Text(locale.storage)),
          SizedBox(width: 60, child: Text(locale.actions)),
        ]
            .map((child) => DefaultTextStyle(style: title!, child: child))
            .toList(),
      ),
    );
  }

  Widget _buildItemRow({
    required BuildContext context,
    required PurchaseInvoiceItem item,
    required bool isLastRow,
    required int rowIndex,
  }) {
    final isLocked = widget.orderId != null;

    return _PurchaseItemRow(
      key: ValueKey(item.rowId),
      item: item,
      isLastRow: isLastRow,
      isLocked: isLocked,
      rowIndex: rowIndex,
      qtyControllers: _qtyControllers,
      batchControllers: _batchControllers,
      sellPriceControllers: _sellPriceControllers,
      purchasePriceControllers: _purchasePriceControllers,
      costPriceControllers: _costPriceControllers,
      productFocusRegistry: _productFocusRegistry,
      onFocusRowProduct: _focusProductRow,
      onAddNewRowAndFocus: _addNewRowAndFocusFromParent,
      onDelete: (rowId) {
        context.read<PurchaseInvoiceBloc>().add(RemovePurchaseItemEvent(rowId));
      },
      onQtyChanged: (rowId, qty) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(rowId: rowId, qty: qty),
        );
      },
      onBatchChanged: (rowId, batch) {
        final effectiveBatch = batch <= 0 ? 1 : batch;
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(rowId: rowId, batch: effectiveBatch),
        );
      },
      onPurchasePriceChanged: (rowId, price) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(rowId: rowId, purPrice: price),
        );
      },
      onSellPriceChanged: (rowId, price) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(rowId: rowId, sellPriceAmount: price),
        );
      },
      onStorageSelected: (rowId, storageId, storageName) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(
            rowId: rowId,
            storageId: storageId,
            storageName: storageName,
          ),
        );
      },
      onProductSelected: (rowId, productId, productName, unit) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(
              rowId: rowId,
              productId: productId,
              productName: productName,
              unit: unit
          ),
        );
        _autoSelectFirstStorage(context, rowId);
      },
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return BlocBuilder<PurchaseInvoiceBloc, PurchaseInvoiceState>(
      builder: (context, state) {
        if (state is PurchaseInvoiceLoaded || state is PurchaseInvoiceSaving) {
          final current = state is PurchaseInvoiceSaving ? state : (state as PurchaseInvoiceLoaded);
          final totalExpenses = current.totalExpenses;
          final needsAccountConversion = current.needsExchangeRate;
          final needsCashConversion = current.needsCashConversion;
          final bool isLoading = current.isExchangeRateLoading;
          final baseCurrency = current.fromCurrency ?? '';
          final bool needsConversion = current.needsExchangeRate;

          return ZCover(
            padding: const EdgeInsets.all(16),
            radius: 15,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Icon(Icons.file_open_outlined),
                                Text(
                                  tr.invoiceSummary.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                        const SizedBox(height: 4),
                        Divider(color: color.outline.withValues(alpha: .2)),
                        const SizedBox(height: 4),

                        _buildSummaryRow(
                          label: tr.subtotal,
                          value: current.subtotal,
                          currency: baseCurrency,
                        ),

                        if (totalExpenses > 0) ...[
                          const SizedBox(height: 4),
                          _buildSummaryRow(
                            label: tr.totalExpense,
                            value: totalExpenses,
                            color: Colors.red,
                            currency: baseCurrency,
                          ),
                          const SizedBox(height: 4),
                        ],

                        Divider(color: color.outline.withValues(alpha: .2)),
                        const SizedBox(height: 4),
                        _buildSummaryRow(
                          label: tr.grandTotal,
                          value: current.subtotal + totalExpenses,
                          isBold: true,
                          fontSize: 17,
                          color: Colors.purple,
                          currency: baseCurrency,
                        ),

                        if (needsConversion && !isLoading) ...[
                          const SizedBox(height: 4),
                          _buildSummaryRow(
                            label: '${tr.grandTotal} (${current.toCurrency})',
                            value: current.grandTotalLocal,
                            fontSize: 14,
                            color: color.outline.withValues(alpha: .8),
                            currency: current.toCurrency ?? '',
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(width: 12),
                  VerticalDivider(
                    width: 20,
                    thickness: 1,
                    color: color.outline.withValues(alpha: .2),
                  ),
                  SizedBox(width: 12),

                  //Cash Payment
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Icon(Icons.money),
                                Text(
                                  tr.payment.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => _showPaymentDialog(current),
                              child: Row(
                                children: [
                                  Text(
                                    _getPaymentModeLabel(current.paymentMode,
                                    ).toUpperCase(),
                                    style: TextStyle(
                                      color: color.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.more_vert_rounded,
                                    size: 20,
                                    color: color.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Divider(color: color.outline.withValues(alpha: .2)),
                        const SizedBox(height: 4),

                        // Payment section with currency conversion
                        if (current.paymentMode == PaymentMode.cash) ...[
                          AmountDisplay(
                            title: tr.cashPayment,
                            baseAmount: current.cashPayment,
                            baseCurrency: baseCurrency,
                            convertedAmount:
                            (needsCashConversion &&
                                current.cashCurrency != null &&
                                current.cashCurrency != baseCurrency)
                                ? current.cashPaymentInCashCurrency
                                : null,
                            convertedCurrency: current.cashCurrency ?? "",
                          ),
                        ] else if (current.paymentMode ==
                            PaymentMode.credit) ...[
                          AmountDisplay(
                            title: tr.payableAmount,
                            baseAmount: current.creditAmount,
                            baseCurrency: baseCurrency,
                            convertedAmount:
                            (current.supplierAccount != null &&
                                needsAccountConversion)
                                ? current.creditAmountLocal
                                : null,
                            convertedCurrency: current.toCurrency ?? "",
                            fontSize: 15,
                          ),
                        ] else if (current.paymentMode ==
                            PaymentMode.mixed) ...[
                          AmountDisplay(
                            title: tr.cashPayment,
                            baseAmount: current.cashPayment,
                            baseCurrency: baseCurrency,
                            convertedAmount:
                            (needsCashConversion &&
                                current.cashCurrency != null &&
                                current.cashCurrency != baseCurrency)
                                ? current.cashPaymentInCashCurrency
                                : null,
                            convertedCurrency: current.cashCurrency ?? "",
                          ),

                          AmountDisplay(
                            title: tr.accountPayable,
                            baseAmount: current.creditAmount,
                            baseCurrency: baseCurrency,
                            convertedAmount:
                            (current.supplierAccount != null &&
                                needsAccountConversion)
                                ? current.creditAmountLocal
                                : null,
                            convertedCurrency: current.toCurrency ?? "",
                            fontSize: 15,
                          ),
                        ],
                      ],
                    ),
                  ),


                  if(current.supplierAccount !=null)...[
                    SizedBox(width: 12),
                    VerticalDivider(
                      width: 20,
                      thickness: 1,
                      color: color.outline.withValues(alpha: .2),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            spacing: 8,
                            children: [
                              Icon(Icons.account_balance_rounded, size: 19),
                              Text(
                                tr.accountInformation.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Divider(color: color.outline.withValues(alpha: .2)),
                          const SizedBox(height: 4),
                          // Account balance section
                          if (current.supplierAccount != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${current.supplierAccount!.accNumber} | ${current.supplierAccount!.accName}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    current.supplierAccount!.accCurrency ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildSummaryRow(
                              label: tr.currentBalance,
                              value: current.currentBalance,
                              color: _getBalanceColor(current.currentBalance),
                              currency: current.supplierAccount!.accCurrency,
                            ),
                            if (current.supplierAccountPayment > 0) ...[
                              const SizedBox(height: 4),
                              AmountDisplay(
                                baseAmount: current.supplierAccountPayment,
                                baseCurrency: baseCurrency,
                                title: tr.accountPayable,
                                convertedAmount: needsConversion ? current.supplierAccountPayment * (current.exchangeRate ?? 1) : null,
                                isPositive: true,
                                showSign: true,
                                fontSize: 16,
                                convertedCurrency: current.supplierAccount!.accCurrency!,
                              ),

                              const SizedBox(height: 4),
                              _buildSummaryRow(
                                label:
                                "${tr.newBalance} | ${_getBalanceStatus(current.newBalance)}",
                                value: current.newBalance,
                                isBold: true,
                                color: _getBalanceColor(current.newBalance),
                                currency: current.supplierAccount!.accCurrency,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Color _getBalanceColor(double balance) {
    if (balance < 0) return Colors.green;
    if (balance > 0) return Colors.orange;
    return Colors.grey;
  }

  String _getBalanceStatus(double balance) {
    if (balance < 0) return AppLocalizations.of(context)!.debitor;
    if (balance > 0) return AppLocalizations.of(context)!.creditor;
    return AppLocalizations.of(context)!.noBalance;
  }

  Widget _buildSummaryRow({
    required String label,
    required double value,
    bool isBold = false,
    Color? color,
    String? currency,
    double fontSize = 16,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
          ),
        ),
        Text(
          "${value.toAmount()} ${currency ?? ''}",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  String _getPaymentModeLabel(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return AppLocalizations.of(context)!.cash;
      case PaymentMode.credit:
        return AppLocalizations.of(context)!.credit;
      case PaymentMode.mixed:
        return AppLocalizations.of(context)!.combinedPayment;
    }
  }

  void _autoSelectFirstStorage(BuildContext context, String rowId) {
    final storageState = context.read<StorageBloc>().state;
    if (storageState is StorageLoadedState && storageState.storage.isNotEmpty) {
      final firstStorage = storageState.storage.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PurchaseInvoiceBloc>().add(
          UpdatePurchaseItemEvent(
            rowId: rowId,
            storageId: firstStorage.stgId!,
            storageName: firstStorage.stgName ?? '',
          ),
        );
      });
    }
  }

  void _saveInvoice(BuildContext context, PurchaseInvoiceLoaded state) {
    if (!state.isFormValid) {
      ToastManager.show(context: context,title: "Failed to save", message: "Please fill all required fields correctly", type: ToastType.error);
      return;
    }

    final completer = Completer<String>();

    context.read<PurchaseInvoiceBloc>().add(
      SavePurchaseInvoiceEvent(
        usrName: _userName ?? '',
        orderName: "Purchase",
        ordPersonal: state.supplier!.perId!,
        xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
        remark: _remark.text,
        baseCurrency: baseCurrency??"",
        completer: completer,
      ),
    );
  }

  void _updateInvoice(BuildContext context, PurchaseInvoiceLoaded state) {
    if (!state.isFormValid) {
      ToastManager.show(context: context,title: "Failed to update", message: "Please fill all required fields correctly", type: ToastType.error);
      return;
    }

    final completer = Completer<String>();

    context.read<PurchaseInvoiceBloc>().add(
      UpdatePurchaseInvoiceEvent(
        usrName: _userName ?? '',
        orderName: "Purchase",
        ordPersonal: state.supplier!.perId!,
        xRef: _xRefController.text.isNotEmpty ? _xRefController.text : null,
        orderId: state.orderId,
        remark: _remark.text,
        baseCurrency: baseCurrency ?? "",
        completer: completer,
      ),
    );
  }

  void _onPrint({String? invoiceNumber}) {
    final state = context.read<PurchaseInvoiceBloc>().state;
    PurchaseInvoiceLoaded? current;

    // Make sure to set the visible property from your settings
    final visibilityState = context.read<SettingsVisibleBloc>().state;


    if (state is PurchaseInvoiceLoaded) {
      current = state;
    } else if (state is PurchaseInvoiceSaved && state.invoiceData != null) {
      current = state.invoiceData;
    }

    if (current == null) {
      ToastManager.show(context: context,title: "Failed to Print", message: "Cannot print: No invoice data available", type: ToastType.error);
      return;
    }

    // Determine the invoice number to use.
// Priority:
//   1) explicit argument (passed by save listener with fresh server value)
//   2) widget.orderId (edit mode: initial route param)
//   3) current state's orderId (edit mode: loaded from server)
//   4) empty string (new invoice with no id yet)
    final String finalInvoiceNumber;
    final String? candidate =
    (invoiceNumber != null && invoiceNumber.isNotEmpty)
        ? invoiceNumber
        : (widget.orderId != null && widget.orderId != 0)
        ? widget.orderId.toString()
        : (current.orderId != null && current.orderId! > 0)
        ? current.orderId.toString()
        : null;

    if (candidate != null && candidate.isNotEmpty && candidate != 'null') {
      finalInvoiceNumber = candidate;
    } else {
      // No invoice number available — show a helpful warning but still allow print.
      ToastManager.show(
        context: context,
        title: "Warning",
        message: "Invoice number is not available yet",
        type: ToastType.warning,
      );
      finalInvoiceNumber = '';
    }

    final needsConversion = current.supplierAccount?.accCurrency != null &&
        baseCurrency != null &&
        baseCurrency != current.supplierAccount!.accCurrency;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) {
      ToastManager.show(context: context,title: "Warning", message: "Company information not available", type: ToastType.warning);

      return;
    }

    company.comName = authState.loginData.company?.comName ?? "";
    company.comAddress = authState.loginData.company?.comAddress ?? "";
    company.compPhone = authState.loginData.company?.comPhone ?? "";
    company.comEmail = authState.loginData.company?.comEmail ?? "";
    company.slogan = authState.loginData.company?.comDetails ?? "";
    company.comWebsite = authState.loginData.company?.comWebsite ?? "";
    company.comFacebook = authState.loginData.company?.comFb ?? "";
    company.comInstagram = authState.loginData.company?.comInsta ?? "";
    company.comWhatsApp = authState.loginData.company?.comWhatsapp ?? "";
    company.invoiceNumber = ordNumber;
    company.statementDate = DateTime.now().toFullDateTime;

    final base64Logo = authState.loginData.company?.comLogo;
    if (base64Logo != null && base64Logo.isNotEmpty) {
      try {
        company.comLogo = base64Decode(base64Logo);
      } catch (e) {
        "";
      }
    }

    final List<InvoiceItem> invoiceItems = current.items.map((item) {
      return PurchaseInvoiceItemForPrint(
        productName: item.productName,
        quantity: item.qty.toDouble(),
        unitPrice: item.purPrice ?? 0.0,
        batch: item.stkBatch,
        unit: item.unit ?? "",
        total: item.totalPurchase,
        storageName: item.storageName,
        localAmount: item.singleLocalAmount,
        localCurrency: current?.supplierAccount?.accCurrency ?? current?.toCurrency,
        exchangeRate: current?.exchangeRate,
      );
    }).toList();
    final totalLocalAmount = current.totalLocalAmount;
    showDialog(
      context: context,
      builder: (_) => PrintPreviewDialog<dynamic>(
        showRoll80: true,
        data: null,
        company: company,
        buildPreview: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return InvoicePrintService().printInvoicePreview(
            invoiceType: "Purchase",
            invoiceNumber: finalInvoiceNumber,
            reference: _xRefController.text,
            invoiceDate: DateTime.now(),
            customerSupplierName: current?.supplier?.perName ?? "",
            items: invoiceItems,
            grandTotal: current!.subtotal,
            cashPayment: current.cashPayment,
            creditAmount: current.creditAmount,
            account: current.supplierAccount,
            language: language,
            orientation: orientation,
            company: company.copyWith(visible: visibilityState),
            pageFormat: pageFormat,
            currency: baseCurrency,
            isSale: false,
            totalLocalAmount: needsConversion ? totalLocalAmount : null,
            localCurrency: needsConversion
                ? (current.supplierAccount?.accCurrency ?? current.toCurrency)
                : null,
            exchangeRate: needsConversion ? current.exchangeRate : null,
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
          return InvoicePrintService().printInvoiceDocument(
            invoiceType: "Purchase",
            invoiceNumber: finalInvoiceNumber,
            reference: _xRefController.text,
            invoiceDate: DateTime.now(),
            customerSupplierName: current?.supplier?.perName ?? "",
            items: invoiceItems,
            grandTotal: current!.subtotal,
            cashPayment: current.cashPayment,
            creditAmount: current.creditAmount,
            account: current.supplierAccount,
            language: language,
            orientation: orientation,
            company: company.copyWith(visible: visibilityState),
            selectedPrinter: selectedPrinter,
            pageFormat: pageFormat,
            copies: copies,
            currency: baseCurrency,
            isSale: false,
            totalLocalAmount: needsConversion ? totalLocalAmount : null,
            localCurrency: needsConversion
                ? (current.supplierAccount?.accCurrency ?? current.toCurrency)
                : null,
            exchangeRate: needsConversion ? current.exchangeRate : null,
          );
        },
        onSave: ({
          required data,
          required language,
          required orientation,
          required pageFormat,
        }) {
          return InvoicePrintService().createInvoiceDocument(
            invoiceType: "Purchase",
            invoiceNumber: finalInvoiceNumber,
            reference: _xRefController.text,
            invoiceDate: DateTime.now(),
            customerSupplierName: "${current?.supplier?.perName} ${current?.supplier?.perLastName}",
            items: invoiceItems,
            grandTotal: current!.subtotal,
            cashPayment: current.cashPayment,
            creditAmount: current.creditAmount,
            account: current.supplierAccount,
            language: language,
            orientation: orientation,
            company: company.copyWith(visible: visibilityState),
            pageFormat: pageFormat,
            currency: baseCurrency,
            isSale: false,
            totalLocalAmount: needsConversion ? totalLocalAmount : null,
            localCurrency: needsConversion
                ? (current.supplierAccount?.accCurrency ?? current.toCurrency)
                : null,
            exchangeRate: needsConversion ? current.exchangeRate : null,
          );
        },
      ),
    );
  }
}
class _DeletePurchaseConfirmDialog extends StatefulWidget {
  final int ordId;
  final String? ref;
  final String usrName;
  final String orderName;
  final VoidCallback onDeleted;
  final ValueChanged<String> onError;

  const _DeletePurchaseConfirmDialog({
    required this.ordId,
    required this.ref,
    required this.usrName,
    required this.orderName,
    required this.onDeleted,
    required this.onError,
  });

  @override
  State<_DeletePurchaseConfirmDialog> createState() =>
      _DeletePurchaseConfirmDialogState();
}

class _DeletePurchaseConfirmDialogState
    extends State<_DeletePurchaseConfirmDialog> {
  bool _isDeleting = false;

  Future<void> _confirm() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);

    final completer = Completer<String>();
    context.read<OrdersBloc>().add(
      DeleteOrderEvent(
        orderId: widget.ordId,
        usrName: widget.usrName,
        ref: widget.ref,
        orderName: widget.orderName,
        completer: completer,
      ),
    );

    String result;
    try {
      result = await completer.future;
    } catch (e) {
      result = e.toString();
    }

    if (!mounted) return;

    if (result == 'success') {
      Navigator.of(context).pop();
      widget.onDeleted();
      return;
    }

    setState(() => _isDeleting = false);
    widget.onError(result.isEmpty ? 'Delete not confirmed by server' : result);
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return ZAlertDialog(
      title: tr.areYouSure,
      content: tr.areYouSure,
      isYesLoading: _isDeleting,
      onYes: _isDeleting ? null : _confirm,
      onNo: _isDeleting ? null : () => Navigator.of(context).pop(),
      yesLabel: tr.yes,
      noLabel: tr.no,
    );
  }
}
class _PurchaseItemRow extends StatefulWidget {
  final PurchaseInvoiceItem item;
  final bool isLastRow;
  final int rowIndex;
  final bool isLocked;
  final Map<String, TextEditingController> qtyControllers;
  final Map<String, TextEditingController> batchControllers;
  final Map<String, TextEditingController> sellPriceControllers;
  final Map<String, TextEditingController> purchasePriceControllers;
  final Map<String, TextEditingController> costPriceControllers;
  final Map<String, FocusNode> productFocusRegistry;
  final ValueChanged<int>? onFocusRowProduct;
  final VoidCallback? onAddNewRowAndFocus;
  final Function(String) onDelete;
  final Function(String, int) onQtyChanged;
  final Function(String, int) onBatchChanged;
  final Function(String, double) onPurchasePriceChanged;
  final Function(String, double) onSellPriceChanged;
  final Function(String, int, String) onStorageSelected;
  final Function(String, String, String, String) onProductSelected;

  const _PurchaseItemRow({
    super.key,
    required this.item,
    required this.isLastRow,
    required this.rowIndex,
    this.isLocked = false,
    required this.qtyControllers,
    required this.batchControllers,
    required this.sellPriceControllers,
    required this.purchasePriceControllers,
    required this.costPriceControllers,
    required this.productFocusRegistry,
    this.onFocusRowProduct,
    this.onAddNewRowAndFocus,
    required this.onDelete,
    required this.onQtyChanged,
    required this.onBatchChanged,
    required this.onPurchasePriceChanged,
    required this.onSellPriceChanged,
    required this.onStorageSelected,
    required this.onProductSelected,
  });

  @override
  State<_PurchaseItemRow> createState() => _PurchaseItemRowState();
}
class _PurchaseItemRowState extends State<_PurchaseItemRow> {
  late TextEditingController _landedPriceController;
  late TextEditingController _storageController;
  late TextEditingController _localAmountController;
  late TextEditingController _sellPriceController;
  late TextEditingController _productController;
  late TextEditingController _headerProductController;

  late TextEditingController _qtyController;
  late TextEditingController _batchController;
  late TextEditingController _purchasePriceController;

  // Focus nodes belong to the row, not the parent invoice screen.
  // ListView.builder can therefore create/dispose them with the visible row.
  late final FocusNode _productFocusNode;
  late final FocusNode _qtyFocusNode;
  late final FocusNode _batchFocusNode;
  late final FocusNode _unitPriceFocusNode;
  late final FocusNode _localAmountFocusNode;
  late final FocusNode _sellPriceFocusNode;

  bool _isUpdating = false;
  bool _isEditingLocalAmount = false;
  Timer? _amountDebounce;
  double? _lastExchangeRate;
  bool _isUpdatingFromBloc = false;
  bool _storageAutoSelected = false;

  @override
  void initState() {
    super.initState();

    _productFocusNode = FocusNode();
    _qtyFocusNode = FocusNode();
    _batchFocusNode = FocusNode();
    _unitPriceFocusNode = FocusNode();
    _localAmountFocusNode = FocusNode();
    _sellPriceFocusNode = FocusNode();

    _productController = TextEditingController(text: widget.item.productName);
    _headerProductController = TextEditingController(text: widget.item.productName);
    _storageController = TextEditingController(text: widget.item.storageName);
    _localAmountController = TextEditingController(text: _getLocalAmountText());

    _qtyController = TextEditingController(
      text: widget.item.qty > 0
          ? widget.item.qty.toString()
          : '',
    );

    _batchController = TextEditingController(
      text: widget.item.stkBatch > 0
          ? widget.item.stkBatch.toString()
          : '1',
    );

    _purchasePriceController = TextEditingController(
      text: widget.item.purPrice != null &&
          widget.item.purPrice! > 0
          ? widget.item.purPrice!.toAmount()
          : '',
    );
    _landedPriceController = TextEditingController(
      text: widget.item.landedPrice != null && widget.item.landedPrice! > 0
          ? widget.item.landedPrice!.toAmount()
          : '',
    );

    _lastExchangeRate = _getCurrentExchangeRate();

    // Initialize sell price controller
    _initializeSellPriceController();

    // Register controllers in parent maps.
    widget.qtyControllers[widget.item.rowId] = _qtyController;
    widget.batchControllers[widget.item.rowId] = _batchController;
    widget.purchasePriceControllers[widget.item.rowId] = _purchasePriceController;
    widget.sellPriceControllers[widget.item.rowId] = _sellPriceController;
    widget.productFocusRegistry[widget.item.rowId] = _productFocusNode;

    // New/empty rows own their focus. This replaces the parent scan over all
    // invoice items and only runs for the row that is actually mounted.
    if (widget.isLastRow && widget.item.productId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _productFocusNode.canRequestFocus) {
          _productFocusNode.requestFocus();
        }
      });
    }
  }

  // Helper method to get local amount text
  String _getLocalAmountText() {
    if (widget.item.localAmount != null && widget.item.localAmount! > 0) {
      return widget.item.localAmount!.toAmount();
    }

    final exchangeRate = _getCurrentExchangeRate();
    if (widget.item.purPrice != null && exchangeRate != null && exchangeRate > 0) {
      final calculatedAmount = widget.item.purPrice! * exchangeRate;
      if (calculatedAmount > 0) {
        return calculatedAmount.toAmount();
      }
    }
    return '';
  }

  // Helper method to check if product is duplicate
  bool _isProductDuplicate(String productId) {
    final state = context.read<PurchaseInvoiceBloc>().state;
    if (state is PurchaseInvoiceLoaded) {
      for (final item in state.items) {
        if (item.rowId != widget.item.rowId && item.productId == productId) {
          return true;
        }
      }
    }
    return false;
  }

  void _addProduct(ProductsModel product) {
    if (!mounted) return;

    final productId = product.proId.toString();

    if (_isProductDuplicate(productId)) {
      _showDuplicateProductDialog(product);
      return;
    }

    _performAddProduct(product);
  }

  void _performAddProduct(ProductsModel product) {
    widget.onProductSelected(
        widget.item.rowId,
        product.proId.toString(),
        product.proName ?? '',
        product.proUnit ?? ''
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectFirstStorage();
    });
  }

  void _showDuplicateProductDialog(ProductsModel product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .6),
      builder: (dialogContext) {
        final FocusNode dialogFocusNode = FocusNode();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          dialogFocusNode.requestFocus();
        });

        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Focus(
            focusNode: dialogFocusNode,
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  Navigator.pop(dialogContext);
                  _productController.clear();
                  _headerProductController.clear();
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                  Navigator.pop(dialogContext);
                  _performAddProduct(product);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: AlertDialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: 450,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "duplicateProduct",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "itemAlreadyExists",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutQuad,
                            builder: (context, opacity, child) {
                              return Opacity(opacity: opacity, child: child);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: .2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        AppLocalizations.of(context)!.productDetails.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product.proName ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  if (product.proCode != null && product.proCode!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Code: ${product.proCode}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.error.withValues(alpha: .2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.duplicateEntry,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ZOutlineButton(
                                  backgroundHover: Theme.of(context).colorScheme.error,
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    _productController.clear();
                                    _headerProductController.clear();
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted && _productFocusNode.canRequestFocus) {
                                        _productFocusNode.requestFocus();
                                      }
                                    });
                                  },
                                  label: Text(
                                    AppLocalizations.of(context)!.cancel.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ZOutlineButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    _performAddProduct(product);
                                  },
                                  isActive: true,
                                  label: Text(
                                    AppLocalizations.of(context)!.addAgain,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _autoSelectFirstStorage() {
    final storageState = context.read<StorageBloc>().state;
    if (storageState is StorageLoadedState && storageState.storage.isNotEmpty) {
      final firstStorage = storageState.storage.first;
      widget.onStorageSelected(
        widget.item.rowId,
        firstStorage.stgId!,
        firstStorage.stgName ?? '',
      );
      _storageController.text = firstStorage.stgName ?? '';
    }
  }

  void _initializeSellPriceController() {
    final sellPrice = widget.item.sellPrice;

    _sellPriceController = TextEditingController(
      text: sellPrice != null && sellPrice > 0
          ? sellPrice.toAmount()
          : '',
    );

    widget.sellPriceControllers[widget.item.rowId] =
        _sellPriceController;
  }

  double? _getCurrentExchangeRate() {
    final state = context.read<PurchaseInvoiceBloc>().state;
    if (state is PurchaseInvoiceLoaded) {
      return state.exchangeRate;
    }
    return null;
  }

  void _updateLocalAmountFromPurchasePrice() {
    if (_isEditingLocalAmount || _isUpdatingFromBloc) return;

    final exchangeRate = _getCurrentExchangeRate();
    if (exchangeRate != null && exchangeRate > 0 && widget.item.purPrice != null) {
      final newLocalAmount = widget.item.purPrice! * exchangeRate;
      final newText = newLocalAmount.toAmount();

      if (_localAmountController.text != newText) {
        _localAmountController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }
  }

  void _updatePurchasePriceFromLocalAmount(double localAmount) {
    if (_isUpdatingFromBloc) return;

    final exchangeRate = _getCurrentExchangeRate();
    if (exchangeRate != null && exchangeRate > 0) {
      final newPurPrice = localAmount / exchangeRate;

      // Update the purchase price controller directly
      final priceController = _purchasePriceController;
      final newPriceText = newPurPrice.toAmount();
      if (priceController.text != newPriceText) {
        priceController.text = newPriceText;
      }

      // Update through callback
      widget.onPurchasePriceChanged(widget.item.rowId, newPurPrice);

      // Dispatch event to update BLoC state
      context.read<PurchaseInvoiceBloc>().add(
        UpdateItemLocalAmountEvent(
          rowId: widget.item.rowId,
          localAmount: localAmount,
        ),
      );
    }
  }

  void _onLocalAmountChanged(String value) {
    _amountDebounce?.cancel();
    _amountDebounce = Timer(const Duration(milliseconds: 1000), () {
      final localAmount = double.tryParse(value.replaceAll(',', ''));
      if (localAmount != null && localAmount > 0) {
        _isEditingLocalAmount = true;
        _updatePurchasePriceFromLocalAmount(localAmount);
        _isEditingLocalAmount = false;
      }
    });
  }

  void _onBaseAmountChanged(String value) {
    _amountDebounce?.cancel();
    _amountDebounce = Timer(const Duration(milliseconds: 1000), () {
      final parsed = double.tryParse(value.replaceAll(',', '')) ?? 0;
      widget.onPurchasePriceChanged(widget.item.rowId, parsed);
      if (!_isEditingLocalAmount) {
        _updateLocalAmountFromPurchasePrice();
      }
    });
  }

  void _updateSellPriceFromAmount() {
    if (_isUpdating) return;
    _isUpdating = true;

    final amount = double.tryParse(_sellPriceController.text.replaceAll(',', '')) ?? 0;

    widget.onSellPriceChanged(widget.item.rowId, amount);
    widget.item.sellPriceAmountOriginal = amount;
    widget.item.sellPrice = amount; // ✅ Store the amount directly

    _isUpdating = false;
  }

  @override
  void didUpdateWidget(covariant _PurchaseItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (identical(oldWidget.item, widget.item)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Update landed price display
      if (widget.item.landedPrice != oldWidget.item.landedPrice) {
        final newValue = widget.item.landedPrice != null && widget.item.landedPrice! > 0
            ? widget.item.landedPrice!.toAmount()
            : '';

        if (_landedPriceController.text != newValue) {
          _landedPriceController.value = TextEditingValue(
            text: newValue,
            selection: TextSelection.collapsed(offset: newValue.length),
          );
        }
      }

      // Update storage display
      if (widget.item.storageId == 0 && oldWidget.item.storageId != 0) {
        _storageAutoSelected = false;
      }

      if (widget.item.storageName != oldWidget.item.storageName) {
        if (_storageController.text != widget.item.storageName) {
          final text = widget.item.storageName;
          _storageController.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
      }

      // ✅ Update sell price display if changed (now reading from percentage)
      if (widget.item.sellPrice != oldWidget.item.sellPrice) {
        final newAmount = widget.item.sellPrice ?? 0;
        if (newAmount > 0) {
          _sellPriceController.text = newAmount.toAmount();
          widget.item.sellPriceAmountOriginal = newAmount;
        } else {
          _sellPriceController.text = '';
          widget.item.sellPriceAmountOriginal = 0;
        }
      }

      // Update purchase price and local amount
      final currentExchangeRate = _getCurrentExchangeRate();
      bool needsUpdate = false;

      if (widget.item.purPrice != oldWidget.item.purPrice) {

        final priceController = _purchasePriceController;
        if (widget.item.purPrice != null) {
          final newPriceText = widget.item.purPrice!.toAmount();
          if (priceController.text != newPriceText) {
            _isUpdatingFromBloc = true;
            priceController.text = newPriceText;
            _isUpdatingFromBloc = false;
          }
        }
        needsUpdate = true;
      }

      // Update local amount
      if (currentExchangeRate != _lastExchangeRate || needsUpdate) {
        _lastExchangeRate = currentExchangeRate;
        if (!_isEditingLocalAmount) {
          _updateLocalAmountFromPurchasePrice();
        }
      }
    });
  }

  @override
  void dispose() {
    _amountDebounce?.cancel();

    // Remove references from parent maps.
    widget.qtyControllers.remove(widget.item.rowId);
    widget.batchControllers.remove(widget.item.rowId);
    widget.purchasePriceControllers.remove(widget.item.rowId);
    widget.sellPriceControllers.remove(widget.item.rowId);
    if (identical(widget.productFocusRegistry[widget.item.rowId], _productFocusNode)) {
      widget.productFocusRegistry.remove(widget.item.rowId);
    }

    // Dispose controllers owned by this row.
    _productController.dispose();
    _headerProductController.dispose();
    _landedPriceController.dispose();
    _storageController.dispose();
    _localAmountController.dispose();

    _qtyController.dispose();
    _batchController.dispose();
    _purchasePriceController.dispose();
    _sellPriceController.dispose();

    _productFocusNode.dispose();
    _qtyFocusNode.dispose();
    _batchFocusNode.dispose();
    _unitPriceFocusNode.dispose();
    _localAmountFocusNode.dispose();
    _sellPriceFocusNode.dispose();

    super.dispose();
  }

  void _requestFocus(FocusNode node) {
    Future.delayed(const Duration(milliseconds: 40), () {
      if (mounted && node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  void focusNextField(FocusNode currentNode) {
    final visibility = context.read<SettingsVisibleBloc>().state;
    final isWholeSale = visibility.isWholeSale;
    final needsLocalConversion = _needsLocalConversion(context);

    if (identical(currentNode, _productFocusNode)) {
      _requestFocus(_qtyFocusNode);
      return;
    }

    if (identical(currentNode, _qtyFocusNode)) {
      if (isWholeSale) {
        _requestFocus(_batchFocusNode);
      } else {
        _requestFocus(_unitPriceFocusNode);
      }
      return;
    }

    if (identical(currentNode, _batchFocusNode)) {
      _requestFocus(_unitPriceFocusNode);
      return;
    }

    if (identical(currentNode, _unitPriceFocusNode)) {
      if (needsLocalConversion) {
        _requestFocus(_localAmountFocusNode);
      } else {
        _requestFocus(_sellPriceFocusNode);
      }
      return;
    }

    if (identical(currentNode, _localAmountFocusNode)) {
      _requestFocus(_sellPriceFocusNode);
      return;
    }

    if (identical(currentNode, _sellPriceFocusNode)) {
      if (widget.isLastRow) {
        _addNewRowAndFocus();
      } else {
        widget.onFocusRowProduct?.call(widget.rowIndex + 1);
      }
      return;
    }
  }

  void _addNewRowAndFocus() {
    if (widget.onAddNewRowAndFocus != null) {
      widget.onAddNewRowAndFocus!();
      return;
    }

    context.read<PurchaseInvoiceBloc>().add(AddNewPurchaseItemEvent());
  }

  String _getBaseCurrency() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      return authState.loginData.company?.comLocalCcy ?? '';
    }
    return '';
  }

  String _getAccountCurrency() {
    final state = context.read<PurchaseInvoiceBloc>().state;
    if (state is PurchaseInvoiceLoaded && state.supplierAccount != null) {
      return state.supplierAccount!.accCurrency ?? '';
    }
    return '';
  }

  bool _needsLocalConversion(BuildContext context) {
    final state = context.read<PurchaseInvoiceBloc>().state;
    if (state is PurchaseInvoiceLoaded && state.supplierAccount != null) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        final baseCurrency = authState.loginData.company?.comLocalCcy ?? '';
        final accountCurrency = state.supplierAccount!.accCurrency ?? '';
        return baseCurrency.isNotEmpty &&
            accountCurrency.isNotEmpty &&
            baseCurrency != accountCurrency;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final visibility = context.read<SettingsVisibleBloc>().state;
    final isWholeSale = visibility.isWholeSale;
    final needsLocalConversion = _needsLocalConversion(context);

    final qtyController = _qtyController;
    final batchController = _batchController;
    final priceController = _purchasePriceController;

    return RepaintBoundary(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                /// Row number
                SizedBox(
                  width: 40,
                  child: Text(
                    (widget.rowIndex + 1).toString(),
                    textAlign: TextAlign.center,
                  ),
                ),

                /// Product Search Field
                Expanded(
                  child: ProductsSearchField(
                    controller: _productController,
                    headerSearchController: _headerProductController,
                    focusNode: _productFocusNode,
                    bloc: context.read<ProductsBloc>(),
                    onProductSelected: (product) {
                      if (product != null) {
                        _addProduct(product);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            if (_qtyFocusNode.canRequestFocus) {
                              _qtyFocusNode.requestFocus();
                            }
                          }
                        });
                      }
                    },
                    onSubmitted: () {
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (mounted && widget.item.productId.isNotEmpty) {
                          if (_qtyFocusNode.canRequestFocus) {
                            _qtyFocusNode.requestFocus();
                          }
                        }
                      });
                    },
                    hintText: AppLocalizations.of(context)!.products,
                    showAllOnFocus: true,
                    openOverlayOnFocus: true,
                  ),
                ),

                /// Qty
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: qtyController,
                    focusNode: _qtyFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: locale.qty,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final qty = int.tryParse(value) ?? 0;
                      widget.onQtyChanged(widget.item.rowId, qty);
                    },
                    onSubmitted: (_) => focusNextField(_qtyFocusNode),
                  ),
                ),

                if (isWholeSale) ...[
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: batchController,
                      focusNode: _batchFocusNode,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: locale.batchTitle,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final batch = int.tryParse(value) ?? 0;
                        final effectiveBatch = batch <= 0 ? 1 : batch;
                        if (effectiveBatch != batch) {
                          batchController.text = effectiveBatch.toString();
                        }
                        widget.onBatchChanged(widget.item.rowId, effectiveBatch);
                      },
                      onSubmitted: (_) => focusNextField(_batchFocusNode),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      widget.item.totalQty.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],

                /// Unit Price (Base Currency)
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: priceController,
                    focusNode: _unitPriceFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,6}')),
                    ],
                    decoration: InputDecoration(
                      hintText: "${locale.unitPrice} (${_getBaseCurrency()})",
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: _onBaseAmountChanged,
                    onSubmitted: (_) => focusNextField(_unitPriceFocusNode),
                  ),
                ),

                /// Local Amount (editable)
                if (needsLocalConversion)
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _localAmountController,
                      focusNode: _localAmountFocusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        hintText: "${locale.amount} (${_getAccountCurrency()})",
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: _onLocalAmountChanged,
                      onSubmitted: (_) => focusNextField(_localAmountFocusNode),
                    ),
                  ),

                /// Sell Price (Simple Amount)
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _sellPriceController,
                    focusNode: _sellPriceFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      hintText: locale.sellPrice,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      _updateSellPriceFromAmount();
                    },
                    onSubmitted: (_) {
                      focusNextField(_sellPriceFocusNode);
                    },
                  ),
                ),

                /// Landed Price (read-only)
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _landedPriceController,
                    decoration: InputDecoration(
                      hintText: locale.landedCost,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    readOnly: true,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                /// Storage
                SizedBox(
                  width: 180,
                  child: BlocBuilder<StorageBloc, StorageState>(
                    buildWhen: (previous, current) {
                      if (current is StorageLoadedState && previous is StorageLoadedState) {
                        return false;
                      }
                      return true;
                    },
                    builder: (context, state) {
                      if (state is StorageLoadedState &&
                          state.storage.isNotEmpty &&
                          widget.item.storageId == 0 &&
                          !_storageAutoSelected) {
                        _storageAutoSelected = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          final first = state.storage.first;
                          widget.onStorageSelected(
                            widget.item.rowId,
                            first.stgId!,
                            first.stgName ?? '',
                          );
                          if (_storageController.text != (first.stgName ?? '')) {
                            _storageController.text = first.stgName ?? '';
                          }
                        });
                      }

                      return GenericUnderlineTextfield<StorageModel, StorageBloc, StorageState>(
                        title: "",
                        controller: _storageController,
                        hintText: locale.storage,
                        bloc: context.read<StorageBloc>(),
                        fetchAllFunction: (bloc) => bloc.add(LoadStorageEvent()),
                        searchFunction: (bloc, query) => bloc.add(LoadStorageEvent()),
                        itemBuilder: (context, stg) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(stg.stgName ?? ''),
                        ),
                        itemToString: (stg) => stg.stgName ?? '',
                        stateToLoading: (state) => state is StorageLoadingState,
                        stateToItems: (state) {
                          if (state is StorageLoadedState) {
                            return state.storage;
                          }
                          return [];
                        },
                        onSelected: (storage) {
                          widget.onStorageSelected(
                            widget.item.rowId,
                            storage.stgId!,
                            storage.stgName ?? '',
                          );
                          _storageController.text = storage.stgName ?? '';
                        },
                      );
                    },
                  ),
                ),

                /// Delete button
                SizedBox(
                  width: 60,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => widget.onDelete(widget.item.rowId),
                  ),
                ),
              ],
            ),
          ),

          /// Add button (only for last row)
          if (widget.isLastRow)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  ZOutlineButton(
                    width: 120,
                    icon: Icons.add,
                    label: Text(locale.addItem),
                    onPressed: () => _addNewRowAndFocus(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PurchasePaymentDialog extends StatefulWidget {
  final PurchaseInvoiceLoaded state;

  const PurchasePaymentDialog({super.key, required this.state});

  @override
  State<PurchasePaymentDialog> createState() => _PurchasePaymentDialogState();
}
class _PurchasePaymentDialogState extends State<PurchasePaymentDialog> {
  late TextEditingController _cashPaymentController;
  late TextEditingController _exchangeRateController;
  late TextEditingController _cashExchangeRateController;

  String _selectedCashCurrency = '';
  double _cashExchangeRate = 1.0;
  bool _isLoadingCashRate = false;
  String _baseCurrency = '';

  PurchaseInvoiceLoaded _currentState = PurchaseInvoiceLoaded(
    items: [],
    payments: [],
    cashPayment: 0.0,
    paymentMode: PaymentMode.cash,
  );

  late StreamSubscription _blocSubscription;
  double _currentCashAmountInSelectedCurrency = 0.0;
  bool get _isPureCashMode => _currentState.supplierAccount == null;

  @override
  void initState() {
    super.initState();

    _currentState = widget.state;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      _baseCurrency = authState.loginData.company?.comLocalCcy ?? '';
    }

    if (_baseCurrency.isEmpty) {
      _baseCurrency = _currentState.fromCurrency ?? '';
    }

    if (_currentState.cashCurrency != null && _currentState.cashCurrency!.isNotEmpty) {
      _selectedCashCurrency = _currentState.cashCurrency!;
    } else {
      _selectedCashCurrency = _baseCurrency;
    }

    _cashExchangeRate = _currentState.cashExchangeRate > 0
        ? _currentState.cashExchangeRate
        : 1.0;

    final totalInvoiceAmount = _currentState.subtotal + _currentState.totalExpenses;

    if (_isPureCashMode) {
      _currentCashAmountInSelectedCurrency = totalInvoiceAmount * _cashExchangeRate;
    } else {
      _currentCashAmountInSelectedCurrency = _currentState.cashPayment * _cashExchangeRate;
    }

    _cashPaymentController = TextEditingController(
      text: _currentCashAmountInSelectedCurrency > 0
          ? _currentCashAmountInSelectedCurrency.toStringAsFixed(2)
          : '',
    );

    _exchangeRateController = TextEditingController(
      text: _currentState.exchangeRate != null && _currentState.exchangeRate! > 0
          ? _currentState.exchangeRate!.toStringAsFixed(4)
          : '',
    );

    _cashExchangeRateController = TextEditingController(
      text: _cashExchangeRate.toStringAsFixed(4),
    );

    if (_currentState.cashCurrency == null || _currentState.cashCurrency!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PurchaseInvoiceBloc>().add(UpdateCashCurrencyEvent(
          currency: _baseCurrency,
          exchangeRate: 1.0,
        ));

        if (_isPureCashMode) {
          context.read<PurchaseInvoiceBloc>().add(UpdateCashPaymentEvent(totalInvoiceAmount));
        }
      });
    }

    _blocSubscription = context.read<PurchaseInvoiceBloc>().stream.listen((state) {
      if (state is PurchaseInvoiceLoaded && mounted) {
        setState(() {
          _currentState = state;

          final newRate = _currentState.exchangeRate != null && _currentState.exchangeRate! > 0
              ? _currentState.exchangeRate!.toStringAsFixed(4)
              : '';
          if (_exchangeRateController.text != newRate) {
            _exchangeRateController.text = newRate;
          }

          if (_currentState.cashCurrency != null && _currentState.cashCurrency!.isNotEmpty) {
            if (_selectedCashCurrency != _currentState.cashCurrency) {
              _selectedCashCurrency = _currentState.cashCurrency!;
              _cashExchangeRate = _currentState.cashExchangeRate;
              _cashExchangeRateController.text = _cashExchangeRate.toStringAsFixed(4);
            }
          }

          if (_isPureCashMode) {
            final totalAmount = _currentState.subtotal + _currentState.totalExpenses;
            final expectedCashInSelectedCurrency = totalAmount * _cashExchangeRate;
            if (_currentCashAmountInSelectedCurrency != expectedCashInSelectedCurrency) {
              _currentCashAmountInSelectedCurrency = expectedCashInSelectedCurrency;
              _cashPaymentController.text = expectedCashInSelectedCurrency.toStringAsFixed(2);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _blocSubscription.cancel();
    _cashPaymentController.dispose();
    _exchangeRateController.dispose();
    _cashExchangeRateController.dispose();
    super.dispose();
  }

  void _updateCashPayment(double amountInSelectedCurrency) {
    if (_isPureCashMode) {
      final totalAmount = _currentState.subtotal + _currentState.totalExpenses;
      final correctAmount = totalAmount * _cashExchangeRate;
      if (_currentCashAmountInSelectedCurrency != correctAmount) {
        setState(() {
          _currentCashAmountInSelectedCurrency = correctAmount;
          _cashPaymentController.text = correctAmount.toStringAsFixed(2);
        });
      }
      return;
    }

    setState(() {
      _currentCashAmountInSelectedCurrency = amountInSelectedCurrency;
    });

    final amountInBaseCurrency = amountInSelectedCurrency / _cashExchangeRate;
    context.read<PurchaseInvoiceBloc>().add(
      UpdateCashPaymentEvent(amountInBaseCurrency),
    );
  }

  void _updateCashCurrencyAndRate(String currency, double rate) {
    setState(() {
      _selectedCashCurrency = currency;
      _cashExchangeRate = rate;
      _cashExchangeRateController.text = rate.toStringAsFixed(4);

      final totalInvoiceAmount = _currentState.subtotal + _currentState.totalExpenses;
      double newAmountInSelectedCurrency;

      if (_isPureCashMode) {
        newAmountInSelectedCurrency = totalInvoiceAmount * rate;
      } else {
        final currentAmountInBase = _currentState.cashPayment;
        newAmountInSelectedCurrency = currentAmountInBase * rate;
      }

      _currentCashAmountInSelectedCurrency = newAmountInSelectedCurrency;
      _cashPaymentController.text = newAmountInSelectedCurrency > 0
          ? newAmountInSelectedCurrency.toStringAsFixed(2)
          : '';
    });

    context.read<PurchaseInvoiceBloc>().add(UpdateCashCurrencyEvent(
      currency: currency,
      exchangeRate: rate,
    ));
  }

  double get _cashAmountInBase {
    if (_isPureCashMode) {
      return _currentState.subtotal + _currentState.totalExpenses;
    }
    return _currentCashAmountInSelectedCurrency / _cashExchangeRate;
  }

  double get _creditAmount {
    final totalInvoiceAmount = _currentState.subtotal;
    if (_isPureCashMode) {
      return 0.0;
    }
    if (_currentState.paymentMode == PaymentMode.credit) {
      return totalInvoiceAmount;
    } else if (_currentState.paymentMode == PaymentMode.mixed) {
      return totalInvoiceAmount - _cashAmountInBase;
    }
    return 0.0;
  }

  double get _creditAmountInSupplierCurrency {
    if (_creditAmount <= 0) return 0.0;
    if (_currentState.exchangeRate == null || _currentState.exchangeRate == 0) return _creditAmount;
    return _creditAmount * _currentState.exchangeRate!;
  }

  double get _newBalanceInSupplierCurrency {
    if (_currentState.supplierAccount == null) return 0.0;
    return _currentState.currentBalance + _creditAmountInSupplierCurrency;
  }

  Color _getBalanceColor(double balance) {
    if (balance > 0) return Colors.orange;
    if (balance < 0) return Colors.green;
    return Colors.grey;
  }

  void _onCashCurrencyChanged(CurrenciesModel? currency) {
    if (currency == null) return;

    final newCurrency = currency.ccyCode!;
    if (newCurrency == _selectedCashCurrency) return;

    setState(() {
      _selectedCashCurrency = newCurrency;
      _isLoadingCashRate = true;
    });

    if (_baseCurrency.isNotEmpty && newCurrency != _baseCurrency) {
      _fetchCashExchangeRate(_baseCurrency, newCurrency);
    } else {
      setState(() {
        _cashExchangeRate = 1.0;
        _cashExchangeRateController.text = '1.0000';
        _isLoadingCashRate = false;
      });
      _updateCashCurrencyAndRate(newCurrency, 1.0);
    }
  }

  Future<void> _fetchCashExchangeRate(String fromCurrency, String toCurrency) async {
    try {
      final rateStr = await context.read<PurchaseInvoiceBloc>().repo.getSingleRate(
        fromCcy: fromCurrency,
        toCcy: toCurrency,
      );
      final rate = double.tryParse(rateStr ?? "1.0") ?? 1.0;

      if (mounted) {
        setState(() {
          _cashExchangeRate = rate;
          _cashExchangeRateController.text = rate.toStringAsFixed(4);
          _isLoadingCashRate = false;
        });
        _updateCashCurrencyAndRate(toCurrency, rate);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cashExchangeRate = 1.0;
          _cashExchangeRateController.text = '1.0000';
          _isLoadingCashRate = false;
        });
        _updateCashCurrencyAndRate(toCurrency, 1.0);
      }
    }
  }

  void _updateExchangeRate(double rate) {
    if (_currentState.supplierAccount != null) {
      context.read<PurchaseInvoiceBloc>().add(
        UpdateExchangeRateManuallyEvent(
          rate: rate,
          fromCurrency: _baseCurrency,
          toCurrency: _currentState.supplierAccount!.accCurrency ?? '',
        ),
      );
    }
  }

  void _updateCashExchangeRate(double rate) {
    if (rate > 0) {
      _updateCashCurrencyAndRate(_selectedCashCurrency, rate);
    }
  }

  void _onConfirm() {
    final finalCashAmount = _cashAmountInBase;
    context.read<PurchaseInvoiceBloc>().add(UpdateCashPaymentEvent(finalCashAmount));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final needsAccountConversion = _currentState.needsExchangeRate && !_isPureCashMode;
    final totalInvoiceAmount = _currentState.subtotal + _currentState.totalExpenses;
    final cashAmountInBase = _cashAmountInBase;
    final creditAmount = _creditAmount;
    final creditAmountInSupplierCurrency = _creditAmountInSupplierCurrency;
    final needsCashConversion = _selectedCashCurrency.isNotEmpty &&
        _baseCurrency.isNotEmpty &&
        _selectedCashCurrency != _baseCurrency;

    final supplierCurrency = _currentState.supplierAccount?.accCurrency ?? _baseCurrency;

    return ZFormDialog(
      title: _isPureCashMode ? "${tr.cashPayment} - ${tr.fullCashPayment}" : tr.payment.toUpperCase(),
      icon: Icons.payment,
      width: 550,
      actionLabel: Text(tr.confirm),
      isActionTrue: true,
      onAction: _onConfirm,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Section
              SectionTitle(title: tr.orderSummary.toUpperCase()),
              const SizedBox(height: 8),
              ZCover(
                padding: const EdgeInsets.all(12),
                radius: 8,
                child: Column(
                  children: [
                    _infoRow(
                      label: tr.grandTotal,
                      value: totalInvoiceAmount,
                      currency: _baseCurrency,
                      isBold: true,
                      fontSize: 20,
                    ),
                    if (_currentState.totalExpenses > 0)
                      _infoRow(
                        label: tr.totalExpense,
                        value: _currentState.totalExpenses,
                        currency: _baseCurrency,
                        color: Colors.red,
                      ),
                    if (needsAccountConversion &&
                        _currentState.exchangeRate != null &&
                        _currentState.exchangeRate! > 0 &&
                        _currentState.toCurrency != null)
                      _infoRow(
                        label: "${tr.grandTotal} (${_currentState.toCurrency})",
                        value: totalInvoiceAmount * _currentState.safeExchangeRate,
                        currency: _currentState.toCurrency!,
                        fontSize: 15,
                        color: color.outline.withValues(alpha: .7),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              SectionTitle(title: tr.payment),
              const SizedBox(height: 10),

              // Cash Payment Field
              ZGenericTextField(
                controller: _cashPaymentController,
                title: "${tr.cashAmount} ($_selectedCashCurrency)",
                hint: "0.00",
                readOnly: _isPureCashMode,
                defaultCurrencyCode: _selectedCashCurrency,
                fieldType: ZTextFieldType.currency,
                onCurrencyChanged: _onCashCurrencyChanged,
                inputFormat: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}'),
                  ),
                ],
                onChanged: (value) {
                  final amountInSelectedCurrency = double.tryParse(value.replaceAll(',', '')) ?? 0;
                  _updateCashPayment(amountInSelectedCurrency);
                },
                showFlag: true,
                showClearButton: true,
                showSymbol: false,
                isRequired: true,
                onSubmit: (_) => _onConfirm(),
              ),

              // Exchange Rate for Cash
              if (needsCashConversion) ...[
                const SizedBox(height: 8),
                ZTextFieldEntitled(
                  controller: _cashExchangeRateController,
                  title: "${tr.exchangeRates} (1 $_baseCurrency = ? $_selectedCashCurrency)",
                  hint: "1 $_baseCurrency = ?",
                  inputFormat: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,6}'),
                    ),
                  ],
                  onChanged: (value) {
                    final rate = double.tryParse(value.replaceAll(',', '')) ?? 1.0;
                    if (rate > 0) {
                      _updateCashExchangeRate(rate);
                    }
                  },
                  trailing: _isLoadingCashRate
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : null,
                ),
              ],

              const SizedBox(height: 12),

              // Account Information Section (Combined with Cash Payment)
              if (!_isPureCashMode && _currentState.supplierAccount != null)
                ZCover(
                  padding: const EdgeInsets.all(12),
                  radius: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.credit_card, size: 20, color: color.primary),
                              const SizedBox(width: 8),
                              Text(
                                tr.accountInformation.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            "${_currentState.supplierAccount?.accName} (${_currentState.supplierAccount?.accNumber})",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Divider(),
                      const SizedBox(height: 5),

                      // Cash Payment in Account Section
                      AmountDisplay(
                        title: tr.cashPayment,
                        baseAmount: cashAmountInBase,
                        baseCurrency: _baseCurrency,
                        convertedAmount: (needsCashConversion && cashAmountInBase > 0)
                            ? _currentCashAmountInSelectedCurrency
                            : null,
                        convertedCurrency: _selectedCashCurrency,
                        baseColor: Colors.green,
                      ),

                      // Account Balance Details
                      AmountDisplay(
                        title: tr.accountPayable,
                        baseAmount: creditAmount,
                        baseCurrency: _baseCurrency,
                        convertedAmount: (needsAccountConversion && creditAmount > 0)
                            ? creditAmountInSupplierCurrency
                            : null,
                        convertedCurrency: supplierCurrency,
                        showSign: true,
                        isPositive: true,
                        baseColor: Colors.orange,
                      ),


                      _infoRow(
                        label: tr.currentBalance,
                        value: _currentState.currentBalance.abs(),
                        currency: supplierCurrency,
                        fontSize: 15,
                        color: _getBalanceColor(_currentState.currentBalance),
                      ),

                      const SizedBox(height: 5),
                      const Divider(),
                      const SizedBox(height: 5),

                      _infoRow(
                        label: tr.newBalance,
                        value: _newBalanceInSupplierCurrency.abs(),
                        currency: supplierCurrency,
                        isBold: true,
                        fontSize: 17,
                        color: _getBalanceColor(_newBalanceInSupplierCurrency),
                      ),
                    ],
                  ),
                ),

              // Exchange Rate for Account (if needed)
              if (!_isPureCashMode && needsAccountConversion && _currentState.toCurrency != null) ...[
                const SizedBox(height: 12),
                ZTextFieldEntitled(
                  controller: _exchangeRateController,
                  title: "${tr.exchangeRates} ($_baseCurrency → ${_currentState.toCurrency})",
                  hint: "1 $_baseCurrency = ?",
                  inputFormat: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,6}'),
                    ),
                  ],
                  onChanged: (value) {
                    final rate = double.tryParse(value.replaceAll(',', '')) ?? 1.0;
                    if (rate > 0) {
                      _updateExchangeRate(rate);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required double value,
    required String currency,
    bool isBold = false,
    Color? color,
    double fontSize = 14,
  }) {
    final themeColor = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "${value.toStringAsFixed(2)} $currency",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color ?? themeColor.primary,
            ),
          ),
        ],
      ),
    );
  }
}

