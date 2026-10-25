// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hello_world => 'Hi! You set up intl!';

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get systemMode => 'System';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get selectAll => 'Select all';

  @override
  String get selectYear => 'Select year';

  @override
  String get selectKeyword => 'Select';

  @override
  String get today => 'Today';

  @override
  String get selectDate => 'Select Date';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get lastweek => 'Last week';

  @override
  String get lastMonth => 'Last month';

  @override
  String get allTime => 'All time';

  @override
  String get thisYear => 'This year';

  @override
  String get lastYear => 'Last year';

  @override
  String get lastThreeMonth => 'Last 90 Days';

  @override
  String get thisMonth => 'This month';

  @override
  String get current => 'Current';

  @override
  String get loginTitle => 'Login';

  @override
  String get usrName => 'Username';

  @override
  String get usrPass => 'Password';

  @override
  String required(String name) {
    return '$name is required';
  }

  @override
  String get rememberMe => 'Remember me';

  @override
  String get logout => 'Logout';

  @override
  String get accessDenied => 'Access Denied';

  @override
  String get confirmLogout => 'Are you sure you want to logout?';

  @override
  String get settings => 'Settings';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get prescription => 'Prescription';

  @override
  String get medicine => 'Medicine';

  @override
  String get report => 'Report';

  @override
  String get organization => 'Organization';

  @override
  String get update => 'Update';

  @override
  String get create => 'Create';

  @override
  String get editMedicine => 'Edit Medicine';

  @override
  String get newMedicine => 'New Medicine';

  @override
  String get medicineName => 'Medicine name';

  @override
  String get unit => 'Unit';

  @override
  String get dosage => 'Dosage';

  @override
  String get brand => 'Brand';

  @override
  String get category => 'Category';

  @override
  String get selectCategory => 'Select category';

  @override
  String get successTitle => 'Success';

  @override
  String get failed => 'Failed';

  @override
  String get noStock => 'Out of stock';

  @override
  String get dispense => 'Dispense';

  @override
  String get stock => 'Stock';

  @override
  String get patient => 'Patient';

  @override
  String get regNo => 'Register No';

  @override
  String get patientName => 'Patient name';

  @override
  String get age => 'Age';

  @override
  String get days => 'Days';

  @override
  String get instruction => 'Instruction';

  @override
  String get qty => 'Qty';

  @override
  String get prescriptions => 'Prescriptions';

  @override
  String get noPrescriptionToday => 'No prescription for today';

  @override
  String get systemSettings => 'System';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get emailOrUsername => 'Username or email';

  @override
  String get zaitoonTitle => 'Zaitoon';

  @override
  String get softwareCompany => 'Software company';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signIn => 'Sign In';

  @override
  String get shippingManagement => 'Shipping Management';

  @override
  String get sign_in_subtitle => 'Please sign in to continue.';

  @override
  String get email => 'Email';

  @override
  String get show_password => 'Show';

  @override
  String get hide_password => 'Hide';

  @override
  String get invalid_email => 'Invalid email';

  @override
  String get password_min_length => 'At least 4 characters';

  @override
  String get fill_all_fields => 'Please fill in all fields.';

  @override
  String get dont_have_account => 'Don\'t have an account?';

  @override
  String get contact_admin => 'Contact admin';

  @override
  String copyright(Object year) {
    return '© $year Zaitoon Software Company';
  }

  @override
  String get shipping_management => 'Shipping Management';

  @override
  String get shipping_subtitle => 'Sign in to manage shipments and routes.';

  @override
  String get software_company => 'Software Company';

  @override
  String get finance => 'Finance';

  @override
  String get hr => 'HR';

  @override
  String get stakeholders => 'Stakeholders';

  @override
  String get transactions => 'Transactions';

  @override
  String get shipment => 'Shipments';

  @override
  String get settingsHint => 'Manage your settings';

  @override
  String get noInternet =>
      'No internet connection. Please check your connection.';

  @override
  String get timeOutMessage => 'The request timed out. Please try again.';

  @override
  String get requestCancelMessage => 'The request was cancelled.';

  @override
  String get badRequest => 'Bad request. Please check your input.';

  @override
  String get unAuthorized => 'You are not authorized. Please log in again.';

  @override
  String get forbidden => 'Access forbidden. You don\'t have permission.';

  @override
  String get url404 => 'The requested resource was not found.';

  @override
  String get notAllowedError => 'Method not allowed.';

  @override
  String get internalServerError =>
      'Internal server error. Please try again later.';

  @override
  String get serviceUnavailable =>
      'Service unavailable. Please try again later.';

  @override
  String get serverError => 'Server error';

  @override
  String get networkError => 'Network error. Please try again.';

  @override
  String get incorrectCredential => 'username or password is incorrect';

  @override
  String get delete => 'Delete';

  @override
  String get submit => 'Submit';

  @override
  String get crop => 'Crop';

  @override
  String get rate => 'Rate';

  @override
  String get currencyTitle => 'Currency';

  @override
  String get refresh => 'Refresh';

  @override
  String get newKeyword => 'New';

  @override
  String get fxRate => 'Exchange Rate';

  @override
  String get accountExistMsg => 'Account already exist, try another name.';

  @override
  String get operationFailedMsg => 'Operation failed, try again later';

  @override
  String get glDependingMsg =>
      'Account has already been link with transactions.';

  @override
  String get asset => 'Asset';

  @override
  String get liability => 'Liability';

  @override
  String get income => 'income';

  @override
  String get expense => 'Expense';

  @override
  String get accountCategory => 'Account Category';

  @override
  String get all => 'All';

  @override
  String get noDataFound => 'No data found';

  @override
  String get accountNumber => 'Account number';

  @override
  String get accountName => 'Account name';

  @override
  String get edit => 'Edit';

  @override
  String get subCategory => 'Subcateogry';

  @override
  String get glAccount => 'GL Accounts';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get overview => 'Overview';

  @override
  String get branchLimit => 'Branch Limit';

  @override
  String get amount => 'Amount';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get branchName => 'Branch name';

  @override
  String get branchCode => 'Branch code';

  @override
  String get mobile1 => 'Mobile 1';

  @override
  String get zipCode => 'Zip code';

  @override
  String get country => 'Country';

  @override
  String get province => 'Province';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get profile => 'Profile';

  @override
  String get branch => 'Branch';

  @override
  String get storage => 'Storage';

  @override
  String get successMsg => 'Operation was successful.';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get baseCurrency => 'Base Currency';

  @override
  String get socialMedia => 'Social media';

  @override
  String get website => 'Website';

  @override
  String get facebook => 'Facebook';

  @override
  String get instagram => 'Instagram';

  @override
  String get location => 'Location';

  @override
  String get details => 'Details';

  @override
  String get status => 'Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get comDetails => 'Company details';

  @override
  String get addressHint => 'Manage your company address';

  @override
  String get socialMediaHint => 'Manage Social Profiles';

  @override
  String get companyDetailsHint => 'Manage company details';

  @override
  String get companyLicence => 'Company Licence';

  @override
  String get payableDue => 'Payable due';

  @override
  String get receivableDue => 'Receiveable due';

  @override
  String get dueType => 'Due type';

  @override
  String get filterByStatus => 'Filter by status';

  @override
  String get reminders => 'Reminders';

  @override
  String get dueDate => 'Due date';

  @override
  String get accounts => 'Accounts';

  @override
  String get accNameOrNumber => 'Account Name or Number';

  @override
  String get amountGreaterZero => 'Amount must greater than zero';

  @override
  String get account => 'Account';

  @override
  String get dueToday => 'Due today';

  @override
  String get dueTomorrow => 'Due tomorrow';

  @override
  String get day => 'Day';

  @override
  String get overdueBy => 'Overdue by';

  @override
  String get overdueByOne => 'Overdue by one day';

  @override
  String get noReminder => 'No reminder';

  @override
  String get done => 'Done';

  @override
  String get aboat => 'Aboat';

  @override
  String get company => 'Company';

  @override
  String get backup => 'Backup';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get fiscalYear => 'End of year';

  @override
  String get payroll => 'Payroll';

  @override
  String get manageFinance => 'Manage Company Finances';

  @override
  String get profitAndLoss => 'Profit & Loss';

  @override
  String get eoyClosing => 'Close Fiscal Year';

  @override
  String get summary => 'Financial Summary';

  @override
  String get noPandLMessage => 'No Profit & Loss';

  @override
  String get proceed => 'Proceed';

  @override
  String get retainedEarnings => 'Retained Earnings';

  @override
  String get remark => 'Remark';

  @override
  String get debit => 'Debit';

  @override
  String get credit => 'Credit';

  @override
  String get total => 'Total';

  @override
  String get attention => 'Attention';

  @override
  String get plMessage =>
      'Close Profit & Loss and transfer the balance to Retained Earnings?';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get profileOverview => 'Profile Overview';
}
