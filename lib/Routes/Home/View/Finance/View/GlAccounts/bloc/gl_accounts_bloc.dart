import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/localization_services.dart';
import '../../../../../../../Services/repository.dart';
import '../model/gl_model.dart';

part 'gl_accounts_event.dart';
part 'gl_accounts_state.dart';

class GlAccountsBloc extends Bloc<GlAccountsEvent, GlAccountsState> {
  final Repositories _repo;

  GlAccountsBloc(this._repo) : super(GlAccountsInitial()) {
    // ── LOAD ────────────────────────────────────────────────────
    on<LoadGlAccountEvent>((event, emit) async {
      emit(GlAccountsLoadingState());
      try {
        final gl = await _repo.getGl(input: event.query);
        emit(GlAccountLoadedState(gl));
      } on ApiException catch (e) {
        emit(GlAccountsErrorState(e.message));
      } catch (e) {
        emit(GlAccountsErrorState(e.toString()));
      }
    });

    // ── ADD ─────────────────────────────────────────────────────
    on<AddGlEvent>((event, emit) async {
      final tr = localizationService.loc;
      emit(GlAccountsLoadingState());
      try {
        await _repo.addGl(newAccount: event.newGl);
        emit(GlSuccessState());
        add(LoadGlAccountEvent());
      } on ApiException catch (e) {
        emit(GlAccountsErrorState(_messageFor(e, tr.accountExistMsg, tr.operationFailedMsg)));
      } catch (e) {
        emit(GlAccountsErrorState(e.toString()));
      }
    });

    // ── UPDATE ──────────────────────────────────────────────────
    on<UpdateGlEvent>((event, emit) async {
      final tr = localizationService.loc;
      emit(GlAccountsLoadingState());
      try {
        await _repo.editGl(newAccount: event.newGl);
        emit(GlSuccessState());
        add(LoadGlAccountEvent());
      } on ApiException catch (e) {
        emit(GlAccountsErrorState(_messageFor(e, tr.accountExistMsg, tr.operationFailedMsg)));
      } catch (e) {
        emit(GlAccountsErrorState(e.toString()));
      }
    });

    // ── DELETE ──────────────────────────────────────────────────
    on<DeleteGlEvent>((event, emit) async {
      final tr = localizationService.loc;
      emit(GlAccountsLoadingState());
      try {
        await _repo.deleteGl(accNumber: event.accNumber);
        emit(GlSuccessState());
        add(LoadGlAccountEvent());
      } on ApiException catch (e) {
        emit(GlAccountsErrorState(_messageForDelete(e, tr.glDependingMsg, tr.operationFailedMsg)));
      } catch (e) {
        emit(GlAccountsErrorState(e.toString()));
      }
    });
  }

  /// Maps an [ApiException] thrown by add/edit into a localized message.
  /// Falls back to the raw server message when the code isn't recognized.
  String _messageFor(ApiException e, String existMsg, String failedMsg) {
    // Read from `code` first (server sends {"code":"exist"} ideally),
    // then from `message` (older servers send {"msg":"exist"}).
    final code = (e.code ?? e.message).toLowerCase().trim();
    switch (code) {
      case 'exist':
      case 'exists':
      case 'duplicate':
        return existMsg;
      case 'failed':
      case 'failure':
        return failedMsg;
      default:
        return e.message;
    }
  }

  /// Delete has a different domain code — a GL account with children.
  String _messageForDelete(ApiException e, String dependentMsg, String failedMsg) {
    final code = (e.code ?? e.message).toLowerCase().trim();
    switch (code) {
      case 'dependent':
      case 'in_use':
      case 'has_children':
        return dependentMsg;
      case 'failed':
      case 'failure':
        return failedMsg;
      default:
        return e.message;
    }
  }
}