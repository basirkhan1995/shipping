// ============================================================
// lib/models/shipping_invoice.dart
// Models for POST /shippingInvoicePrint.php
// ============================================================

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String? _toStr(dynamic v) => v?.toString();

class ShippingInvoice {
  final Customer customer;
  final ContainerInfo container;
  final List<InvoiceItem> items;
  final InvoiceTotals totals;
  final InvoiceMeta meta;

  ShippingInvoice({
    required this.customer,
    required this.container,
    required this.items,
    required this.totals,
    required this.meta,
  });

  factory ShippingInvoice.fromJson(Map<String, dynamic> json) {
    return ShippingInvoice(
      customer: Customer.fromJson(
          (json['customer'] as Map?)?.cast<String, dynamic>() ?? {}),
      container: ContainerInfo.fromJson(
          (json['container'] as Map?)?.cast<String, dynamic>() ?? {}),
      items: ((json['items'] as List?) ?? const [])
          .map((e) => InvoiceItem.fromJson(
          (e as Map).cast<String, dynamic>()))
          .toList(),
      totals: InvoiceTotals.fromJson(
          (json['totals'] as Map?)?.cast<String, dynamic>() ?? {}),
      meta: InvoiceMeta.fromJson(
          (json['meta'] as Map?)?.cast<String, dynamic>() ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'customer': customer.toJson(),
    'container': container.toJson(),
    'items': items.map((e) => e.toJson()).toList(),
    'totals': totals.toJson(),
    'meta': meta.toJson(),
  };
}

// ============================================================
// Customer
// ============================================================
class Customer {
  final int accountNo;
  final String? accountName;
  final String? currency;
  final double creditLimit;
  final PersonInfo person;
  final AddressInfo address;

  Customer({
    required this.accountNo,
    required this.accountName,
    required this.currency,
    required this.creditLimit,
    required this.person,
    required this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      accountNo: _toInt(json['accountNo']),
      accountName: _toStr(json['accountName']),
      currency: _toStr(json['currency']),
      creditLimit: _toDouble(json['creditLimit']),
      person: PersonInfo.fromJson(
          (json['person'] as Map?)?.cast<String, dynamic>() ?? {}),
      address: AddressInfo.fromJson(
          (json['address'] as Map?)?.cast<String, dynamic>() ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'accountNo': accountNo,
    'accountName': accountName,
    'currency': currency,
    'creditLimit': creditLimit,
    'person': person.toJson(),
    'address': address.toJson(),
  };
}

class PersonInfo {
  final int? id;
  final String? code;
  final String? fullName;
  final String? phone;
  final String? email;

  PersonInfo({
    this.id,
    this.code,
    this.fullName,
    this.phone,
    this.email,
  });

  factory PersonInfo.fromJson(Map<String, dynamic> json) => PersonInfo(
    id: json['id'] == null ? null : _toInt(json['id']),
    code: _toStr(json['code']),
    fullName: _toStr(json['fullName']),
    phone: _toStr(json['phone']),
    email: _toStr(json['email']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'fullName': fullName,
    'phone': phone,
    'email': email,
  };
}

class AddressInfo {
  final String? name;
  final String? city;
  final String? province;
  final String? country;
  final String? zipCode;

  AddressInfo({
    this.name,
    this.city,
    this.province,
    this.country,
    this.zipCode,
  });

  factory AddressInfo.fromJson(Map<String, dynamic> json) => AddressInfo(
    name: _toStr(json['name']),
    city: _toStr(json['city']),
    province: _toStr(json['province']),
    country: _toStr(json['country']),
    zipCode: _toStr(json['zipCode']),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'city': city,
    'province': province,
    'country': country,
    'zipCode': zipCode,
  };
}

// ============================================================
// Container
// ============================================================
class ContainerInfo {
  final int shpId;
  final String? portName;
  final String? containerNo;
  final String? sequenceNo;
  final String? loadingDate;
  final String? unloadingDate;
  final String? description;
  final String? status;
  final String? entryDate;
  final String? createdBy;

  ContainerInfo({
    required this.shpId,
    this.portName,
    this.containerNo,
    this.sequenceNo,
    this.loadingDate,
    this.unloadingDate,
    this.description,
    this.status,
    this.entryDate,
    this.createdBy,
  });

  factory ContainerInfo.fromJson(Map<String, dynamic> json) => ContainerInfo(
    shpId: _toInt(json['shpId']),
    portName: _toStr(json['portName']),
    containerNo: _toStr(json['containerNo']),
    sequenceNo: _toStr(json['sequenceNo']),
    loadingDate: _toStr(json['loadingDate']),
    unloadingDate: _toStr(json['unloadingDate']),
    description: _toStr(json['description']),
    status: _toStr(json['status']),
    entryDate: _toStr(json['entryDate']),
    createdBy: _toStr(json['createdBy']),
  );

  Map<String, dynamic> toJson() => {
    'shpId': shpId,
    'portName': portName,
    'containerNo': containerNo,
    'sequenceNo': sequenceNo,
    'loadingDate': loadingDate,
    'unloadingDate': unloadingDate,
    'description': description,
    'status': status,
    'entryDate': entryDate,
    'createdBy': createdBy,
  };
}

// ============================================================
// Item
// ============================================================
class InvoiceItem {
  final int shpItmId;
  final String? itemDescription;
  final int qty;
  final double cbm;
  final double weight;
  final double weightAVG;
  final double ratePerCbm;
  final double ratePerWeight;
  final double extraCharges;
  final double itemRent;
  final String? status;
  final String? entryDate;
  final String? updatedAt;

  InvoiceItem({
    required this.shpItmId,
    this.itemDescription,
    required this.qty,
    required this.cbm,
    required this.weight,
    required this.weightAVG,
    required this.ratePerCbm,
    required this.ratePerWeight,
    required this.extraCharges,
    required this.itemRent,
    this.status,
    this.entryDate,
    this.updatedAt,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
    shpItmId: _toInt(json['shpItmId']),
    itemDescription: _toStr(json['itemDescription']),
    qty: _toInt(json['qty']),
    cbm: _toDouble(json['cbm']),
    weight: _toDouble(json['weight']),
    weightAVG: _toDouble(json['weightAVG']),
    ratePerCbm: _toDouble(json['ratePerCbm']),
    ratePerWeight: _toDouble(json['ratePerWeight']),
    extraCharges: _toDouble(json['extraCharges']),
    itemRent: _toDouble(json['itemRent']),
    status: _toStr(json['status']),
    entryDate: _toStr(json['entryDate']),
    updatedAt: _toStr(json['updatedAt']),
  );

  Map<String, dynamic> toJson() => {
    'shpItmId': shpItmId,
    'itemDescription': itemDescription,
    'qty': qty,
    'cbm': cbm,
    'weight': weight,
    'weightAVG': weightAVG,
    'ratePerCbm': ratePerCbm,
    'ratePerWeight': ratePerWeight,
    'extraCharges': extraCharges,
    'itemRent': itemRent,
    'status': status,
    'entryDate': entryDate,
    'updatedAt': updatedAt,
  };
}

// ============================================================
// Totals
// ============================================================
class InvoiceTotals {
  final int items;
  final int qty;
  final double cbm;
  final double weight;
  final double extraCharges;
  final double totalRent;
  final String? currency;

  InvoiceTotals({
    required this.items,
    required this.qty,
    required this.cbm,
    required this.weight,
    required this.extraCharges,
    required this.totalRent,
    this.currency,
  });

  factory InvoiceTotals.fromJson(Map<String, dynamic> json) => InvoiceTotals(
    items: _toInt(json['items']),
    qty: _toInt(json['qty']),
    cbm: _toDouble(json['cbm']),
    weight: _toDouble(json['weight']),
    extraCharges: _toDouble(json['extraCharges']),
    totalRent: _toDouble(json['totalRent']),
    currency: _toStr(json['currency']),
  );

  Map<String, dynamic> toJson() => {
    'items': items,
    'qty': qty,
    'cbm': cbm,
    'weight': weight,
    'extraCharges': extraCharges,
    'totalRent': totalRent,
    'currency': currency,
  };
}

// ============================================================
// Meta
// ============================================================
class InvoiceMeta {
  final String? generatedAt;

  InvoiceMeta({this.generatedAt});

  factory InvoiceMeta.fromJson(Map<String, dynamic> json) =>
      InvoiceMeta(generatedAt: _toStr(json['generatedAt']));

  Map<String, dynamic> toJson() => {'generatedAt': generatedAt};
}

class PrintInvoiceRequest {
  final String accountNo;
  final String? containerNo;
  final String? sequenceNo;

  const PrintInvoiceRequest({
    required this.accountNo,
    this.containerNo,
    this.sequenceNo,
  });

  /// Throws [ArgumentError] early so the bloc can surface a clean message
  /// instead of bouncing off the server.
  void validate() {
    if (accountNo.trim().isEmpty) {
      throw ArgumentError('accountNo is required');
    }
    final hasContainer =
        containerNo != null && containerNo!.trim().isNotEmpty;
    final hasSequence = sequenceNo != null && sequenceNo!.trim().isNotEmpty;
    if (!hasContainer && !hasSequence) {
      throw ArgumentError(
        'At least one of containerNo or sequenceNo is required',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'accountNo': accountNo.trim(),
    if (containerNo != null && containerNo!.trim().isNotEmpty)
      'containerNo': containerNo!.trim(),
    if (sequenceNo != null && sequenceNo!.trim().isNotEmpty)
      'sequenceNo': sequenceNo!.trim(),
  };
}