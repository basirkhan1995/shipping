import 'package:equatable/equatable.dart';
import '../../../model/stk_model.dart';

abstract class StkAccountsState extends Equatable {
  final int? perId;
  final List<StakeholderAccount> accounts;
  final String? successMessage;
  final String? errorMessage;

  const StkAccountsState({
    this.perId,
    this.accounts = const [],
    this.successMessage,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [perId, accounts, successMessage, errorMessage];

  bool get isLoading => this is StkAccountsLoadingState;
}

class StkAccountsInitialState extends StkAccountsState {
  const StkAccountsInitialState();
}

class StkAccountsLoadingState extends StkAccountsState {
  const StkAccountsLoadingState({
    super.perId,
    super.accounts,
  });
}

class StkAccountsLoadedState extends StkAccountsState {
  const StkAccountsLoadedState({
    super.perId,
    required super.accounts,
    super.successMessage,
    super.errorMessage,
  });
}

class StkAccountsFailureState extends StkAccountsState {
  const StkAccountsFailureState(
      String message, {
        super.perId,
        super.accounts,
      }) : super(errorMessage: message);
}