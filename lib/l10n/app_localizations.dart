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
  /// **'General'**
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
  /// **'Maker'**
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
  /// **'Fund Transfer & Exchange'**
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

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @glStatement.
  ///
  /// In en, this message translates to:
  /// **'GL Statement'**
  String get glStatement;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'ASSETS'**
  String get assets;

  /// No description provided for @liabilitiesEquity.
  ///
  /// In en, this message translates to:
  /// **'LIABILITIES AND EQUITY'**
  String get liabilitiesEquity;

  /// No description provided for @currentAssets.
  ///
  /// In en, this message translates to:
  /// **'Current Assets'**
  String get currentAssets;

  /// No description provided for @fixedAssets.
  ///
  /// In en, this message translates to:
  /// **'Fixed Assets'**
  String get fixedAssets;

  /// No description provided for @intangibleAssets.
  ///
  /// In en, this message translates to:
  /// **'Intangible Assets'**
  String get intangibleAssets;

  /// No description provided for @currentLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Current Liabilities'**
  String get currentLiabilities;

  /// No description provided for @ownerEquity.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s Equity'**
  String get ownerEquity;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @totalAssets.
  ///
  /// In en, this message translates to:
  /// **'TOTAL ASSETS'**
  String get totalAssets;

  /// No description provided for @totalLiabilitiesEquity.
  ///
  /// In en, this message translates to:
  /// **'TOTAL LIABILITIES & EQUITY'**
  String get totalLiabilitiesEquity;

  /// No description provided for @totalTitle.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalTitle;

  /// No description provided for @currentYear.
  ///
  /// In en, this message translates to:
  /// **'Current Year'**
  String get currentYear;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @totalCredit.
  ///
  /// In en, this message translates to:
  /// **'Total Credit'**
  String get totalCredit;

  /// No description provided for @totalDebit.
  ///
  /// In en, this message translates to:
  /// **'Total Debit'**
  String get totalDebit;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @actualBalance.
  ///
  /// In en, this message translates to:
  /// **'Actual Balance'**
  String get actualBalance;

  /// No description provided for @outOfBalance.
  ///
  /// In en, this message translates to:
  /// **'Out of balance'**
  String get outOfBalance;

  /// No description provided for @authorizer.
  ///
  /// In en, this message translates to:
  /// **'Authorizer'**
  String get authorizer;

  /// No description provided for @cashBalance.
  ///
  /// In en, this message translates to:
  /// **'Cash Balance'**
  String get cashBalance;

  /// No description provided for @branchId.
  ///
  /// In en, this message translates to:
  /// **'Branch ID'**
  String get branchId;

  /// No description provided for @currencyBalances.
  ///
  /// In en, this message translates to:
  /// **'Currency Balances'**
  String get currencyBalances;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get openingBalance;

  /// No description provided for @closingBalance.
  ///
  /// In en, this message translates to:
  /// **'Closing Balance'**
  String get closingBalance;

  /// No description provided for @systemEquivalent.
  ///
  /// In en, this message translates to:
  /// **'System Equivalent'**
  String get systemEquivalent;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @grandTotalCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Grand Total Cash flow'**
  String get grandTotalCashFlow;

  /// No description provided for @incomeStatement.
  ///
  /// In en, this message translates to:
  /// **'Income Statement'**
  String get incomeStatement;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// No description provided for @totalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total Expense'**
  String get totalExpense;

  /// No description provided for @applyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get applyFilter;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get loss;

  /// No description provided for @financialPeriod.
  ///
  /// In en, this message translates to:
  /// **'Financial Period'**
  String get financialPeriod;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @searchAccounts.
  ///
  /// In en, this message translates to:
  /// **'Search accounts'**
  String get searchAccounts;

  /// No description provided for @balanceFilter.
  ///
  /// In en, this message translates to:
  /// **'Balance Filter'**
  String get balanceFilter;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @databaseBackup.
  ///
  /// In en, this message translates to:
  /// **'Database Backup'**
  String get databaseBackup;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @recentBackup.
  ///
  /// In en, this message translates to:
  /// **'Recent Backup'**
  String get recentBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackup;

  /// No description provided for @renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameTitle;

  /// No description provided for @openInExplorer.
  ///
  /// In en, this message translates to:
  /// **'Open in folder'**
  String get openInExplorer;

  /// No description provided for @restoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore Completed'**
  String get restoreComplete;

  /// No description provided for @restoreSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Database has been successfully restored.'**
  String get restoreSuccessMsg;

  /// No description provided for @downloadBackup.
  ///
  /// In en, this message translates to:
  /// **'Download Backup'**
  String get downloadBackup;

  /// No description provided for @downloadBackupMsg.
  ///
  /// In en, this message translates to:
  /// **'Keep your data safe & prevent data loss.'**
  String get downloadBackupMsg;

  /// No description provided for @creatingBackupMsg.
  ///
  /// In en, this message translates to:
  /// **'Backing up data before restore...'**
  String get creatingBackupMsg;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @authorizing.
  ///
  /// In en, this message translates to:
  /// **'Authorizing…'**
  String get authorizing;

  /// No description provided for @reversing.
  ///
  /// In en, this message translates to:
  /// **'Reversing...'**
  String get reversing;

  /// No description provided for @unauthorizing.
  ///
  /// In en, this message translates to:
  /// **'Unauthorizing...'**
  String get unauthorizing;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// No description provided for @addStakeholder.
  ///
  /// In en, this message translates to:
  /// **'Add Stakeholder'**
  String get addStakeholder;

  /// No description provided for @searchStakeholders.
  ///
  /// In en, this message translates to:
  /// **'Search Stakeholders'**
  String get searchStakeholders;

  /// No description provided for @stakeholderHint.
  ///
  /// In en, this message translates to:
  /// **'Manage people and organizations involved in your business'**
  String get stakeholderHint;

  /// No description provided for @employeeHint.
  ///
  /// In en, this message translates to:
  /// **'View and manage all employees'**
  String get employeeHint;

  /// No description provided for @searchEmployees.
  ///
  /// In en, this message translates to:
  /// **'Search Employees'**
  String get searchEmployees;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @executiveManagement.
  ///
  /// In en, this message translates to:
  /// **'Executive Management'**
  String get executiveManagement;

  /// No description provided for @operation.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operation;

  /// No description provided for @it.
  ///
  /// In en, this message translates to:
  /// **'Information Technology'**
  String get it;

  /// No description provided for @audit.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get audit;

  /// No description provided for @procurement.
  ///
  /// In en, this message translates to:
  /// **'Procurement'**
  String get procurement;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @customerService.
  ///
  /// In en, this message translates to:
  /// **'Customer Service'**
  String get customerService;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @hourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get hourly;

  /// No description provided for @salaryBased.
  ///
  /// In en, this message translates to:
  /// **'Salary Based'**
  String get salaryBased;

  /// No description provided for @editEmployee.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get editEmployee;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @salaryAccount.
  ///
  /// In en, this message translates to:
  /// **'Salary account'**
  String get salaryAccount;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @hireDate.
  ///
  /// In en, this message translates to:
  /// **'Hire date'**
  String get hireDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @taxInfo.
  ///
  /// In en, this message translates to:
  /// **'Tax info (TIN)'**
  String get taxInfo;

  /// No description provided for @fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get fingerprint;

  /// No description provided for @alreadyEmployed.
  ///
  /// In en, this message translates to:
  /// **'This person is already employed'**
  String get alreadyEmployed;

  /// No description provided for @fieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get fieldsRequired;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get fieldRequired;

  /// No description provided for @salaryMustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'Salary must be a valid number'**
  String get salaryMustBeNumber;

  /// No description provided for @usersHint.
  ///
  /// In en, this message translates to:
  /// **'Manage user accounts, roles, and access permissions.'**
  String get usersHint;

  /// No description provided for @ccyName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ccyName;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @allCurrencies.
  ///
  /// In en, this message translates to:
  /// **'All Currencies'**
  String get allCurrencies;

  /// No description provided for @localName.
  ///
  /// In en, this message translates to:
  /// **'Local name'**
  String get localName;

  /// No description provided for @symbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get symbol;

  /// No description provided for @flag.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get flag;

  /// No description provided for @transactionHint.
  ///
  /// In en, this message translates to:
  /// **'View and manage all your financial transactions'**
  String get transactionHint;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @inTitle.
  ///
  /// In en, this message translates to:
  /// **'IN'**
  String get inTitle;

  /// No description provided for @outTitle.
  ///
  /// In en, this message translates to:
  /// **'OUT'**
  String get outTitle;

  /// No description provided for @systemDate.
  ///
  /// In en, this message translates to:
  /// **'System Date'**
  String get systemDate;

  /// No description provided for @gregorian.
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get gregorian;

  /// No description provided for @shamsi.
  ///
  /// In en, this message translates to:
  /// **'Hijri Shamsi'**
  String get shamsi;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @financialReports.
  ///
  /// In en, this message translates to:
  /// **'Financial Reports'**
  String get financialReports;

  /// No description provided for @accountStatementHint.
  ///
  /// In en, this message translates to:
  /// **'Ledger activity for a single account with running balance.'**
  String get accountStatementHint;

  /// No description provided for @glStatementHint.
  ///
  /// In en, this message translates to:
  /// **'General ledger activity and balances for a chosen account.'**
  String get glStatementHint;

  /// No description provided for @balanceSheetHint.
  ///
  /// In en, this message translates to:
  /// **'Assets, liabilities and equity as of a chosen date.'**
  String get balanceSheetHint;

  /// No description provided for @trialBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Debit and credit totals with automatic balance check.'**
  String get trialBalanceHint;

  /// No description provided for @transactionDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Look up any transaction by its reference number.'**
  String get transactionDetailsHint;

  /// No description provided for @cashBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Cash position for the current branch.'**
  String get cashBalanceHint;

  /// No description provided for @treasuryHint.
  ///
  /// In en, this message translates to:
  /// **'Cash position across all branches.'**
  String get treasuryHint;

  /// No description provided for @profitAndLossHint.
  ///
  /// In en, this message translates to:
  /// **'Income & expense statement.'**
  String get profitAndLossHint;

  /// No description provided for @receivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get receivables;

  /// No description provided for @receivablesHint.
  ///
  /// In en, this message translates to:
  /// **'Accounts where customers owe money to the business.'**
  String get receivablesHint;

  /// No description provided for @payables.
  ///
  /// In en, this message translates to:
  /// **'Payables'**
  String get payables;

  /// No description provided for @payablesHint.
  ///
  /// In en, this message translates to:
  /// **'Accounts where the business owes money to suppliers.'**
  String get payablesHint;

  /// No description provided for @allBalancesHint.
  ///
  /// In en, this message translates to:
  /// **'All accounts balances report.'**
  String get allBalancesHint;

  /// No description provided for @allTransactionsHint.
  ///
  /// In en, this message translates to:
  /// **'All transactions records.'**
  String get allTransactionsHint;

  /// No description provided for @userLogHint.
  ///
  /// In en, this message translates to:
  /// **'Users activities & logs.'**
  String get userLogHint;

  /// No description provided for @attendanceHint.
  ///
  /// In en, this message translates to:
  /// **'Present & Absent records.'**
  String get attendanceHint;

  /// No description provided for @transportCargo.
  ///
  /// In en, this message translates to:
  /// **'Transport & Cargo'**
  String get transportCargo;

  /// No description provided for @shipments.
  ///
  /// In en, this message translates to:
  /// **'Shipments'**
  String get shipments;

  /// No description provided for @shipmentsHint.
  ///
  /// In en, this message translates to:
  /// **'List of Containers imported.'**
  String get shipmentsHint;

  /// No description provided for @shipmentInvoice.
  ///
  /// In en, this message translates to:
  /// **'Shipment Invoice'**
  String get shipmentInvoice;

  /// No description provided for @shipmentInvoiceHint.
  ///
  /// In en, this message translates to:
  /// **'PDF or EXCEL Invoice for customer out of containers.'**
  String get shipmentInvoiceHint;

  /// No description provided for @reportHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a report to view.'**
  String get reportHint;

  /// No description provided for @authorizationMakerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the maker of this transaction can unauthorize or reverse it.'**
  String get authorizationMakerOnly;

  /// No description provided for @authorizationInvalidState.
  ///
  /// In en, this message translates to:
  /// **'This transaction is not in the right state to be authorized.'**
  String get authorizationInvalidState;

  /// No description provided for @authorizationPending.
  ///
  /// In en, this message translates to:
  /// **'This transaction is already pending.'**
  String get authorizationPending;

  /// No description provided for @authorizationFailedProcess.
  ///
  /// In en, this message translates to:
  /// **'The transaction could not be processed.'**
  String get authorizationFailedProcess;

  /// No description provided for @authorizationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authorization failed.'**
  String get authorizationFailed;

  /// No description provided for @newExchange.
  ///
  /// In en, this message translates to:
  /// **'New Exchange'**
  String get newExchange;

  /// No description provided for @atLeastTwoRow.
  ///
  /// In en, this message translates to:
  /// **'Add at least two rows — one debit and one credit — with the same total.'**
  String get atLeastTwoRow;

  /// No description provided for @totalDebitEqualCredit.
  ///
  /// In en, this message translates to:
  /// **'Total debit must equal total credit.'**
  String get totalDebitEqualCredit;

  /// No description provided for @rowsSameCcy.
  ///
  /// In en, this message translates to:
  /// **'Rows use different currencies. Pick one currency for all rows.'**
  String get rowsSameCcy;

  /// No description provided for @fileInfo.
  ///
  /// In en, this message translates to:
  /// **'File Info'**
  String get fileInfo;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhoto;

  /// No description provided for @editProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Update your name, phone, email, date of birth and address.'**
  String get editProfileHint;

  /// No description provided for @changePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Change the password used to sign in to your account.'**
  String get changePasswordHint;

  /// No description provided for @profilePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Update your profile photo'**
  String get profilePhotoHint;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Money Transfer'**
  String get transfer;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @orderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage purchase & sale'**
  String get orderSubtitle;

  /// No description provided for @party.
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get party;

  /// No description provided for @invoiceType.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceType;

  /// No description provided for @totalInvoice.
  ///
  /// In en, this message translates to:
  /// **'Total Invoice'**
  String get totalInvoice;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @newPurchase.
  ///
  /// In en, this message translates to:
  /// **'New Purchase'**
  String get newPurchase;

  /// No description provided for @goodShift.
  ///
  /// In en, this message translates to:
  /// **'Goods Shift'**
  String get goodShift;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @batchTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get batchTitle;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search Products'**
  String get searchProducts;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get pricing;

  /// No description provided for @avgPrice.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get avgPrice;

  /// No description provided for @recentPrice.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentPrice;

  /// No description provided for @sellPrice.
  ///
  /// In en, this message translates to:
  /// **'Sell Price'**
  String get sellPrice;

  /// No description provided for @landedCost.
  ///
  /// In en, this message translates to:
  /// **'Landed Cost'**
  String get landedCost;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get productDetails;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @productCode.
  ///
  /// In en, this message translates to:
  /// **'Product Code'**
  String get productCode;

  /// No description provided for @madeIn.
  ///
  /// In en, this message translates to:
  /// **'Made in'**
  String get madeIn;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @productImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get productImages;

  /// No description provided for @nameAndDescriptions.
  ///
  /// In en, this message translates to:
  /// **'Name & Descriptions'**
  String get nameAndDescriptions;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get newProduct;

  /// No description provided for @productAlreadyExist.
  ///
  /// In en, this message translates to:
  /// **'Product already exists.'**
  String get productAlreadyExist;

  /// No description provided for @stockPaper.
  ///
  /// In en, this message translates to:
  /// **'Stock Paper'**
  String get stockPaper;

  /// No description provided for @saleEntry.
  ///
  /// In en, this message translates to:
  /// **'Sale Entry'**
  String get saleEntry;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get paymentSummary;

  /// No description provided for @newBalance.
  ///
  /// In en, this message translates to:
  /// **'New Balance'**
  String get newBalance;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @cashPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash Payment'**
  String get cashPayment;

  /// No description provided for @cashAmount.
  ///
  /// In en, this message translates to:
  /// **'Cash Amount'**
  String get cashAmount;

  /// No description provided for @fullCashPayment.
  ///
  /// In en, this message translates to:
  /// **'Full Cash Payment'**
  String get fullCashPayment;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get selectAccount;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Please select a customer'**
  String get selectCustomer;

  /// No description provided for @invalidCashAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid cash payment amount'**
  String get invalidCashAmount;

  /// No description provided for @selectCreditAccountMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a credit account'**
  String get selectCreditAccountMsg;

  /// No description provided for @addItemMsg.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one item'**
  String get addItemMsg;

  /// No description provided for @addProductMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a product for all items'**
  String get addProductMsg;

  /// No description provided for @addValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid sale price'**
  String get addValidPrice;

  /// No description provided for @addValidQty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid quantity'**
  String get addValidQty;

  /// No description provided for @notEnoughMsg.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock:'**
  String get notEnoughMsg;

  /// No description provided for @overLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'Transaction amount exceeds the allowed limit'**
  String get overLimitMessage;

  /// No description provided for @accountBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'The account is blocked'**
  String get accountBlockedMessage;

  /// No description provided for @invoiceSummary.
  ///
  /// In en, this message translates to:
  /// **'Invoice Summary'**
  String get invoiceSummary;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @itemDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Item Discounts'**
  String get itemDiscounts;

  /// No description provided for @afterItemDiscount.
  ///
  /// In en, this message translates to:
  /// **'After Item Discount'**
  String get afterItemDiscount;

  /// No description provided for @generalDiscount.
  ///
  /// In en, this message translates to:
  /// **'General Discount'**
  String get generalDiscount;

  /// No description provided for @extraCharges.
  ///
  /// In en, this message translates to:
  /// **'Extra Charges'**
  String get extraCharges;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @amountAddedToAr.
  ///
  /// In en, this message translates to:
  /// **'Receivable amount'**
  String get amountAddedToAr;

  /// No description provided for @localAmount.
  ///
  /// In en, this message translates to:
  /// **'Local Amount'**
  String get localAmount;

  /// No description provided for @addAgain.
  ///
  /// In en, this message translates to:
  /// **'Add Again'**
  String get addAgain;

  /// No description provided for @duplicateEntry.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Entry'**
  String get duplicateEntry;

  /// No description provided for @combinedPayment.
  ///
  /// In en, this message translates to:
  /// **'Combined Payment'**
  String get combinedPayment;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @applyDiscount.
  ///
  /// In en, this message translates to:
  /// **'Apply Discount'**
  String get applyDiscount;

  /// No description provided for @mixTitle.
  ///
  /// In en, this message translates to:
  /// **'AR & Cash'**
  String get mixTitle;

  /// No description provided for @totalQty.
  ///
  /// In en, this message translates to:
  /// **'Total QTY'**
  String get totalQty;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @addNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Add New Producd'**
  String get addNewProduct;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @purchaseEntry.
  ///
  /// In en, this message translates to:
  /// **'Purchase Entry'**
  String get purchaseEntry;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice No'**
  String get invoiceNumber;

  /// No description provided for @payableAmount.
  ///
  /// In en, this message translates to:
  /// **'Payable Amount'**
  String get payableAmount;

  /// No description provided for @accountPayable.
  ///
  /// In en, this message translates to:
  /// **'Account Payable'**
  String get accountPayable;

  /// No description provided for @excelTitle.
  ///
  /// In en, this message translates to:
  /// **'EXCEL'**
  String get excelTitle;

  /// No description provided for @manageProducts.
  ///
  /// In en, this message translates to:
  /// **'Manage your products'**
  String get manageProducts;

  /// No description provided for @importComplete.
  ///
  /// In en, this message translates to:
  /// **'Import has been successfully completed.'**
  String get importComplete;

  /// No description provided for @inserted.
  ///
  /// In en, this message translates to:
  /// **'Inserted'**
  String get inserted;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @errored.
  ///
  /// In en, this message translates to:
  /// **'Errored'**
  String get errored;

  /// No description provided for @productCategory.
  ///
  /// In en, this message translates to:
  /// **'Product Categories'**
  String get productCategory;

  /// No description provided for @invoiceBatch.
  ///
  /// In en, this message translates to:
  /// **'Invoice Batch'**
  String get invoiceBatch;

  /// No description provided for @invoiceBatchHint.
  ///
  /// In en, this message translates to:
  /// **'Active batch in invoices'**
  String get invoiceBatchHint;

  /// No description provided for @invoiceSettings.
  ///
  /// In en, this message translates to:
  /// **'Invoice Settings'**
  String get invoiceSettings;

  /// No description provided for @invoiceProfitHint.
  ///
  /// In en, this message translates to:
  /// **'Show or hide profit & loss inside the sale invoice.'**
  String get invoiceProfitHint;

  /// No description provided for @inventoryHint.
  ///
  /// In en, this message translates to:
  /// **'Product purchase, sale & goods shifting between wharehouses.'**
  String get inventoryHint;

  /// No description provided for @stockReport.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stockReport;

  /// No description provided for @stockInOut.
  ///
  /// In en, this message translates to:
  /// **'IN | OUT'**
  String get stockInOut;

  /// No description provided for @stockActions.
  ///
  /// In en, this message translates to:
  /// **'Stock Actions'**
  String get stockActions;

  /// No description provided for @fromStorage.
  ///
  /// In en, this message translates to:
  /// **'From Storage'**
  String get fromStorage;

  /// No description provided for @toStorage.
  ///
  /// In en, this message translates to:
  /// **'To Storage'**
  String get toStorage;

  /// No description provided for @totalIn.
  ///
  /// In en, this message translates to:
  /// **'Total IN'**
  String get totalIn;

  /// No description provided for @totalOut.
  ///
  /// In en, this message translates to:
  /// **'Total OUT'**
  String get totalOut;

  /// No description provided for @stockBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get stockBalance;

  /// No description provided for @inAndOut.
  ///
  /// In en, this message translates to:
  /// **'IN | OUT'**
  String get inAndOut;

  /// No description provided for @movement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get movement;

  /// No description provided for @stockRecord.
  ///
  /// In en, this message translates to:
  /// **'Stock Record'**
  String get stockRecord;

  /// No description provided for @noProductSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'No product'**
  String get noProductSelectedTitle;

  /// No description provided for @noProductSelectedMsg.
  ///
  /// In en, this message translates to:
  /// **'No product is selected to report'**
  String get noProductSelectedMsg;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get allProducts;

  /// No description provided for @mostSold.
  ///
  /// In en, this message translates to:
  /// **'Most Sold'**
  String get mostSold;

  /// No description provided for @lessSold.
  ///
  /// In en, this message translates to:
  /// **'Least Sold'**
  String get lessSold;

  /// No description provided for @notSold.
  ///
  /// In en, this message translates to:
  /// **'Not Sold'**
  String get notSold;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @marketValue.
  ///
  /// In en, this message translates to:
  /// **'Markel Value'**
  String get marketValue;

  /// No description provided for @shippingAndTransfer.
  ///
  /// In en, this message translates to:
  /// **'Shipping & Money Transfer'**
  String get shippingAndTransfer;

  /// No description provided for @shippingHint.
  ///
  /// In en, this message translates to:
  /// **'Manage shipments, track deliveries, and monitor shipping operations.'**
  String get shippingHint;

  /// No description provided for @moneyTransferHint.
  ///
  /// In en, this message translates to:
  /// **'Send, receive, and manage money transfers securely.'**
  String get moneyTransferHint;

  /// No description provided for @noPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to access this feature.'**
  String get noPermissionMessage;

  /// No description provided for @lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @lockVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get lockVerifyTitle;

  /// No description provided for @lockVerifyLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lockVerifyLockTitle;

  /// No description provided for @lockVerifyUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockVerifyUnlockTitle;

  /// No description provided for @lockVerifyLockExplanation.
  ///
  /// In en, this message translates to:
  /// **'Locking will hide this stakeholder\'s financial data from all users until an admin unlocks it.'**
  String get lockVerifyLockExplanation;

  /// No description provided for @lockVerifyUnlockExplanation.
  ///
  /// In en, this message translates to:
  /// **'Enter your admin password to unlock this stakeholder.'**
  String get lockVerifyUnlockExplanation;

  /// No description provided for @lockVerifyVerifyExplanation.
  ///
  /// In en, this message translates to:
  /// **'This stakeholder is locked. Enter your admin password to view it.'**
  String get lockVerifyVerifyExplanation;

  /// No description provided for @lockVerifyLockAction.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lockVerifyLockAction;

  /// No description provided for @lockVerifyUnlockAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockVerifyUnlockAction;

  /// No description provided for @lockVerifyContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get lockVerifyContinueAction;

  /// No description provided for @lockVerifyCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get lockVerifyCancel;

  /// No description provided for @lockVerifyPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin password'**
  String get lockVerifyPasswordLabel;

  /// No description provided for @lockVerifyPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get lockVerifyPasswordHint;

  /// No description provided for @lockVerifySignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get lockVerifySignedInAs;

  /// No description provided for @lockVerifyVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get lockVerifyVerifiedTitle;

  /// No description provided for @lockVerifyVerifiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access granted'**
  String get lockVerifyVerifiedSubtitle;

  /// No description provided for @lockVerifyRelockingIn.
  ///
  /// In en, this message translates to:
  /// **'Re-locking in'**
  String get lockVerifyRelockingIn;

  /// No description provided for @lockVerifyRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get lockVerifyRequired;

  /// No description provided for @lockVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get lockVerifyFailed;

  /// No description provided for @lockVerifyWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get lockVerifyWrongPassword;

  /// No description provided for @lockedBalancesNotice.
  ///
  /// In en, this message translates to:
  /// **'Balances are hidden. Ask an admin to unlock this profile.'**
  String get lockedBalancesNotice;

  /// No description provided for @lockVerifyDeniedWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password.'**
  String get lockVerifyDeniedWrongPassword;

  /// No description provided for @lockVerifyDeniedWrongRole.
  ///
  /// In en, this message translates to:
  /// **'Your role is not allowed to modify stakeholder locks.'**
  String get lockVerifyDeniedWrongRole;

  /// No description provided for @lockVerifyDeniedServerError.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get lockVerifyDeniedServerError;

  /// No description provided for @lockVerifyDeniedNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get lockVerifyDeniedNetwork;

  /// No description provided for @lockVerifyDeniedMissingUser.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to perform this action.'**
  String get lockVerifyDeniedMissingUser;

  /// No description provided for @lockVerifyDeniedPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get lockVerifyDeniedPasswordRequired;

  /// No description provided for @perCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get perCode;

  /// No description provided for @editStakeholder.
  ///
  /// In en, this message translates to:
  /// **'Edit Stakeholder'**
  String get editStakeholder;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @proColor.
  ///
  /// In en, this message translates to:
  /// **'Product Color'**
  String get proColor;

  /// No description provided for @minimumStock.
  ///
  /// In en, this message translates to:
  /// **'Minimum Stock'**
  String get minimumStock;

  /// No description provided for @moreDetails.
  ///
  /// In en, this message translates to:
  /// **'More Details'**
  String get moreDetails;

  /// No description provided for @noBatch.
  ///
  /// In en, this message translates to:
  /// **'No Batch Available'**
  String get noBatch;
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
