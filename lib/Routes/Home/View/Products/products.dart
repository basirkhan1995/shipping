import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipping/Features/Widgets/shimmer.dart';
import '../../../../../../../../Features/Widgets/search_field.dart';
import '../../../../Features/Other/responsive_widget.dart';
import '../../../../Features/Widgets/extensions.dart';
import '../../../../Features/Widgets/toast.dart';
import '../../../../Features/Widgets/zbutton.dart';
import '../../../../l10n/app_localizations.dart';
import '../Settings/Visibility/bloc/settings_visible_bloc.dart';
import 'SingleProduct/single_product_bloc.dart';
import 'add_edit_product.dart';
import 'bloc/products_bloc.dart';
import 'model/product_model.dart';

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileProductsView(),
      tablet: _TabletProductsView(),
      desktop: _DesktopProductsView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  INTENTS for keyboard shortcuts
// ─────────────────────────────────────────────────────────────────
class _AddProductIntent extends Intent {
  const _AddProductIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

// Base class to share common functionality
class _BaseProductsView extends StatefulWidget {
  final bool isMobile;
  final bool isTablet;

  const _BaseProductsView({
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseProductsView> createState() => _BaseProductsViewState();
}

class _BaseProductsViewState extends State<_BaseProductsView> {
  final searchController = TextEditingController();
  final searchFocus = FocusNode();
  bool _isUploadingExcel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductsBloc>().add(LoadProductsEvent());
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  void onRefresh() {
    context.read<ProductsBloc>().add(LoadProductsEvent());
  }

  // ─────────────────────────────────────────────────────────────
  //  OPEN ADD PRODUCT DIALOG (single source of truth, used by
  //  header button AND the F1 / Ctrl+N shortcut)
  // ─────────────────────────────────────────────────────────────
  void _openAddProductDialog() {
    context.read<SingleProductBloc>().add(ClearSingleProductEvent());
    showDialog(
      context: context,
      builder: (context) => const AddEditProductView(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  EXCEL UPLOAD
  // ─────────────────────────────────────────────────────────────
  Future<void> _pickAndUploadExcel() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result.isEmpty) return;

    final path = result.single.path;
    if (path == null) return;

    final file = File(path);

    if (!mounted) return;

    setState(() => _isUploadingExcel = true);
    context.read<ProductsBloc>().add(AddProductsFromExcelEvent(file));
  }

  void _showExcelSummary(ProductsExcelUploadedState state) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.of(context)!;
    final hasSkipped = state.skipped.isNotEmpty;
    final hasErrors = state.errors.isNotEmpty;
    final isPerfect = !hasSkipped && !hasErrors && state.inserted > 0;

    final accentColor = isPerfect ? Colors.green.shade600 : color.primary;
    final statusIcon =
    isPerfect ? Icons.check_circle_outline : Icons.info_outline;
    final statusText = isPerfect
        ? "xlSuccess"
        : hasErrors
        ? "xlError2"
        : "xlError";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        titlePadding: EdgeInsets.zero,
        title: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: .15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: accentColor, size: 30),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr.importComplete,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              statusText,
              style: textTheme.bodySmall?.copyWith(
                color: color.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _statItem(
                    value: state.inserted,
                    label: tr.inserted,
                    color: Colors.green.shade600,
                  ),
                  _divider(color),
                  _statItem(
                    value: state.skipped.length,
                    label: tr.skipped,
                    color: Colors.orange.shade700,
                  ),
                  _divider(color),
                  _statItem(
                    value: state.errors.length,
                    label: tr.errored,
                    color: color.error,
                  ),
                ],
              ),
            ),
            if (hasSkipped || hasErrors) ...[
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.errorContainer.withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.outline.withValues(alpha: .08),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasSkipped) ...[
                        _sectionHeader(
                          icon: Icons.skip_next_rounded,
                          title: tr.skipped,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(height: 6),
                        ...state.skipped.map(
                              (s) => _detailRow(
                            "Row ${s['row']}",
                            s['reason'].toString(),
                            textTheme,
                            color,
                          ),
                        ),
                      ],
                      if (hasSkipped && hasErrors) const SizedBox(height: 12),
                      if (hasErrors) ...[
                        _sectionHeader(
                          icon: Icons.error_outline_rounded,
                          title: tr.errored,
                          color: color.error,
                        ),
                        const SizedBox(height: 6),
                        ...state.errors.map(
                              (e) => _detailRow(
                            "Row ${e['row']}",
                            e['error'].toString(),
                            textTheme,
                            color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ZOutlineButton(
              isActive: true,
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context.read<ProductsBloc>().add(const LoadProductsEvent());
              },
              label: Text(
                tr.done,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required int value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme color) {
    return Container(
      width: 1,
      height: 32,
      color: color.outline.withValues(alpha: .15),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
      String rowLabel,
      String message,
      TextTheme textTheme,
      ColorScheme color,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: RichText(
        text: TextSpan(
          style: textTheme.bodySmall?.copyWith(
            color: color.onSurface,
            fontSize: 12,
          ),
          children: [
            TextSpan(
              text: "$rowLabel: ",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: message),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader(
      AppLocalizations tr, TextTheme textTheme, ColorScheme color) {
    if (widget.isMobile) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr.products.toUpperCase(),
                style: textTheme.headlineSmall
                    ?.copyWith(letterSpacing: 0.6)),
            Text(
              tr.manageProducts,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.6),
            ),
            const SizedBox(height: 16),
            ReusableSearchBar(
              controller: searchController,
              onChanged: (e) {
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ZOutlineButton(
                    icon: Icons.refresh,
                    onPressed: onRefresh,
                    label: Text(tr.refresh),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: ZOutlineButton(
                    icon: _isUploadingExcel
                        ? Icons.hourglass_top
                        : Icons.file_upload_outlined,
                    onPressed:
                    _isUploadingExcel ? null : _pickAndUploadExcel,
                    label: Text(tr.excelTitle),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: ZOutlineButton(
                    isActive: true,
                    icon: Icons.add,
                    onPressed: _openAddProductDialog,
                    label: Text(tr.newProduct),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (widget.isTablet) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.products.toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.3),
                      ),
                      Text(
                        tr.manageProducts,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: color.outline),
                      ),
                    ],
                  ),
                ),
                ZOutlineButton(
                  width: 100,
                  icon: Icons.refresh,
                  onPressed: onRefresh,
                  label: Text(tr.refresh),
                ),
                const SizedBox(width: 5),
                ZOutlineButton(
                  width: 100,
                  icon: _isUploadingExcel
                      ? Icons.hourglass_top
                      : Icons.file_upload_outlined,
                  onPressed: _isUploadingExcel ? null : _pickAndUploadExcel,
                  label: Text(tr.excelTitle.toUpperCase()),
                ),
                const SizedBox(width: 5),
                ZOutlineButton(
                  isActive: true,
                  icon: Icons.add,
                  onPressed: _openAddProductDialog,
                  label: Text(tr.newProduct),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReusableSearchBar(
              controller: searchController,
              onChanged: (e) {
                setState(() {});
              },
            ),
          ],
        ),
      );
    } else {
      // Desktop header
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.surface,
        ),
        child: Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.products,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                        fontWeight: FontWeight.w600, letterSpacing: 0.6),
                  ),
                  Text(
                    tr.manageProducts,
                    style: textTheme.bodyMedium?.copyWith(
                        color: color.outline,
                        letterSpacing: 0.6,
                        fontSize: 11),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ReusableSearchBar(
                controller: searchController,
                onChanged: (e) {
                  setState(() {});
                },
              ),
            ),
            ZOutlineButton(
              height: 44,
              icon: Icons.refresh,
              onPressed: onRefresh,
              label: Text(tr.refresh),
            ),
            ZOutlineButton(
              height: 44,
              icon: _isUploadingExcel
                  ? Icons.hourglass_top
                  : Icons.file_upload_outlined,
              backgroundHover: Colors.green,
              onPressed: _isUploadingExcel ? null : _pickAndUploadExcel,
              label: Text(tr.excelTitle.toUpperCase()),
            ),
            // Add button — shortcut hint shown next to the label
            ZOutlineButton(
              height: 44,
              isActive: true,
              icon: Icons.add,
              onPressed: _openAddProductDialog,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr.newProduct),
                  const SizedBox(width: 6),
                  _kbdHint("F1"),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // Small keyboard-hint chip ("F1") used next to the Add button label.
  Widget _kbdHint(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(
        color: Colors.black.withValues(alpha: .1),
      ),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: .5,
      ),
    ),
  );

  // ─────────────────────────────────────────────────────────────
  //  TABLE HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildTableHeader(
      AppLocalizations tr, TextStyle? titleStyle, ColorScheme color) {
    final visibility = context.read<SettingsVisibleBloc>().state;
    if (widget.isMobile) {
      return const SizedBox.shrink();
    } else if (widget.isTablet) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.primary.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                tr.productName,
                style: titleStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: Text(
                tr.status,
                style: titleStyle?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: color.outline.withValues(alpha: .2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                '#',
                style: titleStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.outline,
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Text(
                tr.productCode,
                style: titleStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.outline,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                tr.productName,
                style: titleStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.outline,
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                tr.category,
                textAlign: TextAlign.center,
                style: titleStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.outline,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                tr.available,
                style: titleStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (visibility.isWholeSale)
              SizedBox(
                width: 100,
                child: Text(
                  tr.totalItems,
                  style: titleStyle?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: 80,
              child: Text(
                tr.unit,
                style: titleStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                tr.status,
                style: titleStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  CLEAN STATUS WIDGET — 12×12 colored dot + label
  // ─────────────────────────────────────────────────────────────
  Widget _buildStatus(int status, AppLocalizations tr) {
    final isActive = status == 1;
    final Color dotColor =
    isActive ? Colors.green.shade600 : Colors.grey.shade400;
    final Color textColor =
    isActive ? Colors.green.shade800 : Colors.grey.shade600;
    final String label = isActive ? tr.active : tr.inactive;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Outer halo — soft glow ring that reads as "on/off" at a glance
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor.withValues(alpha: isActive ? .18 : .08),
          ),
          child: Center(
            // Inner solid dot
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  PRODUCT ITEM
  // ─────────────────────────────────────────────────────────────
  Widget _buildProductItem(ProductsModel product, int index,
      TextTheme textTheme, ColorScheme color, AppLocalizations tr) {
    final visibility = context.read<SettingsVisibleBloc>().state;
    if (widget.isMobile) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) =>
                  AddEditProductView(proId: product.proId),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.proName ?? '',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // ✅ New clean status
                    _buildStatus(product.proStatus ?? 1, tr),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.code, size: 14, color: color.outline),
                    const SizedBox(width: 4),
                    Text(
                      '${tr.productCode}:',
                      style:
                      textTheme.bodySmall?.copyWith(color: color.outline),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.proCode ?? '',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.category, size: 14, color: color.outline),
                    const SizedBox(width: 4),
                    Text(
                      '${tr.category}:',
                      style:
                      textTheme.bodySmall?.copyWith(color: color.outline),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        product.pcName ?? '',
                        style: textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              tr.qty,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: color.outline),
                            ),
                            Text(
                              product.totalQty?.toAmount(decimal: 0) ?? '0',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              tr.totalItems,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: color.outline),
                            ),
                            Text(
                              product.totalItems?.toAmount(decimal: 0) ?? '0',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: color.secondary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              tr.unit,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: color.outline),
                            ),
                            Text(
                              product.proUnit ?? '',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (product.proDetails != null &&
                    product.proDetails!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest
                          .withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.outline.withValues(alpha: .1),
                      ),
                    ),
                    child: Text(
                      product.proDetails!,
                      style: textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } else if (widget.isTablet) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) =>
                  AddEditProductView(proId: product.proId),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: index.isEven
                  ? color.surfaceContainerHighest.withValues(alpha: .3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.proName ?? '',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.proCode ?? '',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Center(
                    // ✅ New clean status
                    child: _buildStatus(product.proStatus ?? 1, tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) =>
                  AddEditProductView(proId: product.proId),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: index.isOdd
                  ? color.surfaceContainerHighest.withValues(alpha: .3)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    product.proId.toString(),
                    style: textTheme.bodySmall?.copyWith(
                      color: color.outline,
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Text(
                    product.proCode.toString(),
                    style: textTheme.bodySmall?.copyWith(
                      color: color.outline,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    product.proName ?? '',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    product.pcName ?? '',
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    product.totalQty?.toAmount(decimal: 0) ?? '0',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: product.totalItems.toString() == "0"
                          ? color.error
                          : color.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (visibility.isWholeSale)
                  SizedBox(
                    width: 100,
                    child: Text(
                      product.totalItems?.toAmount(decimal: 0) ?? '0',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: product.totalItems.toString() == "0"
                            ? color.error
                            : Colors.green.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: 80,
                  child: Text(
                    product.proUnit ?? '',
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Center(
                    // ✅ New clean status
                    child: _buildStatus(product.proStatus ?? 1, tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD — wrapped in Shortcuts / Actions so F1 & Ctrl+N open
  //  the Add Product dialog from anywhere on this page.
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;
    TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.surface,
    );

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // F1 — primary shortcut
        const SingleActivator(LogicalKeyboardKey.f1):
        const _AddProductIntent(),
        // Ctrl+N / Cmd+N — standard "new" fallback (F1 is
        // reserved by some browsers/OSes for Help)
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
        const _AddProductIntent(),
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
        const _AddProductIntent(),
        // "/" → focus the search field (GitHub/Linear style)
        const SingleActivator(LogicalKeyboardKey.slash):
        const _FocusSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _AddProductIntent: CallbackAction<_AddProductIntent>(
            onInvoke: (_) {
              _openAddProductDialog();
              return null;
            },
          ),
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) {
              searchFocus.requestFocus();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: color.surface,
            body: Column(
              children: [
                _buildHeader(tr, textTheme, color),

                if (!widget.isMobile) ...[
                  const SizedBox(height: 4),
                  _buildTableHeader(
                      tr, titleStyle?.copyWith(letterSpacing: 1), color),
                ],

                Expanded(
                  child: BlocConsumer<ProductsBloc, ProductsState>(
                    listener: (context, state) {
                      if (state is ProductsSuccessState) {
                        ToastManager.show(
                          context: context,
                          title: tr.successTitle,
                          message: tr.successMsg,
                          type: ToastType.success,
                          durationInSeconds: 3,
                          position: ToastPosition.top,
                        );
                      }

                      if (state is ProductsExcelUploadedState) {
                        if (_isUploadingExcel) {
                          setState(() => _isUploadingExcel = false);
                        }
                        _showExcelSummary(state);
                      }

                      if (state is ProductsErrorState) {
                        if (_isUploadingExcel) {
                          setState(() => _isUploadingExcel = false);
                        }
                        ToastManager.show(
                          context: context,
                          title: tr.errorTitle,
                          message: state.message,
                          type: ToastType.error,
                          durationInSeconds: 4,
                          position: ToastPosition.top,
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is ProductsLoadingState) {
                        return Center(
                          child: UniversalShimmer.dataList(
                              numberOfColumns: 6, itemCount: 10),
                        );
                      }
                      if (state is ProductsErrorState) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 80,
                                color: color.error.withValues(alpha: .5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                style: textTheme.titleMedium?.copyWith(
                                  color: color.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ZOutlineButton(
                                icon: Icons.refresh,
                                onPressed: onRefresh,
                                label: Text(tr.refresh),
                              ),
                            ],
                          ),
                        );
                      }
                      if (state is ProductsLoadedState) {
                        final query =
                        searchController.text.toLowerCase().trim();

                        final filteredList = state.products.where((item) {
                          final code = item.proCode?.toLowerCase() ?? '';
                          final productName =
                              item.proName?.toString().toLowerCase() ?? '';
                          final details =
                              item.proDetails?.toLowerCase() ?? '';
                          final madeIn =
                              item.proMadeIn?.toLowerCase() ?? '';
                          final category =
                              item.pcName?.toLowerCase() ?? '';

                          return code.contains(query) ||
                              productName.contains(query) ||
                              details.contains(query) ||
                              madeIn.contains(query) ||
                              category.contains(query);
                        }).toList();

                        if (filteredList.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 80,
                                  color:
                                  color.outline.withValues(alpha: .5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  tr.noDataFound,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: color.outline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  searchController.text.isNotEmpty
                                      ? "Try different search"
                                      : "Try refreshing",
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.outline,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ZOutlineButton(
                                  icon: Icons.refresh,
                                  onPressed: onRefresh,
                                  label: Text(tr.refresh),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: widget.isMobile
                              ? const EdgeInsets.symmetric(vertical: 8)
                              : const EdgeInsets.symmetric(vertical: 4),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final product = filteredList[index];
                            return _buildProductItem(
                                product, index, textTheme, color, tr);
                          },
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileProductsView extends StatelessWidget {
  const _MobileProductsView();

  @override
  Widget build(BuildContext context) {
    return const _BaseProductsView(
      isMobile: true,
      isTablet: false,
    );
  }
}

class _TabletProductsView extends StatelessWidget {
  const _TabletProductsView();

  @override
  Widget build(BuildContext context) {
    return const _BaseProductsView(
      isMobile: false,
      isTablet: true,
    );
  }
}

class _DesktopProductsView extends StatelessWidget {
  const _DesktopProductsView();

  @override
  Widget build(BuildContext context) {
    return const _BaseProductsView(
      isMobile: false,
      isTablet: false,
    );
  }
}