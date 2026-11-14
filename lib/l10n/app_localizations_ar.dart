// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get hello_world => 'سلام، ټول شیان راغلي دي';

  @override
  String get lightMode => 'روښانه حالت';

  @override
  String get darkMode => 'توره حالت';

  @override
  String get systemMode => 'سیستم حالت';

  @override
  String get cancel => 'لغوه کول';

  @override
  String get save => 'خوندي کول';

  @override
  String get selectAll => 'ټول ټاکل';

  @override
  String get selectYear => 'کال ټاکل';

  @override
  String get selectKeyword => 'ټاکل';

  @override
  String get today => 'نن';

  @override
  String get selectDate => 'نېټه ټاکل';

  @override
  String get yesterday => 'پرون';

  @override
  String get lastweek => 'تېره اونۍ';

  @override
  String get lastMonth => 'تېره میاشت';

  @override
  String get allTime => 'ټول وخت';

  @override
  String get thisYear => 'سږکال';

  @override
  String get lastYear => 'تېر کال';

  @override
  String get lastThreeMonth => 'تېرې درې میاشتې';

  @override
  String get thisMonth => 'دا میاشت';

  @override
  String get current => 'اوسنی';

  @override
  String get loginTitle => 'ننوتل';

  @override
  String get usrName => 'کارن نوم';

  @override
  String get usrPass => 'پټنوم';

  @override
  String required(String name) {
    return '$name اړین دی';
  }

  @override
  String get rememberMe => 'ما په یاد وساته';

  @override
  String get logout => 'وتل';

  @override
  String get accessDenied => 'اجازه نه لري';

  @override
  String get confirmLogout => 'ایا غواړئ له اپلیکیشن ووځئ؟';

  @override
  String get settings => 'تنظیمات';

  @override
  String get dashboard => 'ډشبورډ';

  @override
  String get prescription => 'نسخه';

  @override
  String get medicine => 'درمل';

  @override
  String get report => 'راپورونه';

  @override
  String get organization => 'اداره';

  @override
  String get update => 'تازه کول';

  @override
  String get create => 'ثبتول';

  @override
  String get editMedicine => 'د درملو تازه کول';

  @override
  String get newMedicine => 'نوی درمل ثبتول';

  @override
  String get medicineName => 'د درملو نوم';

  @override
  String get unit => 'واحد';

  @override
  String get dosage => 'د کارولو اندازه';

  @override
  String get brand => 'برنډ یا شرکت';

  @override
  String get category => 'بخش';

  @override
  String get selectCategory => 'ډول ټاکل';

  @override
  String get successTitle => 'بریالی';

  @override
  String get failed => 'ناکام';

  @override
  String get noStock => 'نشته';

  @override
  String get dispense => 'تجویزول';

  @override
  String get stock => 'ذخیره';

  @override
  String get patient => 'ناروغ';

  @override
  String get regNo => 'د ثبت شمېره';

  @override
  String get patientName => 'د ناروغ نوم';

  @override
  String get age => 'عمر';

  @override
  String get days => 'ورځې';

  @override
  String get instruction => 'د درملو لارښوونه';

  @override
  String get qty => 'شمېر';

  @override
  String get prescriptions => 'نسخې';

  @override
  String get noPrescriptionToday => 'نسخه ونه موندل شوه';

  @override
  String get systemSettings => 'سیستم';

  @override
  String get am => 'ق.ظ';

  @override
  String get pm => 'ب.ظ';

  @override
  String get emailOrUsername => 'کاربر حساب او ایمیل';

  @override
  String get zaitoonTitle => 'زیتون';

  @override
  String get softwareCompany => 'نرم افزار شرکت';

  @override
  String get welcomeBack => 'بیا ښه راغلاست';

  @override
  String get signIn => 'ننوتل';

  @override
  String get shippingManagement => 'سافټویر شرکت';

  @override
  String get sign_in_subtitle => 'د دوام لپاره مهرباني وکړئ ننوتل وکړئ.';

  @override
  String get email => 'برېښنالیک';

  @override
  String get show_password => 'ښودل';

  @override
  String get hide_password => 'پټول';

  @override
  String get invalid_email => 'ناسم برېښنالیک';

  @override
  String get password_min_length => 'لږ تر لږه ۴ توري';

  @override
  String get fill_all_fields => 'مهرباني وکړئ ټول ساحې ډکې کړئ.';

  @override
  String get dont_have_account => 'حساب نه لرئ؟';

  @override
  String get contact_admin => 'د مدیر سره اړیکه';

  @override
  String copyright(Object year) {
    return '© $year زیتون سافټویر شرکت';
  }

  @override
  String get shipping_management => 'د لیږد مدیریت';

  @override
  String get shipping_subtitle =>
      'د بارونو، چلوونکو او لارو مدیریت لپاره ننوتل وکړئ.';

  @override
  String get software_company => 'سافټویر شرکت';

  @override
  String get finance => 'مالی مدیریت';

  @override
  String get hr => 'بشری منابع';

  @override
  String get stakeholders => 'سهم لرونکی';

  @override
  String get transactions => 'تراکنش ها';

  @override
  String get shipment => 'محموله ها';

  @override
  String get settingsHint => 'خپل تنظیمات تنظیم کړئ';

  @override
  String get noInternet => 'انټرنیټ اړیکه نشته. مهرباني وکړئ خپله اړیکه وګورئ.';

  @override
  String get timeOutMessage =>
      'غوښتنه وخت پای ته ورسېد. مهرباني وکړئ بیا هڅه وکړئ.';

  @override
  String get requestCancelMessage => 'غوښتنه لغوه شوه.';

  @override
  String get badRequest => 'ناسمه غوښتنه. مهرباني وکړئ خپل معلومات وګورئ.';

  @override
  String get unAuthorized => 'تاسو اجازه نه لرئ. مهرباني وکړئ بیا ننوځئ.';

  @override
  String get forbidden => 'لاسرسی بند دی. تاسو اجازه نه لرئ.';

  @override
  String get url404 => 'غوښتل شوی سرچینه ونه موندل شوه.';

  @override
  String get notAllowedError => 'دا طریقه اجازه نه لري.';

  @override
  String get internalServerError =>
      'د سرور داخلي خطا. مهرباني وکړئ وروسته هڅه وکړئ.';

  @override
  String get serviceUnavailable => 'خدمت نشته. مهرباني وکړئ وروسته هڅه وکړئ.';

  @override
  String get serverError => 'د سرور خطا';

  @override
  String get networkError => 'د شبکې خطا. مهرباني وکړئ بیا هڅه وکړئ.';

  @override
  String get incorrectCredential => 'یوزر یا رمز عبور نادرست است';

  @override
  String get delete => 'پاک کول';

  @override
  String get submit => 'ثبت';

  @override
  String get crop => 'قطع کول';

  @override
  String get rate => 'نرخ';

  @override
  String get currencyTitle => 'اسعار';

  @override
  String get refresh => 'تازه کول';

  @override
  String get newKeyword => 'نوی';

  @override
  String get fxRate => 'اسعارو نرخ';

  @override
  String get accountExistMsg => 'حساب به این نام از قبل موجود است';

  @override
  String get operationFailedMsg => 'عملیات ناموفق، لطفا بعدا تلاش نمایید';

  @override
  String get glDependingMsg => 'حساب قبلا در معاملات استفاده شده است';

  @override
  String get asset => 'شتمنی';

  @override
  String get liability => 'بدهی';

  @override
  String get income => 'عواید';

  @override
  String get expense => 'مصرفونه';

  @override
  String get accountCategory => 'حساب بخش';

  @override
  String get all => 'تول';

  @override
  String get noDataFound => 'هیچ اطلاعات یافت نشد';

  @override
  String get accountNumber => 'حساب شمیره';

  @override
  String get accountName => 'حساب نوم';

  @override
  String get edit => 'ویرایش';

  @override
  String get subCategory => 'فرعی بخش';

  @override
  String get glAccount => 'حسابهای سیستم';

  @override
  String get areYouSure => 'آیا مطمئین هستید؟';

  @override
  String get male => 'نارینه';

  @override
  String get female => 'زن';

  @override
  String get overview => 'پروفایل';

  @override
  String get branchLimit => 'حد نمایندگی';

  @override
  String get amount => 'مبلغ';

  @override
  String get unlimited => 'نامحدود';

  @override
  String get branchName => 'نمایندگی نوم';

  @override
  String get branchCode => 'نمایندگی کد';

  @override
  String get mobile1 => 'اریکه شمیره 1';

  @override
  String get zipCode => 'زیپ کد';

  @override
  String get country => 'هیواد';

  @override
  String get province => 'ولایت';

  @override
  String get address => 'پته';

  @override
  String get city => 'شهر';

  @override
  String get profile => 'پروفایل';

  @override
  String get branch => 'نمایندگی';

  @override
  String get storage => 'گدام';

  @override
  String get successMsg => 'عملیات موفقانه انجام شد';

  @override
  String get whatsApp => 'واتساپ';

  @override
  String get baseCurrency => 'ارز پایه سیتم';

  @override
  String get socialMedia => 'صفحات اجتماعی';

  @override
  String get website => 'ویب سایت';

  @override
  String get facebook => 'فیسبوک';

  @override
  String get instagram => 'انستاگرام';

  @override
  String get location => 'موقعیت';

  @override
  String get details => 'جزئیات';

  @override
  String get status => 'حالت';

  @override
  String get active => 'فعال';

  @override
  String get inactive => 'غیرفعال';

  @override
  String get editProfile => 'د پروفایل سمون';

  @override
  String get comDetails => 'شرکت معلومات';

  @override
  String get addressHint => 'د شرکت د پتې مدیریت';

  @override
  String get socialMediaHint => 'د ټولنیزو رسنیو د پروفایل مدیریت';

  @override
  String get companyDetailsHint => 'د شرکت د معلوماتو مدیریت';

  @override
  String get companyLicence => 'د سوداګرۍ جواز';

  @override
  String get payableDue => 'رسېدلې ورکړه';

  @override
  String get receivableDue => 'رسېدونکی طلب';

  @override
  String get dueType => 'د سررسید ډول';

  @override
  String get filterByStatus => 'د حالت فلټر';

  @override
  String get reminders => 'یادونه';

  @override
  String get dueDate => 'سررسید نیته';

  @override
  String get accounts => 'حسابونه';

  @override
  String get accNameOrNumber => 'د حساب نوم یا شمېره';

  @override
  String get amountGreaterZero => 'مقدار باید له صفر څخه لوی وي';

  @override
  String get account => 'حساب';

  @override
  String get dueToday => 'د نن نېټې موعد';

  @override
  String get dueTomorrow => 'د سبا موعد';

  @override
  String get day => 'ورځ';

  @override
  String get overdueBy => 'په ځنډ';

  @override
  String get overdueByOne => '۱ ورځ په ځنډ';

  @override
  String get noReminder => 'هېڅ یادونه نشته';

  @override
  String get done => 'بشپړ شو';

  @override
  String get aboat => 'په اړه';

  @override
  String get company => 'شرکت';

  @override
  String get backup => 'بیک اپ';

  @override
  String get generalSettings => 'عمومی';

  @override
  String get fiscalYear => 'د مالي کال تړل';

  @override
  String get payroll => 'معاشات';

  @override
  String get manageFinance => 'د شرکت مالي مدیریت';

  @override
  String get profitAndLoss => 'ګټه او تاوان';

  @override
  String get eoyClosing => 'د مالي کال تړل';

  @override
  String get summary => 'مالي لنډیز';

  @override
  String get noPandLMessage => 'د ګټې او تاوان راپور لپاره معلومات نشته';

  @override
  String get proceed => 'اقدام کردن';

  @override
  String get retainedEarnings => 'انباشته ګټه';

  @override
  String get remark => 'څرګندونې';

  @override
  String get debit => 'دبت';

  @override
  String get credit => 'کریدت';

  @override
  String get total => 'ټولټال';

  @override
  String get attention => 'توجه';

  @override
  String get plMessage => 'ګټه او تاوان وتړل شي او انباشته ګټې ته ولېږدول شي؟';

  @override
  String get goodMorning => 'سهار مو پخیر';

  @override
  String get profileOverview => 'د پروفایل عمومي کتنه';

  @override
  String get search => 'لتون';

  @override
  String get narration => 'شرح';

  @override
  String get date => 'نېټه';

  @override
  String get reference => 'حواله شمیره';

  @override
  String get type => 'دول';

  @override
  String get maker => 'جوړوونکی';

  @override
  String get cashDeposit => 'نغدي دریافت';

  @override
  String get cashWithdraw => 'نغدي پرداخت';

  @override
  String get clearFilters => 'حذف فلتر';

  @override
  String get noTransaction => 'هیڅ معامله نشته';

  @override
  String get noTransactionMsg => 'د ښودلو لپاره هیڅ معامله نشته';

  @override
  String get dateRange => 'تاریخ رینچ';

  @override
  String get branches => 'نمایندگی ها';

  @override
  String get branchLimitHint => 'حد مجاز تأیید خودکار نمایندگی';

  @override
  String get fxTransaction => 'د اسعارو تبادله';

  @override
  String get bulkTransaction => 'معامله گروهی';

  @override
  String get pending => 'در انتظار';

  @override
  String get authorized => 'ر';

  @override
  String get reversed => 'لغوه شده';

  @override
  String get deleted => 'حذف شده';

  @override
  String get glDebit => 'جی ال دبت';

  @override
  String get glCredit => 'جی ال کریدت';

  @override
  String get exchange => 'تبادله';

  @override
  String get fundTransfer => 'حساب انتقال';

  @override
  String get journal => 'د پیسو لېږد او تبادله';

  @override
  String get cashFlow => 'جریان نقدی';

  @override
  String get tryAgain => 'امتحان دوباره';

  @override
  String get newTransaction => 'معامله جدید';

  @override
  String get noPermission => 'بدون صلاحیت';

  @override
  String get selected => 'تاکل شوی';

  @override
  String selectedCount(int count) {
    return 'انتخاب‌ شده · $count';
  }

  @override
  String get addRow => 'سطر جدید';

  @override
  String get diff => 'تفاوت';

  @override
  String get bulkTransfer => 'ټولیز لېږد';

  @override
  String get editBulkTransfer => 'ویرایش انتقال گروهی';

  @override
  String get authorize => 'تایید کول';

  @override
  String get reverse => 'برگشتاندن';

  @override
  String get print => 'چاپ';

  @override
  String get unauthorize => 'از تایید کشیدن';

  @override
  String get setReminder => 'تعیین یادآوری';

  @override
  String get sameAccount => 'انتقال بین حساب خود مجاز نیست';

  @override
  String get currencyMismatch =>
      'ارز حساب یکسان نیست، هر دو حساب باید ارز یکسان باشد';

  @override
  String get debitAccount => 'حساب دبت';

  @override
  String get creditAccount => 'حساب کریدت';

  @override
  String get balance => 'بیلانس';

  @override
  String get blocked => 'مسدود';

  @override
  String get newFundTransfer => 'نوی انتقال حساب';

  @override
  String get sameCurrencyForExchange => 'حساب ها باید ارز متفاوت داشته باشد';

  @override
  String get recentTransactions => 'آخرین معاملات';

  @override
  String get gender => 'جنسیت';

  @override
  String get dob => 'تاریخ تولد';

  @override
  String get nationalId => 'تذکره';

  @override
  String get debitor => 'بدهکار';

  @override
  String get creditor => 'طلبکار';

  @override
  String get noBalance => 'بی حساب';

  @override
  String get statement => 'صورتحساب';

  @override
  String get addAccount => 'نوی حساب';

  @override
  String get accountLimit => 'حد حساب';

  @override
  String get accountStatus => 'وضعیت حساب';

  @override
  String get accountActiveMsg => 'حساب برای معاملات آماده است';

  @override
  String get accountBlockMsg => 'حساب برای معاملات مسدود است';

  @override
  String get ccyChangeWarnings =>
      'درصورت موجود تراکنش ارز حساب قابل تغییر نیست';

  @override
  String get permissions => 'صلاحیت ها';

  @override
  String get userProfile => 'پروفایل کاربر';

  @override
  String get password8Char => 'پټنوم باید لږ تر لږه ۸ توري ولري';

  @override
  String get passwordUpperCase =>
      'پټنوم باید لږ تر لږه یو لوی انګلیسي توری ولري';

  @override
  String get passwordLowerCase =>
      'پټنوم باید لږ تر لږه یو کوچنی انګلیسي توری ولري';

  @override
  String get passwordWithDigit => 'پټنوم باید لږ تر لږه یوه شمېره ولري';

  @override
  String get passwordWithSpecialChar =>
      'پټنوم باید لږ تر لږه یو ځانګړی نښه ولري';

  @override
  String get usernameMinLength => 'کارن نوم باید لږ تر لږه ۴ توري ولري';

  @override
  String get usernameNoStartDigit => 'کارن نوم نشي کولی په شمېره پیل شي';

  @override
  String get usernameInvalidChars =>
      'کارن نوم یوازې توري، شمېرې، نقطه (.) یا کرښه (_) لرلی شي';

  @override
  String get usernameNoSpaces => 'کارن نوم نشي کولی تشه (space) ولري';

  @override
  String get changePassowrd => 'تغییر رمز عبور';

  @override
  String get oldPassword => 'رمز قبلی';

  @override
  String get newPassword => 'رمز عبور جدید';

  @override
  String get confirmPassword => 'تکرار رمز عبور';

  @override
  String get passwordNotMatch => 'رمز عبور همخوانی ندارد';

  @override
  String get users => 'یوزر ها';

  @override
  String get attendance => 'حضور و غیاب';

  @override
  String get employees => 'کارمندان';

  @override
  String get hrTitle => 'مدیریت منابع بشری';

  @override
  String get emailExists => 'این ایمیل از قبل استفاده شده است';

  @override
  String get usernameExists => 'نام کاربر تکراری است';

  @override
  String get addUser => 'کاربر جدید';

  @override
  String get userOwner => 'دارنده یوزر';

  @override
  String get editRole => 'ویرایش نقش';

  @override
  String get addRole => 'نقش جدید';

  @override
  String get roleName => 'نام نقش';

  @override
  String get userRole => 'نقش کاربر';

  @override
  String get errorTitle => 'خطا';

  @override
  String get retry => 'تلاش دوباره';

  @override
  String get forceChangePassword => 'تغییر رمز بعد ورود';

  @override
  String get forceEmailVerification => 'تایید ایمیل';

  @override
  String get view => 'مشاهده';

  @override
  String get editUser => 'ویرایش یوزر';

  @override
  String get block => 'مسدود کردن';

  @override
  String get unblock => 'فعال کردن';

  @override
  String get transport => 'ترانسپورت';

  @override
  String get inventory => 'ګدام';

  @override
  String get reports => 'راپورونه';

  @override
  String get actions => 'کړنې';

  @override
  String get roleActions => 'د رول کړنې';

  @override
  String get grantAll => 'ټولو ته اجازه ورکول';

  @override
  String get revokeAll => 'ټولې اجازې لغوه کول';

  @override
  String get restoreDefault => 'اصلي حالت ته راګرځول';

  @override
  String get counts => 'ارقام';

  @override
  String get exchangeRateGraph => 'نمودار نرخ تبادله';

  @override
  String get dailyTransactionsGraph => 'نمودار معاملات روزانه';

  @override
  String get dailyTransactionTotals => 'مجموع معاملات روزانه';

  @override
  String get digitalClock => 'ساعت دیجیتال';

  @override
  String get exchangeRates => 'نرخ اسعار';

  @override
  String get profitLossGraph => 'نمودار سود و زیان';

  @override
  String get reminderNotifications => 'اطلاعیه‌های یادآوری';

  @override
  String get currencyTab => 'تب اسعار';

  @override
  String get currency => 'ارز';

  @override
  String get glAccounts => 'حسابهای سیستم';

  @override
  String get allTransactions => 'همه معاملات';

  @override
  String get authorizedTransaction => 'معاملات مجاز';

  @override
  String get pendingTransaction => 'معاملات در انتظار';

  @override
  String get incomeEntry => 'ثبت عواید';

  @override
  String get expenseEntry => 'ثبت مصارف';

  @override
  String get ftSingleAccount => 'انتقال وجه تک‌ حسابی';

  @override
  String get ftMultiAccount => 'انتقال وجه گروهی';

  @override
  String get fxTransactions => 'معاملات ارزی';

  @override
  String get individuals => 'افراد';

  @override
  String get allUsers => 'همه یوزرها';

  @override
  String get userLog => 'سابقه کاربر';

  @override
  String get shipping => 'حمل و نقل';

  @override
  String get drivers => 'رانندگان';

  @override
  String get vehicles => 'وسایط';

  @override
  String get ordersTab => 'تب سفارشات';

  @override
  String get estimateTab => 'تب پیش‌بینی';

  @override
  String get goodsShiftTab => 'تب جابجایی اموال';

  @override
  String get adjustmentTab => 'تب تعدیلات';

  @override
  String get purchase => 'خرید';

  @override
  String get sale => 'فروش';

  @override
  String get estimate => 'پیش‌بینی';

  @override
  String get goodsShift => 'جابجایی اموال';

  @override
  String get adjustment => 'تعدیل';

  @override
  String get findInvoice => 'یافتن بل';

  @override
  String get generalTab => 'تب عمومی';

  @override
  String get passwordChange => 'تغییر رمز';

  @override
  String get rolesAndPermissions => 'نقش‌ها و دسترسی‌ها';

  @override
  String get companyTab => 'تب شرکت';

  @override
  String get transactionType => 'نوع معامله';

  @override
  String get products => 'کالا ها';

  @override
  String get about => 'درباره';

  @override
  String get accountStatementSingleDate => 'صورتحساب تاریخ واحد';

  @override
  String get glStatementSingleDate => 'صورت‌حساب دفتر کل تاریخ واحد';

  @override
  String get glStatementPeriodicDate => 'صورت‌حساب دفتر کل دوره‌ای';

  @override
  String get creditors => 'طلبکاران';

  @override
  String get debtors => 'بدهکاران';

  @override
  String get stockAvailability => 'موجودی اموال';

  @override
  String get productMovement => 'گردش کالاها';

  @override
  String get purchaseInvoices => 'بل‌ های خرید';

  @override
  String get saleInvoices => 'بل‌ های فروش';

  @override
  String get allInvoices => 'همه بل‌ها';

  @override
  String get cashBalanceAllBranch => 'بیلانس نقدی همه شعبات';

  @override
  String get cashBalanceSingleBranch => 'بیلانس نقدی شعبه واحد';

  @override
  String get trialBalance => 'بیلانس آزمایشی';

  @override
  String get transactionDetails => 'جزئیات معامله';

  @override
  String get transactionsReport => 'راپور معاملات';

  @override
  String get allBalances => 'همه بیلانس‌ها';

  @override
  String get userRoleAndPermission => 'نقش کاربر و دسترسی';

  @override
  String get stakeholderAccount => 'حساب سهامدار';

  @override
  String get currencies => 'اسعار';

  @override
  String get balanceSheet => 'د بیلانس شیټ';

  @override
  String get read => 'خواندن';

  @override
  String get language => 'ژبه';

  @override
  String get printers => 'دستگاه چاپ';

  @override
  String get portrait => 'عمودی';

  @override
  String get landscape => 'افقی';

  @override
  String get orientation => 'حالت صفحه';

  @override
  String get paper => 'کاغذ';

  @override
  String get printPreview => 'نمایش چاپ';

  @override
  String get copies => 'تعداد';

  @override
  String get share => 'اشتراک گذاشتن';

  @override
  String get fromDate => 'له نیته';

  @override
  String get toDate => 'به تاریخ';

  @override
  String get currentBalance => 'بیلانس کلی';

  @override
  String get availableBalance => 'بیلانس موجود';

  @override
  String get accountStatement => 'صورتحساب';

  @override
  String get copied => 'کاپی شد';

  @override
  String get copyClipboard => 'کاپی';

  @override
  String get typeMessageHere => 'متن را اینجا بنویسید';

  @override
  String get signatory => 'صلاحیت دار';

  @override
  String get dearCustomer => 'مشتری عزیز';

  @override
  String get regardsTitle => 'بااحترام';

  @override
  String get balanceMessageShare => 'صورتحساب شما';

  @override
  String get accountPosition => 'وضعیت حساب';

  @override
  String get yes => 'هو';

  @override
  String get glStatement => 'صورتحساب جی ال';

  @override
  String get assets => 'دارایی ګانې';

  @override
  String get liabilitiesEquity => 'بدهی ګانې او سرمایه';

  @override
  String get currentAssets => 'روانې دارایی ګانې';

  @override
  String get fixedAssets => 'ثابتې دارایی ګانې';

  @override
  String get intangibleAssets => 'ناسمه دارایی ګانې';

  @override
  String get currentLiabilities => 'روانې بدهی ګانې';

  @override
  String get ownerEquity => 'د مالک سرمایه';

  @override
  String get netProfit => 'خالصه ګټه';

  @override
  String get totalAssets => 'ټولې دارایی ګانې';

  @override
  String get totalLiabilitiesEquity => 'ټولې بدهی ګانې او سرمایه';

  @override
  String get totalTitle => 'ټول';

  @override
  String get currentYear => 'روان کال';

  @override
  String get noData => 'هیڅ معلومات نشته';

  @override
  String get totalCredit => 'مجموعه کریدت';

  @override
  String get totalDebit => 'مجموعه دبت';

  @override
  String get difference => 'تفاوت';

  @override
  String get actualBalance => 'بیلانس حقیقی';

  @override
  String get outOfBalance => 'عدم تعادل';

  @override
  String get authorizer => 'تایید کننده';

  @override
  String get cashBalance => 'صندوق';

  @override
  String get branchId => 'شناسه نمایندگی';

  @override
  String get currencyBalances => 'موجودی اسعار';

  @override
  String get openingBalance => 'بیلانس افتتاحیه';

  @override
  String get closingBalance => 'بیلانس اختتامیه';

  @override
  String get systemEquivalent => 'معادل سیستم';

  @override
  String get grandTotal => 'جمع کل';

  @override
  String get grandTotalCashFlow => 'جمع کل جریان نقدی';

  @override
  String get incomeStatement => 'سود و زیان';

  @override
  String get totalIncome => 'کل مفاد';

  @override
  String get totalExpense => 'کل مصارف';

  @override
  String get applyFilter => 'اعمال فلتر';

  @override
  String get expenses => 'مصارف';

  @override
  String get profit => 'مفاد';

  @override
  String get loss => 'زیان';

  @override
  String get financialPeriod => 'دوره مالی';

  @override
  String get loading => 'درحال بارگیری...';

  @override
  String get searchAccounts => 'جستجو حسابها';

  @override
  String get balanceFilter => 'فلتر بیلانس';

  @override
  String get filters => 'فلتر ها';

  @override
  String get apply => 'اعمال';

  @override
  String get databaseBackup => 'پتشیبانی داده ها';

  @override
  String get browse => 'جستجو';

  @override
  String get recentBackup => 'آخرین پشتیبانی ها';

  @override
  String get restoreBackup => 'بازیابی پشتیبانی';

  @override
  String get renameTitle => 'اصلاح نام';

  @override
  String get openInExplorer => 'باز کردن پوشه';

  @override
  String get restoreComplete => 'بازگردانی موفق';

  @override
  String get restoreSuccessMsg => 'دیتا موفقانه بازگردانی گردید.';

  @override
  String get downloadBackup => 'تهیه پشتیبانی';

  @override
  String get downloadBackupMsg => 'د خپلو معلوماتو بیک اپ واخلئ';

  @override
  String get creatingBackupMsg =>
      'د بیا رغونې مخکې د معلوماتو بیک اپ اخیستل کېږي...';

  @override
  String get saving => 'خوندي کېږي…';

  @override
  String get updating => 'تازه کېږي…';

  @override
  String get authorizing => 'تأییدېږي…';

  @override
  String get reversing => 'درحال برگشتاندن...';

  @override
  String get unauthorizing => 'درحال کشیدن از تایید...';

  @override
  String get deleting => 'در حال خذف...';

  @override
  String get addStakeholder => 'نوی سهمدار';

  @override
  String get searchStakeholders => 'جستجو سهمداران';

  @override
  String get stakeholderHint =>
      'ستاسو په سوداګرۍ کې د ښکېلو اشخاصو او ادارو مدیریت';

  @override
  String get employeeHint => 'د ټولو کارکوونکو کتل او مدیریت';

  @override
  String get searchEmployees => 'د کارکوونکو لټون';

  @override
  String get addEmployee => 'نوی کارکوونکی';

  @override
  String get department => 'دیپارتمنت';

  @override
  String get executiveManagement => 'اجرائیه مدیریت';

  @override
  String get operation => 'عملیات';

  @override
  String get it => 'معلوماتي ټکنالوژي';

  @override
  String get audit => 'پلټنه';

  @override
  String get procurement => 'تدارکات';

  @override
  String get marketing => 'بازار موندنه';

  @override
  String get sales => 'پلور';

  @override
  String get customerService => 'د پېرودونکو خدمتونه';

  @override
  String get legal => 'حقوقي';

  @override
  String get daily => 'ورځنی';

  @override
  String get monthly => 'میاشتنی';

  @override
  String get paymentMethod => 'د تادیې طریقه';

  @override
  String get hourly => 'ساعتي';

  @override
  String get salaryBased => 'د معاش پر بنسټ';

  @override
  String get editEmployee => 'د کارکوونکي سمون';

  @override
  String get firstName => 'لومړی نوم';

  @override
  String get lastName => 'تخلص';

  @override
  String get phone => 'د اړیکې شمېره';

  @override
  String get position => 'دنده';

  @override
  String get salaryAccount => 'د معاش حساب';

  @override
  String get salary => 'معاش';

  @override
  String get hireDate => 'د استخدام نېټه';

  @override
  String get endDate => 'د پای نېټه';

  @override
  String get taxInfo => 'د مالیې معلومات (TIN)';

  @override
  String get fingerprint => 'د ګوتې نښه';

  @override
  String get alreadyEmployed => 'دا شخص لا دمخه استخدام شوی دی';

  @override
  String get fieldsRequired => 'مهرباني وکړئ ټول اړین معلومات بشپړ کړئ';

  @override
  String get fieldRequired => 'مهرباني وکړئ ټول اړین معلومات بشپړ کړئ';

  @override
  String get salaryMustBeNumber => 'معاش باید یوه معتبره شمېره وي';

  @override
  String get usersHint => 'د کاروونکو، رولونو او لاسرسیو مدیریت';

  @override
  String get ccyName => 'ارز نوم';

  @override
  String get code => 'کد';

  @override
  String get allCurrencies => 'همه اسعار';

  @override
  String get localName => 'نام محلی';

  @override
  String get symbol => 'سمبول';

  @override
  String get flag => 'بیرق';

  @override
  String get transactionHint => 'خپلې ټولې مالي معاملې وګورئ او مدیریت یې کړئ';

  @override
  String get accountDetails => 'جزئیات حساب';

  @override
  String get inTitle => 'آمد';

  @override
  String get outTitle => 'رفت';

  @override
  String get systemDate => 'سیستم نیته';

  @override
  String get gregorian => 'میلادی';

  @override
  String get shamsi => 'هجری شمسی';

  @override
  String get theme => 'تم';

  @override
  String get financialReports => 'مالي راپورونه';

  @override
  String get accountStatementHint => 'د یوه حساب معاملې او روان بیلانس.';

  @override
  String get glStatementHint =>
      'د ټاکل شوي حساب لپاره د عمومي لېجر معاملې او بیلانسونه.';

  @override
  String get balanceSheetHint => 'تر ټاکلې نېټې پورې شتمنۍ، پورونه او سرمایه.';

  @override
  String get trialBalanceHint =>
      'د ډیبیټ او کریډیټ ټولیزه اندازه له اتومات توازن کتنې سره.';

  @override
  String get transactionDetailsHint => 'هره معامله د مرجع شمېرې له مخې ولټوئ.';

  @override
  String get cashBalanceHint => 'د اوسنۍ څانګې نغدي وضعیت.';

  @override
  String get treasuryHint => 'په ټولو څانګو کې نغدي وضعیت.';

  @override
  String get profitAndLossHint => 'د عاید او لګښت راپور.';

  @override
  String get receivables => 'د ترلاسه کولو وړ حسابونه';

  @override
  String get receivablesHint =>
      'هغه حسابونه چې پېرودونکي سوداګرۍ ته پوروړي وي.';

  @override
  String get payables => 'د ورکړې وړ حسابونه';

  @override
  String get payablesHint => 'هغه حسابونه چې سوداګري عرضه کوونکو ته پوروړې وي.';

  @override
  String get allBalancesHint => 'د ټولو حسابونو د بیلانس راپور.';

  @override
  String get allTransactionsHint => 'د ټولو معاملو ریکارډونه.';

  @override
  String get userLogHint => 'د کاروونکو فعالیتونه او لاګونه.';

  @override
  String get attendanceHint => 'د حاضرۍ او غیر حاضرۍ ریکارډونه.';

  @override
  String get transportCargo => 'ترانسپورت او بار وړنه';

  @override
  String get shipments => 'لېږدونې';

  @override
  String get shipmentsHint => 'د وارد شوو کانتینرونو لېست.';

  @override
  String get shipmentInvoice => 'د لېږدونې بل';

  @override
  String get shipmentInvoiceHint =>
      'د کانتینرونو پر بنسټ د پیرودونکو لپاره PDF یا Excel بل.';

  @override
  String get reportHint => 'د لیدلو لپاره یو راپور وټاکئ.';

  @override
  String get authorizationMakerOnly =>
      'یوازې د دې معاملې جوړوونکی کولای شي د هغې تأیید لغوه یا بیرته را وګرځوي.';

  @override
  String get authorizationInvalidState =>
      'دا معامله د تأیید لپاره په مناسب حالت کې نه ده.';

  @override
  String get authorizationPending =>
      'دا معامله لا دمخه د انتظار په حالت کې ده.';

  @override
  String get authorizationFailedProcess => 'دا معامله پروسس نه شوه.';

  @override
  String get authorizationFailed => 'تأیید ناکام شو.';

  @override
  String get newExchange => 'تبادله اسعار جدید';

  @override
  String get atLeastTwoRow =>
      'لږ تر لږه دوه قطارونه اضافه کړئ، یو بدهکار او یو بستانکار، چې ټولیز مبلغ یې یو شان وي.';

  @override
  String get totalDebitEqualCredit =>
      'د بدهکار ټولیز مبلغ باید د بستانکار له ټولیز مبلغ سره برابر وي.';

  @override
  String get rowsSameCcy =>
      'قطارونه بېلابېل اسعار کاروي. مهرباني وکړئ د ټولو قطارونو لپاره یو شان اسعار وټاکئ.';

  @override
  String get fileInfo => 'فایل معلومات';

  @override
  String get profilePhoto => 'پروفایل عکس';

  @override
  String get editProfileHint =>
      'خپل نوم، د ټیلیفون شمېره، برېښنالیک، د زېږون نېټه او پته تازه کړئ.';

  @override
  String get changePasswordHint =>
      'هغه پټنوم بدل کړئ چې د خپل حساب ته د ننوتلو لپاره یې کاروئ.';

  @override
  String get profilePhotoHint => 'د خپل پروفایل لپاره نوی انځور وټاکئ';

  @override
  String get uploading => 'درحال بارگیری...';

  @override
  String get transfer => 'حواله ها';

  @override
  String get completed => 'تکمیل شده';

  @override
  String get confirm => 'تایید کردن';

  @override
  String get orders => 'فرمایشات';

  @override
  String get orderSubtitle => 'مدیریت خرید و فروش';

  @override
  String get party => 'طرف حساب';

  @override
  String get invoiceType => 'نوع بل';

  @override
  String get totalInvoice => 'مجموعه بل';

  @override
  String get deselectAll => 'لغو انتخاب همه';

  @override
  String get newSale => 'بل فروش';

  @override
  String get newPurchase => 'بل خرید';

  @override
  String get goodShift => 'انتقال اجناس';

  @override
  String get productName => 'نام جنس';

  @override
  String get batchTitle => 'مقدار';

  @override
  String get unitPrice => 'نرخ';

  @override
  String get searchProducts => 'جستجو اجناس';

  @override
  String get pricing => 'قیمت ها';

  @override
  String get avgPrice => 'اوسط';

  @override
  String get recentPrice => 'آخرین خرید';

  @override
  String get sellPrice => 'قیمت فروش';

  @override
  String get landedCost => 'قیمت تمامشد';

  @override
  String get productDetails => 'جزئیات کالا';

  @override
  String get available => 'موجود';

  @override
  String get productCode => 'کد محصول';

  @override
  String get madeIn => 'ساخت';

  @override
  String get totalItems => 'مجموعه اجناس';

  @override
  String get productImages => 'تصاویر';

  @override
  String get nameAndDescriptions => 'نام و جزئیات';

  @override
  String get newProduct => 'محصول جدید';

  @override
  String get productAlreadyExist => 'این محصول از قبل موجود است';

  @override
  String get stockPaper => 'سند انبار';

  @override
  String get saleEntry => 'ثبت فروش';

  @override
  String get customers => 'مشتریان';

  @override
  String get paymentSummary => 'جزئیات پرداخت';

  @override
  String get newBalance => 'بیلانس نهایی';

  @override
  String get cash => 'نقدی';

  @override
  String get cashPayment => 'پرداخت نقدی';

  @override
  String get cashAmount => 'مبلغ نقدی';

  @override
  String get fullCashPayment => 'پرداخت نقدی';

  @override
  String get payment => 'پرداخت';

  @override
  String get selectAccount => 'انتخاب حساب';

  @override
  String get discount => 'تخفیف';

  @override
  String get addItem => 'سطر جدید';

  @override
  String get selectCustomer => 'مهرباني وکړئ پېرودونکی وټاکئ';

  @override
  String get invalidCashAmount => 'د نغدي تادیې اندازه سمه نه ده';

  @override
  String get selectCreditAccountMsg => 'مهرباني وکړئ اعتباري حساب وټاکئ';

  @override
  String get addItemMsg => 'مهرباني وکړئ لږ تر لږه یو توکی اضافه کړئ';

  @override
  String get addProductMsg => 'مهرباني وکړئ د ټولو توکو لپاره محصول وټاکئ';

  @override
  String get addValidPrice => 'مهرباني وکړئ د پلور معتبره بیه دننه کړئ';

  @override
  String get addValidQty => 'مهرباني وکړئ معتبر مقدار دننه کړئ';

  @override
  String get notEnoughMsg => 'کافي موجودي نشته:';

  @override
  String get overLimitMessage =>
      'د راکړې ورکړې اندازه له ټاکلي حد څخه زیاته ده';

  @override
  String get accountBlockedMessage => 'حساب بند شوی دی';

  @override
  String get invoiceSummary => 'د بل لنډیز';

  @override
  String get subtotal => 'فرعي مجموعه';

  @override
  String get itemDiscounts => 'د توکو تخفیفونه';

  @override
  String get afterItemDiscount => 'له توکو د تخفیف وروسته';

  @override
  String get generalDiscount => 'عمومي تخفیف';

  @override
  String get extraCharges => 'اضافي لګښتونه';

  @override
  String get accountInformation => 'جزئیات حساب';

  @override
  String get amountAddedToAr => 'مبلغ قابل دریافت';

  @override
  String get localAmount => 'مبلغ محلی';

  @override
  String get addAgain => 'تکرار دوباره';

  @override
  String get duplicateEntry => 'ورودی تکراری';

  @override
  String get combinedPayment => 'پرداخت نقدی و حساب';

  @override
  String get orderSummary => 'جزئیات فرمایش';

  @override
  String get applyDiscount => 'اعمال تخفیف';

  @override
  String get mixTitle => 'نقدی و دریافتنی';

  @override
  String get totalQty => 'کل تعداد';

  @override
  String get grade => 'درجه';

  @override
  String get model => 'مدل';

  @override
  String get basicInformation => 'معلومات اولیه';

  @override
  String get addNewProduct => 'محصول جدید';

  @override
  String get supplier => 'فروشنده';

  @override
  String get purchaseEntry => 'بل خرید';

  @override
  String get invoiceNumber => 'نمبر بل';

  @override
  String get payableAmount => 'مبلغ قابل پرداخت';

  @override
  String get accountPayable => 'قابل پرداخت';

  @override
  String get excelTitle => 'اکسل';

  @override
  String get manageProducts => 'محصولات خود را تنظیم کنید';

  @override
  String get importComplete => 'ورود محصولات موفقانه ثبت گردید';

  @override
  String get inserted => 'وارده';

  @override
  String get skipped => 'لغوشده';

  @override
  String get errored => 'خطا شده';

  @override
  String get productCategory => 'نوع کالا ها';

  @override
  String get invoiceBatch => 'بل عمده';

  @override
  String get invoiceBatchHint => 'فعال سازی تعداد عمده در بل ها';

  @override
  String get invoiceSettings => 'تنظیمات بل';

  @override
  String get invoiceProfitHint => 'فعال سازی نمایش سود و زیان در بل فروش';

  @override
  String get inventoryHint =>
      'فعال سازی سهام برای دسترسی به بل های خرید و فروش و انتقال اموال';

  @override
  String get stockReport => 'موجودی انبار';

  @override
  String get stockInOut => 'گردش کالا';

  @override
  String get stockActions => 'عملیات خرید و فروش';

  @override
  String get fromStorage => 'از گدام';

  @override
  String get toStorage => 'به گدام';

  @override
  String get totalIn => 'ورودی ها';

  @override
  String get totalOut => 'خروجی ها';

  @override
  String get stockBalance => 'موجودی گدام';

  @override
  String get inAndOut => 'ورود | خروج';

  @override
  String get movement => 'ورود | خروج';

  @override
  String get stockRecord => 'اجناس گدام';

  @override
  String get noProductSelectedTitle => 'کالا یافت نشد';

  @override
  String get noProductSelectedMsg => 'هیچ کالا برای گزارش انتخاب نشده است';

  @override
  String get invoice => 'بل';

  @override
  String get orderId => 'نمبربل';

  @override
  String get clear => 'پاک کردن';

  @override
  String get allProducts => 'ټول محصولات';

  @override
  String get mostSold => 'تر ټولو ډېر پلورل شوي';

  @override
  String get lessSold => 'تر ټولو لږ پلورل شوي';

  @override
  String get notSold => 'نه دي پلورل شوي';

  @override
  String get outOfStock => 'ناموجود';

  @override
  String get lowStock => 'تعداد کم';

  @override
  String get marketValue => 'کل ارزش بازار';

  @override
  String get shippingAndTransfer => 'باربری و حواله ها';

  @override
  String get shippingHint =>
      'لېږدونې اداره کړئ، سپارنې تعقیب کړئ او د بار وړلو عملیات وڅارئ.';

  @override
  String get moneyTransferHint =>
      'د پیسو لېږدونه په خوندي ډول واستوئ، ترلاسه یې کړئ او مدیریت یې کړئ.';

  @override
  String get noPermissionMessage => 'تاسو دې برخې ته د لاسرسي اجازه نه لرئ.';

  @override
  String get lock => 'قفل کردن';

  @override
  String get unlock => 'باز کردن';

  @override
  String get lockVerifyTitle => 'تایید';

  @override
  String get lockVerifyLockTitle => 'بندول';

  @override
  String get lockVerifyUnlockTitle => 'خلاصول';

  @override
  String get lockVerifyLockExplanation =>
      'بندول به دې شخص مالي معلومات له ټولو کاروونکو څخه تر هغه پټوي چې یو مدیر یې خلاص کړي.';

  @override
  String get lockVerifyUnlockExplanation =>
      'د دې شخص د خلاصولو لپاره خپل مدیر پټنوم ولیکئ.';

  @override
  String get lockVerifyVerifyExplanation =>
      'دا شخص بند دی. د لیدلو لپاره خپل مدیر پټنوم ولیکئ.';

  @override
  String get lockVerifyLockAction => 'بندول';

  @override
  String get lockVerifyUnlockAction => 'خلاصول';

  @override
  String get lockVerifyContinueAction => 'دوام';

  @override
  String get lockVerifyCancel => 'لغوه';

  @override
  String get lockVerifyPasswordLabel => 'د مدیر پټنوم';

  @override
  String get lockVerifyPasswordHint => 'خپل پټنوم ولیکئ';

  @override
  String get lockVerifySignedInAs => 'د دې په توګه ننوتلی';

  @override
  String get lockVerifyVerifiedTitle => 'تایید شو';

  @override
  String get lockVerifyVerifiedSubtitle => 'لاسرسی ورکړل شو';

  @override
  String get lockVerifyRelockingIn => 'بیا بندیدل په';

  @override
  String get lockVerifyRequired => 'اړین';

  @override
  String get lockVerifyFailed => 'تایید ناکام';

  @override
  String get lockVerifyWrongPassword => 'پټنوم غلط دی';

  @override
  String get lockedBalancesNotice =>
      'موجودي پټ دي. د دې پروفایل د خلاصولو لپاره له مدیر وغواړئ.';

  @override
  String get lockVerifyDeniedWrongPassword => 'کارن نوم یا پټنوم غلط دی.';

  @override
  String get lockVerifyDeniedWrongRole =>
      'ستاسو رول د دې شخص قفل بدلولو اجازه نه لري.';

  @override
  String get lockVerifyDeniedServerError =>
      'تایید ناکام شو. مهرباني وکړئ بیا هڅه وکړئ.';

  @override
  String get lockVerifyDeniedNetwork =>
      'د شبکې تېروتنه. مهرباني وکړئ خپل انټرنیټ وګورئ.';

  @override
  String get lockVerifyDeniedMissingUser =>
      'د دې کار لپاره باید لاسلیک شوی یاست.';

  @override
  String get lockVerifyDeniedPasswordRequired => 'مهرباني وکړئ پټنوم ولیکئ.';

  @override
  String get perCode => 'کد';

  @override
  String get editStakeholder => 'ویرایش سهمدار';

  @override
  String get personal => 'معلومات شخصی';

  @override
  String get proColor => 'رنگ کالا';

  @override
  String get minimumStock => 'حداقل تعداد';

  @override
  String get moreDetails => 'جزئیات بیشتر';

  @override
  String get noBatch => 'ناموجود';

  @override
  String get dateFilter => 'فلتر تاریخ';

  @override
  String get txnStatus => 'وضعیت تراکنش';

  @override
  String get txnType => 'نوع تراکنش';

  @override
  String get productCatHint => 'مدیریت نوع کالا ها';

  @override
  String get termsAndConditions => 'شرایط و قوانین';

  @override
  String get termsAndConditonsHint =>
      'فعال سازی شرایط و قوانین در چاپ بل های فروش';

  @override
  String get logoPrint => 'نمایش لوگو';

  @override
  String get textTermsAndConditionsHint =>
      'برای استفاده از شرایط پیش ‌فرض خالی بگذارید';

  @override
  String get customTermsHint =>
      'در صورت پر کردن، جای متن پیش‌فرض نمایش داده می‌شود.';

  @override
  String get resetToDefault => 'بازنشانی';

  @override
  String get logoPrintHint => 'نمایش لوگو در چاپ بل و صورتحساب';

  @override
  String get productMovementHint => 'راپور ورود و خروج کالا ها';

  @override
  String get stockBalanceHint => 'راپور موجودی کالاها در تمام گدام ها';

  @override
  String get saleInvoiceReportHint => 'راپور سوابق بل های فروش';

  @override
  String get purchaseInvoiceReportHint => 'راپور سوابق بل های خرید';

  @override
  String get watermark => 'واترمارک';

  @override
  String get no => 'نه';

  @override
  String get avgPurchasePrice => 'اوسط قیمت خرید';

  @override
  String get recentPurchasePrice => 'آخرین قیمت خرید';

  @override
  String get productId => 'کد کالا';

  @override
  String get customer => 'مشتری';

  @override
  String get recentSales => 'آخرین فروشات';
}
