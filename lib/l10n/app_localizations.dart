import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @hello_world.
  ///
  /// In en, this message translates to:
  /// **'Hi! You set up intl!'**
  String get hello_world;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @selectYear.
  ///
  /// In en, this message translates to:
  /// **'Select year'**
  String get selectYear;

  /// No description provided for @selectKeyword.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectKeyword;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @lastweek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get lastweek;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get thisYear;

  /// No description provided for @lastYear.
  ///
  /// In en, this message translates to:
  /// **'Last year'**
  String get lastYear;

  /// No description provided for @lastThreeMonth.
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get lastThreeMonth;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @usrName.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usrName;

  /// No description provided for @usrPass.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get usrPass;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'{name} is required'**
  String required(String name);

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDenied;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @prescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescription;

  /// No description provided for @medicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medicine;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @editMedicine.
  ///
  /// In en, this message translates to:
  /// **'Edit Medicine'**
  String get editMedicine;

  /// No description provided for @newMedicine.
  ///
  /// In en, this message translates to:
  /// **'New Medicine'**
  String get newMedicine;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine name'**
  String get medicineName;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successTitle;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @noStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get noStock;

  /// No description provided for @dispense.
  ///
  /// In en, this message translates to:
  /// **'Dispense'**
  String get dispense;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @regNo.
  ///
  /// In en, this message translates to:
  /// **'Register No'**
  String get regNo;

  /// No description provided for @patientName.
  ///
  /// In en, this message translates to:
  /// **'Patient name'**
  String get patientName;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @instruction.
  ///
  /// In en, this message translates to:
  /// **'Instruction'**
  String get instruction;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @prescriptions.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptions;

  /// No description provided for @noPrescriptionToday.
  ///
  /// In en, this message translates to:
  /// **'No prescription for today'**
  String get noPrescriptionToday;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemSettings;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Username or email'**
  String get emailOrUsername;

  /// No description provided for @zaitoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Zaitoon'**
  String get zaitoonTitle;

  /// No description provided for @softwareCompany.
  ///
  /// In en, this message translates to:
  /// **'Software company'**
  String get softwareCompany;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @shippingManagement.
  ///
  /// In en, this message translates to:
  /// **'Shipping Management'**
  String get shippingManagement;

  /// No description provided for @sign_in_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get sign_in_subtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @show_password.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show_password;

  /// No description provided for @hide_password.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide_password;

  /// No description provided for @invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalid_email;

  /// No description provided for @password_min_length.
  ///
  /// In en, this message translates to:
  /// **'At least 4 characters'**
  String get password_min_length;

  /// No description provided for @fill_all_fields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get fill_all_fields;

  /// No description provided for @dont_have_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dont_have_account;

  /// No description provided for @contact_admin.
  ///
  /// In en, this message translates to:
  /// **'Contact admin'**
  String get contact_admin;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} Zaitoon Software Company'**
  String copyright(Object year);

  /// No description provided for @shipping_management.
  ///
  /// In en, this message translates to:
  /// **'Shipping Management'**
  String get shipping_management;

  /// No description provided for @shipping_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage shipments and routes.'**
  String get shipping_subtitle;

  /// No description provided for @software_company.
  ///
  /// In en, this message translates to:
  /// **'Software Company'**
  String get software_company;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @hr.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get hr;

  /// No description provided for @stakeholders.
  ///
  /// In en, this message translates to:
  /// **'Stakeholders'**
  String get stakeholders;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @shipment.
  ///
  /// In en, this message translates to:
  /// **'Shipments'**
  String get shipment;

  /// No description provided for @settingsHint.
  ///
  /// In en, this message translates to:
  /// **'Manage your settings'**
  String get settingsHint;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your connection.'**
  String get noInternet;

  /// No description provided for @timeOutMessage.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get timeOutMessage;

  /// No description provided for @requestCancelMessage.
  ///
  /// In en, this message translates to:
  /// **'The request was cancelled.'**
  String get requestCancelMessage;

  /// No description provided for @badRequest.
  ///
  /// In en, this message translates to:
  /// **'Bad request. Please check your input.'**
  String get badRequest;

  /// No description provided for @unAuthorized.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized. Please log in again.'**
  String get unAuthorized;

  /// No description provided for @forbidden.
  ///
  /// In en, this message translates to:
  /// **'Access forbidden. You don\'t have permission.'**
  String get forbidden;

  /// No description provided for @url404.
  ///
  /// In en, this message translates to:
  /// **'The requested resource was not found.'**
  String get url404;

  /// No description provided for @notAllowedError.
  ///
  /// In en, this message translates to:
  /// **'Method not allowed.'**
  String get notAllowedError;

  /// No description provided for @internalServerError.
  ///
  /// In en, this message translates to:
  /// **'Internal server error. Please try again later.'**
  String get internalServerError;

  /// No description provided for @serviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service unavailable. Please try again later.'**
  String get serviceUnavailable;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get networkError;

  /// No description provided for @incorrectCredential.
  ///
  /// In en, this message translates to:
  /// **'username or password is incorrect'**
  String get incorrectCredential;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @currencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyTitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @newKeyword.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newKeyword;

  /// No description provided for @fxRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get fxRate;

  /// No description provided for @accountExistMsg.
  ///
  /// In en, this message translates to:
  /// **'Account already exist, try another name.'**
  String get accountExistMsg;

  /// No description provided for @operationFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Operation failed, try again later'**
  String get operationFailedMsg;

  /// No description provided for @glDependingMsg.
  ///
  /// In en, this message translates to:
  /// **'Account has already been link with transactions.'**
  String get glDependingMsg;

  /// No description provided for @asset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get asset;

  /// No description provided for @liability.
  ///
  /// In en, this message translates to:
  /// **'Liability'**
  String get liability;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @accountCategory.
  ///
  /// In en, this message translates to:
  /// **'Account Category'**
  String get accountCategory;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get accountNumber;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @subCategory.
  ///
  /// In en, this message translates to:
  /// **'Subcateogry'**
  String get subCategory;

  /// No description provided for @glAccount.
  ///
  /// In en, this message translates to:
  /// **'GL Accounts'**
  String get glAccount;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @branchLimit.
  ///
  /// In en, this message translates to:
  /// **'Branch Limit'**
  String get branchLimit;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get branchName;

  /// No description provided for @branchCode.
  ///
  /// In en, this message translates to:
  /// **'Branch code'**
  String get branchCode;

  /// No description provided for @mobile1.
  ///
  /// In en, this message translates to:
  /// **'Mobile 1'**
  String get mobile1;

  /// No description provided for @zipCode.
  ///
  /// In en, this message translates to:
  /// **'Zip code'**
  String get zipCode;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @successMsg.
  ///
  /// In en, this message translates to:
  /// **'Operation was successful.'**
  String get successMsg;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @baseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get baseCurrency;

  /// No description provided for @socialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social media'**
  String get socialMedia;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @instagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagram;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @comDetails.
  ///
  /// In en, this message translates to:
  /// **'Company details'**
  String get comDetails;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Manage your company address'**
  String get addressHint;

  /// No description provided for @socialMediaHint.
  ///
  /// In en, this message translates to:
  /// **'Manage Social Profiles'**
  String get socialMediaHint;

  /// No description provided for @companyDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Manage company details'**
  String get companyDetailsHint;

  /// No description provided for @companyLicence.
  ///
  /// In en, this message translates to:
  /// **'Company Licence'**
  String get companyLicence;

  /// No description provided for @payableDue.
  ///
  /// In en, this message translates to:
  /// **'Payable due'**
  String get payableDue;

  /// No description provided for @receivableDue.
  ///
  /// In en, this message translates to:
  /// **'Receiveable due'**
  String get receivableDue;

  /// No description provided for @dueType.
  ///
  /// In en, this message translates to:
  /// **'Due type'**
  String get dueType;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get filterByStatus;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @accNameOrNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Name or Number'**
  String get accNameOrNumber;

  /// No description provided for @amountGreaterZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must greater than zero'**
  String get amountGreaterZero;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @overdueBy.
  ///
  /// In en, this message translates to:
  /// **'Overdue by'**
  String get overdueBy;

  /// No description provided for @overdueByOne.
  ///
  /// In en, this message translates to:
  /// **'Overdue by one day'**
  String get overdueByOne;

  /// No description provided for @noReminder.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get noReminder;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @aboat.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboat;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @fiscalYear.
  ///
  /// In en, this message translates to:
  /// **'End of year'**
  String get fiscalYear;

  /// No description provided for @payroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payroll;

  /// No description provided for @manageFinance.
  ///
  /// In en, this message translates to:
  /// **'Manage Company Finances'**
  String get manageFinance;

  /// No description provided for @profitAndLoss.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get profitAndLoss;

  /// No description provided for @eoyClosing.
  ///
  /// In en, this message translates to:
  /// **'Close Fiscal Year'**
  String get eoyClosing;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get summary;

  /// No description provided for @noPandLMessage.
  ///
  /// In en, this message translates to:
  /// **'No Profit & Loss'**
  String get noPandLMessage;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @retainedEarnings.
  ///
  /// In en, this message translates to:
  /// **'Retained Earnings'**
  String get retainedEarnings;

  /// No description provided for @remark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remark;

  /// No description provided for @debit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get debit;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @attention.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get attention;

  /// No description provided for @plMessage.
  ///
  /// In en, this message translates to:
  /// **'Close Profit & Loss and transfer the balance to Retained Earnings?'**
  String get plMessage;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @profileOverview.
  ///
  /// In en, this message translates to:
  /// **'Profile Overview'**
  String get profileOverview;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @narration.
  ///
  /// In en, this message translates to:
  /// **'Narration'**
  String get narration;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @maker.
  ///
  /// In en, this message translates to:
  /// **'Txn Maker'**
  String get maker;

  /// No description provided for @cashDeposit.
  ///
  /// In en, this message translates to:
  /// **'Cash Receipt'**
  String get cashDeposit;

  /// No description provided for @cashWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Cash Payment'**
  String get cashWithdraw;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @noTransaction.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransaction;

  /// No description provided for @noTransactionMsg.
  ///
  /// In en, this message translates to:
  /// **'There are no transactions to display'**
  String get noTransactionMsg;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @branches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branches;

  /// No description provided for @branchLimitHint.
  ///
  /// In en, this message translates to:
  /// **'Auto transactions allowance of branch'**
  String get branchLimitHint;

  /// No description provided for @fxTransaction.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get fxTransaction;

  /// No description provided for @bulkTransaction.
  ///
  /// In en, this message translates to:
  /// **'Bulk Transfer'**
  String get bulkTransaction;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @authorized.
  ///
  /// In en, this message translates to:
  /// **'Authorized'**
  String get authorized;

  /// No description provided for @reversed.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get reversed;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @glDebit.
  ///
  /// In en, this message translates to:
  /// **'GL Debit'**
  String get glDebit;

  /// No description provided for @glCredit.
  ///
  /// In en, this message translates to:
  /// **'GL Credit'**
  String get glCredit;

  /// No description provided for @exchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get exchange;

  /// No description provided for @fundTransfer.
  ///
  /// In en, this message translates to:
  /// **'Fund Transfer'**
  String get fundTransfer;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @cashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash flow'**
  String get cashFlow;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @newTransaction.
  ///
  /// In en, this message translates to:
  /// **'New Transaction'**
  String get newTransaction;

  /// No description provided for @noPermission.
  ///
  /// In en, this message translates to:
  /// **'No Permission'**
  String get noPermission;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected · {count}'**
  String selectedCount(int count);

  /// No description provided for @addRow.
  ///
  /// In en, this message translates to:
  /// **'Add Row'**
  String get addRow;

  /// No description provided for @diff.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get diff;

  /// No description provided for @bulkTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bulk Transfer'**
  String get bulkTransfer;

  /// No description provided for @editBulkTransfer.
  ///
  /// In en, this message translates to:
  /// **'Edit Bulk Transfer'**
  String get editBulkTransfer;

  /// No description provided for @authorize.
  ///
  /// In en, this message translates to:
  /// **'Authorize'**
  String get authorize;

  /// No description provided for @reverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse'**
  String get reverse;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @unauthorize.
  ///
  /// In en, this message translates to:
  /// **'Unauthorize'**
  String get unauthorize;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set reminder'**
  String get setReminder;

  /// No description provided for @sameAccount.
  ///
  /// In en, this message translates to:
  /// **'Same account transfer is not allowed.'**
  String get sameAccount;

  /// No description provided for @currencyMismatch.
  ///
  /// In en, this message translates to:
  /// **'Currency doesn\'t match, both must same currency'**
  String get currencyMismatch;

  /// No description provided for @debitAccount.
  ///
  /// In en, this message translates to:
  /// **'Debit Account'**
  String get debitAccount;

  /// No description provided for @creditAccount.
  ///
  /// In en, this message translates to:
  /// **'Credit Account'**
  String get creditAccount;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @newFundTransfer.
  ///
  /// In en, this message translates to:
  /// **'New Fund Transfer'**
  String get newFundTransfer;

  /// No description provided for @sameCurrencyForExchange.
  ///
  /// In en, this message translates to:
  /// **'Debit and credit currencies must differ.'**
  String get sameCurrencyForExchange;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dob;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @debitor.
  ///
  /// In en, this message translates to:
  /// **'Debitor'**
  String get debitor;

  /// No description provided for @creditor.
  ///
  /// In en, this message translates to:
  /// **'Creditor'**
  String get creditor;

  /// No description provided for @noBalance.
  ///
  /// In en, this message translates to:
  /// **'No Balance'**
  String get noBalance;

  /// No description provided for @statement.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get statement;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @accountLimit.
  ///
  /// In en, this message translates to:
  /// **'Account Limit'**
  String get accountLimit;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @accountActiveMsg.
  ///
  /// In en, this message translates to:
  /// **'Account is available for transactions'**
  String get accountActiveMsg;

  /// No description provided for @accountBlockMsg.
  ///
  /// In en, this message translates to:
  /// **'Account is blocked for transactions.'**
  String get accountBlockMsg;

  /// No description provided for @ccyChangeWarnings.
  ///
  /// In en, this message translates to:
  /// **'Currency cannot be changed if the account has recorded transactions.'**
  String get ccyChangeWarnings;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @password8Char.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get password8Char;

  /// No description provided for @passwordUpperCase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordUpperCase;

  /// No description provided for @passwordLowerCase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one lowercase letter'**
  String get passwordLowerCase;

  /// No description provided for @passwordWithDigit.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one digit'**
  String get passwordWithDigit;

  /// No description provided for @passwordWithSpecialChar.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one special character'**
  String get passwordWithSpecialChar;

  /// No description provided for @usernameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 4 characters'**
  String get usernameMinLength;

  /// No description provided for @usernameNoStartDigit.
  ///
  /// In en, this message translates to:
  /// **'Username cannot start with a number'**
  String get usernameNoStartDigit;

  /// No description provided for @usernameInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Username can only contain letters, numbers, . or _'**
  String get usernameInvalidChars;

  /// No description provided for @usernameNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Username cannot contain spaces'**
  String get usernameNoSpaces;

  /// No description provided for @changePassowrd.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassowrd;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Passwor'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get confirmPassword;

  /// No description provided for @passwordNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get passwordNotMatch;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @hrTitle.
  ///
  /// In en, this message translates to:
  /// **'Human Resources Management'**
  String get hrTitle;

  /// No description provided for @emailExists.
  ///
  /// In en, this message translates to:
  /// **'Email already exists, try another'**
  String get emailExists;

  /// No description provided for @usernameExists.
  ///
  /// In en, this message translates to:
  /// **'Username already exists, try another'**
  String get usernameExists;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @userOwner.
  ///
  /// In en, this message translates to:
  /// **'User owner'**
  String get userOwner;

  /// No description provided for @editRole.
  ///
  /// In en, this message translates to:
  /// **'Edit Role'**
  String get editRole;

  /// No description provided for @addRole.
  ///
  /// In en, this message translates to:
  /// **'Add Role'**
  String get addRole;

  /// No description provided for @roleName.
  ///
  /// In en, this message translates to:
  /// **'Role name'**
  String get roleName;

  /// No description provided for @userRole.
  ///
  /// In en, this message translates to:
  /// **'User Role'**
  String get userRole;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @forceChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password after login'**
  String get forceChangePassword;

  /// No description provided for @forceEmailVerification.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get forceEmailVerification;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get unblock;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @roleActions.
  ///
  /// In en, this message translates to:
  /// **'Role Actions'**
  String get roleActions;

  /// No description provided for @grantAll.
  ///
  /// In en, this message translates to:
  /// **'Grant All'**
  String get grantAll;

  /// No description provided for @revokeAll.
  ///
  /// In en, this message translates to:
  /// **'Revoke All'**
  String get revokeAll;

  /// No description provided for @restoreDefault.
  ///
  /// In en, this message translates to:
  /// **'Restore Default'**
  String get restoreDefault;

  /// No description provided for @counts.
  ///
  /// In en, this message translates to:
  /// **'Counts'**
  String get counts;

  /// No description provided for @exchangeRateGraph.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate Graph'**
  String get exchangeRateGraph;

  /// No description provided for @dailyTransactionsGraph.
  ///
  /// In en, this message translates to:
  /// **'Daily Transactions Graph'**
  String get dailyTransactionsGraph;

  /// No description provided for @dailyTransactionTotals.
  ///
  /// In en, this message translates to:
  /// **'Daily Transaction Totals'**
  String get dailyTransactionTotals;

  /// No description provided for @digitalClock.
  ///
  /// In en, this message translates to:
  /// **'Digital Clock'**
  String get digitalClock;

  /// No description provided for @exchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get exchangeRates;

  /// No description provided for @profitLossGraph.
  ///
  /// In en, this message translates to:
  /// **'Profit Loss Graph'**
  String get profitLossGraph;

  /// No description provided for @reminderNotifications.
  ///
  /// In en, this message translates to:
  /// **'Reminder Notifications'**
  String get reminderNotifications;

  /// No description provided for @currencyTab.
  ///
  /// In en, this message translates to:
  /// **'Currency Tab'**
  String get currencyTab;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @glAccounts.
  ///
  /// In en, this message translates to:
  /// **'GL Accounts'**
  String get glAccounts;

  /// No description provided for @allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get allTransactions;

  /// No description provided for @authorizedTransaction.
  ///
  /// In en, this message translates to:
  /// **'Authorized Transaction'**
  String get authorizedTransaction;

  /// No description provided for @pendingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Pending Transaction'**
  String get pendingTransaction;

  /// No description provided for @incomeEntry.
  ///
  /// In en, this message translates to:
  /// **'Income Entry'**
  String get incomeEntry;

  /// No description provided for @expenseEntry.
  ///
  /// In en, this message translates to:
  /// **'Expense Entry'**
  String get expenseEntry;

  /// No description provided for @ftSingleAccount.
  ///
  /// In en, this message translates to:
  /// **'FT Single Account'**
  String get ftSingleAccount;

  /// No description provided for @ftMultiAccount.
  ///
  /// In en, this message translates to:
  /// **'FT Multi Account'**
  String get ftMultiAccount;

  /// No description provided for @fxTransactions.
  ///
  /// In en, this message translates to:
  /// **'FX Transactions'**
  String get fxTransactions;

  /// No description provided for @individuals.
  ///
  /// In en, this message translates to:
  /// **'Individuals'**
  String get individuals;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @userLog.
  ///
  /// In en, this message translates to:
  /// **'User Log'**
  String get userLog;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @ordersTab.
  ///
  /// In en, this message translates to:
  /// **'Orders Tab'**
  String get ordersTab;

  /// No description provided for @estimateTab.
  ///
  /// In en, this message translates to:
  /// **'Estimate Tab'**
  String get estimateTab;

  /// No description provided for @goodsShiftTab.
  ///
  /// In en, this message translates to:
  /// **'Goods Shift Tab'**
  String get goodsShiftTab;

  /// No description provided for @adjustmentTab.
  ///
  /// In en, this message translates to:
  /// **'Adjustment Tab'**
  String get adjustmentTab;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sale;

  /// No description provided for @estimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get estimate;

  /// No description provided for @goodsShift.
  ///
  /// In en, this message translates to:
  /// **'Goods Shift'**
  String get goodsShift;

  /// No description provided for @adjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get adjustment;

  /// No description provided for @findInvoice.
  ///
  /// In en, this message translates to:
  /// **'Find Invoice'**
  String get findInvoice;

  /// No description provided for @generalTab.
  ///
  /// In en, this message translates to:
  /// **'General Tab'**
  String get generalTab;

  /// No description provided for @passwordChange.
  ///
  /// In en, this message translates to:
  /// **'Password Change'**
  String get passwordChange;

  /// No description provided for @rolesAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'Roles and Permissions'**
  String get rolesAndPermissions;

  /// No description provided for @companyTab.
  ///
  /// In en, this message translates to:
  /// **'Company Tab'**
  String get companyTab;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @accountStatementSingleDate.
  ///
  /// In en, this message translates to:
  /// **'Account Statement Single Date'**
  String get accountStatementSingleDate;

  /// No description provided for @glStatementSingleDate.
  ///
  /// In en, this message translates to:
  /// **'GL Statement Single Date'**
  String get glStatementSingleDate;

  /// No description provided for @glStatementPeriodicDate.
  ///
  /// In en, this message translates to:
  /// **'GL Statement Periodic Date'**
  String get glStatementPeriodicDate;

  /// No description provided for @creditors.
  ///
  /// In en, this message translates to:
  /// **'Creditors'**
  String get creditors;

  /// No description provided for @debtors.
  ///
  /// In en, this message translates to:
  /// **'Debtors'**
  String get debtors;

  /// No description provided for @stockAvailability.
  ///
  /// In en, this message translates to:
  /// **'Stock Availability'**
  String get stockAvailability;

  /// No description provided for @productMovement.
  ///
  /// In en, this message translates to:
  /// **'Product Movement'**
  String get productMovement;

  /// No description provided for @purchaseInvoices.
  ///
  /// In en, this message translates to:
  /// **'Purchase Invoices'**
  String get purchaseInvoices;

  /// No description provided for @saleInvoices.
  ///
  /// In en, this message translates to:
  /// **'Sale Invoices'**
  String get saleInvoices;

  /// No description provided for @allInvoices.
  ///
  /// In en, this message translates to:
  /// **'All Invoices'**
  String get allInvoices;

  /// No description provided for @cashBalanceAllBranch.
  ///
  /// In en, this message translates to:
  /// **'Cash Balance All Branch'**
  String get cashBalanceAllBranch;

  /// No description provided for @cashBalanceSingleBranch.
  ///
  /// In en, this message translates to:
  /// **'Cash Balance Single Branch'**
  String get cashBalanceSingleBranch;

  /// No description provided for @trialBalance.
  ///
  /// In en, this message translates to:
  /// **'Trial Balance'**
  String get trialBalance;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @transactionsReport.
  ///
  /// In en, this message translates to:
  /// **'Transactions Report'**
  String get transactionsReport;

  /// No description provided for @allBalances.
  ///
  /// In en, this message translates to:
  /// **'All Balances'**
  String get allBalances;

  /// No description provided for @userRoleAndPermission.
  ///
  /// In en, this message translates to:
  /// **'User Role and Permission'**
  String get userRoleAndPermission;

  /// No description provided for @stakeholderAccount.
  ///
  /// In en, this message translates to:
  /// **'Stakeholder Account'**
  String get stakeholderAccount;

  /// No description provided for @currencies.
  ///
  /// In en, this message translates to:
  /// **'Currencies'**
  String get currencies;

  /// No description provided for @balanceSheet.
  ///
  /// In en, this message translates to:
  /// **'Balance Sheet'**
  String get balanceSheet;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @printers.
  ///
  /// In en, this message translates to:
  /// **'Printers'**
  String get printers;

  /// No description provided for @portrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get portrait;

  /// No description provided for @landscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get landscape;

  /// No description provided for @orientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get orientation;

  /// No description provided for @paper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get paper;

  /// No description provided for @printPreview.
  ///
  /// In en, this message translates to:
  /// **'Print Preview'**
  String get printPreview;

  /// No description provided for @copies.
  ///
  /// In en, this message translates to:
  /// **'Copies'**
  String get copies;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get toDate;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @accountStatement.
  ///
  /// In en, this message translates to:
  /// **'Account Statement'**
  String get accountStatement;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copyClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy clipboard'**
  String get copyClipboard;

  /// No description provided for @typeMessageHere.
  ///
  /// In en, this message translates to:
  /// **'Type message here'**
  String get typeMessageHere;

  /// No description provided for @signatory.
  ///
  /// In en, this message translates to:
  /// **'Signatory'**
  String get signatory;

  /// No description provided for @dearCustomer.
  ///
  /// In en, this message translates to:
  /// **'Dear Customer'**
  String get dearCustomer;

  /// No description provided for @regardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Regards,'**
  String get regardsTitle;

  /// No description provided for @balanceMessageShare.
  ///
  /// In en, this message translates to:
  /// **'Please find your balance here'**
  String get balanceMessageShare;

  /// No description provided for @accountPosition.
  ///
  /// In en, this message translates to:
  /// **'Account Position'**
  String get accountPosition;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
