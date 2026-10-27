import 'package:dio/dio.dart';
import 'package:http/http.dart' hide MultipartFile;
import 'package:flutter/services.dart';
import '../Routes/Home/View/Finance/View/Currencies/model/ccy_model.dart';
import '../Routes/Home/View/Finance/View/EOY/model/eoy_model.dart';
import '../Routes/Home/View/Finance/View/ExchangeRate/model/ex_rate_model.dart';
import '../Routes/Home/View/Finance/View/GlAccounts/GlCategories/model/cat_model.dart';
import '../Routes/Home/View/Finance/View/GlAccounts/model/gl_model.dart';
import '../Routes/Home/View/Finance/View/Reminder/model/reminder_model.dart';
import '../Routes/Home/View/Settings/View/Company/Branch/Ui/BranchLimits/model/limit_model.dart';
import '../Routes/Home/View/Settings/View/Company/Branches/model/branch_model.dart';
import '../Routes/Home/View/Settings/View/Company/CompanyProfile/model/com_model.dart';
import '../Routes/Home/View/Settings/View/Company/Storage/model/storage_model.dart';
import '../Routes/Home/View/Stakeholder/model/stk_model.dart';
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
    return _requireSuccess(
      response.data,
      fallback: 'Failed to authorize transaction',
    );
  }

  Future<Map<String, dynamic>> unAuthorizeTxn({
    required String reference,
    required String? usrName,
  }) async {
    final response = await _api.put(
      endpoint: '/journal/unauthorizeTrn.php',
      data: {'reference': reference, 'username': usrName},
    );
    return _requireSuccess(
      response.data,
      fallback: 'Failed to unauthorize transaction',
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


}