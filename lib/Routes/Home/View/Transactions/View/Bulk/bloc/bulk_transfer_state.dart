import 'package:equatable/equatable.dart';
import '../model/bulk_model.dart';

sealed class BulkTransferState extends Equatable {
  const BulkTransferState();
  @override
  List<Object?> get props => const [];
}

class BulkTransferEditing extends BulkTransferState {
  final List<BulkTransferRow> rows;
  final double totalDebit;
  final double totalCredit;

  /// Non-null when the dialog is editing an existing transaction.
  final String? reference;

  /// 0 = pending, 1 = authorized
  final int? status;
  /// 'Pending' | 'Authorized' | 'Reversed' | 'Deleted'
  final String? stateText;
  /// Username of the transaction maker.
  final String? makerName;

  const BulkTransferEditing({
    required this.rows,
    required this.totalDebit,
    required this.totalCredit,
    this.reference,
    this.status,
    this.stateText,
    this.makerName,
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
  bool get noMixedAmounts =>
      rows.every((r) => !(r.debit > 0 && r.credit > 0));

  Set<String> get rowCurrencies => rows
      .map((r) => r.currency)
      .whereType<String>()
      .where((c) => c.isNotEmpty)
      .toSet();

  bool get hasCurrencyMix => rowCurrencies.length > 1;

  bool get canSubmit =>
      !isEmpty &&
          isBalanced &&
          allAccountsSelected &&
          hasNonZeroAmount &&
          noMixedAmounts &&
          !hasCurrencyMix;

  BulkTransferEditing copyWith({
    List<BulkTransferRow>? rows,
    double? totalDebit,
    double? totalCredit,
    String? reference,
    int? status,
    String? stateText,
    String? makerName,
  }) =>
      BulkTransferEditing(
        rows: rows ?? this.rows,
        totalDebit: totalDebit ?? this.totalDebit,
        totalCredit: totalCredit ?? this.totalCredit,
        reference: reference ?? this.reference,
        status: status ?? this.status,
        stateText: stateText ?? this.stateText,
        makerName: makerName ?? this.makerName,
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
  ];
}

class BulkTransferSubmitting extends BulkTransferEditing {
  const BulkTransferSubmitting({
    required super.rows,
    required super.totalDebit,
    required super.totalCredit,
    super.reference,
    super.status,
    super.stateText,
    super.makerName,
  });
}

/// Loading an existing reference for edit.
class BulkTransferLoadingForEdit extends BulkTransferState {
  const BulkTransferLoadingForEdit();
}

class BulkTransferSuccess extends BulkTransferState {
  final String message;
  final String? reference;
  const BulkTransferSuccess(this.message, {this.reference});
  @override
  List<Object?> get props => [message, reference];
}

class BulkTransferFailure extends BulkTransferState {
  final String message;
  final String? errorType;
  final List<BulkTransferRow> rows;
  final String? reference;
  final int? status;
  final String? stateText;
  final String? makerName;

  const BulkTransferFailure(
      this.message, {
        this.errorType,
        required this.rows,
        this.reference,
        this.status,
        this.stateText,
        this.makerName,
      });

  @override
  List<Object?> get props =>
      [message, errorType, rows, reference, status, stateText, makerName];
}

class BulkTransferDeleted extends BulkTransferState {
  final String reference;
  const BulkTransferDeleted(this.reference);
  @override
  List<Object?> get props => [reference];
}