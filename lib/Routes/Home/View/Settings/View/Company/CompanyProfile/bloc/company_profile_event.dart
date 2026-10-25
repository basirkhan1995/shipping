part of 'company_profile_bloc.dart';

sealed class CompanyProfileEvent extends Equatable {
  const CompanyProfileEvent();
}

class LoadCompanyProfileEvent extends CompanyProfileEvent{
  @override
  List<Object> get props => [];
}

class UpdateCompanyProfileEvent extends CompanyProfileEvent{
  final CompanySettingsModel company;
  const UpdateCompanyProfileEvent(this.company);
  @override
  List<Object> get props => [company];
}

class UploadCompanyLogoEvent extends CompanyProfileEvent{
  final Uint8List image;
  const UploadCompanyLogoEvent(this.image);
  @override
  List<Object> get props => [image];
}