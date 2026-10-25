import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:typed_data';
import '../../../../../../../../Services/api_exception.dart';
import '../../../../../../../../Services/repository.dart';
import '../model/com_model.dart';


part 'company_profile_event.dart';
part 'company_profile_state.dart';

class CompanyProfileBloc
    extends Bloc<CompanyProfileEvent, CompanyProfileState> {
  final Repositories _repo;

  CompanyProfileBloc(this._repo) : super(CompanyProfileInitial()) {
    // ── LOAD ────────────────────────────────────────────────────────
    on<LoadCompanyProfileEvent>((event, emit) async {
      emit(CompanyProfileLoadingState());
      try {
        final com = await _repo.getCompanyProfile();
        emit(CompanyProfileLoadedState(com));
      } on ApiException catch (e) {
        emit(CompanyProfileErrorState(e.message));
      } catch (e) {
        emit(CompanyProfileErrorState(e.toString()));
      }
    });

    // ── UPDATE ──────────────────────────────────────────────────────
    on<UpdateCompanyProfileEvent>((event, emit) async {
      emit(CompanyProfileLoadingState());
      try {
        await _repo.editCompanyProfile(newData: event.company);
        emit(CompanyProfileSuccessState());
        add(LoadCompanyProfileEvent());
      } on ApiException catch (e) {
        emit(CompanyProfileErrorState(e.message));
      } catch (e) {
        emit(CompanyProfileErrorState(e.toString()));
      }
    });

    // ── UPLOAD LOGO ─────────────────────────────────────────────────
    on<UploadCompanyLogoEvent>((event, emit) async {
      emit(CompanyProfileLoadingState());
      try {
        await _repo.uploadCompanyProfile(image: event.image);
        emit(CompanyProfileSuccessState());
        add(LoadCompanyProfileEvent());
      } on ApiException catch (e) {
        emit(CompanyProfileErrorState(e.message));
      } catch (e) {
        emit(CompanyProfileErrorState(e.toString()));
      }
    });
  }
}