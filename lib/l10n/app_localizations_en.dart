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
  String get income => 'Income';

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
  String get aboat => 'About';

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

  @override
  String get search => 'Search';

  @override
  String get narration => 'Narration';

  @override
  String get date => 'Date';

  @override
  String get reference => 'Reference';

  @override
  String get type => 'Type';

  @override
  String get maker => 'Txn Maker';

  @override
  String get cashDeposit => 'Cash Receipt';

  @override
  String get cashWithdraw => 'Cash Payment';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get noTransaction => 'No transactions';

  @override
  String get noTransactionMsg => 'There are no transactions to display';

  @override
  String get dateRange => 'Date range';

  @override
  String get branches => 'Branches';

  @override
  String get branchLimitHint => 'Auto transactions allowance of branch';

  @override
  String get fxTransaction => 'Exchange';

  @override
  String get bulkTransaction => 'Bulk Transfer';

  @override
  String get pending => 'Pending';

  @override
  String get authorized => 'Authorized';

  @override
  String get reversed => 'Reversed';

  @override
  String get deleted => 'Deleted';

  @override
  String get glDebit => 'GL Debit';

  @override
  String get glCredit => 'GL Credit';

  @override
  String get exchange => 'Exchange';

  @override
  String get fundTransfer => 'Fund Transfer';

  @override
  String get journal => 'Journal';

  @override
  String get cashFlow => 'Cash flow';

  @override
  String get tryAgain => 'Try again';

  @override
  String get newTransaction => 'New Transaction';

  @override
  String get noPermission => 'No Permission';

  @override
  String get selected => 'Selected';

  @override
  String selectedCount(int count) {
    return 'Selected · $count';
  }

  @override
  String get addRow => 'Add Row';

  @override
  String get diff => 'Diff';

  @override
  String get bulkTransfer => 'Bulk Transfer';

  @override
  String get editBulkTransfer => 'Edit Bulk Transfer';

  @override
  String get authorize => 'Authorize';

  @override
  String get reverse => 'Reverse';

  @override
  String get print => 'Print';

  @override
  String get unauthorize => 'Unauthorize';

  @override
  String get setReminder => 'Set reminder';

  @override
  String get sameAccount => 'Same account transfer is not allowed.';

  @override
  String get currencyMismatch =>
      'Currency doesn\'t match, both must same currency';

  @override
  String get debitAccount => 'Debit Account';

  @override
  String get creditAccount => 'Credit Account';

  @override
  String get balance => 'Balance';

  @override
  String get blocked => 'Blocked';

  @override
  String get newFundTransfer => 'New Fund Transfer';

  @override
  String get sameCurrencyForExchange =>
      'Debit and credit currencies must differ.';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get gender => 'Gender';

  @override
  String get dob => 'Date of birth';

  @override
  String get nationalId => 'National ID';

  @override
  String get debitor => 'Debitor';

  @override
  String get creditor => 'Creditor';

  @override
  String get noBalance => 'No Balance';

  @override
  String get statement => 'Statement';

  @override
  String get addAccount => 'Add Account';

  @override
  String get accountLimit => 'Account Limit';

  @override
  String get accountStatus => 'Account Status';

  @override
  String get accountActiveMsg => 'Account is available for transactions';

  @override
  String get accountBlockMsg => 'Account is blocked for transactions.';

  @override
  String get ccyChangeWarnings =>
      'Currency cannot be changed if the account has recorded transactions.';

  @override
  String get permissions => 'Permissions';

  @override
  String get userProfile => 'User Profile';

  @override
  String get password8Char => 'Password must be at least 8 characters';

  @override
  String get passwordUpperCase =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordLowerCase =>
      'Password must contain at least one lowercase letter';

  @override
  String get passwordWithDigit => 'Password must contain at least one digit';

  @override
  String get passwordWithSpecialChar =>
      'Password must contain at least one special character';

  @override
  String get usernameMinLength => 'Username must be at least 4 characters';

  @override
  String get usernameNoStartDigit => 'Username cannot start with a number';

  @override
  String get usernameInvalidChars =>
      'Username can only contain letters, numbers, . or _';

  @override
  String get usernameNoSpaces => 'Username cannot contain spaces';

  @override
  String get changePassowrd => 'Change Password';

  @override
  String get oldPassword => 'Old Passwor';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Re-enter password';

  @override
  String get passwordNotMatch => 'Passwords don\'t match.';

  @override
  String get users => 'Users';

  @override
  String get attendance => 'Attendance';

  @override
  String get employees => 'Employees';

  @override
  String get hrTitle => 'Human Resources Management';

  @override
  String get emailExists => 'Email already exists, try another';

  @override
  String get usernameExists => 'Username already exists, try another';

  @override
  String get addUser => 'Add User';

  @override
  String get userOwner => 'User owner';

  @override
  String get editRole => 'Edit Role';

  @override
  String get addRole => 'Add Role';

  @override
  String get roleName => 'Role name';

  @override
  String get userRole => 'User Role';

  @override
  String get errorTitle => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get forceChangePassword => 'Change Password after login';

  @override
  String get forceEmailVerification => 'Email Verification';

  @override
  String get view => 'View';

  @override
  String get editUser => 'Edit User';

  @override
  String get block => 'Block';

  @override
  String get unblock => 'Activate';

  @override
  String get transport => 'Transport';

  @override
  String get inventory => 'Inventory';

  @override
  String get reports => 'Reports';

  @override
  String get actions => 'Actions';

  @override
  String get roleActions => 'Role Actions';

  @override
  String get grantAll => 'Grant All';

  @override
  String get revokeAll => 'Revoke All';

  @override
  String get restoreDefault => 'Restore Default';

  @override
  String get counts => 'Counts';

  @override
  String get exchangeRateGraph => 'Exchange Rate Graph';

  @override
  String get dailyTransactionsGraph => 'Daily Transactions Graph';

  @override
  String get dailyTransactionTotals => 'Daily Transaction Totals';

  @override
  String get digitalClock => 'Digital Clock';

  @override
  String get exchangeRates => 'Exchange Rates';

  @override
  String get profitLossGraph => 'Profit Loss Graph';

  @override
  String get reminderNotifications => 'Reminder Notifications';

  @override
  String get currencyTab => 'Currency Tab';

  @override
  String get currency => 'Currency';

  @override
  String get glAccounts => 'GL Accounts';

  @override
  String get allTransactions => 'All Transactions';

  @override
  String get authorizedTransaction => 'Authorized Transaction';

  @override
  String get pendingTransaction => 'Pending Transaction';

  @override
  String get incomeEntry => 'Income Entry';

  @override
  String get expenseEntry => 'Expense Entry';

  @override
  String get ftSingleAccount => 'FT Single Account';

  @override
  String get ftMultiAccount => 'FT Multi Account';

  @override
  String get fxTransactions => 'FX Transactions';

  @override
  String get individuals => 'Individuals';

  @override
  String get allUsers => 'All Users';

  @override
  String get userLog => 'User Log';

  @override
  String get shipping => 'Shipping';

  @override
  String get drivers => 'Drivers';

  @override
  String get vehicles => 'Vehicles';

  @override
  String get ordersTab => 'Orders Tab';

  @override
  String get estimateTab => 'Estimate Tab';

  @override
  String get goodsShiftTab => 'Goods Shift Tab';

  @override
  String get adjustmentTab => 'Adjustment Tab';

  @override
  String get purchase => 'Purchase';

  @override
  String get sale => 'Sale';

  @override
  String get estimate => 'Estimate';

  @override
  String get goodsShift => 'Goods Shift';

  @override
  String get adjustment => 'Adjustment';

  @override
  String get findInvoice => 'Find Invoice';

  @override
  String get generalTab => 'General Tab';

  @override
  String get passwordChange => 'Password Change';

  @override
  String get rolesAndPermissions => 'Roles and Permissions';

  @override
  String get companyTab => 'Company Tab';

  @override
  String get transactionType => 'Transaction Type';

  @override
  String get products => 'Products';

  @override
  String get about => 'About';

  @override
  String get accountStatementSingleDate => 'Account Statement Single Date';

  @override
  String get glStatementSingleDate => 'GL Statement Single Date';

  @override
  String get glStatementPeriodicDate => 'GL Statement Periodic Date';

  @override
  String get creditors => 'Creditors';

  @override
  String get debtors => 'Debtors';

  @override
  String get stockAvailability => 'Stock Availability';

  @override
  String get productMovement => 'Product Movement';

  @override
  String get purchaseInvoices => 'Purchase Invoices';

  @override
  String get saleInvoices => 'Sale Invoices';

  @override
  String get allInvoices => 'All Invoices';

  @override
  String get cashBalanceAllBranch => 'Cash Balance All Branch';

  @override
  String get cashBalanceSingleBranch => 'Cash Balance Single Branch';

  @override
  String get trialBalance => 'Trial Balance';

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get transactionsReport => 'Transactions Report';

  @override
  String get allBalances => 'All Balances';

  @override
  String get userRoleAndPermission => 'User Role and Permission';

  @override
  String get stakeholderAccount => 'Stakeholder Account';

  @override
  String get currencies => 'Currencies';

  @override
  String get balanceSheet => 'Balance Sheet';

  @override
  String get read => 'Read';

  @override
  String get language => 'Language';

  @override
  String get printers => 'Printers';

  @override
  String get portrait => 'Portrait';

  @override
  String get landscape => 'Landscape';

  @override
  String get orientation => 'Orientation';

  @override
  String get paper => 'Paper';

  @override
  String get printPreview => 'Print Preview';

  @override
  String get copies => 'Copies';

  @override
  String get share => 'Share';

  @override
  String get fromDate => 'From date';

  @override
  String get toDate => 'To date';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get availableBalance => 'Available Balance';

  @override
  String get accountStatement => 'Account Statement';

  @override
  String get copied => 'Copied';

  @override
  String get copyClipboard => 'Copy clipboard';

  @override
  String get typeMessageHere => 'Type message here';

  @override
  String get signatory => 'Signatory';

  @override
  String get dearCustomer => 'Dear Customer';

  @override
  String get regardsTitle => 'Regards,';

  @override
  String get balanceMessageShare => 'Please find your balance here';

  @override
  String get accountPosition => 'Account Position';

  @override
  String get yes => 'Yes';

  @override
  String get glStatement => 'GL Statement';

  @override
  String get assets => 'ASSETS';

  @override
  String get liabilitiesEquity => 'LIABILITIES AND EQUITY';

  @override
  String get currentAssets => 'Current Assets';

  @override
  String get fixedAssets => 'Fixed Assets';

  @override
  String get intangibleAssets => 'Intangible Assets';

  @override
  String get currentLiabilities => 'Current Liabilities';

  @override
  String get ownerEquity => 'Owner\'s Equity';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get totalAssets => 'TOTAL ASSETS';

  @override
  String get totalLiabilitiesEquity => 'TOTAL LIABILITIES & EQUITY';

  @override
  String get totalTitle => 'Total';

  @override
  String get currentYear => 'Current Year';

  @override
  String get noData => 'No data available';
}
