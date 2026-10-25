part of 'company_profile_bloc.dart';

sealed class CompanyProfileState extends Equatable {
  const CompanyProfileState();
}

final class CompanyProfileInitial extends CompanyProfileState {
  @override
  List<Object> get props => [];
}

final class CompanyProfileLoadingState extends CompanyProfileState{
  @override
  List<Object> get props => [];
}

final class CompanyProfileSuccessState extends CompanyProfileState{
  @override
  List<Object> get props => [];
}

final class CompanyProfileErrorState extends CompanyProfileState{
  final String message;
  const CompanyProfileErrorState(this.message);
  @override
  List<Object> get props => [message];
}

final class CompanyProfileLoadedState extends CompanyProfileState {
  final CompanySettingsModel company;
  const CompanyProfileLoadedState(this.company);
  @override
  List<Object> get props => [company];
}
