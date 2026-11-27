import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shipping/Features/Date/shamsi_converter.dart';
import '../../../../../../../../../Features/PrintSettings/PaperSize/paper_size.dart';
import '../../../../../../../../../Features/PrintSettings/print_services.dart';
import '../../../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../../../../../Features/Widgets/extensions.dart';
import '../model/shp_details_model.dart';

class ShpByIdPrintSettings extends PrintServices {
  final pdf = pw.Document();

  // Landscape by default — the items table has 10+ columns.

  // ═══════════════════════════════════════════════════════════════
  // HIGH-LEVEL UI ENTRY POINTS
  // ═══════════════════════════════════════════════════════════════

  Future<pw.Document> printPreview({
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
    required ShipmentDetailsModel info,
  }) {
    return _generate(
      report: company,
      info: info,
      language: language,
      orientation: orientation,
      pageFormat: pageFormat,
    );
  }

  Future<void> createDocument({
    required ShipmentDetailsModel info,
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

    final containerNo =
        info.shipment.containerNo;

    await saveDocument(
      suggestedName: 'Container_$containerNo.pdf',
      pdf: document,
    );
  }

  Future<void> printDocument({
    required ShipmentDetailsModel info,
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
    final containerNo =
        info.shipment.containerNo;

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'container_$containerNo.pdf',
    );
  }

  /// Returns the real user Documents folder on desktop.
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
    required List<ShipmentDetailsModel> infoList,
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
    required String containerFolder,
  }) async {
    if (infoList.isEmpty) return const [];

    final baseDir = await _userDocumentsDir();
    final safeFolder = _safeFileName(containerFolder);
    final target = Directory(p.join(baseDir.path, 'containers', safeFolder));
    if (!target.existsSync()) target.createSync(recursive: true);

    final written = <String>[];
    for (final info in infoList) {
      final doc = await _generate(
        report: company,
        info: info,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );
      final bytes = await doc.save();
      final name = _safeFileName(
        info.shipment.containerNo,
      );
      final file = File(p.join(target.path, '$name.pdf'));
      await file.writeAsBytes(bytes);
      written.add(file.path);
    }
    return written;
  }

  // ═══════════════════════════════════════════════════════════════
  // CORE BUILDER
  // ═══════════════════════════════════════════════════════════════
  Future<pw.Document> _generate({
    required String language,
    required ReportModel report,
    required ShipmentDetailsModel info,
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
          _titleBar(language: language, info: info),
          pw.SizedBox(height: 6),
          _containerBox(language: language, info: info),
          pw.SizedBox(height: 8),
          _itemsTable(language: language, info: info),
          pw.SizedBox(height: 8),
          _totalsBox(language: language, info: info),
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
  pw.Widget _titleBar({
    required String language,
    required ShipmentDetailsModel info,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          zText(
            text: tr(text: 'containerReport', tr: language),
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
          zText(
            text:
            "${DateTime.now().toFormattedDate()} | ${DateTime.now().shamsiDateString}",
            fontSize: 10,
            color: pw.PdfColors.grey700,
          ),
        ],
      ),
    );
  }

  String _statusLabel(String? status, String language) {
    if (status == null || status.isEmpty) return "";
    final key = switch (status.toLowerCase()) {
      'pending' => 'statusPending',
      'shipped' => 'statusShipped',
      'delivered' => 'statusDelivered',
      _ => null,
    };
    if (key == null) return status;
    return tr(text: key, tr: language);
  }

  // ── CONTAINER INFO BOX ─────────────────────────────────────────
  pw.Widget _containerBox({
    required String language,
    required ShipmentDetailsModel info,
  }) {
    final c = info.shipment;

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pw.PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
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
                  value: "${c.containerNo} | ${c.sequenceNo ?? "—"}",
                ),
                _kv(
                  label: tr(text: 'port', tr: language),
                  value: c.portName,
                ),
                _kv(
                  label: tr(text: 'loadingDate', tr: language),
                  value: c.loadingDate,
                ),
                _kv(
                  label: tr(text: 'unloadingDate', tr: language),
                  value: c.unloadingDate ?? "—",
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: tr(text: 'status', tr: language),
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 4),
                horizontalDivider(width: 260),
                pw.SizedBox(height: 4),
                _kv(
                  label: tr(text: 'status', tr: language),
                  value: _statusLabel(c.status, language),
                ),
                _kv(
                  label: tr(text: 'description', tr: language),
                  value: c.description ?? "—",
                ),
                _kv(
                  label: tr(text: 'entryDate', tr: language),
                  value: c.entryDate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ITEMS TABLE (LANDSCAPE FITS 10 COLUMNS) ───────────────────
  pw.Widget _itemsTable({
    required String language,
    required ShipmentDetailsModel info,
  }) {
    const idxW = 22.0;
    const custW = 100.0;
    const qtyW = 36.0;
    const cbmW = 38.0;
    const weightW = 44.0;
    const avgW = 48.0;
    const rateW = 50.0;
    const extraW = 45.0;
    const rentW = 50.0;

    final isRtl = language != "en";
    final align = isRtl ? pw.TextAlign.right : pw.TextAlign.left;

    pw.Widget h(String t, double w) => pw.SizedBox(
      width: w,
      child: zText(
        text: t,
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        textAlign: align,
      ),
    );

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
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                child: zText(
                  text: tr(text: 'description', tr: language),
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: align,
                ),
              ),
              h(tr(text: 'customer', tr: language), custW),
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
              'cust': custW,
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
    required ShipmentItemModel item,
    required Map<String, double> widths,
  }) {
    final isRtl = language != "en";
    final align = isRtl ? pw.TextAlign.right : pw.TextAlign.left;

    pw.Widget cell(String t, double w) => pw.SizedBox(
      width: w,
      child: zText(text: t, fontSize: 7, textAlign: align),
    );

    final rate = item.ratePerCbm > 0
        ? "${item.ratePerCbm.toAmount()} ${tr(text: 'cbm', tr: language)}"
        : "${item.ratePerWeight.toAmount()} ${tr(text: 'weight', tr: language)}";

    final avgDisplay = _safeAmount(item.weightAvg);
    final customer = "${item.perName ?? ''} ${item.perLastName ?? ''}".trim();
    final accountNo = "${item.accountNo} - ${item.perCode}";

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: pw.BoxDecoration(
        color: i.isOdd ? pw.PdfColors.grey100 : null,
      ),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: widths['idx']!,
            child: zText(
              text: "${i + 1}",
              fontSize: 7.5,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            child: zText(
              text: item.itemDescription ?? "",
              fontSize: 7.5,
              textAlign: align,
            ),
          ),
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              cell(customer, widths['cust']!),
              cell(accountNo, widths['cust']!),
            ]
          ),
          cell(item.qty.toAmount(decimal: 0), widths['qty']!),
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
    required ShipmentDetailsModel info,
  }) {
    final items = info.items;

    // ── Column totals ─────────────────────────────────────────────
    final totalQty    = items.fold<double>(0, (s, i) => s + i.qty);
    final totalCbm    = items.fold<double>(0, (s, i) => s + i.cbm);
    final totalWeight = items.fold<double>(0, (s, i) => s + i.weight);
    final totalAvg    = items.fold<double>(
      0.0, (s, i) => s + (i.weightAvg.isFinite ? i.weightAvg : 0.0),
    );

    final totalRentInclExtras = items.fold<double>(0, (s, i) => s + i.itemRent);
    final totalExtra          = items.fold<double>(0, (s, i) => s + i.extraCharges);
    final baseRent            = totalRentInclExtras - totalExtra;
    final grandTotal          = baseRent + totalExtra;   // == Σ itemRent

    // ── Status splits ─────────────────────────────────────────────
    final totalDelivered = items.fold<double>(
      0, (s, i) => s + (i.status?.toLowerCase() == 'delivered' ? i.qty : 0),
    );
    final pendingQty = items.fold<double>(
      0, (s, i) => s + (i.status?.toLowerCase() == 'pending' ? i.qty : 0),
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
              // ── Section header ────────────────────────────────
              buildSummary(
                distance: 150,
                label: tr(text: 'containerSummary', tr: language),
                value: "",
                fontSize: 11,
                isEmphasized: true,
              ),
              pw.SizedBox(height: 2),
              horizontalDivider(width: 220),
              pw.SizedBox(height: 2),

              // ── Counts ────────────────────────────────────────
              buildSummary(
                distance: 100,
                label: tr(text: 'noItems', tr: language),
                value: "${items.length}",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 100,
                label: tr(text: 'totalQty', tr: language),
                value: totalQty.toAmount(decimal: 0),
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 100,
                label: tr(text: 'notDelivered', tr: language),
                value: pendingQty.toAmount(decimal: 0),
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 100,
                label: tr(text: 'delivered', tr: language),
                value: totalDelivered.toAmount(decimal: 0),
              ),

              // ── Physical totals ───────────────────────────────
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 100,
                label: tr(text: 'totalCbm', tr: language),
                value: "${totalCbm.toAmount(decimal: 3)} CBM",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 100,
                label: tr(text: 'totalWeight', tr: language),
                value: "${totalWeight.toAmount(decimal: 2)} kg",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 100,
                label: tr(text: 'weightAverage', tr: language),
                value: "${_safeAmount(totalAvg)} kg",
              ),

              // ── Financial breakdown ───────────────────────────
              pw.SizedBox(height: 2),
              horizontalDivider(width: 220),
              pw.SizedBox(height: 2),
              buildSummary(
                distance: 100,
                label: tr(text: 'rent', tr: language),          // base rent
                value: _safeAmount(baseRent),
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 100,
                label: tr(text: 'extraCharges', tr: language),  // extras
                value: _safeAmount(totalExtra),
              ),

              // ── Grand total ───────────────────────────────────
              pw.SizedBox(height: 2),
              horizontalDivider(width: 220),
              pw.SizedBox(height: 2),
              buildTotalSummary(
                label: tr(text: 'grandTotal', tr: language),
                ccySymbol: "USD",
                value: _safeAmount(grandTotal),                 // = Σ itemRent
                isEmphasized: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
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

  // ── Helpers ────────────────────────────────────────────────────
  static String _safeAmount(num? v) {
    if (v == null) return "—";
    final d = v.toDoubleAmount(decimal: 2);
    if (!d.isFinite) return "—";
    return d.toAmount();
  }

  static String _safeFileName(String s) => s
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .trim();
}