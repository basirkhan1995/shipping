import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' hide MultipartFile;
import 'package:flutter/services.dart';
import '../Routes/Home/View/Dashboard/model/ds_model.dart';
import '../Routes/Home/View/Finance/View/Currencies/model/ccy_model.dart';
import '../Routes/Home/View/Finance/View/EOY/model/eoy_model.dart';
import '../Routes/Home/View/Finance/View/ExchangeRate/model/ex_rate_model.dart';
import '../Routes/Home/View/Finance/View/GlAccounts/GlCategories/model/cat_model.dart';
import '../Routes/Home/View/Finance/View/GlAccounts/model/gl_model.dart';
import '../Routes/Home/View/Finance/View/Reminder/model/reminder_model.dart';
import '../Routes/Home/View/HR/View/Users/model/user_model.dart';
import '../Routes/Home/View/HR/View/Users/model/usr_report_model.dart';
import '../Routes/Home/View/Report/AccountStatement/model/stmt_model.dart';
import '../Routes/Home/View/Report/ArAndAp/model/ar_ap_model.dart';
import '../Routes/Home/View/Report/BalanceSheet/model/bs_model.dart';
import '../Routes/Home/View/Report/GLStatement/model/gl_statement_model.dart';
import '../Routes/Home/View/Report/CashBalances/model/cash_balance_model.dart';
import '../Routes/Home/View/Report/IncomeStatement/model/income_stmt_model.dart';
import '../Routes/Home/View/Report/TrialBalance/model/trial_balance_model.dart';
import '../Routes/Home/View/Report/TxnByReference/model/txn_report_model.dart';
import '../Routes/Home/View/Settings/View/Company/Branch/Ui/BranchLimits/model/limit_model.dart';
import '../Routes/Home/View/Settings/View/Company/Branches/model/branch_model.dart';
import '../Routes/Home/View/Settings/View/Company/CompanyProfile/model/com_model.dart';
import '../Routes/Home/View/Settings/View/Company/Storage/model/storage_model.dart';
import '../Routes/Home/View/Settings/View/General/DefaultPermissions/model/permission_settings_model.dart';
import '../Routes/Home/View/Settings/View/General/UserRole/model/role_model.dart';
import '../Routes/Home/View/Stakeholder/model/stk_model.dart';
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

  Future<Map<String, dynamic>> getCashTxnByReference({
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

    final msg = body['msg']?.toString().toLowerCase() ?? '';
    if (msg == 'success') return body;

    throw ApiException(
      body['error']?.toString() ??
          (msg == 'not_found' ? 'Transaction not found.' : 'Failed to load transaction'),
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

}