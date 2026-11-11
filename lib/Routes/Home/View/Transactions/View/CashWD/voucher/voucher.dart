import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shipping/Features/Date/shamsi_converter.dart';
import 'package:shipping/Features/PrintSettings/print_services.dart';
import 'package:shipping/Features/PrintSettings/report_model.dart';
import '../../../../../../../Features/PrintSettings/num_to_word.dart';
import '../model/wd_model.dart';

// ═════════════════════════════════════════════════════════════════
// PUBLIC ENTRY POINTS
// ═════════════════════════════════════════════════════════════════

class CashTxnVoucherPrintSettings extends PrintServices {
  // ── SAVE ─────────────────────────────────────────────────
  Future<void> createDocument({
    required CashTxnDetail data,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final document = await generateVoucher(
      data: data,
      language: language,
      orientation: orientation,
      report: company,
      pageFormat: pageFormat,
    );

    await saveDocument(
      suggestedName: '${data.reference ?? "voucher"}.pdf',
      pdf: document,
    );
  }

  // ── PRINT ────────────────────────────────────────────────
  Future<void> printDocument({
    required CashTxnDetail data,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required String pages,
  }) async {
    final document = await generateVoucher(
      data: data,
      language: language,
      orientation: orientation,
      report: company,
      pageFormat: pageFormat,
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
  }

  // ── PREVIEW ──────────────────────────────────────────────
  Future<pw.Document> printPreview({
    required CashTxnDetail data,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) =>
      generateVoucher(
        data: data,
        language: language,
        orientation: orientation,
        report: company,
        pageFormat: pageFormat,
      );

  // ── GENERATOR ────────────────────────────────────────────
  Future<pw.Document> generateVoucher({
    required CashTxnDetail data,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel report,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document();

    pw.ImageProvider? logo;
    if (report.comLogo != null &&
        report.comLogo is Uint8List &&
        report.comLogo!.isNotEmpty) {
      logo = pw.MemoryImage(report.comLogo!);
    }

    final isRtl = _isRtl(language);

    // Pre-load contact icons once — reused on every voucher copy.
    final icons = await _loadContactIcons();

    document.addPage(
      pw.MultiPage(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        maxPages: 1000,
        margin: const pw.EdgeInsets.all(20),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (_) => [
          _voucherPage(
            data: data,
            language: language,
            report: report,
            logo: logo,
            icons: icons,
            isRtl: isRtl,
          ),
        ],
      ),
    );
    return document;
  }

  // ═════════════════════════════════════════════════════════════
  // LAYOUT
  // ═════════════════════════════════════════════════════════════

  pw.Widget _voucherPage({
    required CashTxnDetail data,
    required String language,
    required ReportModel report,
    pw.ImageProvider? logo,
    required _ContactIcons icons,
    required bool isRtl,
  }) {
    return pw.Column(
      children: [
        _singleVoucher(
          data: data,
          language: language,
          report: report,
          logo: logo,
          icons: icons,
          isRtl: isRtl,
          isCopy: false,
        ),
        pw.SizedBox(height: isRtl ? 25 : 20),
        _cutLine(language, isRtl),
        pw.SizedBox(height: isRtl ? 25 : 20),
        _singleVoucher(
          data: data,
          language: language,
          report: report,
          logo: logo,
          icons: icons,
          isRtl: isRtl,
          isCopy: true,
        ),
      ],
    );
  }

  pw.Widget _cutLine(String language, bool isRtl) => pw.Row(
    children: [
      pw.Expanded(
        child: pw.Container(height: 0.5, color: PdfColors.grey400),
      ),
      pw.SizedBox(width: 10),
      zText(
        text: '--- ${tr(text: 'cutHere', tr: language)} ---',
        fontSize: 8,
        color: PdfColors.grey500,
      ),
      pw.SizedBox(width: 10),
      pw.Expanded(
        child: pw.Container(height: 0.5, color: PdfColors.grey400),
      ),
    ],
  );

  // ═════════════════════════════════════════════════════════════
  // SINGLE VOUCHER
  // ═════════════════════════════════════════════════════════════

  pw.Widget _singleVoucher({
    required CashTxnDetail data,
    required String language,
    required ReportModel report,
    pw.ImageProvider? logo,
    required _ContactIcons icons,
    required bool isRtl,
    required bool isCopy,
  }) {
    final subject = data.subjectLine;
    final contra = data.contraLine;

    final amountStr =
        subject?.amountDisplay ?? contra?.amountDisplay ?? '0.00';
    final ccy = (subject?.ccy ?? contra?.ccy ?? '').toUpperCase();
    final ccyWord = _currencyWord(ccy, language);

    final amtDouble = double.tryParse(amountStr.replaceAll(',', '')) ?? 0;
    final wordsLang = NumberToWords.getLanguageFromLocale(Locale(language));
    final amountWords =
        '${NumberToWords.convert(amtDouble.round(), wordsLang)} $ccyWord';

    final voucherDate = '${data.entryDate?.toFullDateTime} | ${data.entryDate?.shamsiDateString}';

    final accountValue = subject == null
        ? '-'
        : _accountWithName(subject.trdAccount, subject.accName);

    return pw.Stack(
      children: [
        // ── Watermark ──────────────────────────────────────
        if (logo != null)
          pw.Positioned.fill(
            child: pw.Center(
              child: pw.Opacity(
                opacity: 0.08,
                child: pw.Container(
                  width: 320,
                  height: 320,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
              ),
            ),
          ),

        // ── Voucher body ───────────────────────────────────
        pw.Container(
          padding: pw.EdgeInsets.all(isRtl ? 10 : 14),
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(5),
           // border: pw.Border.all(width: 1.5, color: PdfColors.grey600),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // ── 3-column header ──────────────────────────
              _companyHeader(
                report: report,
                logo: logo,
                icons: icons,
                isRtl: isRtl,
                language: language,
                title: tr(text: 'cashVoucher', tr: language).toUpperCase(),
                isCopy: isCopy,
              ),

              pw.SizedBox(height: isRtl ? 8 : 12),

              // ── Header fields ────────────────────────────
              _kvRow(
                tr(text: 'trnType', tr: language),
                tr(text: data.type ?? '-', tr: language),
                isRtl,
              ),
              _kvRow(
                tr(text: 'date', tr: language),
                voucherDate,
                isRtl,
              ),
              _kvRow(
                tr(text: 'reference', tr: language),
                data.reference ?? '-',
                isRtl,
              ),
              _kvRow(
                tr(text: 'branch', tr: language),
                subject?.branch?.toString() ?? '-',
                isRtl,
              ),
              _kvRow(
                tr(text: 'accountNumber', tr: language),
                accountValue,
                isRtl,
              ),
              _kvRow(
                tr(text: 'status', tr: language),
                _statusLabel(data, language),
                isRtl,
              ),
              pw.SizedBox(height: isRtl ? 3 : 0),

              // ── Narration ────────────────────────────────
              _kvRow(
                tr(text: 'narration', tr: language),
                subject?.narration ?? '-',
                isRtl,
              ),

              pw.SizedBox(height: isRtl ? 3 : 0),

              // ── Amount banner (number LTR + currency RTL) ─
              pw.Container(
                width: double.infinity,
                child: pw.Row(
                  children: [
                    zText(
                      text: '${tr(text: 'amount', tr: language)}:',
                      fontSize: isRtl ? 11 : 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    pw.SizedBox(width: isRtl ? 85 : 132),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Directionality(
                          textDirection: pw.TextDirection.ltr,
                          child: zText(
                            text: _thousands(amountStr),
                            fontSize: isRtl ? 13 : 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        zText(
                          text: ccyWord,
                          fontSize: isRtl ? 13 : 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: isRtl ? 3 : 0),

              // ── Amount in words ──────────────────────────
              pw.Container(
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    zText(
                      text: tr(text: 'amountInWords', tr: language),
                      fontSize: isRtl ? 8 : 9,
                      color: PdfColors.grey700,
                    ),
                    zText(
                      text: amountWords,
                      fontSize: isRtl ? 8 : 9,
                      color: PdfColors.grey900,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: isRtl ? 5 : 8),

              // ── Signatures ───────────────────────────────
              _signatures(data, language, isRtl),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _companyHeader({
    required ReportModel report,
    required pw.ImageProvider? logo,
    required _ContactIcons icons,
    required bool isRtl,
    required String language,
    required String title,
    required bool isCopy,
  }) {
    final name = (report.comName ?? '').trim();
    final address = (report.comAddress ?? '').trim();
    final phone = (report.compPhone ?? '').trim();
    final whatsapp = (report.comWhatsApp ?? '').trim();
    final email = (report.comEmail ?? '').trim();
    final website = (report.comWebsite ?? '').trim();

    // ── LEFT: logo + company name ─────────────────────────
    pw.Widget leftColumn() => pw.Expanded(
      flex: 3,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(
              width: 62,
              height: 62,
              margin: const pw.EdgeInsets.symmetric(horizontal: 2),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          if (name.isNotEmpty)
            pw.Expanded(
              child: zText(
                text: name,
                fontSize: isRtl ? 14 : 15,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
        ],
      ),
    );

    // ── CENTER: title + copy chip ─────────────────────────
    pw.Widget centerColumn() => pw.Expanded(
      flex: 3,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          zText(
            text: title,
            fontSize: isRtl ? 28 : 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
          if (isCopy) ...[
            pw.SizedBox(height: 2),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 1,
              ),
              color: PdfColors.blueGrey50,
              child: zText(
                text: tr(text: 'copy', tr: language).toUpperCase(),
                fontSize: isRtl ? 8 : 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
          ],
        ],
      ),
    );

    // ── RIGHT: contact column ─────────────────────────────
    pw.Widget rightColumn() {
      final rows = <pw.Widget>[];

      void addRow(pw.ImageProvider? icon, String value) {
        if (value.isEmpty) return;
        rows.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 1.5),
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Directionality(
                  textDirection: pw.TextDirection.ltr,
                  child: zText(
                    text: value,
                    fontSize: isRtl ? 8 : 8.5,
                    color: PdfColors.grey700,
                  ),
                ),
                if (icon != null)
                  pw.Container(
                    width: 9,
                    height: 9,
                    margin: const pw.EdgeInsets.only(right: 4, left: 4),
                    child: pw.Image(icon, fit: pw.BoxFit.contain),
                  ),
              ],
            ),
          ),
        );
      }
      addRow(icons.phone, phone);
      addRow(icons.whatsapp, whatsapp);
      addRow(icons.email, email);
      addRow(icons.website, website);
      addRow(icons.location, address);

      return pw.Expanded(
        flex: 3,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: rows,
        ),
      );
    }

    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: isRtl ? 6 : 8,
        vertical: isRtl ? 5 : 6,
      ),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(2),
        border: pw.Border.all(width: 0.5, color: PdfColors.grey800),
      ),
      // ── Force LTR row layout so logo stays left and contacts
      //    stay right in BOTH LTR and RTL documents. Inter text
      //    still renders RTL per-string via zText.
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            leftColumn(),
            pw.SizedBox(width: 6),
            centerColumn(),
            pw.SizedBox(width: 6),
            rightColumn(),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // PIECES
  // ═════════════════════════════════════════════════════════════

  /// "Label : value" row.
  pw.Widget _kvRow(String label, String value, bool isRtl) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: isRtl ? 0 : 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: isRtl ? 80 : 150,
            child: zText(
              text: '$label:',
              fontSize: isRtl ? 12 : 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(width: 30),
          zText(
            text: value,
            fontSize: isRtl ? 12 : 10,
            color: PdfColors.grey900,
          ),
        ],
      ),
    );
  }

  pw.Widget _signatures(CashTxnDetail data, String language, bool isRtl) {
    pw.Widget block(String label, String value) => pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          horizontalDivider(width: isRtl ? 120 : 130),
          pw.SizedBox(height: isRtl ? 3 : 4),
          zText(
            text: label,
            fontSize: isRtl ? 8 : 9,
            color: PdfColors.grey600,
          ),
          pw.SizedBox(height: 2),
          zText(
            text: value,
            fontSize: isRtl ? 9 : 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ],
      ),
    );

    final subject = data.subjectLine;
    final holder = subject == null
        ? '___________'
        : _accountWithName(subject.trdAccount, subject.accName);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        block(
          tr(text: 'createdBy', tr: language),
          data.makerName ?? '___________',
        ),
        pw.SizedBox(width: isRtl ? 15 : 20),
        block(
          tr(text: 'cashier', tr: language),
          data.checkerName ?? '___________',
        ),
        pw.SizedBox(width: isRtl ? 15 : 20),
        block(
          tr(text: 'accountHolder', tr: language),
          holder,
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════

  bool _isRtl(String language) {
    final code = language.toLowerCase();
    return code.startsWith('fa') ||
        code.startsWith('ar') ||
        code.startsWith('ps');
  }

  /// "500000 - Basir Ahmad" or just "500000" when the name is missing.
  String _accountWithName(int? number, String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty || n.toLowerCase() == 'null') {
      return number?.toString() ?? '-';
    }
    return '${number ?? "-"} - $n';
  }

  /// Localized currency word. In Persian / Arabic / Pashto we return
  /// the translated word; otherwise the currency code itself.
  String _currencyWord(String code, String language) {
    final upper = code.toUpperCase();
    if (upper == 'USD' || upper == 'AFN' || upper == 'EUR' || upper == 'CNY') {
      final key = 'ccy${upper[0]}${upper.substring(1).toLowerCase()}';
      final translated = tr(text: key, tr: language);
      if (translated != key) return translated;
    }
    return upper;
  }

  String _statusLabel(CashTxnDetail d, String language) {
    final s = d.stateText;
    if (s != null && s.isNotEmpty) {
      return tr(text: s.toLowerCase(), tr: language);
    }
    switch (d.status) {
      case 0:
        return tr(text: 'pending', tr: language);
      case 1:
        return tr(text: 'authorized', tr: language);
      case 2:
        return tr(text: 'reversed', tr: language);
      case 3:
        return tr(text: 'deleted', tr: language);
      default:
        return '-';
    }
  }

  /// Group thousands: "12345.6" -> "12,345.60"
  String _thousands(String raw) {
    final v = double.tryParse(raw.replaceAll(',', ''));
    if (v == null) return raw;
    final fixed = v.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final frac = parts.length > 1 ? parts[1] : '00';
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '$buf.$frac';
  }

  /// Loads the small PNG icons used in the header, once per document.
  Future<_ContactIcons> _loadContactIcons() async {
    Future<pw.ImageProvider?> load(String path) async {
      try {
        final data = await rootBundle.load(path);
        return pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        return null;
      }
    }

    return _ContactIcons(
      location: await load('assets/images/location.png'),
      phone: await load('assets/images/phone.png'),
      whatsapp: await load('assets/images/whatsapp.png'),
      email: await load('assets/images/email.png'),
      website: await load('assets/images/internet.png'),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Small holder for the contact icons
// ═════════════════════════════════════════════════════════════════

class _ContactIcons {
  final pw.ImageProvider? location;
  final pw.ImageProvider? phone;
  final pw.ImageProvider? whatsapp;
  final pw.ImageProvider? email;
  final pw.ImageProvider? website;

  const _ContactIcons({
    this.location,
    this.phone,
    this.whatsapp,
    this.email,
    this.website,
  });
}