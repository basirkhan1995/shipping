import 'package:equatable/equatable.dart';
import '../model/order_txn_model.dart';

sealed class OrdersTxnState extends Equatable {
  const OrdersTxnState();
  @override
  List<Object?> get props => const [];
}

class OrdersTxnEditing extends OrdersTxnState {
  final List<OrdersTxnRow> rows;
  final double totalDebit;
  final double totalCredit;

  /// e.g. "SALE", "PRCH" — loaded from the API on edit.
  final String? txnType;

  /// e.g. "2026-11-10 10:18:45" — loaded from the API on edit.
  final String? entryDate;

  /// Non-null when editing an existing transaction.
  final String? reference;

  /// 0 = pending, 1 = authorized
  final int? status;

  /// 'Pending' | 'Authorized' | 'Reversed' | 'Deleted'
  final String? stateText;

  /// Username of the transaction maker.
  final String? makerName;

  /// Header currency — display only. Rows carry their own currency
  /// and are NOT forced to match this. The API reconciles currencies.
  final String? headerCurrency;

  const OrdersTxnEditing({
    required this.rows,
    required this.totalDebit,
    required this.totalCredit,
    this.reference,
    this.status,
    this.stateText,
    this.makerName,
    this.headerCurrency,
    this.txnType,
    this.entryDate,
  });

  bool get isEditing => reference != null;
  bool get isPending => stateText == 'Pending';
  bool get isAuthorized => stateText == 'Authorized';
  bool get isReversed => stateText == 'Reversed';
  bool get isDeleted => stateText == 'Deleted';

  double get difference => totalDebit - totalCredit;
  bool get isBalanced => difference.abs() < 0.01;
  bool get isEmpty => rows.isEmpty;

  bool get hasNonZeroAmount => rows.any((r) => r.debit > 0 || r.credit > 0);
  bool get allAccountsSelected => rows.every((r) => r.accountNumber != null);

  // ── NO CURRENCY GATE ─────────────────────────────────────────
  // Mixed currencies are allowed. The API reconciles them.
  //
  // NOTE: `isBalanced` compares raw debit/credit totals across ALL
  // currencies, so a mixed-currency txn (Dr 13000 AFN / Cr 200 USD)
  // is NOT "balanced" by this check. If you want mixed-currency
  // submissions to pass client-side, drop `isBalanced &&` here.
  bool get canSubmit =>
      !isEmpty && allAccountsSelected && hasNonZeroAmount;
  // ^ intentionally NOT using isBalanced — the API owns the balance
  //   rule per currency. Restore `isBalanced &&` if you prefer the
  //   old behaviour.

  OrdersTxnEditing copyWith({
    List<OrdersTxnRow>? rows,
    double? totalDebit,
    double? totalCredit,
    String? reference,
    int? status,
    String? stateText,
    String? makerName,
    String? headerCurrency,
    String? txnType,
    String? entryDate,
  }) =>
      OrdersTxnEditing(
        rows: rows ?? this.rows,
        totalDebit: totalDebit ?? this.totalDebit,
        totalCredit: totalCredit ?? this.totalCredit,
        reference: reference ?? this.reference,
        status: status ?? this.status,
        stateText: stateText ?? this.stateText,
        makerName: makerName ?? this.makerName,
        headerCurrency: headerCurrency ?? this.headerCurrency,
        txnType: txnType ?? this.txnType,
        entryDate: entryDate ?? this.entryDate,
      );

  @override
  List<Object?> get props => [
    rows,
    totalDebit,
    totalCredit,
    reference,
    status,
    stateText,
    makerName,
    headerCurrency,
    txnType,
    entryDate,
  ];
}

class OrdersTxnSubmitting extends OrdersTxnEditing {
  const OrdersTxnSubmitting({
    required super.rows,
    required super.totalDebit,
    required super.totalCredit,
    super.reference,
    super.status,
    super.stateText,
    super.makerName,
    super.headerCurrency,
    super.txnType,     // ← was missing
    super.entryDate,   // ← was missing
  });
}

class OrdersTxnLoadingForEdit extends OrdersTxnState {
  const OrdersTxnLoadingForEdit();
}

class OrdersTxnSuccess extends OrdersTxnState {
  final String message;
  final String? reference;
  const OrdersTxnSuccess(this.message, {this.reference});
  @override
  List<Object?> get props => [message, reference];
}

class OrdersTxnFailure extends OrdersTxnState {
  final String message;
  final String? errorType;
  final List<OrdersTxnRow> rows;
  final String? reference;
  final int? status;
  final String? stateText;
  final String? makerName;
  final String? headerCurrency;
  final String? txnType;
  final String? entryDate;

  const OrdersTxnFailure(
      this.message, {
        this.errorType,
        required this.rows,
        this.reference,
        this.status,
        this.stateText,
        this.makerName,
        this.headerCurrency,
        this.txnType,
        this.entryDate,
      });

  @override
  List<Object?> get props => [
    message,
    errorType,
    rows,
    reference,
    status,
    stateText,
    makerName,
    headerCurrency,
    txnType,
    entryDate,
  ];
}

class OrdersTxnDeleted extends OrdersTxnState {
  final String reference;
  const OrdersTxnDeleted(this.reference);
  @override
  List<Object?> get props => [reference];
}