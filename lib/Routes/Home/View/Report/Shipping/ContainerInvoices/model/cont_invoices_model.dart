import 'package:equatable/equatable.dart';
import '../../InvoicePrint/model/inv_print_model.dart';

// ═══════════════════════════════════════════════════════════════════
// ContainerInvoices — batch response wrapper
// ═══════════════════════════════════════════════════════════════════
class ContainerInvoices extends Equatable {
  final int shpId;
  final String? containerNo;
  final String? sequenceNo;
  final int count;
  final List<ShippingInvoice> invoices;

  /// The full shared container block (portName, loadingDate, status, ...).
  /// Kept here so the UI can show a single header for all invoices.
  final Map<String, dynamic> container;

  const ContainerInvoices({
    required this.shpId,
    required this.containerNo,
    required this.sequenceNo,
    required this.count,
    required this.invoices,
    required this.container,
  });

  factory ContainerInvoices.fromJson(Map<String, dynamic> j) {
    // Full container block sent once at the top level.
    final rawContainer =
        (j['container'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    final rawInvoices = (j['invoices'] as List?) ?? const [];

    final list = rawInvoices.whereType<Map>().map((e) {
      // Copy each invoice map so we can inject `container` + `meta`
      // without mutating the decoded JSON.
      final invoiceMap = Map<String, dynamic>.from(e);

      // Server sends `container` once at the top level, but
      // ShippingInvoice.fromJson expects it per invoice.
      invoiceMap['container'] = rawContainer;

      // Backfill per-invoice meta from top-level if the server ever omits it.
      invoiceMap['meta'] ??= j['meta'];

      return ShippingInvoice.fromJson(invoiceMap);
    }).toList();

    return ContainerInvoices(
      shpId: (rawContainer['shpId'] as num?)?.toInt() ?? 0,
      containerNo: rawContainer['containerNo'] as String?,
      sequenceNo: rawContainer['sequenceNo'] as String?,
      count: (j['count'] as num?)?.toInt() ?? list.length,
      invoices: list,
      container: rawContainer,
    );
  }

  @override
  List<Object?> get props =>
      [shpId, containerNo, sequenceNo, count, invoices, container];
}

// ═══════════════════════════════════════════════════════════════════
// ContainerInvoiceRequest — outgoing request body
// ═══════════════════════════════════════════════════════════════════
class ContainerInvoiceRequest extends Equatable {
  final String? containerNo;
  final String? sequenceNo;

  const ContainerInvoiceRequest({this.containerNo, this.sequenceNo});

  /// Fail fast before hitting the network — mirrors
  /// [PrintInvoiceRequest.validate].
  void validate() {
    final c = containerNo?.trim() ?? '';
    final s = sequenceNo?.trim() ?? '';
    if (c.isEmpty && s.isEmpty) {
      throw ArgumentError(
        'At least one of containerNo or sequenceNo is required.',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    if (containerNo != null && containerNo!.trim().isNotEmpty)
      'containerNo': containerNo!.trim(),
    if (sequenceNo != null && sequenceNo!.trim().isNotEmpty)
      'sequenceNo': sequenceNo!.trim(),
  };

  @override
  List<Object?> get props => [containerNo, sequenceNo];
}