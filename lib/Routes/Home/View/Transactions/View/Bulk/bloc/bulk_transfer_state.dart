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

  const BulkTransferEditing({
    required this.rows,
    required this.totalDebit,
    required this.totalCredit,
  });

  double get difference => totalDebit - totalCredit;
  bool get isBalanced => difference.abs() < 0.01;
  bool get isEmpty => rows.isEmpty;

  bool get hasNonZeroAmount => rows.any((r) => r.debit > 0 || r.credit > 0);
  bool get allAccountsSelected => rows.every((r) => r.accountNumber != null);
  bool get noMixedAmounts =>
      rows.every((r) => !(r.debit > 0 && r.credit > 0));

  /// Unique currencies currently represented in the rows.
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

  @override
  List<Object?> get props => [rows, totalDebit, totalCredit];
}

class BulkTransferSubmitting extends BulkTransferEditing {
  const BulkTransferSubmitting({
    required super.rows,
    required super.totalDebit,
    required super.totalCredit,
  });

  @override
  List<Object?> get props => [rows, totalDebit, totalCredit];
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
  /// Mirrors the PHP error codes: no limit / blocked / diff ccy / failed.
  final String? errorType;
  final List<BulkTransferRow> rows;

  const BulkTransferFailure(
      this.message, {
        this.errorType,
        required this.rows,
      });

  @override
  List<Object?> get props => [message, errorType, rows];
}