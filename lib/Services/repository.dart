import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' hide MultipartFile;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shipping/Services/config.dart';
import '../Routes/Home/View/Dashboard/model/ds_model.dart';
import '../Routes/Home/View/Finance/View/Currencies/model/ccy_model.dart';
import '../Routes/Home/View/Finance/View/EOY/model/eoy_model.dart';
import '../Routes/Home/View/Finance/View/ExchangeRate/model/ex_rate_model.dart';
import '../Routes/Home/View/Finance/View/GlAccounts/GlCategories/model/cat_model.dart';
import '../Routes/Home/View/Finance/View/GlAccounts/model/gl_model.dart';
import '../Routes/Home/View/Finance/View/Reminder/model/reminder_model.dart';
import '../Routes/Home/View/HR/View/Attendance/model/attendance_model.dart';
import '../Routes/Home/View/HR/View/Employees/model/emp_model.dart';
import '../Routes/Home/View/HR/View/Users/model/user_model.dart';
import '../Routes/Home/View/HR/View/Users/model/usr_report_model.dart';
import '../Routes/Home/View/Report/AccountStatement/model/stmt_model.dart';
import '../Routes/Home/View/Report/AllBalances/model/all_balances_model.dart';
import '../Routes/Home/View/Report/ArAndAp/model/ar_ap_model.dart';
import '../Routes/Home/View/Report/BalanceSheet/model/bs_model.dart';
import '../Routes/Home/View/Report/GLStatement/model/gl_statement_model.dart';
import '../Routes/Home/View/Report/CashBalances/model/cash_balance_model.dart';
import '../Routes/Home/View/Report/IncomeStatement/model/income_stmt_model.dart';
import '../Routes/Home/View/Report/TrialBalance/model/trial_balance_model.dart';
import '../Routes/Home/View/Report/TxnByReference/model/txn_report_model.dart';
import '../Routes/Home/View/Report/TxnReport/TxnTypes/model/txn_types_model.dart';
import '../Routes/Home/View/Report/TxnReport/model/txn_report_model.dart';
import '../Routes/Home/View/Report/UserLog/model/user_log_model.dart';
import '../Routes/Home/View/Settings/View/Company/Branch/Ui/BranchLimits/model/limit_model.dart';
import '../Routes/Home/View/Settings/View/Company/Branches/model/branch_model.dart';
import '../Routes/Home/View/Settings/View/Company/CompanyProfile/model/com_model.dart';
import '../Routes/Home/View/Settings/View/Company/Storage/model/storage_model.dart';
import '../Routes/Home/View/Settings/View/General/DefaultPermissions/model/permission_settings_model.dart';
import '../Routes/Home/View/Settings/View/General/UserProfile/model/user_profile_model.dart';
import '../Routes/Home/View/Settings/View/General/UserRole/model/role_model.dart';
import '../Routes/Home/View/Stakeholder/model/stk_model.dart';
import '../Routes/Home/View/Transactions/View/CashWD/model/wd_model.dart';
import '../Routes/Home/View/Transactions/View/Exchange/model/ex_model.dart';
import '../Routes/Home/View/Transactions/View/FundTransfer/model/ft_model.dart';
import '../Routes/Home/View/Transactions/model/trn_model.dart';
import 'api_exception.dart';
import 'api_services.dart';

class Repositories {
  final ApiServices _api;

  const Repositories(this._api);

  // ═════════════════════════════════════════════════════════════════
// Reminders
// ═════════════════════════════════════════════════════════════════

  Future<List<ReminderModel>> getAlertReminders({
    int? alert,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/finance/reminders.php',
      queryParams: {
        'alerts': ?alert,
      },
      cancelToken: cancelToken,
    );

    final body = response.data;

    // Case 1: a plain array.
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => ReminderModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Case 2: a single object → wrap in a one-element list.
    if (body is Map<String, dynamic>) {
      return [ReminderModel.fromMap(body)];
    }
    if (body is Map) {
      return [ReminderModel.fromMap(Map<String, dynamic>.from(body))];
    }

    _fail(body, fallback: 'Failed to load reminders');
  }

  Future<void> addNewReminder({required ReminderModel newData}) async {
    final response = await _api.post(
      endpoint: '/finance/reminders.php',
      data: newData.toMap(),
    );
    _requireSuccess(response.data, fallback: 'Failed to add reminder');
  }

  Future<void> updateReminder({required ReminderModel newData}) async {
    final response = await _api.put(
      endpoint: '/finance/reminders.php',
      data: newData.toMap(),
    );
    _requireSuccess(response.data, fallback: 'Failed to update reminder');
  }

// ═════════════════════════════════════════════════════════════════
// Exchange rates
// ═════════════════════════════════════════════════════════════════
  Future<List<ExchangeRateModel>> getExchangeRate({
    String? ccyCode,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/finance/exchangeRate.php',
      queryParams: {
        if (ccyCode != null && ccyCode.isNotEmpty) 'ccy': ccyCode,
      },
      cancelToken: cancelToken,
    );
    return _parseList(
      response.data,
      ExchangeRateModel.fromMap,
      fallback: 'Failed to load exchange rates',
    );
  }

  Future<void> addExchangeRate({
    required ExchangeRateModel newRate,
  }) async {
    final response = await _api.post(
      endpoint: '/finance/exchangeRate.php',
      data: newRate.toMap(),
    );
    _requireSuccess(response.data, fallback: 'Failed to add exchange rate');
  }

  Future<String?> getSingleRate({
    required String fromCcy,
    required String toCcy,
  }) async {
    final response = await _api.post(
      endpoint: '/journal/getSingleExRate.php',
      data: {'ccyFrom': fromCcy, 'ccyTo': toCcy},
    );
    final body = _asMap(response.data);
    if (body == null) {
      throw ApiException('Invalid server response');
    }
    if (body['msg'] != null && body['msg']?.toString() != 'success') {
      _fail(body, fallback: 'Failed to get exchange rate');
    }
    return body['crExchange']?.toString();
  }
  // ═════════════════════════════════════════════════════════════════
  // Private helpers — the only place that decides "success vs error"
  // ═════════════════════════════════════════════════════════════════

  /// Returns a map view of the body, or null if it isn't a map.
  Map<String, dynamic>? _asMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    return null;
  }

  /// Returns a list view of the body, or null if it isn't a list.
  List<dynamic>? _asList(dynamic body) => body is List ? body : null;

  /// Extracts the server's error message from `error`, `message`, or `msg`.
  String? _serverMessage(dynamic body) {
    final map = _asMap(body);
    if (map == null) return null;
    final raw = map['error'] ?? map['message'] ?? map['msg'];
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Reads a numeric-or-string field as int.
  int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  /// Throws an [ApiException] built from a failed response.
  Never _fail(dynamic body, {String fallback = 'Request failed'}) {
    throw ApiException(_serverMessage(body) ?? fallback);
  }

  /// Parses a success response or throws [ApiException].
  Map<String, dynamic> _requireSuccess(
      dynamic body, {
        String fallback = 'Request failed',
      }) {
    final map = _asMap(body);
    if (map != null && map['msg']?.toString().toLowerCase() == 'success') {
      return map;
    }
    _fail(body, fallback: fallback);
  }

  /// Parses a response body as a typed list or throws [ApiException].
  List<T> _parseList<T>(
      dynamic body,
      T Function(Map<String, dynamic>) fromMap, {
        String fallback = 'Failed to load data',
      }) {
    final list = _asList(body);
    if (list == null) _fail(body, fallback: fallback);
    return list
        .whereType<Map>()
        .map((e) => fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ═════════════════════════════════════════════════════════════════
  // Authentication
  // ═════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _api.post(
      endpoint: '/user/login.php',
      data: {'usrName': username, 'usrPass': password},
    );
    final body = _asMap(response.data);
    if (body == null) {
      throw ApiException('Invalid server response');
    }
    return body;
  }

  Future<Map<String, dynamic>> fetchProfile({
    required String username,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/user/login.php',
      queryParams: {'username': username},
      cancelToken: cancelToken,
    );

    final body = _asMap(response.data);
    if (body == null) {
      throw ApiException('Invalid server response');
    }

    return body;
  }



  // ═════════════════════════════════════════════════════════════════
  // Stakeholders
  // ═════════════════════════════════════════════════════════════════
  Future<List<IndividualsModel>> getStakeholders({String? search}) async {
    final res = await _api.get(
      endpoint: '/stakeholder/personal.php',
      queryParams: {
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
      },
    );
    return _parseList(
      res.data,
      IndividualsModel.fromMap,
      fallback: 'Failed to load stakeholders',
    );
  }

  Future<IndividualsModel> getStakeholderById(int perId) async {
    final res = await _api.get(
      endpoint: '/stakeholder/personal.php',
      queryParams: {'perID': perId},
    );
    final body = res.data;

    final list = _asList(body);
    if (list != null) {
      if (list.isEmpty) {
        throw ApiException('Stakeholder not found');
      }
      return IndividualsModel.fromMap(
        Map<String, dynamic>.from(list.first as Map),
      );
    }

    // Some servers return a single object instead of a list.
    final map = _asMap(body);
    if (map != null && map['perId'] != null) {
      return IndividualsModel.fromMap(map);
    }
    _fail(body, fallback: 'Stakeholder not found');
  }

  Future<int> addStakeholder(IndividualsModel model) async {
    final res = await _api.post(
      endpoint: '/stakeholder/personal.php',
      data: model.toMap(),
    );
    final body = _requireSuccess(
      res.data,
      fallback: 'Failed to add stakeholder',
    );

    final raw = body['personalID'] ?? body['perID'] ?? body['id'];
    final id = _asInt(raw);
    if (id != null) return id;

    throw ApiException('Server returned success but no personal id');
  }

  Future<void> updateStakeholder(IndividualsModel model) async {
    final res = await _api.put(
      endpoint: '/stakeholder/personal.php',
      data: model.toMap(),
    );
    _requireSuccess(res.data, fallback: 'Failed to update stakeholder');
  }

  Future<void> deleteStakeholder(int perId) async {
    final res = await _api.delete(
      endpoint: '/stakeholder/personal.php?id=$perId',
      data: {'id': perId},
    );
    final body = _asMap(res.data);
    if (body == null) {
      throw ApiException('Failed to delete stakeholder');
    }

    final msg = body['msg']?.toString().toLowerCase() ?? '';
    final message = body['message']?.toString().toLowerCase() ?? '';
    if (msg == 'success' ||
        message.contains('deleted') ||
        message.contains('removed')) {
      return;
    }
    _fail(body, fallback: 'Failed to delete stakeholder');
  }

  // ═════════════════════════════════════════════════════════════════
  // Accounts
  // ═════════════════════════════════════════════════════════════════
  Future<List<StakeholderAccount>> getAccounts({
    int? perId,
    String? search,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/stakeholder/account.php',
      queryParams: {
        'perID': ?perId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      cancelToken: cancelToken,
    );
    return _parseList(
      response.data,
      StakeholderAccount.fromMap,
      fallback: 'Failed to load accounts',
    );
  }

  Future<Map<String, dynamic>> uploadStakeholderPhoto({
    required int perID,
    required Uint8List image,
  }) async {
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final formData = FormData.fromMap({
      'perID': perID.toString(),
      'image': MultipartFile.fromBytes(
        image,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    final response = await _api.uploadFile(
      endpoint: '/stakeholder/uploadPersonalPhoto.php',
      data: formData,
    );
    final body = _asMap(response.data);
    if (body == null) {
      throw ApiException('Invalid server response');
    }
    return body;
  }

  Future<int> addAccount({
    required String accName,
    required String actCurrency,
    required dynamic actCreditLimit,
    required int actSignatory,
  }) async {
    final res = await _api.post(
      endpoint: '/stakeholder/account.php',
      data: {
        'accName': accName,
        'actCurrency': actCurrency,
        'actCreditLimit': actCreditLimit,
        'actSignatory': actSignatory,
      },
    );
    final body = _requireSuccess(res.data, fallback: 'Failed to add account');
    final id = _asInt(body['accountNo'] ?? body['accountNumber'] ?? body['id']);
    if (id != null) return id;
    throw ApiException('Server returned success but no account number');
  }

  Future<void> editAccount({
    required int accNumber,
    String? accName,
    String? actCurrency,
    dynamic actCreditLimit,
    int? actStatus,
  }) async {
    final data = <String, dynamic>{'accNumber': accNumber};
    if (accName != null) data['accName'] = accName;
    if (actCurrency != null) data['actCurrency'] = actCurrency;
    if (actCreditLimit != null) data['actCreditLimit'] = actCreditLimit;
    if (actStatus != null) data['actStatus'] = actStatus;

    final res = await _api.put(
      endpoint: '/stakeholder/account.php',
      data: data,
    );
    final body = _asMap(res.data);

    if (body != null && body['msg']?.toString().toLowerCase() == 'success') {
      return;
    }

    // Currency change refused because transactions exist.
    if (body != null && body['error']?.toString() == 'trn_exists') {
      final count = body['transaction_count'];
      throw ApiException(
        'Cannot change currency. '
            '${count != null ? '$count transaction(s) exist for this account.' : 'There are existing transactions.'}',
      );
    }

    _fail(body, fallback: 'Failed to update account');
  }

  Future<void> blockAccount(int accNumber) =>
      editAccount(accNumber: accNumber, actStatus: 0);

  Future<void> unblockAccount(int accNumber) =>
      editAccount(accNumber: accNumber, actStatus: 1);

  Future<void> deleteAccount(int accNumber) async {
    final res = await _api.delete(
      endpoint: '/stakeholder/account.php?accNumber=$accNumber',
      data: {'accNumber': accNumber},
    );
    final body = _asMap(res.data);

    if (body != null && body['msg']?.toString().toLowerCase() == 'success') {
      return;
    }

    if (body != null && body['error']?.toString() == 'trn_exists') {
      final count = body['transaction_count'];
      throw ApiException(
        'Cannot delete account. '
            '${count != null ? '$count transaction(s) already recorded.' : 'There are existing transactions.'}',
      );
    }

    _fail(body, fallback: 'Failed to delete account');
  }

  // ═════════════════════════════════════════════════════════════════
  // Currencies
  // ═════════════════════════════════════════════════════════════════
  Future<List<CurrenciesModel>> getCurrencies({
    required int? status,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/finance/currency.php',
      queryParams: {
        // Omit `status` entirely when null → server returns all currencies.
        'status': ?status,
      },
      cancelToken: cancelToken,
    );
    return _parseList(
      response.data,
      CurrenciesModel.fromMap,
      fallback: 'Failed to load currencies',
    );
  }

  Future<void> updateCcyStatus({
    required bool status,
    required String? ccyCode,
  }) async {
    final response = await _api.put(
      endpoint: '/finance/currency.php',
      data: {
        'action': 'status',
        'ccyStatus': status ? 1 : 0,
        'ccyCode': ccyCode,
      },
    );
    _requireSuccess(
      response.data,
      fallback: 'Failed to update currency status',
    );
  }

  Future<void> addCurrency({required CurrenciesModel ccy}) async {
    final response = await _api.post(
      endpoint: '/finance/currency.php',
      data: ccy.toMap(),
    );
    _requireSuccess(response.data, fallback: 'Failed to add currency');
  }

  Future<void> updateCurrency({required CurrenciesModel ccy}) async {
    final response = await _api.put(
      endpoint: '/finance/currency.php',
      data: {
        'action': 'full',
        ...ccy.toMap(),
      },
    );
    _requireSuccess(response.data, fallback: 'Failed to update currency');
  }

  /// Transactions
  Future<Map<String, dynamic>> getTransactions({
    String status = 'all',
    String? from,
    String? to,
    String? type,
    int? branch,
    String? search,
  }) async {
    final response = await _api.get(
      endpoint: '/journal/getTransactions.php',
      queryParams: {
        'status': status,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        if (type != null && type.isNotEmpty) 'type': type,
        'branch': ?branch,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final body = _asMap(response.data);
    if (body == null) {
      throw ApiException('Invalid server response');
    }
    if (body['msg'] == 'failed') {
      throw ApiException(
        body['error']?.toString() ?? 'Failed to load transactions',
      );
    }
    return body;
  }

  // Future<TxnByReferenceModel> getTxnByReference({
  //   required String reference,
  //   CancelToken? cancelToken,
  // }) async {
  //   final response = await _api.get(
  //     endpoint: '/journal/getSingleTransaction.php',
  //     queryParams: {'ref': reference},
  //     cancelToken: cancelToken,
  //   );
  //
  //   final body = response.data;
  //
  //   // Case 1: a single object.
  //   final map = _asMap(body);
  //   if (map != null) {
  //     return TxnByReferenceModel.fromMap(map);
  //   }
  //
  //   // Case 2: a list — take the first element.
  //   final list = _asList(body);
  //   if (list != null && list.isNotEmpty && list.first is Map) {
  //     return TxnByReferenceModel.fromMap(
  //       Map<String, dynamic>.from(list.first as Map),
  //     );
  //   }
  //
  //   _fail(body, fallback: 'Failed to load transaction by reference');
  // }
  //
  // Future<FetchAtatModel> getATATByReference({
  //   required String reference,
  //   CancelToken? cancelToken,
  // }) async {
  //   final response = await _api.get(
  //     endpoint: '/journal/fundTransfer.php',
  //     queryParams: {'ref': reference},
  //     cancelToken: cancelToken,
  //   );
  //
  //   final body = response.data;
  //
  //   // Case 1: a single object.
  //   final map = _asMap(body);
  //   if (map != null) {
  //     return FetchAtatModel.fromMap(map);
  //   }
  //
  //   // Case 2: a list — take the first element.
  //   final list = _asList(body);
  //   if (list != null && list.isNotEmpty && list.first is Map) {
  //     return FetchAtatModel.fromMap(
  //       Map<String, dynamic>.from(list.first as Map),
  //     );
  //   }
  //
  //   _fail(body, fallback: 'Failed to load transfer by reference');
  // }

  Future<Map<String, dynamic>> cashFlowOperations({
    required TransactionDraft newTransaction,
  }) async {
    final response = await _api.post(
      endpoint: '/journal/cashWD.php',
      data: newTransaction.toMap(),
    );
    return _requireSuccess(
      response.data,
      fallback: 'Failed to process cash transaction',
    );
  }

  Future<Map<String, dynamic>> updateTxn({
    required TransactionDraft newTxn,
  }) async {
    final response = await _api.put(
      endpoint: '/journal/cashWD.php',
      data: newTxn.toMap(),
    );
    return _requireSuccess(
      response.data,
      fallback: 'Failed to update transaction',
    );
  }

  Future<Map<String, dynamic>> fundTransfer({
    required TransactionDraft newTransaction,
  }) async {
    final response = await _api.post(
      endpoint: '/journal/fundTransfer.php',
      data: newTransaction.toMap(),
    );
    return _requireSuccess(
      response.data,
      fallback: 'Failed to process fund transfer',
    );
  }

  Future<Map<String, dynamic>> bulkTransfer({
    required String userName,
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await _api.post(
      endpoint: '/journal/fundTransferMA.php',
      data: {'usrName': userName, 'records': records},
    );

    final body = response.data;

    // Success response is typically a map.
    final map = _asMap(body);
    if (map != null) return map;

    // Some servers respond with a bare string message.
    if (body is String) {
      return {'msg': body};
    }

    _fail(body, fallback: 'Failed to process bulk transfer');
  }

  Future<Map<String, dynamic>> fxTransfer({
    required String userName,
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await _api.post(
      endpoint: '/journal/crossCurrency.php',
      data: {'usrName': userName, 'records': records},
    );

    final body = response.data;

    final map = _asMap(body);
    if (map != null) return map;

    // Some servers respond with a bare string message; echo it back as
    // both `msg` and `account` to preserve the old contract.
    if (body is String) {
      return {'msg': body, 'account': body};
    }

    _fail(body, fallback: 'Failed to process FX transfer');
  }

  Future<Map<String, dynamic>> authorizeTxn({
    required String reference,
    required String? usrName,
  }) async {
    final response = await _api.put(
      endpoint: '/journal/transactionActivity.php',
      data: {'reference': reference, 'username': usrName},
    );

    final body = _asMap(response.data);
    if (body == null) throw ApiException('Invalid server response');

    final msg = body['msg']?.toString().toLowerCase() ?? '';

    // Accept both — PHP currently sends 'authorized'.
    if (msg == 'success' || msg == 'authorized') return body;

    // Anything else is a real failure.
    throw ApiException(
      body['error']?.toString() ??
          body['message']?.toString() ??
          (msg == 'invalid'
              ? 'Only the maker of this transaction can authorize it.'
              : msg == 'invalid action'
              ? 'This transaction is not in the right state to be authorized.'
              : msg == 'pending'
              ? 'This transaction is already pending.'
              : msg == 'failed'
              ? 'The transaction could not be processed.'
              : msg.isEmpty
              ? 'Authorization failed.'
              : msg),
    );
  }

  Future<Map<String, dynamic>> unAuthorizeTxn({
    required String reference,
    required String? usrName,
  }) async {
    final response = await _api.put(
      endpoint: "/journal/transactionActivity.php",
      data: {'action': 'unauthorize',"reference": reference, "username": usrName},
    );

    final body = _asMap(response.data);
    if (body == null) throw ApiException('Invalid server response');

    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg == 'success') return body;

    throw ApiException(
      body['error']?.toString() ??
          (msg == 'invalid'
              ? 'Only the maker of this transaction can unauthorize it.'
              : msg == 'invalid action'
              ? 'This transaction cannot be unauthorized in its current state.'
              : msg == 'failed'
              ? 'The transaction could not be unauthorized.'
              : msg.isEmpty
              ? 'Unauthorization failed.'
              : msg),
    );
  }

  Future<Map<String, dynamic>> reverseTxn({
    required String reference,
    required String? usrName,
  }) async {
    final response = await _api.post(
      endpoint: '/journal/transactionActivity.php',
      data: {'reference': reference, 'username': usrName},
    );
    return _requireSuccess(
      response.data,
      fallback: 'Failed to reverse transaction',
    );
  }

  Future<Map<String, dynamic>> deleteTxn({
    required String reference,
    required String? usrName,
  }) async {
    final response = await _api.delete(
      endpoint: '/journal/transactionActivity.php',
      data: {'reference': reference, 'username': usrName},
    );
    return _requireSuccess(
      response.data,
      fallback: 'Failed to delete transaction',
    );
  }


  // ═════════════════════════════════════════════════════════════════
// GL Accounts
// ═════════════════════════════════════════════════════════════════

  Future<List<GlAccountsModel>> getGl({
    String? input,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/finance/glAccount.php',
      queryParams: {
        if (input != null && input.trim().isNotEmpty) 'input': input.trim(),
      },
      cancelToken: cancelToken,
    );
    return _parseList(
      response.data,
      GlAccountsModel.fromMap,
      fallback: 'Failed to load GL accounts',
    );
  }

  Future<void> addGl({required GlAccountsModel newAccount}) async {
    final response = await _api.post(
      endpoint: '/finance/glAccount.php',
      data: newAccount.toMap(),
    );
    _requireSuccess(response.data, fallback: 'Failed to add GL account');
  }

  Future<void> editGl({required GlAccountsModel newAccount}) async {
    final response = await _api.put(
      endpoint: '/finance/glAccount.php',
      data: newAccount.toMap(),
    );
    _requireSuccess(response.data, fallback: 'Failed to update GL account');
  }

  Future<void> deleteGl({required int accNumber}) async {
    final response = await _api.delete(
      endpoint: '/finance/glAccount.php',
      data: {'acc': accNumber},
    );
    _requireSuccess(response.data, fallback: 'Failed to delete GL account');
  }

// ═════════════════════════════════════════════════════════════════
// GL Sub Categories
// ═════════════════════════════════════════════════════════════════

  Future<List<GlCategoriesModel>> getGlSubCategories({
    required int catId,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/finance/accountCategory.php',
      queryParams: {'cat': catId},
      cancelToken: cancelToken,
    );
    return _parseList(
      response.data,
      GlCategoriesModel.fromMap,
      fallback: 'Failed to load GL sub-categories',
    );
  }

  // ═════════════════════════════════════════════════════════════════
// Password settings
// ═════════════════════════════════════════════════════════════════

  Future<void> forceChangePassword({
    required String credential,
    required String newPassword,
  }) async {
    final response = await _api.put(
      endpoint: '/user/changePass.php',
      data: {'usrName': credential, 'usrPass': newPassword},
    );
    _requireSuccess(response.data, fallback: 'Failed to change password');
  }

  Future<void> changePassword({
    required String credential,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _api.post(
      endpoint: '/user/changePass.php',
      data: {
        'usrName': credential,
        'usrPass': oldPassword,
        'usrNewPass': newPassword,
      },
    );
    _requireSuccess(response.data, fallback: 'Failed to change password');
  }

  Future<void> resetPassword({
    required String credential,
    required String newPassword,
  }) async {
    final response = await _api.put(
      endpoint: '/user/users.php',
      data: {'credential': credential, 'newPassword': newPassword},
    );
    _requireSuccess(response.data, fallback: 'Failed to reset password');
  }

// ═════════════════════════════════════════════════════════════════
// Branches & limits
// ═════════════════════════════════════════════════════════════════

  Future<List<BranchModel>> getBranches({int? brcId, CancelToken? cancelToken,}) async {
    final response = await _api.get(
      endpoint: '/setting/branch.php',
      queryParams: {
        'brcID': ?brcId,
      },
      cancelToken: cancelToken,
    );
    return _parseList(
      response.data,
      BranchModel.fromMap,
      fallback: 'Failed to load branches',
    );
  }
  Future<void> addBranch({required BranchModel newBranch}) async {
    final response = await _api.post(
      endpoint: '/setting/branch.php',
      data: newBranch.toMap(),
    );
    _requireSuccess(response.data, fallback: 'Failed to add branch');
  }
  Future<void> updateBranch({required BranchModel newBranch}) async {
    final response = await _api.put(
      endpoint: '/setting/branch.php',
      data: newBranch.toMap(),
    );
    _requireSuccess(response.data, fallback: 'Failed to update branch');
  }
  Future<List<BranchLimitModel>> getBranchLimits({int? brcCode, CancelToken? cancelToken,}) async {
    final response = await _api.get(
      endpoint: '/setting/branchAuthLimit.php',
      queryParams: {
        'code': ?brcCode,
      },
      cancelToken: cancelToken,
    );
    return _parseList(
      response.data,
      BranchLimitModel.fromMap,
      fallback: 'Failed to load branch limits',
    );
  }
  Future<void> addEditBranchLimit({required BranchLimitModel newLimit}) async {
    final response = await _api.post(
      endpoint: '/setting/branchAuthLimit.php',
      data: newLimit.toMap(),
    );
    _requireSuccess(response.data, fallback: 'Failed to save branch limit');
  }

  // ═════════════════════════════════════════════════════════════════
  // Company profile
  // ═════════════════════════════════════════════════════════════════
  Future<CompanySettingsModel> getCompanyProfile({CancelToken? cancelToken,}) async {
    final response = await _api.get(
      endpoint: '/setting/companyProfile.php',
      cancelToken: cancelToken,
    );

    final body = response.data;

    // Case 1: a single JSON object.
    if (body is Map<String, dynamic>) {
      return CompanySettingsModel.fromMap(body);
    }

    // Case 2: an array — take the first element.
    if (body is List) {
      if (body.isEmpty) {
        throw ApiException('Company profile not found');
      }
      final first = body.first;
      if (first is Map<String, dynamic>) {
        return CompanySettingsModel.fromMap(first);
      }
      if (first is Map) {
        return CompanySettingsModel.fromMap(Map<String, dynamic>.from(first));
      }
    }

    _fail(body, fallback: 'Invalid company profile response');
  }
  Future<void> editCompanyProfile({required CompanySettingsModel newData,}) async {
    final response = await _api.put(
      endpoint: '/setting/companyProfile.php',
      data: newData.toMap(),
    );
    _requireSuccess(response.data, fallback: 'Failed to update company profile');
  }
  Future<void> uploadCompanyProfile({
    required Uint8List image,
    int comID = 1,
  }) async {
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final formData = FormData.fromMap({
      'comID': comID,
      'image': MultipartFile.fromBytes(
        image,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    final response = await _api.uploadFile(
      endpoint: '/setting/companyProfile.php',
      data: formData,
    );
    _requireSuccess(response.data, fallback: 'Failed to upload company profile');
  }


  // ═════════════════════════════════════════════════════════════════
  // Storage
  // ═════════════════════════════════════════════════════════════════
  Future<List<StorageModel>> getStorage({CancelToken? cancelToken}) async {
    final response = await _api.get(
      endpoint: '/setting/storage.php',
      cancelToken: cancelToken,
    );
    return _parseList(
      response.data,
      StorageModel.fromMap,
      fallback: 'Failed to load storage',
    );
  }
  Future<void> addStorage({required StorageModel newStorage}) async {
    final response = await _api.post(
      endpoint: '/setting/storage.php',
      data: newStorage.toMap(),
    );
    _requireSuccess(response.data, fallback: 'Failed to add storage');
  }
  Future<void> updateStorage({required StorageModel newStorage}) async {
    final response = await _api.put(
      endpoint: '/setting/storage.php',
      data: newStorage.toMap(),
    );
    _requireSuccess(response.data, fallback: 'Failed to update storage');
  }

  // ═════════════════════════════════════════════════════════════════
// Finance — EOY operation / P&L
// ═════════════════════════════════════════════════════════════════

  Future<void> eoyOperationProcess({
    required String usrName,
    required String remark,
    required int branchCode,
  }) async {
    final response = await _api.post(
      endpoint: '/finance/eoyOperation.php',
      data: {
        'usrName': usrName,
        'remark': remark,
        'parkingBranch': branchCode,
      },
    );
    _requireSuccess(response.data, fallback: 'Failed to run EOY operation');
  }

  Future<List<PAndLModel>> getProfitAndLoss({
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/finance/eoyOperation.php',
      cancelToken: cancelToken,
    );
    return _parseList(
      response.data,
      PAndLModel.fromMap,
      fallback: 'Failed to load profit and loss',
    );
  }

  // GET /journal/fundTransferMA.php?ref=…
  Future<Map<String, dynamic>> getBulkTransferByReference({
    required String reference,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/journal/fundTransferMA.php',
      queryParams: {'ref': reference},
      cancelToken: cancelToken,
    );

    final body = _asMap(response.data);
    if (body == null) {
      throw ApiException('Invalid server response');
    }

    final msg = body['msg']?.toString().toLowerCase();
    if (msg == 'failed' || msg == 'empty') {
      throw ApiException(
        body['error']?.toString() ??
            body['message']?.toString() ??
            'Bulk transfer not found',
      );
    }
    return body;
  }

// PUT /journal/fundTransferMA.php
  Future<Map<String, dynamic>> updateBulkTransfer({
    required String reference,
    required String userName,
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await _api.put(
      endpoint: '/journal/fundTransferMA.php',
      data: {
        'reference': reference,
        'usrName': userName,
        'records': records,
      },
    );

    final body = _asMap(response.data);
    if (body == null) {
      throw ApiException('Invalid server response');
    }

    final msg = body['msg']?.toString().toLowerCase();
    if (msg == 'success') return body;

    throw ApiException(
      body['error']?.toString() ??
          body['message']?.toString() ??
          _bulkErrorText(msg ?? ''),
    );
  }

  String _bulkErrorText(String code) => switch (code) {
    'no limit' => 'One or more accounts exceeded their credit limit.',
    'blocked' => 'One or more accounts are blocked.',
    'diff ccy' => 'All rows must use the same currency as their account.',
    'unbalanced' => 'Total debit must equal total credit.',
    'not_found' => 'Transaction not found.',
    'invalid user' => 'You are not the maker of this transaction.',
    'invalid action' => 'This transaction can no longer be edited.',
    'failed' || 'empty' => 'The transaction could not be processed.',
    _ => 'Transaction failed.',
  };

  Future<Map<String, dynamic>> deleteBulkTransfer({
    required String reference,
    required String userName,
  }) async {
    final response = await _api.delete(
      endpoint: '/journal/fundTransferMA.php',
      queryParams: {
        'ref': reference,
        'usrName': userName,
      },
    );

    debugPrint('DELETE RAW: ${response.data}');

    final body = _asMap(response.data);
    if (body == null) {
      throw ApiException('Invalid server response');
    }

    final msg = body['msg']?.toString().toLowerCase();
    if (msg == 'success') return body;

    throw ApiException(
      body['error']?.toString() ??
          body['message']?.toString() ??
          'Failed to delete transaction',
    );
  }

  Future<CashTxnDetail> getCashTxnByRef({
    required String reference,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/journal/cashWD.php',
      queryParams: {'ref': reference},
      cancelToken: cancelToken,
    );

    final body = _asMap(response.data);
    if (body == null) throw ApiException('Invalid server response');

    final detail = CashTxnDetail.fromJson(body);

    if (detail.isSuccess) return detail;

    throw ApiException(
      body['error']?.toString() ??
          ((detail.msg ?? '').toLowerCase() == 'not_found'
              ? 'Transaction not found.'
              : 'Failed to load transaction'),
    );
  }

  Future<Map<String, dynamic>> deleteCashTxn({
    required String reference,
    required String userName,
  }) async {
    final response = await _api.delete(
      endpoint: '/journal/cashWD.php',
      data: {'reference': reference, 'username': userName},
    );

    final body = _asMap(response.data);
    if (body == null) throw ApiException('Invalid server response');

    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg == 'success') return body;

    throw ApiException(
      body['error']?.toString() ??
          (msg == 'invalid action'
              ? 'Only pending transactions can be deleted.'
              : msg == 'invalid'
              ? 'Only the maker can delete this transaction.'
              : 'Failed to delete transaction'),
    );
  }


  // ═════════════════════════════════════════════════════════════════
  // Fund Transfer (account → account)
  //   Add / Edit / Delete / Get (list + single).
  //   Authorize / Unauthorize / Reverse are handled by the generic
  //   transactions.php endpoint via authorizeTxn / unAuthorizeTxn /
  //   reverseTxn above.
  // ═════════════════════════════════════════════════════════════════

  /// GET list — supports optional state filter and search.
  Future<List<FundTransferListItem>> getFundTransfers({
    String? state,
    String? search,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/journal/fundTransfer.php',
      queryParams: {
        if (state != null && state.isNotEmpty) 'state': state,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      cancelToken: cancelToken,
    );
    return _parseList(
      response.data,
      FundTransferListItem.fromMap,
      fallback: 'Failed to load fund transfers',
    );
  }

  /// GET single — used by the edit form.
  Future<FundTransferDetail> getFundTransferByReference({
    required String reference,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/journal/fundTransfer.php',
      queryParams: {'ref': reference},
      cancelToken: cancelToken,
    );

    final body = _asMap(response.data);
    if (body == null) throw ApiException('Invalid server response');

    // Server returns {msg: 'not_found'} / {msg: 'invalid_type'} on bad refs.
    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg.isNotEmpty && msg != 'success') {
      throw ApiException(
        body['error']?.toString() ??
            (msg == 'not_found'
                ? 'Fund transfer not found.'
                : msg == 'invalid_type'
                ? 'This reference is not a fund transfer.'
                : msg == 'missing_ref'
                ? 'Missing reference.'
                : 'Failed to load fund transfer'),
      );
    }

    return FundTransferDetail.fromMap(body);
  }

  /// POST — create a new account → account transfer (always Pending).
  /// Returns the new trnReference.
  Future<String> addFundTransfer({
    required String usrName,
    required int fromAccount,
    required String fromAccCcy,
    required int toAccount,
    required String toAccCcy,
    required double amount,
    required String narration,
  }) async {
    final response = await _api.post(
      endpoint: '/journal/fundTransfer.php',
      data: {
        'usrName': usrName,
        'fromAccount': fromAccount,
        'fromAccCcy': fromAccCcy,
        'toAccount': toAccount,
        'toAccCcy': toAccCcy,
        'amount': amount,
        'narration': narration,
      },
    );

    final body = _asMap(response.data);
    if (body == null) throw ApiException('Invalid server response');

    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg == 'success') {
      final ref = body['reference']?.toString();
      if (ref == null || ref.isEmpty) {
        throw ApiException('Server returned success but no reference');
      }
      return ref;
    }

    throw ApiException(
      body['error']?.toString() ??
          (msg == 'empty'
              ? 'Please fill in all fields.'
              : msg == 'same_account'
              ? 'From and To accounts must be different.'
              : msg == 'currency_unmatch'
              ? 'From and To accounts must share the same currency.'
              : msg == 'blocked'
              ? 'One of the accounts is blocked.'
              : msg == 'no_limit'
              ? 'The account has exceeded its credit limit.'
              : msg == 'invalid_user'
              ? 'Invalid user.'
              : msg == 'failed'
              ? 'The fund transfer could not be created.'
              : msg.isEmpty
              ? 'Failed to create fund transfer'
              : msg),
    );
  }

  /// PUT — edit a Pending fund transfer. Maker only.
  Future<void> editFundTransfer({
    required String reference,
    required String usrName,
    required String fromAccCcy,
    required String toAccCcy,
    required int fromAccount,
    required int toAccount,
    required double amount,
    required String narration,
  }) async {
    final response = await _api.put(
      endpoint: '/journal/fundTransfer.php',
      data: {
        'reference': reference,
        'usrName': usrName,
        'fromAccount': fromAccount,
        'toAccount': toAccount,
        'fromAccCcy': fromAccCcy,
        'toAccCcy': toAccCcy,
        'amount': amount,
        'narration': narration,
      },
    );

    final body = _asMap(response.data);
    if (body == null) throw ApiException('Invalid server response');

    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg == 'success') return;

    throw ApiException(
      body['error']?.toString() ??
          (msg == 'empty'
              ? 'Please fill in all fields.'
              : msg == 'same_account'
              ? 'From and To accounts must be different.'
              : msg == 'blocked'
              ? 'One of the accounts is blocked.'
              : msg == 'no_limit'
              ? 'The account has exceeded its credit limit.'
              : msg == 'not_found'
              ? 'Fund transfer not found.'
              : msg == 'invalid_type'
              ? 'This reference is not a fund transfer.'
              : msg == 'invalid_action'
              ? 'Only Pending fund transfers can be edited.'
              : msg == 'invalid'
              ? 'Only the maker can edit this fund transfer.'
              : msg == 'failed'
              ? 'The fund transfer could not be updated.'
              : msg.isEmpty
              ? 'Failed to update fund transfer'
              : msg),
    );
  }

  /// DELETE — soft delete a Pending fund transfer. Maker only.
  /// Keeps the header row, marks it Deleted, and drops the detail legs.
  Future<void> deleteFundTransfer({
    required String reference,
    required String usrName,
  }) async {
    final response = await _api.delete(
      endpoint: '/journal/fundTransfer.php',
      data: {'reference': reference, 'usrName': usrName},
    );

    final body = _asMap(response.data);
    if (body == null) throw ApiException('Invalid server response');

    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg == 'success') return;

    throw ApiException(
      body['error']?.toString() ??
          (msg == 'empty'
              ? 'Missing reference or user.'
              : msg == 'not_found'
              ? 'Fund transfer not found.'
              : msg == 'invalid_type'
              ? 'This reference is not a fund transfer.'
              : msg == 'invalid_action'
              ? 'Only Pending fund transfers can be deleted.'
              : msg == 'invalid'
              ? 'Only the maker can delete this fund transfer.'
              : msg == 'failed'
              ? 'The fund transfer could not be deleted.'
              : msg.isEmpty
              ? 'Failed to delete fund transfer'
              : msg),
    );
  }

  Future<ExchangeDetail> getExchangeByReference({
    required String reference,
    CancelToken? cancelToken,
  }) async {
    final res = await _api.get(
      endpoint: '/journal/crossCurrency.php',
      queryParams: {'ref': reference},
      cancelToken: cancelToken,
    );
    final body = _asMap(res.data);
    if (body == null) throw ApiException('Invalid server response');

    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg.isNotEmpty && msg != 'success') {
      throw ApiException(
        body['error']?.toString() ??
            (msg == 'not_found'
                ? 'Exchange transfer not found.'
                : msg == 'invalid_type'
                ? 'This reference is not an exchange transfer.'
                : 'Failed to load exchange transfer'),
      );
    }
    return ExchangeDetail.fromMap(body);
  }

  Future<List<ExchangeListItem>> getExchangeList({
    String? state,
    String? search,
    CancelToken? cancelToken,
  }) async {
    final res = await _api.get(
      endpoint: '/journal/crossCurrency.php',
      queryParams: {
        if (state != null && state.isNotEmpty) 'state': state,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      cancelToken: cancelToken,
    );
    return _parseList(
      res.data,
      ExchangeListItem.fromMap,
      fallback: 'Failed to load exchange transfers',
    );
  }

  Future<String> addExchangeTransfer({
    required String usrName,
    required ExchangeLeg debit,
    required ExchangeLeg credit,
  }) async {
    final records = ExchangeDraft(
      usrName: usrName,
      debit: debit,
      credit: credit,
    ).toRecords();

    final res = await _api.post(
      endpoint: '/journal/crossCurrency.php',
      data: {
        'usrName': usrName,
        'records': records,
      },
    );

    final body = _asMap(res.data);
    if (body == null) throw ApiException('Invalid server response');

    if (body['msg']?.toString().toLowerCase() == 'success') {
      return '${body['reference'] ?? ''}';
    }
    throw ApiException(_fxErrorText('${body['msg'] ?? ''}', body));
  }

  Future<void> editExchangeTransfer({
    required String reference,
    required String usrName,
    required ExchangeLeg debit,
    required ExchangeLeg credit,
  }) async {
    final res = await _api.put(
      endpoint: '/journal/crossCurrency.php',
      data: ExchangeEditDraft(
        reference: reference,
        usrName: usrName,
        debit: debit,
        credit: credit,
      ).toMap(),
    );
    final body = _asMap(res.data);
    if (body == null) throw ApiException('Invalid server response');
    if (body['msg']?.toString().toLowerCase() == 'success') return;
    throw ApiException(_fxErrorText('${body['msg'] ?? ''}', body));
  }

  Future<void> deleteExchangeTransfer({
    required String reference,
    required String usrName,
  }) async {
    final response = await _api.delete(
      endpoint: '/journal/crossCurrency.php',
      data: {'reference': reference, 'usrName': usrName},
    );
    final body = _asMap(response.data);
    if (body == null) throw ApiException('Invalid server response');
    if (body['msg']?.toString().toLowerCase() == 'success') return;
    throw ApiException(_fxErrorText('${body['msg'] ?? ''}', body));
  }

  String _fxErrorText(String code, Map<String, dynamic> body) {
    final serverErr = body['error']?.toString();
    if (serverErr != null && serverErr.isNotEmpty) return serverErr;
    return switch (code.toLowerCase()) {
      'empty' => 'Please fill in all fields.',
      'same_account' => 'Debit and credit accounts must be different.',
      'same_ccy' => 'Exchange requires two different currencies.',
      'ccy_mismatch' => 'Leg currency does not match the account currency.',
      'blocked' => 'One of the accounts is blocked.',
      'no_limit' => 'The account has exceeded its credit limit.',
      'not_found' => 'Exchange transfer not found.',
      'invalid_type' => 'This reference is not an exchange transfer.',
      'invalid_action' => 'Only Pending exchange transfers can be modified.',
      'invalid' => 'Only the maker can perform this action.',
      'invalid_legs' => 'An exchange needs exactly one debit and one credit leg.',
      'invalid_user' => 'Invalid user.',
      'failed' => 'The exchange transfer could not be processed.',
      _ => 'Exchange transfer failed.',
    };
  }

  ///Users .....................................................................
  Future<List<UsersModel>> getUsers({int? usrOwner, CancelToken? cancelToken,}) async {
    // Build query parameters dynamically
    final queryParams = usrOwner != null ? {'perID': usrOwner} : null;

    // Fetch data from API
    final response = await _api.get(
      endpoint: "/HR/users.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => UsersModel.fromMap(json))
          .toList();
    }

    return [];
  }
  Future<Map<String, dynamic>> addUser({required UsersModel newUser}) async {
    final response = await _api.post(
      endpoint: "/HR/users.php",
      data: newUser.toMap(),
    );
    return response.data;
  }
  Future<Map<String, dynamic>> editUser({required UsersModel newUser}) async {
    final response = await _api.put(
      endpoint: "/HR/users.php",
      data: newUser.toMap(),
    );
    return response.data;
  }
  Future<List<UsersReportModel>> getUsersReport({
    String? usrName,
    int? status,
    int? branch,
    int? role,
  }) async {
    final response = await _api.post(
      endpoint: "/reports/usersList.php",
      data: {
        "username": usrName,
        "status": status,
        "branch": branch,
        "role": role,
      },
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => UsersReportModel.fromMap(json))
          .toList();
    }

    return [];
  }

  ///Roles .....................................................................
  Future<List<UserRoleModel>> getUserRole({int? usrOwner, CancelToken? cancelToken,}) async {
    // Fetch data from API
    final response = await _api.get(
      endpoint: "/setting/roles.php",
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => UserRoleModel.fromMap(json))
          .toList();
    }

    return [];
  }
  Future<Map<String, dynamic>> addNewRole({required String usrName, required String roleName}) async {
    final response = await _api.post(
        endpoint: "/setting/roles.php",
        data: {
          "usrName": usrName,
          "rolName": roleName
        }
    );
    return response.data;
  }
  Future<Map<String, dynamic>> editUserRole({required UserRoleModel newRole}) async {
    final response = await _api.put(
        endpoint: "/setting/roles.php",
        data: newRole.toMap()
    );
    return response.data;
  }
  Future<Map<String, dynamic>> deleteUserRole({required int roleId}) async {
    final response = await _api.delete(
      endpoint: "/setting/roles.php",
      data:  {
        "rolID": roleId
      },
    );
    return response.data;
  }

  ///User Role Settings ........................................................
  Future<List<UserRolePermissionSettingModel>> getPermissionSettings({CancelToken? cancelToken,}) async {
    final response = await _api.get(
      endpoint: "/setting/userRoles.php",
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => UserRolePermissionSettingModel.fromMap(json))
          .toList();
    }

    return [];
  }
  Future<Map<String, dynamic>> updatePermissionSettings({required PermissionActionModel permissions,}) async {

    final response = await _api.put(
      endpoint: "/setting/userRoles.php",
      data: permissions.toMap(),
    );
    return response.data;
  }

  ///Reports ...................................................................
  // Account Statement
  Future<AccountStatementModel> getAccountStatement({
    required int account,
    required String fromDate,
    required String toDate,
  }) async {
    final response = await _api.post(
      endpoint: "/reports/accountStatement.php",
      data: {"account": account, "fromDate": fromDate, "toDate": toDate},
    );

    // Handle message response
    if (response.data is Map && response.data['msg'] != null) {
      throw response.data['msg'];
    }

    // Handle empty response
    if (response.data == null || response.data.isEmpty) {
      throw "No data received";
    }

    // Convert response to string and back to ensure proper typing
    final jsonString = json.encode(response.data);
    final decodedData = json.decode(jsonString) as dynamic;

    return AccountStatementModel.fromApiResponse(decodedData);
  }

  Future<GlStatementModel> getGlStatement({
    required int account,
    required String currency,
    required int branchCode,
    required String fromDate,
    required String toDate,
  }) async {
    final response = await _api.post(
      endpoint: "/reports/glStatement.php",
      data: {
        "ccy": currency,
        "branch": branchCode,
        "account": account,
        "fromDate": fromDate,
        "toDate": toDate,
      },
    );

    // Handle message response
    if (response.data is Map && response.data['msg'] != null) {
      throw response.data['msg'];
    }

    // Handle empty response
    if (response.data == null || response.data.isEmpty) {
      throw "No data received";
    }

    // Convert response to string and back to ensure proper typing
    final jsonString = json.encode(response.data);
    final decodedData = json.decode(jsonString) as dynamic;

    return GlStatementModel.fromApiResponse(decodedData);
  }

  Future<List<TrialBalanceModel>> getTrialBalance({
    required String date,
    int? branchCode,
  }) async {
    final response = await _api.post(
      endpoint: "/reports/trialBalance.php",
      data: {"date": date, "branch": branchCode},
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => TrialBalanceModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<BalanceSheetModel> balanceSheet({int? branchCode, CancelToken? cancelToken}) async {
    final response = await _api.get(
      endpoint: "/reports/balanceSheet.php",
      queryParams: {"branch": branchCode},
      cancelToken: cancelToken,
    );

    // Check if API returned a message
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If response is null
    if (response.data == null) {
      throw Exception("No data found");
    }

    // Convert the JSON to BalanceSheetModel
    if (response.data is Map<String, dynamic>) {
      return BalanceSheetModel.fromMap(response.data);
    }

    throw Exception("Unexpected response format");
  }


  Future<DashboardStatsModel> getDashboardStats({
    String? fromDate,
    String? toDate,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.post(
      endpoint: '/reports/counts.php',
      data: {
        if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
      },
      cancelToken: cancelToken,
    );

    final body = _asMap(response.data);
    if (body == null) {
      throw ApiException('Invalid server response');
    }
    if (body['status']?.toString().toLowerCase() != 'success') {
      _fail(body, fallback: 'Failed to load dashboard stats');
    }
    return DashboardStatsModel.fromMap(body);
  }

  //Get Transaction Details By Ref
  Future<TxnReportByRefModel> getTransactionByRefReport({
    required String ref,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: "/reports/referenceHistory.php",
      queryParams: {"ref": ref},
      cancelToken: cancelToken,
    );

    // Handle message response
    if (response.data is Map && response.data['msg'] != null) {
      throw response.data['msg'];
    }

    // Handle empty response
    if (response.data == null || response.data.isEmpty) {
      throw "No data received";
    }

    // Convert response to string and back to ensure proper typing
    final jsonString = json.encode(response.data);
    final decodedData = json.decode(jsonString) as dynamic;

    return TxnReportByRefModel.fromMap(decodedData);
  }

  Future<CashBalancesModel?> cashBalances({
    int? branchId,
    String? from,
    String? to,
    CancelToken? cancelToken,
  }) async {
    final queryParams = <String, dynamic>{
      'brcID': branchId,
    };

    if (from != null && from.isNotEmpty) queryParams['fromDate'] = from;
    if (to   != null && to.isNotEmpty)   queryParams['toDate']   = to;

    final response = await _api.get(
      endpoint: "/reports/cashBalance.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    if (response.data == null) return null;
    if (response.data is Map<String, dynamic>) {
      if (response.data['msg'] != null) return null;
      return CashBalancesModel.fromMap(response.data);
    }
    if (response.data is List) {
      final list = response.data as List;
      if (list.isEmpty) return null;
      return CashBalancesModel.fromMap(list.first);
    }
    return null;
  }

  Future<List<CashBalancesModel>> allCashBalances({
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: "/reports/cashBalance.php",
      cancelToken: cancelToken,
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null) {
      throw Exception("No data found");
    }

    // Parse as list
    if (response.data is List) {
      return List<CashBalancesModel>.from(
        response.data.map((x) => CashBalancesModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic>) {
      return [CashBalancesModel.fromMap(response.data)];
    }

    throw Exception("Unexpected response format");
  }

  Future<List<IncomeStatementModel>> getIncomeStatement({String? startDate, String? endDate}) async {
    final response = await _api.post(
      endpoint: "/reports/incomeStatement.php",
      data: {
        "startDate": startDate,
        "endDate": endDate
      },
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      // If no records found, return empty list
      if (response.data['msg'] == 'failed') {
        return [];
      }
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<IncomeStatementModel>.from(
        response.data.map((x) => IncomeStatementModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic> && response.data.isNotEmpty) {
      return [IncomeStatementModel.fromMap(response.data)];
    }

    return [];
  }

// ═════════════════════════════════════════════════════════════════
// AR / AP Report
// ═════════════════════════════════════════════════════════════════
  Future<ArApReportModel> getArApReport({
    String? name,
    String? ccy,
    String? type, // '' | 'ar' | 'ap'
    bool includeZero = false,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.post(
      endpoint: "/reports/stakeholderBalances.php", // adjust to your server path
      data: {
        'name': name ?? '',
        'ccy': ccy ?? '',
        'type': type ?? '',
        'include_zero': includeZero,
      },
      cancelToken: cancelToken,
    );

    // Handle message response
    if (response.data is Map && response.data['msg'] != null) {
      throw response.data['msg'];
    }

    // Handle empty response
    if (response.data == null || response.data.isEmpty) {
      throw "No data received";
    }

    // Convert response to string and back to ensure proper typing
    final jsonString = json.encode(response.data);
    final decodedData = json.decode(jsonString) as dynamic;

    return ArApReportModel.fromApiResponse(decodedData);
  }

  Future<List<AllBalancesModel>> allBalances({
    int? catId,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: "/reports/allBalances.php",
      queryParams: {"cat": catId},
      cancelToken: cancelToken,
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<AllBalancesModel>.from(
        response.data.map((x) => AllBalancesModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic>) {
      return [AllBalancesModel.fromMap(response.data)];
    }

    return [];
  }

  Future<List<TransactionReportModel>> transactionReport({
    String? fromDate,
    String? toDate,
    String? txnType,
    int? status,
    String? maker,
    String? checker,
    String? currency,
  }) async {
    final response = await _api.post(
      endpoint: "/reports/transactionsReport.php",
      data: {
        "fromDate": fromDate,
        "toDate": toDate,
        "type": txnType,
        "status": status,
        "maker": maker,
        "checker": checker,
        "currency": currency,
      },
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // Parse as list
    if (response.data is List) {
      return List<TransactionReportModel>.from(
        response.data.map((x) => TransactionReportModel.fromMap(x)),
      );
    }

    // If single object, wrap in list
    if (response.data is Map<String, dynamic>) {
      return [TransactionReportModel.fromMap(response.data)];
    }

    return [];
  }

  /// Transaction Types ........................................................
  Future<Map<String, dynamic>> addTxnType({
    required TxnTypeModel newType,
  }) async {
    final response = await _api.post(
      endpoint: "/setting/trnType.php",
      data: newType.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateTxnType({
    required TxnTypeModel newType,
  }) async {
    final response = await _api.put(
      endpoint: "/setting/trnType.php",
      data: newType.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteTxnType({required String trnCode}) async {
    final response = await _api.delete(
      endpoint: "/setting/trnType.php",
      data: {"trntCode": trnCode},
    );
    return response.data;
  }

  Future<List<TxnTypeModel>> getTxnTypes({
    String? trnCode,
    CancelToken? cancelToken,
  }) async {
    final queryParams = {'trntCode': trnCode};
    // Fetch data from API
    final response = await _api.get(
      endpoint: "/setting/trnType.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => TxnTypeModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<List<UserLogModel>> getUserLog({
    String? usrName,
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = {
      'usrName': usrName,
      'fromDate': fromDate,
      'toDate': toDate,
    };
    // Fetch data from API
    final response = await _api.post(
      endpoint: "/reports/userLogs.php",
      data: queryParams,
    );

    // Handle error messages from server
    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    // If data is null or empty, return empty list
    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    // Parse list of stakeholders safely
    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>() // ensure map type
          .map((json) => UserLogModel.fromMap(json))
          .toList();
    }

    return [];
  }

  ///Backup
  Future<Directory> _getBackupBaseDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
      return (await getExternalStorageDirectory())!;
    }

    if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    }

    // Windows / macOS / Linux
    return await getApplicationDocumentsDirectory();
  }
  Future<File> downloadBackup() async {
    Directory baseDir;

    // 🔹 ANDROID
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }

      final androidDownload = Directory('/storage/emulated/0/Download');
      if (await androidDownload.exists()) {
        baseDir = androidDownload;
      } else {
        baseDir = (await getExternalStorageDirectory())!;
      }
    }
    // 🔹 iOS
    else if (Platform.isIOS) {
      baseDir = await getApplicationDocumentsDirectory();
    }
    // 🔹 Windows / macOS / Linux
    else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final backupDir = Directory('${baseDir.path}/ZaitoonBackups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final now = DateTime.now();
    final formattedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day
        .toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(
        2, '0')}';

    final filePath = '${backupDir.path}/zBackup_$formattedDate.sql';

    await _api.downloadFile(
      endpoint: "/setting/backupLocally.php",
      savePath: filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          // progress callback
        }
      },
    );

    return File(filePath);
  }
  Future<void> renameBackup(String oldPath, String newPath) async {
    try {
      final file = File(oldPath);

      // Check if the source file exists
      if (!await file.exists()) {
        throw Exception('Source file does not exist');
      }

      // Check if a file with the new name already exists
      final newFile = File(newPath);
      if (await newFile.exists()) {
        throw Exception('A file with this name already exists');
      }

      // Rename the file
      await file.rename(newPath);
    } catch (e) {

      throw Exception('Failed to rename backup: $e');
    }
  }
  Future<void> deleteBackup(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
  Future<void> restoreBackup(
      String filePath, {
        Function(String)? onProgress,
      }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found at: $filePath');
      }
      if (!filePath.toLowerCase().endsWith('.sql')) {
        throw Exception('Only .sql backup files can be restored.');
      }
      if (Config.token.isEmpty) {
        throw Exception(
          'Restore token is not configured. '
              'Build with --dart-define=RESTORE_TOKEN=<token>.',
        );
      }

      onProgress?.call('Uploading backup to server...');

      final formData = FormData.fromMap({
        'backup': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split(Platform.pathSeparator).last,
          contentType: DioMediaType('application', 'sql'),
        ),
      });

      final response = await _api.uploadFile(
        endpoint: '/setting/restore.php',
        data: formData,
        headers: {
          'Authorization': 'Bearer ${Config.token}',
          'Accept': 'application/json',
        },
        onSendProgress: (sent, total) {
          if (total > 0) {
            final pct = (sent / total * 100).toStringAsFixed(1);
            onProgress?.call('Uploading: $pct%');
          }
        },
      );

      onProgress?.call('Server is restoring the database...');

      final data = response.data;
      Map<String, dynamic> body;
      if (data is Map) {
        body = Map<String, dynamic>.from(data);
      } else {
        body = {'status': 'error', 'message': data?.toString() ?? ''};
      }

      final status = body['status']?.toString().toLowerCase() ?? '';
      if (status != 'success') {
        final msg = body['message']?.toString() ?? 'Restore failed.';
        throw Exception(msg);
      }

      onProgress?.call('Restore completed successfully!');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Database restore failed: $e');
    }
  }
  // Future<void> restoreBackup(String filePath, {Function(String)? onProgress}) async {
  //   try {
  //     final host = 'localhost';
  //     final port = '3306';
  //     final username = 'root';
  //     final database = 'zaitoondb';
  //
  //     // Laragon's default MySQL password is blank (same as XAMPP)
  //     // If you set a password in Laragon, add: -p, 'your_password'
  //
  //     String mysqlPath;
  //     if (Platform.isWindows) {
  //       // Check for Laragon first, then fallback to XAMPP
  //       final laragonPath = 'C:\\laragon\\bin\\mysql';
  //       final xamppPath = 'C:\\xampp\\mysql\\bin\\mysql.exe';
  //
  //       if (await Directory(laragonPath).exists()) {
  //         // Find the MySQL version folder dynamically
  //         final dir = Directory(laragonPath);
  //         final entries = await dir.list().toList();
  //         final mysqlDirs = entries.whereType<Directory>()
  //             .where((d) => d.path.contains('mysql-'))
  //             .toList();
  //
  //         if (mysqlDirs.isNotEmpty) {
  //           // Use the first MySQL version found
  //           mysqlPath = '${mysqlDirs.first.path}\\bin\\mysql.exe';
  //         } else {
  //           throw Exception('No MySQL installation found in Laragon');
  //         }
  //       } else if (await File(xamppPath).exists()) {
  //         mysqlPath = xamppPath;
  //       } else {
  //         throw Exception('Neither Laragon nor XAMPP MySQL found');
  //       }
  //     } else if (Platform.isMacOS) {
  //       // Laragon doesn't exist on macOS, so keep XAMPP fallback
  //       mysqlPath = '/Applications/XAMP/xampfiles/bin/mysql';
  //     } else {
  //       // Linux
  //       mysqlPath = '/opt/lampp/bin/mysql';
  //     }
  //
  //     final mysqlFile = File(mysqlPath);
  //     if (!await mysqlFile.exists()) {
  //       throw Exception('MySQL executable not found at: $mysqlPath');
  //     }
  //
  //     final backupFile = File(filePath);
  //     if (!await backupFile.exists()) {
  //       throw Exception('Backup file not found at: $filePath');
  //     }
  //
  //     onProgress?.call('Starting MySQL restore...');
  //
  //     // NOTE: Laragon's MySQL might have a different default password
  //     // If Laragon asks for password, add these args:
  //     // '-p', 'your_password',
  //     // But by default, Laragon has no password just like XAMPP
  //
  //     final process = await Process.start(
  //       mysqlPath,
  //       [
  //         '-h', host,
  //         '-P', port,
  //         '-u', username,
  //         '--default-character-set=utf8mb4',
  //         database,
  //       ],
  //       runInShell: true,
  //     );
  //
  //     final fileSize = await backupFile.length();
  //     var bytesRead = 0;
  //
  //     await backupFile.openRead().map((chunk) {
  //       bytesRead += chunk.length;
  //       final progress = (bytesRead / fileSize * 100).toStringAsFixed(1);
  //       onProgress?.call('Restoring: $progress%');
  //       return chunk;
  //     }).pipe(process.stdin);
  //
  //     await process.stdin.close();
  //
  //     final exitCode = await process.exitCode;
  //
  //     if (exitCode != 0) {
  //       final stderr = await process.stderr
  //           .transform(utf8.decoder)
  //           .join();
  //       throw Exception('Restore failed (exit code: $exitCode): $stderr');
  //     }
  //
  //     onProgress?.call('Restore completed successfully!');
  //   } catch (e) {
  //     throw Exception('Database restore failed: $e');
  //   }
  // }
  Future<void> openBackupFolder() async {
    try {
      String backupDir;

      if (Platform.isWindows) {
        // Check for Laragon first
        final laragonBackup = 'C:\\laragon\\data\\mysql\\backups';
        final xamppBackup = 'C:\\xampp\\mysql\\data\\backups';

        if (await Directory('C:\\laragon').exists()) {
          backupDir = laragonBackup;
        } else {
          backupDir = xamppBackup;
        }
      } else if (Platform.isMacOS) {
        backupDir = '/Applications/XAMP/xampfiles/data/backups';
      } else {
        backupDir = '/opt/lampp/data/backups';
      }

      final dir = Directory(backupDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      if (Platform.isWindows) {
        await Process.run('explorer', [backupDir]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [backupDir]);
      } else {
        await Process.run('xdg-open', [backupDir]);
      }
    } catch (e) {
      throw Exception('Failed to open backup folder: $e');
    }
  }
  Future<List<FileSystemEntity>> getBackupFiles({int? limit = 10}) async {
    try {
      final baseDir = await _getBackupBaseDirectory();
      final backupDir = Directory('${baseDir.path}/ZaitoonBackups');

      if (!await backupDir.exists()) return [];

      final files = backupDir.listSync().whereType<File>().toList();

      // Sort by modification time (most recent first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      // Return only the top 'limit' files
      if (limit != null && limit > 0) {
        return files.take(limit).toList();
      }

      return files; // Return all if limit is null or 0
    } catch (e) {
      throw Exception('Failed to load backups: $e');
    }
  }

  ///Employees .................................................................
  ///Employees .................................................................
  Future<List<EmployeeModel>> getEmployees({
    String? cat,
    CancelToken? cancelToken,
  }) async {
    final queryParams = cat != null ? {'cat': cat} : null;

    final response = await _api.get(
      endpoint: "/HR/employees.php",
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    if (response.data is Map<String, dynamic> && response.data['msg'] != null) {
      throw Exception(response.data['msg']);
    }

    if (response.data == null ||
        (response.data is List && response.data.isEmpty)) {
      return [];
    }

    if (response.data is List) {
      return (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => EmployeeModel.fromMap(json))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> addEmployee({
    required EmployeeModel newEmployee,
  }) async {
    final response = await _api.post(
      endpoint: "/HR/employees.php",
      data: newEmployee.toMap(),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateEmployee({
    required EmployeeModel newEmployee,
  }) async {
    final response = await _api.put(
      endpoint: "/HR/employees.php",
      data: newEmployee.toMap(),
    );
    return response.data;
  }

  Future<void> deleteEmployee({
    required int empId,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.delete(
      endpoint: '/HR/employees.php',
      data: {'empID': empId},
      cancelToken: cancelToken,
    );

    final body = _asMap(response.data);
    if (body == null) {
      throw ApiException('Invalid server response');
    }

    final msg = body['msg']?.toString().toLowerCase() ?? '';

    switch (msg) {
      case 'success':
        return;

      case 'notfound':
        throw ApiException('Employee not found.');

      case 'empty':
        throw ApiException('Missing employee id.');

      case 'inuse':
        final detail = body['detail']?.toString().trim();
        if (detail != null && detail.isNotEmpty) {
          throw ApiException('Cannot delete this employee. $detail');
        }

        final deps = (body['dependencies'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((m) {
          final reason = m['reason']?.toString() ?? 'records';
          final count = m['count']?.toString() ?? '?';
          return '$reason ($count)';
        })
            .join(', ');
        throw ApiException(
          deps.isEmpty
              ? 'Cannot delete this employee — related records exist.'
              : 'Cannot delete this employee. Related records: $deps',
        );

      default:
      // `_fail` returns Never, so this is the correct terminal statement —
      // no `return` after it.
        _fail(body, fallback: 'Failed to delete employee');
    }
  }

  // ═════════════════════════════════════════════════════════════════
// Attendance
// ═════════════════════════════════════════════════════════════════
  Future<List<AttendanceModel>> getAttendance({
    String? date,
    String? month,
    int? emaID,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/HR/attendance.php',
      queryParams: {
        'emaID': ?emaID,
        if (date  != null && date.isNotEmpty)  'date':  date,
        if (month != null && month.isNotEmpty) 'month': month,
      },
      cancelToken: cancelToken,
    );
    return _parseList(
      response.data,
      AttendanceModel.fromMap,
      fallback: 'Failed to load attendance',
    );
  }

  /// mode: 'single' | 'multiple' | 'all'
  Future<Map<String, dynamic>> addAttendance({
    required String mode,
    required String usrName,
    required String emaDate,
    int? emaEmployee,
    String? emaCheckedIn,
    String? emaCheckedOut,
    String? emaStatus,
    List<Map<String, dynamic>>? records,
  }) async {
    final payload = <String, dynamic>{
      'mode': mode,
      'usrName': usrName,
      'emaDate': emaDate,
      if (mode == 'single') ...{
        'emaEmployee': emaEmployee,
        'emaCheckedIn': emaCheckedIn,
        'emaCheckedOut': emaCheckedOut,
        'emaStatus': emaStatus ?? 'Present',
      },
      if (mode == 'all') ...{
        'emaCheckedIn': emaCheckedIn,
        'emaCheckedOut': emaCheckedOut,
        'emaStatus': emaStatus ?? 'Present',
      },
      if (mode == 'multiple') 'records': records ?? const [],
    };

    final response = await _api.post(
      endpoint: '/HR/attendance.php',
      data: payload,
    );

    final body = _asMap(response.data);
    if (body == null) throw ApiException('Invalid server response');

    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg == 'success') return body;

    // ✅ Accept any 'failed' body that still inserted rows
    final inserted = _asInt(body['inserted']) ?? 0;
    if (inserted > 0) return body;

    if (msg == 'empty')        throw ApiException('Please fill in all fields.');
    if (msg == 'invalid_mode') throw ApiException('Invalid attendance mode.');
    _fail(body, fallback: 'Failed to add attendance');
  }

  Future<Map<String, dynamic>> updateAttendance({
    required String usrName,
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await _api.put(
      endpoint: '/HR/attendance.php',
      data: {'usrName': usrName, 'records': records},
    );
    return _requireSuccess(response.data, fallback: 'Failed to update attendance');
  }

  Future<Map<String, dynamic>> deleteAttendance({
    required int emaID,
    String? usrName,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.delete(
      endpoint: '/HR/attendance.php',
      data: {'emaID': emaID, 'usrName': usrName},
      cancelToken: cancelToken,
    );

    final body = _asMap(response.data);
    if (body == null) {
      // Some servers return a raw string on success
      final s = response.data?.toString().toLowerCase() ?? '';
      if (s.contains('success')) {
        return {'msg': 'success', 'message': 'Attendance deleted.'};
      }
      throw ApiException('Invalid server response');
    }

    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg == 'success')  return body;
    if (msg == 'notfound') throw ApiException('Attendance record not found.');
    if (msg == 'empty')    throw ApiException('Missing attendance id.');
    _fail(body, fallback: 'Failed to delete attendance');
  }



  // ═════════════════════════════════════════════════════════════════
  // Logged-in user profile
  //   GET    /users/profile.php?usrName=…
  //   POST   /users/profile.php?action=update
  //   POST   /users/profile.php?action=password
  //   POST   /users/profile.php?action=photo
  // ═════════════════════════════════════════════════════════════════

  /// Load the whole profile of the logged-in user.
  Future<UserProfile> getUserProfile({
    required String usrName,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      endpoint: '/setting/profile.php',
      queryParams: {'usrName': usrName},
      cancelToken: cancelToken,
    );

    final body = _asMap(response.data);
    if (body == null) {
      throw ApiException('Invalid server response');
    }

    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg.isNotEmpty && msg != 'success') {
      _fail(body, fallback: 'Failed to load profile');
    }

    return UserProfile.fromJson(body);
  }

  /// Update name / last name / phone / email / DoB / gender + address.
  /// Only the provided fields are sent — the server ignores the rest.
  Future<UserProfile> updateUserProfile({
    required UpdateUserProfileRequest request,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.put(
      endpoint: '/setting/profile.php?action=update',
      data: request.toJson(),
      cancelToken: cancelToken,
    );

    final body = _requireSuccess(
      response.data,
      fallback: 'Failed to update profile',
    );

    return UserProfile.fromJson(body);
  }

  /// Change the logged-in user's password.
  Future<void> changeProfilePassword({
    required String usrName,
    required String oldPassword,
    required String newPassword,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.put(
      endpoint: '/setting/profile.php?action=password',
      data: {
        'usrName': usrName,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
      cancelToken: cancelToken,
    );

    _requireSuccess(
      response.data,
      fallback: 'Failed to change password',
    );
  }

  /// Upload / replace the profile photo.
  /// Multipart like your existing `uploadStakeholderPhoto`.
  Future<Map<String, dynamic>> uploadProfilePhoto({
    required String usrName,
    required Uint8List image,
  }) async {
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final formData = FormData.fromMap({
      'usrName': usrName,
      'image': MultipartFile.fromBytes(
        image,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    final response = await _api.uploadFile(                    // POST multipart
      endpoint: '/setting/profile.php?action=photo',
      data: formData,
    );

    final body = _asMap(response.data);
    if (body == null) throw ApiException('Invalid server response');
    return body;
  }

}