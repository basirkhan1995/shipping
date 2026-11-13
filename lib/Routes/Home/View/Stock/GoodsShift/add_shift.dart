import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/toast.dart';
import 'package:shipping/Features/Widgets/zbutton.dart';
import '../../../../../Features/Other/form_dialog.dart';
import '../../../../../Features/Widgets/cover.dart';
import '../../../../../Features/Widgets/extensions.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../Auth/bloc/auth_bloc.dart';
import '../../Products/bloc/products_bloc.dart';
import '../../Products/model/product_stock_model.dart';
import '../../Settings/View/Company/Storage/bloc/storage_bloc.dart';
import '../../Settings/View/Company/Storage/model/storage_model.dart';
import '../Purchase/features/underline_field.dart';
import '../Sale/features/sale_product_field.dart';
import 'bloc/goods_shift_bloc.dart';
import 'model/shift_model.dart';

// ------------------------------------------------------------------
// PUBLIC ENTRY POINT — open create or edit dialog
// ------------------------------------------------------------------
Future<bool?> showGoodsShiftDialog(
    BuildContext context, {
      required String usrName,
      int? ordId,
    }) {
  final bloc = context.read<GoodsShiftBloc>();

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: AddGoodsShiftView(
        ordId: ordId,
        usrNameOverride: usrName,
      ),
    ),
  );
}

// ------------------------------------------------------------------
// WIDGET
// ------------------------------------------------------------------
class AddGoodsShiftView extends StatefulWidget {
  /// When null → create mode. When set → edit mode (loads + prefills).
  final int? ordId;

  /// Optional override (e.g. from caller). Falls back to AuthBloc.
  final String? usrNameOverride;

  const AddGoodsShiftView({
    super.key,
    this.ordId,
    this.usrNameOverride,
  });

  bool get isEdit => ordId != null;

  @override
  State<AddGoodsShiftView> createState() => _AddGoodsShiftViewState();
}

class _AddGoodsShiftViewState extends State<AddGoodsShiftView> {
  final List<TextEditingController> _productControllers = [];
  final List<TextEditingController> _fromStorageControllers = [];
  final List<TextEditingController> _toStorageControllers = [];
  final List<TextEditingController> _qtyControllers = [];

  String? _userName;
  final List<ShiftRecord> _records = [];

  final List<ProductsStockModel?> _selectedProducts = [];
  final List<StorageModel?> _selectedFromStorages = [];
  final List<StorageModel?> _selectedToStorages = [];

  bool _isSaving = false;
  bool _hasError = false;
  bool _isLoadingDetail = false;
  String? _errorMessage;

  /// Prevents the edit-prefill listener from firing more than once.
  bool _prefilled = false;

  final List<List<FocusNode>> _rowFocusNodes = [];

  @override
  void initState() {
    super.initState();

    // Resolve user
    final authState = context.read<AuthBloc>().state;
    _userName = widget.usrNameOverride ??
        (authState is AuthenticatedState
            ? authState.loginData.usrName
            : null);

    if (widget.isEdit) {
      // EDIT: load the shift, don't create an empty row yet
      _isLoadingDetail = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context
            .read<GoodsShiftBloc>()
            .add(LoadGoodsShiftByIdEvent(widget.ordId!));
      });
    } else {
      // CREATE: start with one empty row and focus
      _addEmptyItem();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _focusFirstProductField();
        });
      });
    }
  }

  void _focusFirstProductField() {
    if (_rowFocusNodes.isNotEmpty && _rowFocusNodes[0].isNotEmpty) {
      _rowFocusNodes[0][0].requestFocus();
    }
  }

  @override
  void dispose() {
    for (final c in _productControllers) {
      c.dispose();
    }
    for (final c in _fromStorageControllers) {
      c.dispose();
    }
    for (final c in _toStorageControllers) {
      c.dispose();
    }
    for (final c in _qtyControllers) {
      c.dispose();
    }
    for (final nodes in _rowFocusNodes) {
      for (final n in nodes) {
        n.dispose();
      }
    }
    super.dispose();
  }

  // ------------------------------------------------------------------
  // ROW MANAGEMENT
  // ------------------------------------------------------------------
  void _addEmptyItem() {
    _productControllers.add(TextEditingController());
    _fromStorageControllers.add(TextEditingController());
    _toStorageControllers.add(TextEditingController());
    _qtyControllers.add(TextEditingController(text: "1"));

    _selectedProducts.add(null);
    _selectedFromStorages.add(null);
    _selectedToStorages.add(null);

    _records.add(ShiftRecord(
      stkProduct: 0,
      fromStorageId: 0,
      toStorageId: 0,
      stkQuantity: 1,
      stkPurPrice: "0.00",
      stkLandedPurPrice: "0.00",
      stkQtyInBatch: 0,
    ));

    _rowFocusNodes.add([FocusNode(), FocusNode(), FocusNode()]);
  }

  void _removeItem(int index) {
    if (_records.length <= 1) {
      ToastManager.show(
        context: context,
        title: "Error",
        message: 'Must have at least one item',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _productControllers.removeAt(index).dispose();
      _fromStorageControllers.removeAt(index).dispose();
      _toStorageControllers.removeAt(index).dispose();
      _qtyControllers.removeAt(index).dispose();
      _selectedProducts.removeAt(index);
      _selectedFromStorages.removeAt(index);
      _selectedToStorages.removeAt(index);
      _records.removeAt(index);
      for (final n in _rowFocusNodes.removeAt(index)) {
        n.dispose();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rowFocusNodes.isNotEmpty) {
        final focusIndex = index > 0 ? index - 1 : 0;
        if (_rowFocusNodes[focusIndex].isNotEmpty) {
          _rowFocusNodes[focusIndex][0].requestFocus();
        }
      }
    });
  }

  void _updateRecord(
      int index, {
        int? productId,
        int? fromStorage,
        int? toStorage,
        double? quantity,
        double? purchasePrice,
        double? landedPurPrice,
        int? qtyInBatch,
      }) {
    final record = _records[index];

    _records[index] = record.copyWith(
      stkProduct: productId ?? record.stkProduct,
      fromStorage: fromStorage ?? record.fromStorageId,
      toStorage: toStorage ?? record.toStorageId,
      stkQuantity: quantity ?? record.stkQuantity,
      stkPurPrice: purchasePrice?.toStringAsFixed(2) ?? record.stkPurPrice,
      stkLandedPurPrice:
      landedPurPrice?.toStringAsFixed(2) ?? record.stkLandedPurPrice,
      stkQtyInBatch: qtyInBatch ?? record.stkQtyInBatch,
    );

    setState(() {});
  }

  double get _totalQuantity {
    double total = 0.0;
    for (final record in _records) {
      total += record.quantity!;
    }
    return total;
  }

  void _addNewRowAndFocus() {
    final lastRecord = _records.isNotEmpty ? _records.last : null;

    if (lastRecord != null &&
        (lastRecord.stkProduct == null || lastRecord.stkProduct == 0)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted &&
              _rowFocusNodes.isNotEmpty &&
              _rowFocusNodes.last.isNotEmpty) {
            _rowFocusNodes.last[0].requestFocus();
          }
        });
      });
      return;
    }

    setState(() => _addEmptyItem());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted &&
            _rowFocusNodes.isNotEmpty &&
            _rowFocusNodes.last.isNotEmpty) {
          _rowFocusNodes.last[0].requestFocus();
        }
      });
    });
  }

  // ------------------------------------------------------------------
  // EDIT MODE — prefill rows from loaded shift
  // ------------------------------------------------------------------
  void _prefillFromShift(GoodShiftModel shift) {
    if (_prefilled) return;
    _prefilled = true;

    // Wipe any current rows
    for (final c in _productControllers) {
      c.dispose();
    }
    for (final c in _fromStorageControllers) {
      c.dispose();
    }
    for (final c in _toStorageControllers) {
      c.dispose();
    }
    for (final c in _qtyControllers) {
      c.dispose();
    }
    for (final nodes in _rowFocusNodes) {
      for (final n in nodes) {
        n.dispose();
      }
    }
    _productControllers.clear();
    _fromStorageControllers.clear();
    _toStorageControllers.clear();
    _qtyControllers.clear();
    _rowFocusNodes.clear();
    _records.clear();
    _selectedProducts.clear();
    _selectedFromStorages.clear();
    _selectedToStorages.clear();

    // The API returns one OUT row + one IN row per shift line.
    // We rebuild one editable row per OUT row, matching its IN counterpart.
    final outs = (shift.records ?? []).where((r) => r.isOutEntry).toList();
    final ins = (shift.records ?? []).where((r) => r.isInEntry).toList();

    for (final out in outs) {
      // Find the matching IN (same product, batch, qty)
      ShiftRecord? match;
      for (final r in ins) {
        if (r.stkProduct == out.stkProduct &&
            r.stkQtyInBatch == out.stkQtyInBatch &&
            r.stkQuantity == out.stkQuantity) {
          match = r;
          break;
        }
      }

      _productControllers.add(TextEditingController(text: out.proName ?? ''));
      _fromStorageControllers
          .add(TextEditingController(text: out.storageName ?? ''));
      _toStorageControllers
          .add(TextEditingController(text: match?.storageName ?? ''));
      _qtyControllers.add(
          TextEditingController(text: (out.stkQuantity ?? 0).toString()));

      _selectedProducts.add(null);
      _selectedFromStorages.add(null);
      _selectedToStorages.add(null);

      _records.add(ShiftRecord(
        stkProduct: out.stkProduct,
        fromStorageId: out.storageId,
        toStorageId: match?.storageId,
        stkQuantity: out.stkQuantity,
        stkPurPrice: out.stkPurPrice ?? '0.00',
        stkLandedPurPrice: out.stkLandedPurPrice ?? '0.00',
        stkQtyInBatch: out.stkQtyInBatch,
      ));

      _rowFocusNodes.add([FocusNode(), FocusNode(), FocusNode()]);
    }

    // Safety: if the order somehow had no records, show one empty row
    if (_records.isEmpty) {
      _addEmptyItem();
    }

    setState(() {
      _isLoadingDetail = false;
    });

    // Focus the first product field after prefill
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _focusFirstProductField();
      });
    });
  }

  // ------------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return BlocListener<GoodsShiftBloc, GoodsShiftState>(
      listener: _onBlocStateChange,
      child: ZFormDialog(
        title: widget.isEdit ? '${tr.edit} ${tr.goodShift}' : tr.goodShift,
        icon: widget.isEdit ? Icons.edit : Icons.swap_horiz,
        isLoading: _isSaving || _isLoadingDetail,
        isButtonEnabled: !_isSaving && !_isLoadingDetail,
        errorMessage: _hasError ? _errorMessage : null,
        width: MediaQuery.sizeOf(context).width * .85,
        height: MediaQuery.sizeOf(context).height * .85,
        padding: const EdgeInsets.all(8),
        actionLabel: Text(widget.isEdit ? tr.update : tr.create),
        onAction: _createGoodsShift,
        child: _isLoadingDetail
            ? const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        )
            : SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height * .70,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LEFT: Summary
              SizedBox(
                width: 260,
                child: ZCover(
                  radius: 10,
                  padding: EdgeInsets.all(15),
                  borderColor: color.primary.withValues(alpha: .3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr.details,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Icon(Icons.move_down_rounded,
                              size: 20, color: color.primary),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Divider(
                          thickness: 1.2,
                          color: color.outline
                              .withValues(alpha: .5)),
                      const SizedBox(height: 6),
                      _buildSummaryRow(
                        label: tr.totalItems,
                        value: _records.length.toDouble(),
                        isAmount: false,
                      ),
                      _buildSummaryRow(
                        label: tr.totalQty,
                        value: _totalQuantity,
                        isAmount: false,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: color.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.isEdit
                                    ? 'Shift will remain Pending'
                                    : 'Shift will be saved as Pending',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: color.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // RIGHT: Items
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildItemsHeader(tr),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ...List.generate(_records.length, (index) {
                                final isLastRow = index == _records.length - 1;
                                return _buildItemRow(index, isLastRow, tr);
                              }),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    ZOutlineButton(
                                      width: 120,
                                      icon: Icons.add,
                                      label: Text(tr.addItem),
                                      onPressed: _isSaving
                                          ? null
                                          : _addNewRowAndFocus,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // BLOC LISTENER — single source of truth for state transitions
  // ------------------------------------------------------------------
  void _onBlocStateChange(BuildContext context, GoodsShiftState state) {
    // 1) EDIT — prefill once
    if (state is GoodsShiftDetailLoadedState && widget.isEdit) {
      _prefillFromShift(state.shift);
      return;
    }

    // 2) Error
    if (state is GoodsShiftErrorState) {
      ToastManager.show(
        context: context,
        title: "Error",
        message: state.error,
        type: ToastType.error,
      );
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isLoadingDetail = false;
          _hasError = true;
          _errorMessage = state.error;
        });
      }
      return;
    }

    // 3) Success (create or update)
    if (state is GoodsShiftSavedState || state is GoodsShiftUpdatedState) {
      final msg = state is GoodsShiftSavedState
          ? state.message
          : (state as GoodsShiftUpdatedState).message;
      ToastManager.show(
        context: context,
        title: "Success",
        message: msg,
        type: ToastType.success,
      );
      if (mounted) Navigator.pop(context, true);
      return;
    }

    // 4) Busy
    if (state is GoodsShiftSavingState || state is GoodsShiftUpdatingState) {
      if (!mounted) return;
      setState(() {
        _isSaving = true;
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  // ------------------------------------------------------------------
  // HEADER / ROWS / SUMMARY
  // ------------------------------------------------------------------
  Widget _buildItemsHeader(AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;
    final title = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(color: color.surface,fontSize: 15,letterSpacing: 0.6);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.primary,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 36,
              child: Text('#', style: title, textAlign: TextAlign.center)),
          Expanded(
              flex: 5,
              child: Text(tr.products,
                  style: title, textAlign: TextAlign.start)),
          Expanded(
              flex: 2,
              child: Text(tr.fromStorage,
                  style: title, textAlign: TextAlign.start)),
          Expanded(
              flex: 2,
              child: Text(tr.toStorage,
                  style: title, textAlign: TextAlign.start)),
          Expanded(
              flex: 2,
              child:
              Text(tr.qty, style: title, textAlign: TextAlign.start)),
          SizedBox(
              width: 50,
              child: Text(tr.actions,
                  style: title, textAlign: TextAlign.center)),
        ].map((child) => DefaultTextStyle(
          style: TextStyle(color: color.surface),
          child: child,
        )).toList(),
      ),
    );
  }

  Widget _buildItemRow(int index, bool isLastRow, AppLocalizations tr) {
    final color = Theme.of(context).colorScheme;
    final nodes = _rowFocusNodes[index];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border:
        Border(bottom: BorderSide(color: color.outline.withValues(alpha: .2))),
        color: index.isOdd
            ? color.outline.withValues(alpha: .06)
            : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              (index + 1).toString(),
              textAlign: TextAlign.center,
            ),
          ),

          // Product
          Expanded(
            flex: 5,
            child: ProductSearchField<ProductsStockModel, ProductsBloc,
                ProductsState>(
              controller: _productControllers[index],
              hintText: tr.products,
              focusNode: nodes[0],
              bloc: context.read<ProductsBloc>(),
              searchFunction: (bloc, query) =>
                  bloc.add(LoadProductsStockEvent(input: query)),
              fetchAllFunction: (bloc) =>
                  bloc.add(LoadProductsStockEvent()),
              stateToItems: (state) {
                if (state is ProductsStockLoadedState) return state.products;
                return [];
              },
              stateToLoading: (state) => state is ProductsLoadingState,
              itemToString: (product) => product.proName ?? '',
              getProductId: (product) => product.proId?.toString(),
              getProductName: (product) => product.proName,
              getProductCode: (product) => product.proCode,
              getStorageId: (product) => product.stkStorage,
              getStorageName: (product) => product.stgName,
              getAvailable: (product) => product.available,
              getBatch: (product) => product.stkQtyInBatch ?? 0,
              getLandedPrice: (product) => product.recentLandedPurPrice,
              getProductUnit: (product) => product.proUnit,
              getAveragePrice: (product) => product.averagePrice,
              getRecentPrice: (product) => product.recentPurPrice,
              getSellPrice: (product) => product.sellPrice,
              onProductSelected: (product) {
                if (product == null) return;

                final purchasePrice = double.tryParse(
                  product.averagePrice?.replaceAll(',', '') ?? "0.0",
                ) ??
                    0.0;

                final landedPurPrice = double.tryParse(
                  product.recentLandedPurPrice?.replaceAll(',', '') ??
                      "0.0",
                ) ??
                    0.0;

                final qtyInBatch = product.stkQtyInBatch ?? 0;

                _selectedProducts[index] = product;
                _fromStorageControllers[index].text =
                    product.stgName ?? '';

                _updateRecord(
                  index,
                  productId: product.proId,
                  fromStorage: product.stkStorage,
                  purchasePrice: purchasePrice,
                  landedPurPrice: landedPurPrice,
                  qtyInBatch: qtyInBatch,
                );

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (nodes.length > 2) nodes[2].requestFocus();
                });
              },
              onSubmit: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (nodes.length > 2) nodes[2].requestFocus();
                });
              },
              openOverlayOnFocus: true,
              showAllOnFocus: true,
              noResultsText: tr.noDataFound,
            ),
          ),

          // From Storage (read-only)
          Expanded(
            flex: 2,
            child: TextField(
              controller: _fromStorageControllers[index],
              readOnly: true,
              decoration: InputDecoration(
                hintText: tr.fromStorage,
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),

          // To Storage
          Expanded(
            flex: 2,
            child:
            GenericUnderlineTextfield<StorageModel, StorageBloc, StorageState>(
              controller: _toStorageControllers[index],
              hintText: tr.toStorage,
              focusNode: nodes[2],
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
                if (state is StorageLoadedState) return state.storage;
                return [];
              },
              onSelected: (storage) {
                _selectedToStorages[index] = storage;
                _updateRecord(index, toStorage: storage.stgId);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (nodes.length > 1) nodes[1].requestFocus();
                });
              },
              title: '',
              enabled: !_isSaving,
              onSubmitted: (e) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (nodes.length > 1) nodes[1].requestFocus();
                });
              },
            ),
          ),

          // Quantity
          Expanded(
            flex: 2,
            child: TextField(
              controller: _qtyControllers[index],
              focusNode: nodes[1],
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                hintText: tr.qty,
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                final qty = double.tryParse(value) ?? 0.0;
                _updateRecord(index, quantity: qty);
              },
              onSubmitted: (_) {
                if (isLastRow) {
                  final lastRecord = _records.last;
                  if (lastRecord.stkProduct != null &&
                      lastRecord.stkProduct! > 0) {
                    _addNewRowAndFocus();
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (nodes.isNotEmpty) nodes[0].requestFocus();
                    });
                  }
                } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_rowFocusNodes.length > index + 1 &&
                        _rowFocusNodes[index + 1].isNotEmpty) {
                      _rowFocusNodes[index + 1][0].requestFocus();
                    }
                  });
                }
              },
              enabled: !_isSaving,
            ),
          ),

          // Remove
          SizedBox(
            width: 50,
            child: IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: color.error),
              onPressed: _isSaving ? null : () => _removeItem(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required double value,
    bool isAmount = true,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            isAmount ? value.toAmount() : value.toAmount(decimal: 0),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // SUBMIT
  // ------------------------------------------------------------------
  void _createGoodsShift() {
    if (_userName == null) {
      ToastManager.show(
        context: context,
        title: "Error",
        message: 'User not authenticated',
        type: ToastType.error,
      );
      return;
    }

    // Validate all items
    for (var i = 0; i < _records.length; i++) {
      final record = _records[i];

      if (record.stkProduct == null || record.stkProduct == 0) {
        ToastManager.show(
          context: context,
          title: "Error",
          message: 'Please select a product for item ${i + 1}',
          type: ToastType.error,
        );
        return;
      }

      if (record.fromStorageId == null || record.fromStorageId == 0) {
        ToastManager.show(
          context: context,
          title: "Error",
          message: 'Please select from storage for item ${i + 1}',
          type: ToastType.error,
        );
        return;
      }

      if (record.toStorageId == null || record.toStorageId == 0) {
        ToastManager.show(
          context: context,
          title: "Error",
          message: 'Please select to storage for item ${i + 1}',
          type: ToastType.error,
        );
        return;
      }

      if (record.fromStorageId == record.toStorageId) {
        ToastManager.show(
          context: context,
          title: "Error",
          message: 'From and to storage cannot be same for item ${i + 1}',
          type: ToastType.error,
        );
        return;
      }

      final qty = record.quantity;
      if (qty! <= 0) {
        ToastManager.show(
          context: context,
          title: "Error",
          message: 'Please enter a valid quantity for item ${i + 1}',
          type: ToastType.error,
        );
        return;
      }
    }

    if (widget.isEdit) {
      context.read<GoodsShiftBloc>().add(UpdateGoodsShiftEvent(
        ordID: widget.ordId!,
        usrName: _userName!,
        records: _records,
      ));
    } else {
      context.read<GoodsShiftBloc>().add(AddGoodsShiftEvent(
        usrName: _userName!,
        records: _records,
      ));
    }
  }
}