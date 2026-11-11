import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:shipping/Features/Widgets/extensions.dart';
import '../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../Features/PrintSettings/num_to_word.dart';
import '../../../../../Features/PrintSettings/print_services.dart';
import '../../../../../Features/PrintSettings/report_model.dart';
import '../../Stakeholder/model/stk_model.dart';


/// ============================================================
///  ARTEL GREEN BRAND PALETTE
/// ============================================================
class _InvoiceColors {
  static const pw.PdfColor primary      = pw.PdfColor.fromInt(0xFF005994); // lightScheme.primary
  static const pw.PdfColor primaryDark  = pw.PdfColor.fromInt(0xFF001E3A); // lightScheme.onPrimaryContainer
  static const pw.PdfColor primaryLight = pw.PdfColor.fromInt(0xFFE3F2FF); // lightScheme.primaryContainer
  static const pw.PdfColor stripeLight  = pw.PdfColor.fromInt(0xFFF7F8FC); // lightScheme.surfaceContainerLow
  static const pw.PdfColor border       = pw.PdfColor.fromInt(0xFFC3C7D0); // lightScheme.outlineVariant
  static const pw.PdfColor divider      = pw.PdfColor.fromInt(0xFFC3C7D0); // lightScheme.outlineVariant
  static const pw.PdfColor accentText   = pw.PdfColor.fromInt(0xFF003258); // darker accent, derived from primary
  static const pw.PdfColor negative     = pw.PdfColor.fromInt(0xFFC62828); // lightScheme.error
  static const pw.PdfColor warning      = pw.PdfColor.fromInt(0xFFEF6C00); // keep amber
}

abstract class InvoiceItem {
  String get productName;
  double get quantity;
  String get unit;
  int get batch;
  double get unitPrice;
  double get total;
  String get storageName;
  double? get localAmount;
  String? get localCurrency;
  double? get exchangeRate;
}

class SaleInvoiceItemForPrint implements InvoiceItem {
  @override
  final String productName;
  @override
  final double quantity;
  @override
  final String unit;
  @override
  final int batch;
  @override
  final double unitPrice;
  @override
  final double total;
  @override
  final String storageName;
  final double? purchasePrice;
  final double? profit;
  @override
  final double? localAmount;
  @override
  final String? localCurrency;
  @override
  final double? exchangeRate;

  SaleInvoiceItemForPrint({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.batch,
    required this.unitPrice,
    required this.total,
    required this.storageName,
    this.purchasePrice,
    this.profit,
    this.localAmount,
    this.localCurrency,
    this.exchangeRate,
  });
}

class PurchaseInvoiceItemForPrint implements InvoiceItem {
  @override
  final String productName;
  @override
  final double quantity;
  @override
  final String unit;
  @override
  final int batch;
  @override
  final double unitPrice;
  @override
  final double total;
  @override
  final String storageName;
  @override
  final double? localAmount;
  @override
  final String? localCurrency;
  @override
  final double? exchangeRate;

  PurchaseInvoiceItemForPrint({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.batch,
    required this.unitPrice,
    required this.total,
    required this.storageName,
    this.localAmount,
    this.localCurrency,
    this.exchangeRate,
  });
}

class InvoicePrintService extends PrintServices {

  bool _isRollFormat(pw.PdfPageFormat format) {
    return format.width == pw.PdfPageFormat.roll80.width;
  }

  /// ============================================================
  ///  WATERMARK
  /// ============================================================
  pw.Widget _buildWatermark({
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    double opacity = 0.15,
    double widthFactor = 0.9,
    double heightFactor = 0.9,
    double angle = 0,
    pw.BoxFit fit = pw.BoxFit.contain,
    double topOffset = 0,
    double leftOffset = 0,
  }) {
    final logo = company.comLogo;
    if (logo == null || logo.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final double targetWidth = pageFormat.availableWidth * widthFactor;
    final double targetHeight = pageFormat.availableHeight * heightFactor;

    pw.Widget image = pw.Image(
      pw.MemoryImage(logo),
      fit: fit,
    );

    if (angle != 0) {
      image = pw.Transform.rotate(angle: angle, child: image);
    }

    return pw.Center(
      child: pw.Transform.translate(
        offset: pw.PdfPoint(leftOffset, topOffset),
        child: pw.Opacity(
          opacity: opacity,
          child: pw.SizedBox(
            width: targetWidth,
            height: targetHeight,
            child: image,
          ),
        ),
      ),
    );
  }

  /// ============================================================
  ///  SALE INVOICE — TERMS & CONDITIONS MESSAGE (Persian only)
  /// ============================================================
  pw.Widget _saleTermsMessage({required String language, ReportModel? company}) {
    final custom = company?.customTermsAndConditions?.trim();
    final hasCustom = custom != null && custom.isNotEmpty;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: tr(text: "termsAndConditionTitle", tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _InvoiceColors.primaryDark,
                ),
                if (hasCustom)
                  zText(text: custom, fontSize: 8)
                else ...[
                  zText(text: tr(text: "termsAndCondition1", tr: language), fontSize: 8),
                  pw.SizedBox(height: 2),
                  zText(text: tr(text: "termsAndCondition2", tr: language), fontSize: 8),
                  pw.SizedBox(height: 2),
                  zText(text: tr(text: "termsAndCondition3", tr: language), fontSize: 8),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Container(
            width: 2,
            color: _InvoiceColors.primary,
          ),
        ],
      ),
    );
  }

  Future<pw.Document> _generateRoll80Invoice({
    required String invoiceType,
    required String invoiceNumber,
    required String? reference,
    required DateTime? invoiceDate,
    required String customerSupplierName,
    required List<InvoiceItem> items,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required StkAccountModel? account,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    required bool isSale,
    String? currency,
    String? remark,
    double? totalLocalAmount,
    String? localCurrency,
    double? exchangeRate,
    double? subtotal,
    double? totalItemDiscount,
    double? generalDiscount,
    double? extraCharges,
  }) async {
    final document = pw.Document();

    final bool hasCompanyLogo = company.comLogo != null && company.comLogo is Uint8List && company.comLogo!.isNotEmpty;

    pw.ImageProvider? logoImage;
    if (hasCompanyLogo) {
      logoImage = pw.MemoryImage(company.comLogo ?? Uint8List(0));
    }

    final needsConversion = localCurrency != null &&
        currency != null &&
        currency != localCurrency &&
        exchangeRate != null;

    final safeLocalCurrency = localCurrency ?? '';
    final safeExchangeRate = exchangeRate ?? 1.0;
    final safeBaseCurrency = currency ?? '';

    final double effectiveSubtotal = subtotal ??
        items.fold(
          0.0,
              (sum, item) => sum + ((item.quantity * item.batch) * item.unitPrice),
        );

    final double itemDiscount = totalItemDiscount ?? 0.0;
    final double generalDisc = generalDiscount ?? 0.0;
    final double totalDiscount = itemDiscount + generalDisc;

    final double charges = extraCharges ?? 0.0;

    final double finalGrandTotal =
        effectiveSubtotal - totalDiscount + charges;

    final double localSubtotal = needsConversion
        ? effectiveSubtotal * safeExchangeRate
        : effectiveSubtotal;
    final double localCharges =
    needsConversion ? charges * safeExchangeRate : charges;
    final double localFinalGrandTotal = needsConversion
        ? (totalLocalAmount ?? finalGrandTotal * safeExchangeRate)
        : finalGrandTotal;
    final double localCashPayment =
    needsConversion ? cashPayment * safeExchangeRate : cashPayment;
    final double localCreditAmount =
    needsConversion ? creditAmount * safeExchangeRate : creditAmount;

    final String displayCurrency =
    needsConversion ? safeLocalCurrency : safeBaseCurrency;

    final double totalQty = items.fold(
      0.0,
          (sum, item) => sum + item.quantity,
    );

    String accCcy;
    if (needsConversion && safeLocalCurrency.isNotEmpty) {
      accCcy = safeLocalCurrency;
    } else if (account?.accCurrency != null &&
        account!.accCurrency!.isNotEmpty) {
      accCcy = account.accCurrency!;
    } else {
      accCcy = safeBaseCurrency;
    }

    final double accountBalance = account != null
        ? double.tryParse(account.accBalance.toAmount()) ?? 0.0
        : 0.0;

    final lang = NumberToWords.getLanguageFromLocale(Locale(language));
    final amountForWords = needsConversion
        ? (totalLocalAmount ?? finalGrandTotal * safeExchangeRate)
        : finalGrandTotal;
    final parsedAmount = int.tryParse(
        double.tryParse(amountForWords.toString())?.toStringAsFixed(0) ??
            "0") ??
        0;
    final amountInWords = NumberToWords.convert(parsedAmount, lang);

    document.addPage(
      pw.Page(
        pageFormat: const pw.PdfPageFormat(
          80 * pw.PdfPageFormat.mm,
          double.infinity,
          marginLeft: 6,
          marginRight: 6,
          marginTop: 8,
          marginBottom: 8,
        ),
        textDirection: documentLanguage(language: language),
        build: (context) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: _buildWatermark(
                  company: company,
                  pageFormat: pageFormat,
                  opacity: 0.15,
                  widthFactor: 0.9,
                  heightFactor: 0.9,
                  angle: -0.35,
                  fit: pw.BoxFit.contain,
                  topOffset: 60,
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 4, horizontal: 3),
                    decoration: pw.BoxDecoration(
                      color: _InvoiceColors.primaryLight,
                      border: pw.Border(
                        bottom: pw.BorderSide(
                            color: _InvoiceColors.primary, width: 1.2),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoImage != null)
                          pw.Image(logoImage, width: 60, height: 60),
                        pw.SizedBox(height: 3),
                        zText(
                          text: company.comName ?? "",
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          textAlign: pw.TextAlign.center,
                          color: _InvoiceColors.primaryDark,
                        ),
                        if ((company.compPhone ?? '').isNotEmpty)
                          zText(
                            text: company.compPhone ?? '',
                            fontSize: 8,
                            textAlign: pw.TextAlign.center,
                            color: _InvoiceColors.accentText,
                          ),
                        if ((company.comAddress ?? '').isNotEmpty)
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              zText(
                                text: company.comAddress ?? '',
                                fontSize: 7,
                                textAlign: pw.TextAlign.center,
                                color: _InvoiceColors.accentText,
                              ),
                              if ((company.partyCity ?? '').isNotEmpty) ...[
                                pw.SizedBox(width: 1),
                                zText(
                                  text: company.partyCity ?? '',
                                  fontSize: 7,
                                  textAlign: pw.TextAlign.center,
                                  color: _InvoiceColors.accentText,
                                ),
                              ]
                            ],
                          ),
                      ],
                    ),
                  ),
                  _rollSummaryRow(
                    label: tr(text: 'invoiceNumber', tr: language),
                    value: invoiceNumber,
                    language: language,
                  ),
                  _rollSummaryRow(
                    label: tr(
                      text: isSale ? 'customer' : 'supplier',
                      tr: language,
                    ),
                    value: customerSupplierName,
                    language: language,
                  ),
                  _rollSummaryRow(
                    label: tr(text: 'date', tr: language),
                    value: invoiceDate?.shamsiDateFormatted ?? '',
                    language: language,
                  ),
                  if ((reference ?? '').isNotEmpty)
                    _rollSummaryRow(
                      label: tr(text: 'reference', tr: language),
                      value: reference ?? '',
                      language: language,
                    ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2, horizontal: 1),
                    decoration: pw.BoxDecoration(
                      color: _InvoiceColors.primaryLight,
                      border: pw.Border(
                        top: pw.BorderSide(
                            color: _InvoiceColors.primary, width: 0.8),
                        bottom: pw.BorderSide(
                            color: _InvoiceColors.primary, width: 0.8),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 14,
                          child: zText(
                            text: '#',
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                            textAlign: pw.TextAlign.center,
                            color: _InvoiceColors.primaryDark,
                          ),
                        ),
                        pw.SizedBox(width: 2),
                        pw.Expanded(
                          flex: 5,
                          child: zText(
                            text: tr(text: 'items', tr: language),
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            textAlign: pw.TextAlign.start,
                            color: _InvoiceColors.primaryDark,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: zText(
                            text: tr(text: 'quantity', tr: language),
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            textAlign: pw.TextAlign.center,
                            color: _InvoiceColors.primaryDark,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: zText(
                            text: tr(text: 'unitPrice', tr: language),
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            textAlign: pw.TextAlign.end,
                            color: _InvoiceColors.primaryDark,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: zText(
                            text: tr(text: 'total', tr: language),
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            textAlign: pw.TextAlign.end,
                            color: _InvoiceColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    final itemUnitPrice = needsConversion
                        ? (item.unitPrice * safeExchangeRate)
                        : item.unitPrice;
                    final itemTotal = needsConversion
                        ? (item.total * safeExchangeRate)
                        : item.total;

                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 2, horizontal: 1),
                      decoration: index.isOdd
                          ? pw.BoxDecoration(
                          color: _InvoiceColors.stripeLight)
                          : null,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 12,
                            child: zText(
                              text: "${index + 1}",
                              fontSize: 6,
                              textAlign: pw.TextAlign.center,
                              color: _InvoiceColors.accentText,
                            ),
                          ),
                          pw.SizedBox(width: 2),
                          pw.Expanded(
                            flex: 5,
                            child: zText(
                              textAlign: pw.TextAlign.start,
                              text: item.productName,
                              fontSize: 7,
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: zText(
                              text: item.quantity.toStringAsFixed(0),
                              fontSize: 7,
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: zText(
                              text: itemUnitPrice.toAmount(decimal: 2),
                              fontSize: 7,
                              textAlign: pw.TextAlign.end,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: zText(
                              text: itemTotal.toAmount(decimal: 2),
                              fontSize: 7,
                              textAlign: pw.TextAlign.end,
                              fontWeight: pw.FontWeight.bold,
                              color: _InvoiceColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                          color: _InvoiceColors.border, width: 0.6),
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                    child: pw.Column(
                      children: [
                        _rollSummaryRow(
                          label: tr(text: 'totalQty', tr: language),
                          value: totalQty.toStringAsFixed(0),
                          language: language,
                        ),
                        if (effectiveSubtotal != finalGrandTotal ||
                            itemDiscount > 0 ||
                            generalDisc > 0 ||
                            charges > 0)
                          _rollSummaryRow(
                            label: tr(text: 'subtotal', tr: language),
                            value:
                            "${needsConversion ? localSubtotal.toAmount(decimal: 2) : effectiveSubtotal.toAmount(decimal: 2)} $displayCurrency",
                            language: language,
                          ),
                        if (itemDiscount > 0)
                          _rollSummaryRow(
                            label: tr(text: 'itemDiscounts', tr: language),
                            value:
                            "- ${needsConversion ? (itemDiscount * safeExchangeRate).toAmount(decimal: 2) : itemDiscount.toAmount(decimal: 2)} $displayCurrency",
                            language: language,
                            color: _InvoiceColors.negative,
                          ),
                        if (generalDisc > 0)
                          _rollSummaryRow(
                            label: tr(text: 'generalDiscount', tr: language),
                            value:
                            "- ${needsConversion ? (generalDisc * safeExchangeRate).toAmount(decimal: 2) : generalDisc.toAmount(decimal: 2)} $displayCurrency",
                            language: language,
                            color: _InvoiceColors.negative,
                          ),
                        if (charges > 0)
                          _rollSummaryRow(
                            label: tr(text: 'extraCharges', tr: language),
                            value:
                            "+ ${needsConversion ? localCharges.toAmount(decimal: 2) : charges.toAmount(decimal: 2)} $displayCurrency",
                            language: language,
                            color: _InvoiceColors.warning,
                          ),
                        horizontalDivider(),
                        _rollSummaryRow(
                          label: tr(text: 'grandTotal', tr: language),
                          value:
                          "${localFinalGrandTotal.toAmount(decimal: 2)} $displayCurrency",
                          language: language,
                          isBold: true,
                          fontSize: 10,
                          color: _InvoiceColors.primaryDark,
                        ),
                        if (creditAmount > 0)
                          _rollSummaryRow(
                            label: tr(text: 'invoiceAmount', tr: language),
                            value: "${localCreditAmount.toAmount(decimal: 2)} $displayCurrency",
                            language: language,
                          ),
                        if (cashPayment > 0)
                          _rollSummaryRow(
                            label: tr(text: 'cashReceipt', tr: language),
                            value:
                            "${localCashPayment.toAmount(decimal: 2)} $displayCurrency",
                            language: language,
                          ),
                        if (account != null) ...[
                          _rollSummaryRow(
                            label: tr(text: 'previousBalance', tr: language),
                            value:
                            "${accountBalance.toAmount(decimal: 2)} $accCcy",
                            language: language,
                          ),
                          _rollSummaryRow(
                            label: tr(text: 'newBalance', tr: language),
                            value:
                            "${(isSale ? accountBalance - localCreditAmount : accountBalance + localCreditAmount).toAmount(decimal: 2)} $accCcy",
                            language: language,
                            isBold: true,
                            color: _InvoiceColors.primaryDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  if (amountInWords.isNotEmpty) ...[
                    zText(
                      text: amountInWords,
                      fontSize: 7,
                      color: pw.PdfColors.grey800,
                    ),
                    pw.SizedBox(height: 4),
                  ],
                  if ((remark ?? '').isNotEmpty) ...[
                    zText(
                      text: tr(text: 'note', tr: language),
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _InvoiceColors.primaryDark,
                    ),
                    pw.SizedBox(height: 2),
                    zText(text: remark ?? '', fontSize: 7),
                    pw.SizedBox(height: 5),
                  ],
                  pw.Center(
                    child: zText(
                      text: tr(text: 'thankYou', tr: language),
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _InvoiceColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return document;
  }

  /// ================= ROLL SUMMARY ROW =================
  pw.Widget _rollSummaryRow({
    required String label,
    required String value,
    required String language,
    bool isBold = false,
    double fontSize = 8,
    pw.PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: zText(
              text: label,
              fontSize: fontSize,
              fontWeight:
              isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              textAlign: pw.TextAlign.start,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: zText(
              text: value,
              fontSize: fontSize,
              fontWeight:
              isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              textAlign: pw.TextAlign.end,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CREATE INVOICE ====================
  Future<void> createInvoiceDocument({
    required String invoiceType,
    required String invoiceNumber,
    required String? reference,
    required DateTime? invoiceDate,
    required String customerSupplierName,
    required List<InvoiceItem> items,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required StkAccountModel? account,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    required bool isSale,
    String? remark,
    String? currency,
    double? totalLocalAmount,
    String? localCurrency,
    double? exchangeRate,
    double? subtotal,
    double? totalItemDiscount,
    double? generalDiscount,
    double? extraCharges,
  }) async {
    try {
      final document = await generateInvoiceDocument(
        invoiceType: invoiceType,
        invoiceNumber: invoiceNumber,
        reference: reference,
        remark: remark,
        invoiceDate: invoiceDate,
        customerSupplierName: customerSupplierName,
        items: items,
        grandTotal: grandTotal,
        cashPayment: cashPayment,
        creditAmount: creditAmount,
        account: account,
        language: language,
        orientation: orientation,
        company: company,
        pageFormat: pageFormat,
        currency: currency,
        isSale: isSale,
        totalLocalAmount: totalLocalAmount,
        localCurrency: localCurrency,
        exchangeRate: exchangeRate,
        subtotal: subtotal,
        totalItemDiscount: totalItemDiscount,
        generalDiscount: generalDiscount,
        extraCharges: extraCharges,
      );
      await saveDocument(
        suggestedName: "${invoiceType}_$invoiceNumber.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  // ==================== PRINT INVOICE ====================
  Future<void> printInvoiceDocument({
    required String invoiceType,
    required String invoiceNumber,
    required String? reference,
    required DateTime? invoiceDate,
    required String customerSupplierName,
    required List<InvoiceItem> items,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required StkAccountModel? account,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required bool isSale,
    String? remark,
    String? currency,
    double? totalLocalAmount,
    String? localCurrency,
    double? exchangeRate,
    double? subtotal,
    double? totalItemDiscount,
    double? generalDiscount,
    double? extraCharges,
  }) async {
    try {
      final document = await generateInvoiceDocument(
        invoiceType: invoiceType,
        invoiceNumber: invoiceNumber,
        reference: reference,
        invoiceDate: invoiceDate,
        customerSupplierName: customerSupplierName,
        items: items,
        grandTotal: grandTotal,
        cashPayment: cashPayment,
        creditAmount: creditAmount,
        account: account,
        language: language,
        remark: remark,
        orientation: orientation,
        company: company,
        pageFormat: pageFormat,
        currency: currency,
        isSale: isSale,
        totalLocalAmount: totalLocalAmount,
        localCurrency: localCurrency,
        exchangeRate: exchangeRate,
        subtotal: subtotal,
        totalItemDiscount: totalItemDiscount,
        generalDiscount: generalDiscount,
        extraCharges: extraCharges,
      );

      for (int i = 0; i < copies; i++) {
        await Printing.directPrintPdf(
          printer: selectedPrinter,
          onLayout: (pw.PdfPageFormat format) async {
            return document.save();
          },
        );
        if (i < copies - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // ==================== PREVIEW INVOICE ====================
  Future<pw.Document> printInvoicePreview({
    required String invoiceType,
    required String invoiceNumber,
    required String? reference,
    required DateTime? invoiceDate,
    required String customerSupplierName,
    required List<InvoiceItem> items,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required StkAccountModel? account,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    required bool isSale,
    String? remark,
    String? currency,
    double? totalLocalAmount,
    String? localCurrency,
    double? exchangeRate,
    double? subtotal,
    double? totalItemDiscount,
    double? generalDiscount,
    double? extraCharges,
  }) async {
    return generateInvoiceDocument(
      invoiceType: invoiceType,
      invoiceNumber: invoiceNumber,
      reference: reference,
      invoiceDate: invoiceDate,
      customerSupplierName: customerSupplierName,
      items: items,
      grandTotal: grandTotal,
      cashPayment: cashPayment,
      creditAmount: creditAmount,
      account: account,
      language: language,
      orientation: orientation,
      company: company,
      pageFormat: pageFormat,
      currency: currency,
      isSale: isSale,
      remark: remark,
      totalLocalAmount: totalLocalAmount,
      localCurrency: localCurrency,
      exchangeRate: exchangeRate,
      subtotal: subtotal,
      totalItemDiscount: totalItemDiscount,
      generalDiscount: generalDiscount,
      extraCharges: extraCharges,
    );
  }

  bool _shouldShowLocalAmount({
    String? baseCurrency,
    String? localCurrency,
    double? exchangeRate,
  }) {
    return localCurrency != null &&
        baseCurrency != null &&
        baseCurrency != localCurrency &&
        exchangeRate != null;
  }

  // ==================== GENERATE INVOICE ====================
  Future<pw.Document> generateInvoiceDocument({
    required String invoiceType,
    required String invoiceNumber,
    required String? reference,
    required DateTime? invoiceDate,
    required String customerSupplierName,
    required List<InvoiceItem> items,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required StkAccountModel? account,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    required bool isSale,
    String? currency,
    String? remark,
    double? totalLocalAmount,
    String? localCurrency,
    double? exchangeRate,
    double? subtotal,
    double? totalItemDiscount,
    double? generalDiscount,
    double? extraCharges,
  }) async {
    final document = pw.Document();

    if (_isRollFormat(pageFormat)) {
      return _generateRoll80Invoice(
        invoiceType: invoiceType,
        invoiceNumber: invoiceNumber,
        reference: reference,
        invoiceDate: invoiceDate,
        customerSupplierName: customerSupplierName,
        items: items,
        grandTotal: grandTotal,
        cashPayment: cashPayment,
        creditAmount: creditAmount,
        account: account,
        language: language,
        orientation: orientation,
        company: company,
        pageFormat: pageFormat,
        isSale: isSale,
        currency: currency,
        remark: remark,
        totalLocalAmount: totalLocalAmount,
        localCurrency: localCurrency,
        exchangeRate: exchangeRate,
        subtotal: subtotal,
        totalItemDiscount: totalItemDiscount,
        generalDiscount: generalDiscount,
        extraCharges: extraCharges,
      );
    }

    final firstPageHeader = await _firstPageHeader(
      language: language,
      com: company,
      customerSupplierName: customerSupplierName,
      isSale: isSale,
      invoiceType: invoiceType,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      reference: reference,
      account: account,
    );

    final pageTheme = pw.PageTheme(
      pageFormat: pageFormat,
      orientation: orientation,
      margin: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      textDirection: documentLanguage(language: language),
      buildBackground: (pw.Context context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Center(
          child: _buildWatermark(
            company: company,
            pageFormat: pageFormat,
            opacity: 0.15,
            widthFactor: 0.9,
            heightFactor: 0.9,
            angle: -0.35,
            fit: pw.BoxFit.contain,
            topOffset: 60,
          ),
        ),
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        maxPages: 1000,

        build: (pw.Context context) => [
          firstPageHeader,
          _itemsTableHeader(
            language: language,
            report: company,
            showLocalAmount: _shouldShowLocalAmount(
              baseCurrency: currency,
              localCurrency: localCurrency,
              exchangeRate: exchangeRate,
            ),
          ),
          pw.SizedBox(height: 5),
          ..._buildItemsTableContent(
            items: items,
            language: language,
            baseCurrency: currency,
            localCurrency: localCurrency,
            exchangeRate: exchangeRate,
            report: company,
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (isSale && company.visible?.termsAndConditions == true) ...[
                pw.SizedBox(width: 15),
                pw.Expanded(
                  flex: 1,
                  child: _saleTermsMessage(language: language,company: company),
                ),
              ],
              pw.Expanded(
                flex: 1,
                child: _paymentSummary(
                  language: language,
                  grandTotal: grandTotal,
                  cashPayment: cashPayment,
                  creditAmount: creditAmount,
                  account: account,
                  isSale: isSale,
                  items: items,
                  remark: remark,
                  totalLocalAmount: totalLocalAmount,
                  localCurrency: localCurrency,
                  baseCurrency: currency,
                  exchangeRate: exchangeRate,
                  subtotal: subtotal,
                  totalItemDiscount: totalItemDiscount,
                  generalDiscount: generalDiscount,
                  extraCharges: extraCharges,
                ),
              ),
            ],
          ),
          if (remark != null && remark.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                    text: tr(text: "note", tr: language),
                    fontSize: 8,
                    color: _InvoiceColors.accentText),
                pw.SizedBox(width: 5),
                zText(text: remark, fontSize: 8),
              ],
            ),
          ],
        ],

        header: (pw.Context context) => _pageHeader(
          language: language,
          report: company,
          context: context,
          baseCurrency: currency,
          localCurrency: localCurrency,
          exchangeRate: exchangeRate,
        ),
      ),
    );
    return document;
  }

  Future<pw.Widget> _firstPageHeader({
    required String language,
    required ReportModel com,
    required String customerSupplierName,
    required bool isSale,
    required String invoiceType,
    required String invoiceNumber,
    required DateTime? invoiceDate,
    required String? reference,
    required StkAccountModel? account,
  }) async {
    final companyHeader = await header(report: com);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        companyHeader,
        pw.SizedBox(height: 4),
        _invoiceHeaderWidget(
          language: language,
          com: com,
          customerSupplierName: customerSupplierName,
          isSale: isSale,
          invoiceType: invoiceType,
          invoiceNumber: invoiceNumber,
          invoiceDate: invoiceDate,
          reference: reference,
          account: account,
        ),
      ],
    );
  }

  pw.Widget _pageHeader({
    required pw.Context context,
    required String language,
    required ReportModel report,
    String? baseCurrency,
    String? localCurrency,
    double? exchangeRate,
  }) {
    final pageNumber = context.pageNumber;

    if (pageNumber > 1) {
      final needsConversion = localCurrency != null &&
          baseCurrency != null &&
          baseCurrency != localCurrency &&
          exchangeRate != null;
      final showLocalAmount = needsConversion;

      return pw.Column(
        children: [
          pw.SizedBox(height: 5),
          _itemsTableHeader(
            language: language,
            report: report,
            showLocalAmount: showLocalAmount,
          ),
        ],
      );
    }

    return pw.SizedBox();
  }

  /// ============================================================
  ///  ITEMS TABLE HEADER
  ///  For RTL rows we use `pw.Alignment` (physical, direction-immune)
  ///  so that money columns always hug the LEFT edge, and description
  ///  always hugs the RIGHT edge — regardless of RTL/LTR flipping.
  /// ============================================================
  pw.Widget _itemsTableHeader({
    required String language,
    required ReportModel report,
    required bool showLocalAmount,
  }) {
    const numberWidth = 30.0;
    const descriptionWidth = 230.0;
    const qtyWidth = 28.0;
    const unitWidth = 24.0;
    const totalQtyWidth = 70.0;
    const priceWidth = 50.0;
    const totalWidth = 60.0;
    const batchWidth = 45.0;
    double headerFontSize = 9;

    final isRtl = language == 'fa' || language == 'ar';
    final isWholeSale = report.visible?.isWholeSale ?? false;

    final Map<int, pw.TableColumnWidth> columnWidths;
    final List<({String text, pw.Alignment align})> headers;

    if (isRtl) {
      if (showLocalAmount) {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(totalQtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(batchWidth),
            5: pw.FixedColumnWidth(qtyWidth),
            6: pw.FixedColumnWidth(descriptionWidth),
            7: pw.FixedColumnWidth(numberWidth),
          };
          headers = [
            (text: tr(text: 'total', tr: language),       align: pw.Alignment.centerLeft),
            (text: tr(text: 'unitPrice', tr: language),   align: pw.Alignment.centerLeft),
            (text: tr(text: 'totalQty', tr: language),    align: pw.Alignment.center),
            (text: tr(text: 'unit', tr: language),        align: pw.Alignment.center),
            (text: tr(text: 'packing', tr: language),     align: pw.Alignment.center),
            (text: tr(text: 'quantity', tr: language),    align: pw.Alignment.center),
            (text: tr(text: 'description', tr: language), align: pw.Alignment.centerRight),
            (text: tr(text: 'number', tr: language),      align: pw.Alignment.center),
          ];
        } else {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(unitWidth),
            3: pw.FixedColumnWidth(qtyWidth),
            4: pw.FixedColumnWidth(descriptionWidth),
            5: pw.FixedColumnWidth(numberWidth),
          };
          headers = [
            (text: tr(text: 'total', tr: language),       align: pw.Alignment.centerLeft),
            (text: tr(text: 'unitPrice', tr: language),   align: pw.Alignment.centerLeft),
            (text: tr(text: 'unit', tr: language),        align: pw.Alignment.center),
            (text: tr(text: 'quantity', tr: language),    align: pw.Alignment.center),
            (text: tr(text: 'description', tr: language), align: pw.Alignment.centerRight),
            (text: tr(text: 'number', tr: language),      align: pw.Alignment.center),
          ];
        }
      } else {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(totalQtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(batchWidth),
            5: pw.FixedColumnWidth(qtyWidth),
            6: pw.FixedColumnWidth(descriptionWidth),
            7: pw.FixedColumnWidth(numberWidth),
          };
          headers = [
            (text: tr(text: 'total', tr: language),       align: pw.Alignment.centerLeft),
            (text: tr(text: 'unitPrice', tr: language),   align: pw.Alignment.centerLeft),
            (text: tr(text: 'totalQty', tr: language),    align: pw.Alignment.center),
            (text: tr(text: 'unit', tr: language),        align: pw.Alignment.center),
            (text: tr(text: 'packing', tr: language),     align: pw.Alignment.center),
            (text: tr(text: 'quantity', tr: language),    align: pw.Alignment.center),
            (text: tr(text: 'description', tr: language), align: pw.Alignment.centerRight),
            (text: tr(text: 'number', tr: language),      align: pw.Alignment.center),
          ];
        } else {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(unitWidth),
            3: pw.FixedColumnWidth(qtyWidth),
            4: pw.FixedColumnWidth(descriptionWidth),
            5: pw.FixedColumnWidth(numberWidth),
          };
          headers = [
            (text: tr(text: 'total', tr: language),       align: pw.Alignment.centerLeft),
            (text: tr(text: 'unitPrice', tr: language),   align: pw.Alignment.centerLeft),
            (text: tr(text: 'unit', tr: language),        align: pw.Alignment.center),
            (text: tr(text: 'quantity', tr: language),    align: pw.Alignment.center),
            (text: tr(text: 'description', tr: language), align: pw.Alignment.centerRight),
            (text: tr(text: 'number', tr: language),      align: pw.Alignment.center),
          ];
        }
      }
    } else {
      if (showLocalAmount) {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(batchWidth),
            4: pw.FixedColumnWidth(unitWidth),
            5: pw.FixedColumnWidth(totalQtyWidth),
            6: pw.FixedColumnWidth(priceWidth),
            7: pw.FixedColumnWidth(totalWidth),
          };
          headers = [
            (text: tr(text: 'number', tr: language),      align: pw.Alignment.center),
            (text: tr(text: 'description', tr: language), align: pw.Alignment.centerLeft),
            (text: tr(text: 'quantity', tr: language),    align: pw.Alignment.center),
            (text: tr(text: 'packing', tr: language),     align: pw.Alignment.center),
            (text: tr(text: 'unit', tr: language),        align: pw.Alignment.center),
            (text: tr(text: 'totalQty', tr: language),    align: pw.Alignment.center),
            (text: tr(text: 'unitPrice', tr: language),   align: pw.Alignment.centerRight),
            (text: tr(text: 'total', tr: language),       align: pw.Alignment.centerRight),
          ];
        } else {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(priceWidth),
            5: pw.FixedColumnWidth(totalWidth),
          };
          headers = [
            (text: tr(text: 'number', tr: language),      align: pw.Alignment.center),
            (text: tr(text: 'description', tr: language), align: pw.Alignment.centerLeft),
            (text: tr(text: 'quantity', tr: language),    align: pw.Alignment.center),
            (text: tr(text: 'unit', tr: language),        align: pw.Alignment.center),
            (text: tr(text: 'unitPrice', tr: language),   align: pw.Alignment.centerRight),
            (text: tr(text: 'total', tr: language),       align: pw.Alignment.centerRight),
          ];
        }
      } else {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(batchWidth),
            4: pw.FixedColumnWidth(unitWidth),
            5: pw.FixedColumnWidth(totalQtyWidth),
            6: pw.FixedColumnWidth(priceWidth),
            7: pw.FixedColumnWidth(totalWidth),
          };
          headers = [
            (text: tr(text: 'number', tr: language),      align: pw.Alignment.center),
            (text: tr(text: 'description', tr: language), align: pw.Alignment.centerLeft),
            (text: tr(text: 'quantity', tr: language),    align: pw.Alignment.center),
            (text: tr(text: 'packing', tr: language),     align: pw.Alignment.center),
            (text: tr(text: 'unit', tr: language),        align: pw.Alignment.center),
            (text: tr(text: 'totalQty', tr: language),    align: pw.Alignment.center),
            (text: tr(text: 'unitPrice', tr: language),   align: pw.Alignment.centerRight),
            (text: tr(text: 'total', tr: language),       align: pw.Alignment.centerRight),
          ];
        } else {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(priceWidth),
            5: pw.FixedColumnWidth(totalWidth),
          };
          headers = [
            (text: tr(text: 'number', tr: language),      align: pw.Alignment.center),
            (text: tr(text: 'description', tr: language), align: pw.Alignment.centerLeft),
            (text: tr(text: 'quantity', tr: language),    align: pw.Alignment.center),
            (text: tr(text: 'unit', tr: language),        align: pw.Alignment.center),
            (text: tr(text: 'unitPrice', tr: language),   align: pw.Alignment.centerRight),
            (text: tr(text: 'total', tr: language),       align: pw.Alignment.centerRight),
          ];
        }
      }
    }

    return pw.Table(
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: _InvoiceColors.primary, width: 1.2),
        horizontalInside:
        pw.BorderSide(color: _InvoiceColors.divider, width: 0.5),
      ),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          decoration: pw.BoxDecoration(color: _InvoiceColors.primaryLight),
          children: headers.map((h) {
            return pw.Container(
              alignment: h.align,
              padding: pw.EdgeInsets.all(4),
              child: zText(
                text: h.text,
                fontSize: headerFontSize,
                fontWeight: pw.FontWeight.bold,
                color: _InvoiceColors.primaryDark,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<pw.Widget> _buildItemsTableContent({
    required List<InvoiceItem> items,
    required String language,
    String? baseCurrency,
    String? localCurrency,
    double? exchangeRate,
    required ReportModel report,
  }) {
    const numberWidth = 30.0;
    const descriptionWidth = 230.0;
    const qtyWidth = 28.0;
    const unitWidth = 24.0;
    const totalQtyWidth = 70.0;
    const priceWidth = 50.0;
    const totalWidth = 60.0;
    const batchWidth = 45.0;

    final isRtl = language == 'fa' || language == 'ar';
    final safeLocalCurrency = localCurrency ?? '';
    final safeExchangeRate = exchangeRate ?? 1.0;
    final isWholeSale = report.visible?.isWholeSale ?? false;

    final needsConversion = localCurrency != null &&
        baseCurrency != null &&
        baseCurrency != localCurrency &&
        exchangeRate != null;

    final showLocalAmount = needsConversion;

    final Map<int, pw.TableColumnWidth> columnWidths;

    if (isRtl) {
      if (showLocalAmount) {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(totalQtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(batchWidth),
            5: pw.FixedColumnWidth(qtyWidth),
            6: pw.FixedColumnWidth(descriptionWidth),
            7: pw.FixedColumnWidth(numberWidth),
          };
        } else {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(unitWidth),
            3: pw.FixedColumnWidth(qtyWidth),
            4: pw.FixedColumnWidth(descriptionWidth),
            5: pw.FixedColumnWidth(numberWidth),
          };
        }
      } else {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(totalQtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(batchWidth),
            5: pw.FixedColumnWidth(qtyWidth),
            6: pw.FixedColumnWidth(descriptionWidth),
            7: pw.FixedColumnWidth(numberWidth),
          };
        } else {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(unitWidth),
            3: pw.FixedColumnWidth(qtyWidth),
            4: pw.FixedColumnWidth(descriptionWidth),
            5: pw.FixedColumnWidth(numberWidth),
          };
        }
      }
    } else {
      if (showLocalAmount) {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(batchWidth),
            4: pw.FixedColumnWidth(unitWidth),
            5: pw.FixedColumnWidth(totalQtyWidth),
            6: pw.FixedColumnWidth(priceWidth),
            7: pw.FixedColumnWidth(totalWidth),
          };
        } else {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(priceWidth),
            5: pw.FixedColumnWidth(totalWidth),
          };
        }
      } else {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(batchWidth),
            4: pw.FixedColumnWidth(unitWidth),
            5: pw.FixedColumnWidth(totalQtyWidth),
            6: pw.FixedColumnWidth(priceWidth),
            7: pw.FixedColumnWidth(totalWidth),
          };
        } else {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(priceWidth),
            5: pw.FixedColumnWidth(totalWidth),
          };
        }
      }
    }

    return [
      pw.Table(
        border: pw.TableBorder(
          bottom: pw.BorderSide(color: _InvoiceColors.primary, width: 1.2),
          horizontalInside:
          pw.BorderSide(color: _InvoiceColors.divider, width: 0.5),
        ),
        columnWidths: columnWidths,
        children: [
          for (int i = 0; i < items.length; i++)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: _InvoiceColors.divider,
                    width: 1,
                  ),
                ),
              ),
              verticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: isRtl
                  ? _buildRtlRow(items[i], i, showLocalAmount,
                  safeLocalCurrency, safeExchangeRate, report)
                  : _buildLtrRow(items[i], i, showLocalAmount,
                  safeLocalCurrency, safeExchangeRate, report),
            ),
          pw.TableRow(
            children: List.generate(
              columnWidths.length,
                  (index) => pw.Container(height: 0),
            ),
          ),
        ],
      ),
    ];
  }

  List<pw.Widget> _buildAddressPhoneItems(ReportModel com) {
    final List<pw.Widget> items = [];

    if (com.partyPhone?.isNotEmpty == true) {
      items.add(
          verticalDivider(height: 10, width: 1));
      items.add(zText(text: com.partyPhone ?? "", fontSize: 10));
    }

    if (com.partyAddress?.isNotEmpty == true) {
      items.add(
          verticalDivider(height: 10, width: 1));
      items.add(zText(text: com.partyAddress ?? "", fontSize: 10));
    }

    if (com.partyCity?.isNotEmpty == true) {
      items.add(
          verticalDivider(height: 10, width: 1));
      items.add(zText(text: com.partyCity ?? "", fontSize: 10));
    }

    if (com.partyProvince?.isNotEmpty == true) {
      items.add(
          verticalDivider(height: 10, width: 1));
      items.add(zText(text: com.partyProvince ?? "", fontSize: 10));
    }

    return items;
  }

  bool _hasAnyAddressPhoneInfo(ReportModel com) {
    return (com.partyPhone?.isNotEmpty == true) ||
        (com.partyAddress?.isNotEmpty == true) ||
        (com.partyCity?.isNotEmpty == true) ||
        (com.partyProvince?.isNotEmpty == true);
  }

  pw.Widget _invoiceHeaderWidget({
    required String language,
    required String invoiceType,
    required String invoiceNumber,
    required DateTime? invoiceDate,
    required String customerSupplierName,
    required bool isSale,
    required ReportModel com,
    required String? reference,
    required StkAccountModel? account,
  }) {
    final invoiceTitle = invoiceType.toLowerCase().contains('sale')
        ? tr(text: 'SEL', tr: language)
        : tr(text: 'PUR', tr: language);

    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 0, horizontal: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    children: [
                      if(language=="en")...[
                        zText(
                          text: invoiceTitle,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _InvoiceColors.primaryDark,
                        ),
                        pw.SizedBox(width: 2),
                        zText(
                            text: tr(text: 'invoiceNumber', tr: language),
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _InvoiceColors.primaryDark),
                      ],

                      if(language == "fa" || language == "ar")...[
                        zText(
                            text: tr(text: 'invoiceNumber', tr: language),
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _InvoiceColors.primaryDark),
                        pw.SizedBox(width: 3),
                        zText(
                          text: invoiceTitle,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _InvoiceColors.primaryDark,
                        ),
                      ],

                      verticalDivider(height: 10, width: 1),
                      zText(
                        text: invoiceNumber,
                        fontSize: 10,
                      ),
                    ],
                  )
                ],
              ),
              pw.Spacer(),
              pw.Row(
                children: [
                  zText(
                      text: tr(text: "invoiceDate", tr: language),
                      fontSize: 10,
                      color: _InvoiceColors.primaryDark,
                      fontWeight: pw.FontWeight.bold),
                  verticalDivider(
                      height: 10, width: 1),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      zText(
                        text: invoiceDate?.shamsiDateFormatted ??
                            DateTime.now().shamsiDateFormatted,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _InvoiceColors.primaryDark,
                      ),
                      verticalDivider(
                          height: 10, width: 1),
                      zText(
                        text: invoiceDate?.toFormattedDate() ??
                            DateTime.now().toFormattedDate(),
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _InvoiceColors.accentText,
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: _customerSupplierInfo(
                  language: language,
                  customerSupplierName: customerSupplierName,
                  isSale: isSale,
                  account: account,
                ),
              ),

              if (_hasAnyAddressPhoneInfo(com))
                pw.Row(
                  children: [
                    zText(
                      text: tr(text: 'addressAndPhone', tr: language),
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _InvoiceColors.primaryDark,
                    ),
                    ..._buildAddressPhoneItems(com),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 4),
        ],
      ),
    );
  }

  pw.Widget _customerSupplierInfo({
    required String language,
    required String customerSupplierName,
    required bool isSale,
    required StkAccountModel? account,
  }) {
    final title = isSale
        ? tr(text: 'customer', tr: language)
        : tr(text: 'supplier', tr: language);

    String accountInfo = '';
    if (account != null &&
        account.accNumber != null &&
        account.accName?.isNotEmpty == true) {
      accountInfo = "${account.accName}";
    }

    return pw.Container(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          zText(
              text: "$title :",
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _InvoiceColors.primaryDark),
          pw.SizedBox(width: 4),
          zText(
            text: customerSupplierName,
            fontSize: 10,
          ),
          if (accountInfo.isNotEmpty) ...[
            verticalDivider(
                height: 8, width: 1),
            zText(
              text: accountInfo,
              fontSize: 10,
            ),
          ],
        ],
      ),
    );
  }

  /// ============================================================
  ///  LTR ROW
  /// ============================================================
  List<pw.Widget> _buildLtrRow(
      InvoiceItem item,
      int index,
      bool showLocalAmount,
      String localCurrency,
      double exchangeRate,
      ReportModel report,
      ) {
    final isWholeSale = report.visible?.isWholeSale ?? false;
    final totalQty = (item.quantity * item.batch).toStringAsFixed(0);
    final localUnitPrice = (item.unitPrice * exchangeRate).toAmount(decimal: 2);
    final totalLocalAmount =
    (item.quantity * item.batch * item.unitPrice * exchangeRate)
        .toAmount(decimal: 2);

    final widgets = <pw.Widget>[];

    widgets.add(pw.Container(
      alignment: pw.Alignment.center,
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: (index + 1).toString(),
        fontSize: 10,
        color: _InvoiceColors.accentText,
      ),
    ));

    widgets.add(pw.Container(
      alignment: pw.Alignment.centerLeft,
      padding: pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: zText(
        text: item.productName,
        fontSize: 12,
      ),
    ));

    widgets.add(pw.Container(
      alignment: pw.Alignment.center,
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.quantity.toStringAsFixed(0),
        fontSize: 10,
      ),
    ));

    if (isWholeSale) {
      widgets.add(pw.Container(
        alignment: pw.Alignment.center,
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.batch.toString(),
          fontSize: 10,
        ),
      ));
    }

    widgets.add(pw.Container(
      alignment: pw.Alignment.center,
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.unit.isEmpty ? '-' : item.unit,
        fontSize: 10,
      ),
    ));

    if (isWholeSale) {
      widgets.add(pw.Container(
        alignment: pw.Alignment.center,
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: totalQty,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _InvoiceColors.primaryDark,
        ),
      ));
    }

    if (showLocalAmount) {
      widgets.add(pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: pw.EdgeInsets.all(3),
        child: zText(text: localUnitPrice, fontSize: 10),
      ));
      widgets.add(pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: totalLocalAmount,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _InvoiceColors.primaryDark,
        ),
      ));
    } else {
      widgets.add(pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.unitPrice.toAmount(decimal: 2),
          fontSize: 10,
        ),
      ));
      widgets.add(pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.total.toAmount(),
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _InvoiceColors.primaryDark,
        ),
      ));
    }

    return widgets;
  }

  /// ============================================================
  ///  RTL ROW
  ///  Uses `pw.Alignment` (physical, direction-immune):
  ///    - total / unitPrice hug the LEFT edge (physically)
  ///    - description hugs the RIGHT edge (physically)
  ///    - small numeric columns center
  ///  Column push order matches the RTL `columnWidths` map.
  /// ============================================================
  List<pw.Widget> _buildRtlRow(
      InvoiceItem item,
      int index,
      bool showLocalAmount,
      String localCurrency,
      double exchangeRate,
      ReportModel report,
      ) {
    final isWholeSale = report.visible?.isWholeSale ?? false;
    final totalQty = (item.quantity * item.batch).toStringAsFixed(0);
    final localUnitPrice = (item.unitPrice * exchangeRate).toAmount(decimal: 2);
    final totalLocalAmount =
    (item.quantity * item.batch * item.unitPrice * exchangeRate)
        .toAmount(decimal: 2);

    final widgets = <pw.Widget>[];

    // Helper for a centered numeric cell.
    pw.Widget numericCell(String text, {bool bold = false, pw.PdfColor? color}) {
      return pw.Container(
        alignment: pw.Alignment.center,
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: text,
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      );
    }

    // Helper for a "left-anchored" money cell.
    pw.Widget moneyCell(String text, {bool bold = false, pw.PdfColor? color}) {
      return pw.Container(
        alignment: pw.Alignment.centerLeft,
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: text,
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      );
    }

    // ── 0: total (physically LEFT of paper) → anchor LEFT ──
    if (showLocalAmount) {
      widgets.add(moneyCell(
        totalLocalAmount,
        bold: true,
        color: _InvoiceColors.primaryDark,
      ));
    } else {
      widgets.add(moneyCell(
        item.total.toAmount(),
        bold: true,
        color: _InvoiceColors.primaryDark,
      ));
    }

    // ── 1: unitPrice → anchor LEFT ──
    if (showLocalAmount) {
      widgets.add(moneyCell(localUnitPrice));
    } else {
      widgets.add(moneyCell(item.unitPrice.toAmount(decimal: 2)));
    }

    // ── 2: totalQty (wholesale only) ──
    if (isWholeSale) {
      widgets.add(numericCell(
        totalQty,
        bold: true,
        color: _InvoiceColors.primaryDark,
      ));
    }

    // ── 3: unit ──
    widgets.add(numericCell(item.unit.isEmpty ? '-' : item.unit));

    // ── 4: packing / batch (wholesale only) ──
    if (isWholeSale) {
      widgets.add(numericCell(item.batch.toString()));
    }

    // ── 5: quantity ──
    widgets.add(numericCell(item.quantity.toStringAsFixed(0)));

    // ── 6: description (physically RIGHT of paper) → anchor RIGHT ──
    widgets.add(pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: zText(
        text: item.productName,
        fontSize: 12,
      ),
    ));

    // ── 7: number ──
    widgets.add(numericCell(
      (index + 1).toString(),
      color: _InvoiceColors.accentText,
    ));

    return widgets;
  }

  pw.Widget _paymentSummary({
    required String language,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required StkAccountModel? account,
    required bool isSale,
    required List<InvoiceItem> items,
    String? remark,
    double? totalLocalAmount,
    String? localCurrency,
    String? baseCurrency,
    double? exchangeRate,
    double? subtotal,
    double? totalItemDiscount,
    double? generalDiscount,
    double? extraCharges,
  }) {
    final totalQty = items.fold<double>(0, (sum, item) => sum + item.quantity);
    final lang = NumberToWords.getLanguageFromLocale(Locale(language));

    final safeBaseCurrency = baseCurrency ?? '';
    final safeLocalCurrency = localCurrency ?? '';
    final safeExchangeRate = exchangeRate ?? 1.0;

    final needsConversion = localCurrency != null &&
        baseCurrency != null &&
        baseCurrency != localCurrency &&
        exchangeRate != null &&
        exchangeRate != 1.0;

    final double effectiveSubtotal = subtotal ??
        items.fold(
            0.0,
                (sum, item) =>
            sum + ((item.quantity * item.batch) * item.unitPrice));
    final double effectiveLocalSubtotal =
        effectiveSubtotal * safeExchangeRate;

    final double totalDiscount =
        (totalItemDiscount ?? 0.0) + (generalDiscount ?? 0.0);
    final double totalLocalDiscount = totalDiscount * safeExchangeRate;

    final double effectiveExtraCharges = extraCharges ?? 0.0;
    final double effectiveLocaleExtraCharges =
        effectiveExtraCharges * safeExchangeRate;

    final double finalGrandTotal =
        effectiveSubtotal - totalDiscount + effectiveExtraCharges;
    final double grandTotalLocal = finalGrandTotal * safeExchangeRate;

    final effectiveCashPayment =
    (needsConversion && cashPayment > 0)
        ? cashPayment * safeExchangeRate
        : cashPayment;
    final effectiveCreditAmount =
    (needsConversion && creditAmount > 0)
        ? creditAmount * safeExchangeRate
        : creditAmount;

    final amountForWords = needsConversion
        ? (totalLocalAmount ?? finalGrandTotal * safeExchangeRate)
        : finalGrandTotal;
    final parsedAmount = int.tryParse(
        double.tryParse(amountForWords.toString())?.toStringAsFixed(0) ??
            "0") ??
        0;
    final amountInWords = NumberToWords.convert(parsedAmount, lang);

    String accCcy;
    if (needsConversion && safeLocalCurrency.isNotEmpty) {
      accCcy = safeLocalCurrency;
    } else if (account != null &&
        account.accCurrency != null &&
        account.accCurrency!.isNotEmpty) {
      accCcy = account.accCurrency!;
    } else {
      accCcy = safeBaseCurrency;
    }

    final accountBalance = account != null
        ? double.tryParse(account.accBalance.toAmount()) ?? 0.0
        : 0.0;

    return pw.Container(
      width: 300,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (finalGrandTotal != effectiveSubtotal) ...[
            _buildCompactRow(
                language: language,
                label: tr(text: 'subtotal', tr: language),
                value: needsConversion
                    ? effectiveLocalSubtotal
                    : effectiveSubtotal,
                currency:
                needsConversion ? safeLocalCurrency : safeBaseCurrency,
                fontSize: 11)
          ],
          if (totalDiscount > 0)
            _buildCompactRow(
                language: language,
                label: tr(text: 'totalDiscount', tr: language),
                value:
                needsConversion ? -totalLocalDiscount : -totalDiscount,
                currency:
                needsConversion ? safeLocalCurrency : safeBaseCurrency,
                color: _InvoiceColors.negative,
                fontSize: 11),
          if (effectiveExtraCharges > 0)
            _buildCompactRow(
                language: language,
                label: tr(text: 'extraCharges', tr: language),
                value: needsConversion
                    ? effectiveLocaleExtraCharges
                    : effectiveExtraCharges,
                currency:
                needsConversion ? safeLocalCurrency : safeBaseCurrency,
                color: _InvoiceColors.warning,
                fontSize: 11),

          _buildGrandTotalCompact(
            label: tr(text: 'grandTotal', tr: language),
            value: needsConversion ? grandTotalLocal : finalGrandTotal,
            currency: needsConversion ? safeLocalCurrency : safeBaseCurrency,
            language: language,
            color: _InvoiceColors.primaryDark,
          ),
          pw.SizedBox(height: 3),
          if (cashPayment > 0) ...[
            _buildCompactRow(
                language: language,
                label: tr(text: 'cashReceipt', tr: language),
                value: effectiveCashPayment,
                currency:
                needsConversion ? safeLocalCurrency : safeBaseCurrency,
                fontSize: 11),
          ],
          pw.SizedBox(height: 3),
          _buildCompactRow(
              language: language,
              label: tr(text: 'totalQty', tr: language),
              value: totalQty,
              decimalRange: 0,
              currency: '',
              fontSize: 11),
          if (account != null && creditAmount > 0) ...[
            _buildCompactRow(
              language: language,
              label: tr(text: 'previousBalance', tr: language),
              value: accountBalance,
              fontSize: 11,
              currency: accCcy,
            ),
            if (needsConversion)
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    zText(
                      text: tr(text: 'exchangeRate', tr: language),
                      fontSize: 10,
                      color: _InvoiceColors.accentText,
                      textAlign: pw.TextAlign.start,
                    ),
                    pw.Spacer(),
                    zText(
                      text:
                      "1 ${_getLocalizedCurrency(safeBaseCurrency, language)} = ${safeExchangeRate.toStringAsFixed(4)} ${_getLocalizedCurrency(safeLocalCurrency, language)}",
                      fontSize: 10,
                      color: _InvoiceColors.accentText,
                      textAlign: pw.TextAlign.end,
                    ),
                  ],
                ),
              ),
            _buildGrandTotalRow(
              label: tr(text: 'newBalance', tr: language),
              value: isSale
                  ? accountBalance - effectiveCreditAmount
                  : accountBalance + effectiveCreditAmount,
              currency: accCcy,
              language: language,
            ),
          ],
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              zText(
                  text: tr(text: "amountInWords", tr: language),
                  fontSize: 8,
                  color: _InvoiceColors.accentText,
                  textAlign: pw.TextAlign.start),
              verticalDivider(
                  height: 10, width: 1),
              zText(
                text:
                "$amountInWords ${accCcy == "USD" ? tr(text: 'usd', tr: language) : accCcy == "AFN" ? tr(text: "afn", tr: language) : accCcy == "CNY" ? tr(text: "cny", tr: language) : accCcy}",
                fontSize: 8,
                textAlign: pw.TextAlign.start,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGrandTotalCompact({
    required String label,
    required double value,
    required String currency,
    required String language,
    int decimalRange = 2,
    pw.PdfColor color = _InvoiceColors.primaryDark,
  }) {
    final displayValue = value.toAmount(decimal: decimalRange);
    final localizedCurrency = _getLocalizedCurrency(currency, language);
    final displayCurrency = currency.isEmpty ? '' : ' $localizedCurrency';

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 3),
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      decoration: pw.BoxDecoration(
        color: _InvoiceColors.primaryLight,
        borderRadius: pw.BorderRadius.circular(2),
        border: pw.Border.all(color: _InvoiceColors.border, width: 0.6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: zText(
              text: label,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _InvoiceColors.primaryDark,
              textAlign: pw.TextAlign.start,
            ),
          ),
          zText(
            text: "$displayValue$displayCurrency",
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            textAlign: pw.TextAlign.end,
            color: color,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGrandTotalRow({
    required String label,
    required double value,
    required String currency,
    required String language,
    int decimalRange = 2,
  }) {
    final displayValue = value.toAmount(decimal: decimalRange);
    final localizedCurrency = _getLocalizedCurrency(currency, language);
    final displayCurrency = currency.isEmpty ? '' : ' $localizedCurrency';

    final isNegative = value < 0;

    final bgColor = isNegative
        ? pw.PdfColor.fromInt(0xFFFFEBEE)
        : _InvoiceColors.primaryLight;

    final textColor =
    isNegative ? _InvoiceColors.negative : _InvoiceColors.primaryDark;

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 3),
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(2),
        border: pw.Border.all(color: _InvoiceColors.border, width: 0.6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: zText(
              text: label,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _InvoiceColors.primaryDark,
              textAlign: pw.TextAlign.start,
            ),
          ),
          zText(
            text: "$displayValue$displayCurrency",
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            textAlign: pw.TextAlign.end,
            color: textColor,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactRow({
    required String label,
    required double value,
    int? decimalRange,
    required String currency,
    required String language,
    bool isBold = false,
    pw.PdfColor? color,
    double fontSize = 9,
  }) {
    final displayValue = value.toAmount(decimal: decimalRange ?? 2);
    final localizedCurrency = _getLocalizedCurrency(currency, language);
    final displayCurrency = currency.isEmpty ? '' : ' $localizedCurrency';

    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: language == "en"? 1 : 0, horizontal: 5),
      child: pw.Row(
        children: [
          // Label takes the remaining space, aligned to .start
          pw.Expanded(
            child: zText(
              text: label,
              fontSize: fontSize,
              fontWeight:
              isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: _InvoiceColors.primaryDark,
              textAlign: pw.TextAlign.start,
            ),
          ),
          pw.SizedBox(width: 10),
          // Value hugs the END edge of the row
          pw.Container(
            alignment: pw.Alignment.centerRight, // physical — always right
            child: zText(
              text: "$displayValue$displayCurrency",
              fontSize: fontSize,
              fontWeight:
              isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedCurrency(String currencyCode, String language) {
    if (language == 'en') {
      return currencyCode;
    }

    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return 'دالر';
      case 'AFN':
        return 'افغانی';
      case 'EUR':
      case 'EURO':
        return 'یورو';
      default:
        return currencyCode;
    }
  }
}