import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shipping/Features/Date/shamsi_converter.dart';
import '../../../../../../../../Features/PrintSettings/PaperSize/paper_size.dart';
import '../../../../../../../../Features/PrintSettings/print_services.dart';
import '../../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../../Features/Widgets/extensions.dart';
import '../model/cont_invoices_model.dart';

class ContainerInvoicesPrintSettings extends PrintServices {
  final pdf = pw.Document();

  // ── Defaults used by the UI (so UI never imports pdf types) ────────
  static const pw.PdfPageFormat _defaultFormat = pw.PdfPageFormat.a4;
  static const pw.PageOrientation _defaultOrientation =
      pw.PageOrientation.portrait;

  // ═══════════════════════════════════════════════════════════════
  // HIGH-LEVEL UI ENTRY POINTS (no pw types in signatures)
  // ═══════════════════════════════════════════════════════════════

  /// Saves one PDF per customer to `Documents/invoices/<folder>/`.
  /// Returns the list of absolute file paths that were written.
  Future<List<String>> saveBatch({
    required List<ShippingInvoice> infoList,
    required String language,
    required ReportModel company,
    required String containerFolder,
  }) {
    return saveBatchToFolder(
      infoList: infoList,
      language: language,
      company: company,
      orientation: _defaultOrientation,
      pageFormat: _defaultFormat,
      containerFolder: containerFolder,
    );
  }

  /// Shares one PDF per customer via the OS share sheet.
  Future<void> shareBatch({
    required List<ShippingInvoice> infoList,
    required String language,
    required ReportModel company,
  }) {
    return shareBatchInvoices(
      infoList: infoList,
      language: language,
      company: company,
      orientation: _defaultOrientation,
      pageFormat: _defaultFormat,
    );
  }

  // ── PREVIEW (build the pw.Document but don't save) ────────────────
  Future<pw.Document> printPreview({
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required ShippingInvoice info,
    required pw.PdfPageFormat pageFormat,
  }) {
    return _generate(
      report: company,
      info: info,
      language: language,
      orientation: orientation,
      pageFormat: pageFormat,
    );
  }

  // ── SAVE AS PDF ────────────────────────────────────────────────
  Future<void> createDocument({
    required ShippingInvoice info,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final document = await _generate(
      report: company,
      info: info,
      language: language,
      orientation: orientation,
      pageFormat: pageFormat,
    );

    await saveDocument(
      suggestedName:
      "Invoice_${info.customer.accountNo}_${info.container.containerNo ?? info.container.sequenceNo ?? ""}.pdf",
      pdf: document,
    );
  }

  // ── PRINT ──────────────────────────────────────────────────────
  Future<void> printDocument({
    required ShippingInvoice info,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required String pages,
  }) async {
    final cleanFormat = PdfFormatHelper.getPrinterFriendlyFormat(pageFormat);

    final document = await _generate(
      report: company,
      info: info,
      language: language,
      orientation: orientation,
      pageFormat: cleanFormat,
    );

    final bytes = await document.save();

    await Printing.sharePdf(
      bytes: bytes,
      filename:
      'invoice_${info.customer.accountNo}_${info.container.containerNo ?? ""}.pdf',
    );
  }

  /// Returns the *real* user Documents folder on desktop.
  /// On mobile, falls back to the app-private documents directory.
  Future<Directory> _userDocumentsDir() async {
    if (Platform.isWindows) {
      final profile = Platform.environment['USERPROFILE'];
      if (profile != null && profile.isNotEmpty) {
        return Directory(p.join(profile, 'Documents'));
      }
    }
    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory(p.join(home, 'Documents'));
      }
    }
    return getApplicationDocumentsDirectory();
  }

  Future<List<String>> saveBatchToFolder({
    required List<ShippingInvoice> infoList,
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
    required String containerFolder,
  }) async {
    if (infoList.isEmpty) return const [];

    final baseDir = await _userDocumentsDir();
    final safeFolder = _safeFileName(containerFolder);
    final target = Directory(p.join(baseDir.path, 'invoices', safeFolder));
    if (!target.existsSync()) target.createSync(recursive: true);

    final written = <String>[];

    for (final inv in infoList) {
      final doc = await _generate(
        report: company,
        info: inv,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      final bytes = await doc.save();
      final name = _safeFileName(
        '${inv.customer.accountNo}_${inv.customer.accountName ?? "customer"}',
      );
      final file = File(p.join(target.path, '$name.pdf'));
      await file.writeAsBytes(bytes);
      written.add(file.path);
    }

    return written;
  }

  /// Shares each customer PDF individually via the OS share sheet.
  Future<void> shareBatchInvoices({
    required List<ShippingInvoice> infoList,
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    for (final inv in infoList) {
      final doc = await _generate(
        report: company,
        info: inv,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );
      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
        'invoice_${inv.customer.accountNo}_${inv.container.containerNo ?? ""}.pdf',
      );
    }
  }

  // ── CORE BUILDER ───────────────────────────────────────────────
  Future<pw.Document> _generate({
    required String language,
    required ReportModel report,
    required ShippingInvoice info,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document();
    final prebuiltHeader = await header(report: report);

    final ByteData imageData =
    await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

    document.addPage(
      pw.MultiPage(
        maxPages: 1000,
        margin: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => [
          _invoiceHeader(language: language, info: info),
          pw.SizedBox(height: 0),
          _customerAndContainerBox(language: language, info: info),
          pw.SizedBox(height: 8),
          _itemsTable(language: language, info: info),
          pw.SizedBox(height: 8),
          _totalsBox(language: language, info: info),
          pw.SizedBox(height: 24),
          _signatureRow(language: language, report: report),
        ],
        header: (context) => prebuiltHeader,
        footer: (context) => footer(
          report: report,
          context: context,
          language: language,
          logoImage: logoImage,
        ),
      ),
    );
    return document;
  }

  // ── TITLE BAR ──────────────────────────────────────────────────
  pw.Widget _invoiceHeader({
    required String language,
    required ShippingInvoice info,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          zText(
            text: tr(text: 'factor', tr: language),
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
          zText(
            text:
            "${info.meta.generatedAt.toFormattedDate()} | ${info.meta.generatedAt?.shamsiDateString}",
            fontSize: 10,
            color: pw.PdfColors.grey700,
          ),
        ],
      ),
    );
  }

  /// Maps a DB enum value ('pending', 'shipped', 'delivered') to its
  /// localized label. Falls back to the raw value if unknown.
  String _statusLabel(String? status, String language) {
    if (status == null || status.isEmpty) return "";

    final key = switch (status.toLowerCase()) {
      'pending' => 'statusPending',
      'shipped' => 'statusShipped',
      'delivered' => 'statusDelivered',
      _ => null,
    };

    if (key == null) return status; // unknown value → show as-is
    return tr(text: key, tr: language);
  }

  // ── CUSTOMER + CONTAINER SIDE BY SIDE ─────────────────────────
  pw.Widget _customerAndContainerBox({
    required String language,
    required ShippingInvoice info,
  }) {
    final c = info.customer;
    final ct = info.container;

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pw.PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ─── CUSTOMER ───────────────────────────────
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: tr(text: 'customerInfo', tr: language),
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 4),
                horizontalDivider(width: 260),
                pw.SizedBox(height: 4),
                _kv(
                  label: tr(text: 'signatory', tr: language),
                  value: "${c.person.code ?? ""} | ${c.person.fullName ?? ""}",
                ),
                _kv(
                  label: tr(text: 'accountName', tr: language),
                  value: "${c.accountNo} | ${c.accountName ?? ""}",
                ),
                _kv(
                  label: tr(text: 'currency', tr: language),
                  value: c.currency ?? "",
                ),
                _kv(
                  label: tr(text: 'mobile', tr: language),
                  value: c.person.phone ?? "",
                ),
                _kv(
                  label: tr(text: 'address', tr: language),
                  value: [
                    c.address.country,
                    c.address.province,
                    c.address.city,
                  ].where((e) => e != null && e.isNotEmpty).join(', '),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          // ─── CONTAINER ──────────────────────────────
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: tr(text: 'containerInfo', tr: language),
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 4),
                horizontalDivider(width: 260),
                pw.SizedBox(height: 4),
                _kv(
                  label: tr(text: 'containerNo', tr: language),
                  value: "${ct.containerNo ?? "—"} | ${ct.sequenceNo ?? "—"}",
                ),
                _kv(
                  label: tr(text: 'port', tr: language),
                  value: ct.portName ?? "",
                ),
                _kv(
                  label: tr(text: 'loadingDate', tr: language),
                  value: ct.loadingDate ?? "",
                ),
                _kv(
                  label: tr(text: 'unloadingDate', tr: language),
                  value: ct.unloadingDate ?? "—",
                ),
                _kv(
                  label: tr(text: 'status', tr: language),
                  value: _statusLabel(ct.status, language),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ITEMS TABLE ────────────────────────────────────────────────
  pw.Widget _itemsTable({
    required String language,
    required ShippingInvoice info,
  }) {
    const idxW = 20.0;
    const qtyW = 36.0;
    const cbmW = 46.0;
    const weightW = 50.0;
    const avgW = 52.0;
    const rateW = 70.0;
    const extraW = 50.0;
    const rentW = 62.0;

    final isRtl = language != "en";

    pw.Widget h(String t, double w, {bool alignStart = false}) {
      return pw.SizedBox(
        width: w,
        child: zText(
          text: t,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          textAlign: alignStart ? pw.TextAlign.left : pw.TextAlign.right,
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // HEADER
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.grey100,
            border: pw.Border(
              bottom: pw.BorderSide(width: 1, color: pw.PdfColors.grey300),
            ),
          ),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: idxW,
                child: zText(
                  text: "#",
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                child: zText(
                  text: tr(text: 'description', tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: isRtl ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              ),
              h(tr(text: 'qty', tr: language), qtyW),
              h(tr(text: 'cbm', tr: language), cbmW),
              h(tr(text: 'weight', tr: language), weightW),
              h(tr(text: 'weightAverage', tr: language), avgW),
              h(tr(text: 'rate', tr: language), rateW),
              h(tr(text: 'charges', tr: language), extraW),
              h(tr(text: 'total', tr: language), rentW),
            ],
          ),
        ),
        // ROWS
        for (int i = 0; i < info.items.length; i++)
          _itemRow(
            language: language,
            i: i,
            item: info.items[i],
            widths: const {
              'idx': idxW,
              'qty': qtyW,
              'cbm': cbmW,
              'weight': weightW,
              'avg': avgW,
              'rate': rateW,
              'extra': extraW,
              'rent': rentW,
            },
          ),
      ],
    );
  }

  pw.Widget _itemRow({
    required String language,
    required int i,
    required InvoiceItem item,
    required Map<String, double> widths,
  }) {
    final isRtl = language != "en";
    final align = isRtl ? pw.TextAlign.right : pw.TextAlign.left;

    pw.Widget cell(String t, double w) => pw.SizedBox(
      width: w,
      child: zText(
        text: t,
        fontSize: 8,
        textAlign: pw.TextAlign.right,
      ),
    );

    final rate = item.ratePerCbm > 0
        ? "${item.ratePerCbm.toAmount()} ${tr(text: 'cbm', tr: language)}"
        : "${item.ratePerWeight.toAmount()} ${tr(text: 'weight', tr: language)}";

    // Guard: weightAVG can be NaN/Infinity if server sent 0 for cbm
    // and the client computed (weight / 0). Show "—" instead.
    final avgDisplay = _safeAmount(item.weightAVG);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: pw.BoxDecoration(
        color: i.isOdd ? pw.PdfColors.grey100 : null,
      ),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: widths['idx']!,
            child: zText(
              text: "${i + 1}",
              fontSize: 8,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            child: zText(
              text: item.itemDescription ?? "",
              fontSize: 8,
              textAlign: align,
            ),
          ),
          cell("${item.qty}", widths['qty']!),
          cell(item.cbm.toAmount(decimal: 3), widths['cbm']!),
          cell(item.weight.toAmount(decimal: 2), widths['weight']!),
          cell(avgDisplay, widths['avg']!),
          cell(rate, widths['rate']!),
          cell(_safeAmount(item.extraCharges), widths['extra']!),
          cell(_safeAmount(item.itemRent), widths['rent']!),
        ],
      ),
    );
  }

  // ── TOTALS ─────────────────────────────────────────────────────
  pw.Widget _totalsBox({
    required String language,
    required ShippingInvoice info,
  }) {
    final t = info.totals;

    // Summary value must match what the "Weight Average" column shows
    // per item — so we sum the per-item values, not weight/cbm.
    // NaN-safe: skip any item whose weightAVG is not finite.
    final totalWeightAverage = info.items.fold<double>(
      0.0,
          (sum, it) => sum + (it.weightAVG.isFinite ? it.weightAVG : 0.0),
    );

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildSummary(
                distance: 150,
                label: tr(text: 'invoiceSummary', tr: language),
                value: "",
                fontSize: 11,
                isEmphasized: true,
              ),
              pw.SizedBox(height: 2),
              horizontalDivider(width: 220),
              pw.SizedBox(height: 2),
              buildSummary(
                distance: 100,
                label: tr(text: 'noItems', tr: language),
                value: "${t.items}",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 100,
                label: tr(text: 'totalQty', tr: language),
                value: "${t.qty}",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 100,
                label: tr(text: 'totalCbm', tr: language),
                value: "${t.cbm.toAmount(decimal: 3)} CBM",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 100,
                label: tr(text: 'totalWeight', tr: language),
                value: "${t.weight.toAmount(decimal: 2)} kg",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 100,
                label: tr(text: 'weightAverage', tr: language),
                value: "${_safeAmount(totalWeightAverage)} kg",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 100,
                label: tr(text: 'extraCharges', tr: language),
                value: _safeAmount(t.extraCharges),
              ),
              pw.SizedBox(height: 2),
              horizontalDivider(width: 220),
              pw.SizedBox(height: 2),
              buildTotalSummary(
                label: tr(text: 'grandTotal', tr: language),
                ccySymbol: t.currency,
                value: _safeAmount(t.totalRent),
                isEmphasized: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SIGNATURE ROW ──────────────────────────────────────────────
  pw.Widget _signatureRow({
    required String language,
    required ReportModel report,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _sigBlock(tr(text: 'customerSignature', tr: language)),
        _sigBlock(tr(text: 'authorizedSignature', tr: language)),
      ],
    );
  }

  pw.Widget _sigBlock(String label) => pw.Column(
    children: [
      pw.SizedBox(height: 30),
      pw.Container(width: 120, height: 1, color: pw.PdfColors.grey500),
      pw.SizedBox(height: 4),
      zText(text: label, fontSize: 8),
    ],
  );

  pw.Widget _kv({required String label, required String value}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 75,
            child: zText(
              text: "$label:",
              fontSize: 8,
              color: pw.PdfColors.grey700,
            ),
          ),
          zText(text: value, fontSize: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════

  /// Returns "—" for NaN / Infinity / non-finite numbers,
  /// otherwise formats with [double.toAmount] (2-decimal string).
  static String _safeAmount(num? v) {
    if (v == null) return "—";
    final d = v.toDoubleAmount(decimal: 2);
    if (!d.isFinite) return "—";
    return d.toAmount();
  }

  /// Strips filesystem-illegal chars and collapses whitespace.
  static String _safeFileName(String s) => s
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .trim();
}