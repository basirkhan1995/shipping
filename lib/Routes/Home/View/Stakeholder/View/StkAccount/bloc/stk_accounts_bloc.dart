import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import 'stk_accounts_event.dart';
import 'stk_accounts_state.dart';

class StkAccountsBloc extends Bloc<StkAccountsEvent, StkAccountsState> {
  final Repositories _repo;

  StkAccountsBloc(this._repo) : super(const StkAccountsInitialState()) {
    on<LoadStkAccountsEvent>(_onLoad);
    on<SwitchStakeholderEvent>(_onSwitch);
    on<AddStkAccountEvent>(_onAdd);
    on<EditStkAccountEvent>(_onEdit);
    on<BlockStkAccountEvent>(_onBlock);
    on<UnblockStkAccountEvent>(_onUnblock);
    on<DeleteStkAccountEvent>(_onDelete);
    on<ClearStkAccountMessagesEvent>(_onClear);
  }

  // ════════════════════════════════════════════════════════════════
  // LOAD / SWITCH
  // ════════════════════════════════════════════════════════════════
  Future<void> _onLoad(
      LoadStkAccountsEvent e,
      Emitter<StkAccountsState> emit,
      ) async {
    await _load(
      perId: e.perId,
      search: e.query,
      emit: emit,
    );
  }

  Future<void> _onSwitch(
      SwitchStakeholderEvent e,
      Emitter<StkAccountsState> emit,
      ) async {
    await _load(perId: e.perId, emit: emit);
  }

  /// [perId]  null  → all accounts
  /// [search] null  → no search filter
  Future<void> _load({
    required int? perId,
    String? search,
    required Emitter<StkAccountsState> emit,
  }) async {
    emit(StkAccountsLoadingState(
      perId: perId,
      accounts: state.accounts,
    ));

    try {
      final accounts = await _repo.getAccounts(
        perId: perId,
        search: search,
      );
      emit(StkAccountsLoadedState(
        perId: perId,
        accounts: accounts,
      ));
    } on ApiException catch (e) {
      emit(StkAccountsFailureState(
        e.message,
        perId: perId,
        accounts: state.accounts,
      ));
    } catch (e) {
      emit(StkAccountsFailureState(
        e.toString(),
        perId: perId,
        accounts: state.accounts,
      ));
    }
  }

  // ════════════════════════════════════════════════════════════════
  // ADD
  // ════════════════════════════════════════════════════════════════
  Future<void> _onAdd(
      AddStkAccountEvent e,
      Emitter<StkAccountsState> emit,
      ) async {
    final perId = e.perId ?? state.perId;

    if (perId == null) {
      emit(StkAccountsFailureState(
        'Cannot add account — perId was not provided.',
        perId: state.perId,
        accounts: state.accounts,
      ));
      return;
    }

    try {
      await _repo.addAccount(
        accName: e.accName,
        actCurrency: e.actCurrency,
        actCreditLimit: e.actCreditLimit,
        actSignatory: perId,
      );
      final accounts = await _repo.getAccounts(perId: perId);
      emit(StkAccountsLoadedState(
        perId: perId,
        accounts: accounts,
        successMessage: 'Account created',
      ));
    } on ApiException catch (err) {
      emit(StkAccountsFailureState(
        err.message,
        perId: perId,
        accounts: state.accounts,
      ));
    } catch (err) {
      emit(StkAccountsFailureState(
        err.toString(),
        perId: perId,
        accounts: state.accounts,
      ));
    }
  }

  // ════════════════════════════════════════════════════════════════
  // EDIT
  // ════════════════════════════════════════════════════════════════
  Future<void> _onEdit(
      EditStkAccountEvent e,
      Emitter<StkAccountsState> emit,
      ) async {
    final perId = e.perId;

    try {
      await _repo.editAccount(
        accNumber: e.accNumber,
        accName: e.accName,
        actCurrency: e.actCurrency,
        actCreditLimit: e.actCreditLimit,
        actStatus: e.actStatus,
      );
      final accounts = await _repo.getAccounts(perId: perId);
      emit(StkAccountsLoadedState(
        perId: perId,
        accounts: accounts,
        successMessage: 'Account updated',
      ));
    } on ApiException catch (err) {
      emit(StkAccountsFailureState(
        err.message,
        perId: perId,
        accounts: state.accounts,
      ));
    } catch (err) {
      emit(StkAccountsFailureState(
        err.toString(),
        perId: perId,
        accounts: state.accounts,
      ));
    }
  }

  // ════════════════════════════════════════════════════════════════
  // BLOCK / UNBLOCK
  // ════════════════════════════════════════════════════════════════
  Future<void> _onBlock(
      BlockStkAccountEvent e,
      Emitter<StkAccountsState> emit,
      ) async {
    final perId = e.perId;
    try {
      await _repo.blockAccount(e.accNumber);
      final accounts = await _repo.getAccounts(perId: perId);
      emit(StkAccountsLoadedState(
        perId: perId,
        accounts: accounts,
        successMessage: 'Account blocked',
      ));
    } on ApiException catch (err) {
      emit(StkAccountsFailureState(
        err.message,
        perId: perId,
        accounts: state.accounts,
      ));
    } catch (err) {
      emit(StkAccountsFailureState(
        err.toString(),
        perId: perId,
        accounts: state.accounts,
      ));
    }
  }

  Future<void> _onUnblock(
      UnblockStkAccountEvent e,
      Emitter<StkAccountsState> emit,
      ) async {
    final perId = e.perId;
    try {
      await _repo.unblockAccount(e.accNumber);
      final accounts = await _repo.getAccounts(perId: perId);
      emit(StkAccountsLoadedState(
        perId: perId,
        accounts: accounts,
        successMessage: 'Account unblocked',
      ));
    } on ApiException catch (err) {
      emit(StkAccountsFailureState(
        err.message,
        perId: perId,
        accounts: state.accounts,
      ));
    } catch (err) {
      emit(StkAccountsFailureState(
        err.toString(),
        perId: perId,
        accounts: state.accounts,
      ));
    }
  }

  // ════════════════════════════════════════════════════════════════
  // DELETE
  // ════════════════════════════════════════════════════════════════
  Future<void> _onDelete(
      DeleteStkAccountEvent e,
      Emitter<StkAccountsState> emit,
      ) async {
    final perId = e.perId;
    try {
      await _repo.deleteAccount(e.accNumber);
      final accounts = await _repo.getAccounts(perId: perId);
      emit(StkAccountsLoadedState(
        perId: perId,
        accounts: accounts,
        successMessage: 'Account deleted',
      ));
    } on ApiException catch (err) {
      emit(StkAccountsFailureState(
        err.message,
        perId: perId,
        accounts: state.accounts,
      ));
    } catch (err) {
      emit(StkAccountsFailureState(
        err.toString(),
        perId: perId,
        accounts: state.accounts,
      ));
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CLEAR
  // ════════════════════════════════════════════════════════════════
  void _onClear(
      ClearStkAccountMessagesEvent _,
      Emitter<StkAccountsState> emit,
      ) {
    // Re-emit whatever the last data-bearing state was, minus messages.
    emit(StkAccountsLoadedState(
      perId: state.perId,
      accounts: state.accounts,
    ));
  }
}