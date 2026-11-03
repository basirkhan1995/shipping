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

    final bytes = await document.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${data.reference ?? "voucher"}.pdf',
    );
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
    required bool isRtl,
  }) {
    return pw.Column(
      children: [
        _singleVoucher(
          data: data,
          language: language,
          report: report,
          logo: logo,
          isRtl: isRtl,
          isCopy: false,
        ),
        pw.SizedBox(height: isRtl ? 3 : 16),
        _cutLine(language, isRtl),
        pw.SizedBox(height: isRtl ? 3 : 16),
        _singleVoucher(
          data: data,
          language: language,
          report: report,
          logo: logo,
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
    required bool isRtl,
    required bool isCopy,
  }) {
    final subject = data.subjectLine;
    final contra = data.contraLine;

    // Amount comes from the subject leg (or contra as fallback).
    final amountStr =
        subject?.amountDisplay ?? contra?.amountDisplay ?? '0.00';
    final ccy = (subject?.ccy ?? contra?.ccy ?? '').toUpperCase();
    final amountText = '${_thousands(amountStr)} $ccy';

    // ── Amount in words (currency-word localized) ──────────
    final amtDouble = double.tryParse(amountStr.replaceAll(',', '')) ?? 0;
    final wordsLang = NumberToWords.getLanguageFromLocale(Locale(language));
    final ccyWord = _currencyWord(ccy, language);
    final amountWords =
        '${NumberToWords.convert(amtDouble.round(), wordsLang)} $ccyWord';

    final voucherDate =
        '${data.entryDate?.toFullDateTime} | ${data.entryDate?.shamsiDateString}';

    // Account display: only the subject side.
    final accountValue =
    subject == null ? '-' : '${subject.trdAccount ?? "-"}';

    // Dynamic voucher title per type.
    final titleKey = _titleKey(data);
    final titleText = tr(text: titleKey, tr: language).toUpperCase();

    return pw.Stack(
      children: [
        // ── Watermark ──────────────────────────────────────
        if (logo != null)
          pw.Positioned.fill(
            child: pw.Center(
              child: pw.Opacity(
                opacity: 0.06,
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
            border: pw.Border.all(width: 1.5, color: PdfColors.blueGrey800),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // ── Company header ───────────────────────────
              _companyHeader(report, logo, isRtl, language),

              pw.SizedBox(height: isRtl ? 5 : 8),
              pw.Container(height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: isRtl ? 5 : 8),

              // ── Title + date ─────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      zText(
                        text: titleText,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: isRtl ? 16 : 17,
                        color: PdfColors.blueGrey900,
                      ),
                      if (isCopy) ...[
                        pw.SizedBox(width: isRtl ? 8 : 10),
                        pw.Container(
                          padding: pw.EdgeInsets.symmetric(
                            horizontal: isRtl ? 8 : 10,
                          ),
                          color: PdfColors.blueGrey50,
                          child: zText(
                            text: tr(text: 'copy', tr: language).toUpperCase(),
                            fontSize: isRtl ? 9 : 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                      ],
                    ],
                  ),
                  _labelValue(
                    label: tr(text: 'date', tr: language),
                    value: voucherDate,
                    isRtl: isRtl,
                    labelSize: isRtl ? 10 : 11,
                    valueSize: isRtl ? 10 : 11,
                    labelColor: PdfColors.blueGrey700,
                    valueColor: PdfColors.blueGrey700,
                    boldLabel: false,
                  ),
                ],
              ),

              pw.SizedBox(height: isRtl ? 6 : 7),

              // ── Header fields ────────────────────────────
              _kvRow(
                tr(text: 'trnType', tr: language),
                tr(text: data.type ?? '-', tr: language),
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

              pw.SizedBox(height: isRtl ? 3 : 4),

              // ── Narration ────────────────────────────────
              _kvRow(
                tr(text: 'narration', tr: language),
                subject?.narration ?? '-',
                isRtl,
              ),

              pw.SizedBox(height: isRtl ? 3 : 4),

              // ── Amount banner ────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.symmetric(
                  vertical: isRtl ? 3 : 2,
                  horizontal: isRtl ? 8 : 10,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1, color: PdfColors.blueGrey100),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    zText(
                      text: '${tr(text: 'amount', tr: language)}:',
                      fontSize: isRtl ? 11 : 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: zText(
                        text: amountText,
                        fontSize: isRtl ? 15 : 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: isRtl ? 3 : 0),

              // ── Amount in words ──────────────────────────
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(isRtl ? 7 : 3),
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

  // ═════════════════════════════════════════════════════════════
  // PIECES
  // ═════════════════════════════════════════════════════════════

  pw.Widget _companyHeader(
      ReportModel report,
      pw.ImageProvider? logo,
      bool isRtl,
      String language,
      ) {
    final name = (report.comName ?? '').trim();
    final address = (report.comAddress ?? '').trim();

    // Build each contact pair as a separate widget so phone numbers
    // don't reverse in RTL — labels use tr().
    final phone = (report.compPhone ?? '').trim();
    final whatsapp = (report.comWhatsApp ?? '').trim();
    final email = (report.comEmail ?? '').trim();

    return pw.SizedBox(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo — small, leading edge.
          if (logo != null)
            pw.Container(
              width: 70,
              height: 70,
              margin: pw.EdgeInsets.only(
                right: isRtl ? 0 : 10,
                left: isRtl ? 10 : 0,
              ),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),

          // Company info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: isRtl
                  ? pw.CrossAxisAlignment.start
                  : pw.CrossAxisAlignment.end,
              children: [
                if (name.isNotEmpty)
                  zText(
                    text: name,
                    fontSize: isRtl ? 18 : 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                if (address.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  zText(
                    text: address,
                    fontSize: isRtl ? 8.5 : 9,
                    color: PdfColors.grey700,
                  ),
                ],
                if (phone.isNotEmpty ||
                    whatsapp.isNotEmpty ||
                    email.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 2,
                    alignment: isRtl
                        ? pw.WrapAlignment.end
                        : pw.WrapAlignment.start,
                    children: [
                      if (phone.isNotEmpty)
                        _labelValue(
                          label: tr(text: 'tel', tr: language),
                          value: phone,
                          isRtl: isRtl,
                          labelSize: isRtl ? 8.5 : 8.5,
                          valueSize: isRtl ? 8.5 : 8.5,
                          labelColor: PdfColors.grey600,
                          valueColor: PdfColors.grey700,
                          boldLabel: false,
                        ),
                      if (whatsapp.isNotEmpty)
                        _labelValue(
                          label: 'WhatsApp',
                          value: whatsapp,
                          isRtl: isRtl,
                          labelSize: isRtl ? 8.5 : 8.5,
                          valueSize: isRtl ? 8.5 : 8.5,
                          labelColor: PdfColors.grey600,
                          valueColor: PdfColors.grey700,
                          boldLabel: false,
                        ),
                      if (email.isNotEmpty)
                        _labelValue(
                          label: 'Email',
                          value: email,
                          isRtl: isRtl,
                          labelSize: isRtl ? 8.5 : 8.5,
                          valueSize: isRtl ? 8.5 : 8.5,
                          labelColor: PdfColors.grey600,
                          valueColor: PdfColors.grey700,
                          boldLabel: false,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  /// Renders "Label: value" where the label and the value can each be
  /// laid out in their natural script direction. Prevents numbers /
  /// emails / dates from being reversed inside an RTL line.
  pw.Widget _labelValue({
    required String label,
    required String value,
    required bool isRtl,
    double labelSize = 10,
    double valueSize = 10,
    PdfColor? labelColor,
    PdfColor? valueColor,
    bool boldLabel = true,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        zText(
          text: '$label:',
          fontSize: labelSize,
          fontWeight: boldLabel ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: labelColor ?? PdfColors.grey700,
        ),
        pw.SizedBox(width: 3),
        // Force LTR for the value so digits, dates, emails, and
        // reference codes never get reversed in RTL.
        pw.Directionality(
          textDirection: pw.TextDirection.ltr,
          child: zText(
            text: value,
            fontSize: valueSize,
            color: valueColor ?? PdfColors.grey900,
          ),
        ),
      ],
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
          data.subjectLine?.trdAccount?.toString() ?? '___________',
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

  /// Pick the voucher title key by transaction type, with a Dr/Cr
  /// fallback when the type is unknown.
  String _titleKey(CashTxnDetail d) {
    final t = (d.type ?? '').toUpperCase();

    // Cash Deposit
    if (t.contains('CHDP') || t.contains('CDP')) {
      return 'cashReceipt';
    }
    // Cash Withdraw / Withdrawal
    if (t.contains('CHWL') ||
        t.contains('CHWD') ||
        t.contains('CWL') ||
        t.contains('CWD')) {
      return 'cashPayment';
    }
    // Expense
    if (t.contains('XNPS') || t.contains('EXP')) {
      return 'expenseV';
    }
    // Income
    if (t.contains('INCM') || t.contains('INC')) {
      return 'income';
    }

    // Fallback by Dr/Cr side of the subject leg.
    final subject = d.subjectLine;
    if (subject != null && subject.isCredit) {
      return 'cashReceipt'; // money came IN
    }
    return 'cashPayment'; // money went OUT
  }

  /// Localized currency word. In Persian (and Arabic/Pshto as they
  /// share the same tr() entries) we return the translated word;
  /// otherwise the currency code itself is returned.
  String _currencyWord(String code, String language) {
    final upper = code.toUpperCase();
    // Only the four supported codes get a translated word.
    if (upper == 'USD' || upper == 'AFN' || upper == 'EUR' || upper == 'CNY') {
      final key = 'ccy${upper[0]}${upper.substring(1).toLowerCase()}';
      // keys: ccyUsd, ccyAfn, ccyEur, ccyCny
      final translated = tr(text: key, tr: language);
      // tr() returns the key unchanged if not found — guard against that.
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
}