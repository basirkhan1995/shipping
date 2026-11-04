import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_exception.dart';
import 'localization_services.dart';

class ApiServices {
  static const String baseUrl = "https://www.ferdawsbelalnabizada.com/rapi";
  static const String imageUrl =
      "https://www.ferdawsbelalnabizada.com/images/personal/";

  late final Dio _dio;

  Dio get client => _dio;

  ApiServices() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cache-Control": "no-cache",
        },
      ),
    );

    // ────────────────────────────────────────────────────────────────
    // Log interceptor — DEBUG ONLY.
    // Goes AFTER _dio = Dio(...) because _dio must exist first.
    // ────────────────────────────────────────────────────────────────
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (o) => debugPrint('🌐 $o'),
        ),
      );
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                              Error Handling                                */
  /* -------------------------------------------------------------------------- */

  ApiException _handleError(DioException e) {
    final tr = localizationService.loc;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException(tr.timeOutMessage,
            statusCode: e.response?.statusCode);

      case DioExceptionType.cancel:
        return ApiException(tr.requestCancelMessage,
            statusCode: e.response?.statusCode);

      case DioExceptionType.connectionError:
        return ApiException(tr.noInternet,
            statusCode: e.response?.statusCode);

      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;

        String? code;
        if (data is Map && data['code'] is String) {
          code = data['code'] as String;
        }

        String? serverMessage;
        if (data is Map) {
          final raw = data['error'] ?? data['message'] ?? data['msg'];
          if (raw is String && raw.isNotEmpty) serverMessage = raw;
        } else if (data is String && data.isNotEmpty) {
          serverMessage = data;
        }

        String message;
        switch (status) {
          case 400: message = serverMessage ?? tr.badRequest; break;
          case 401: message = serverMessage ?? tr.unAuthorized; break;
          case 403: message = serverMessage ?? tr.forbidden; break;
          case 404: message = serverMessage ?? tr.url404; break;
          case 405: message = serverMessage ?? tr.notAllowedError; break;
          case 500: message = serverMessage ?? tr.internalServerError; break;
          case 503: message = serverMessage ?? tr.serviceUnavailable; break;
          default:  message = serverMessage ?? "${tr.serverError}: $status";
        }
        return ApiException(message, statusCode: status, code: code);

    // 🎯 THE FIX: don't hide JSON parse failures as "network error"
      case DioExceptionType.unknown:
        final raw = e.response?.data;
        final statusCode = e.response?.statusCode;

        if (raw is String) {
          final preview = raw.length > 200 ? '${raw.substring(0, 200)}…' : raw;
          return ApiException(
            'Server returned invalid JSON (HTTP $statusCode): $preview',
            statusCode: statusCode,
          );
        }
        if (raw is Map) {
          final serverMessage =
          (raw['error'] ?? raw['message'] ?? raw['msg'])?.toString();
          if (serverMessage != null && serverMessage.isNotEmpty) {
            return ApiException(serverMessage, statusCode: statusCode);
          }
        }
        return ApiException(
          'Unexpected server response: ${e.message ?? e.error ?? ''}',
          statusCode: statusCode,
        );

      default:
        return ApiException(
          e.message?.isNotEmpty == true
              ? e.message!
              : tr.networkError,
          statusCode: e.response?.statusCode,
        );
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                   GET                                      */
  /* -------------------------------------------------------------------------- */

  Future<Response> get({
    required String endpoint,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        endpoint,
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                   POST                                     */
  /* -------------------------------------------------------------------------- */

  Future<Response> post({
    required String endpoint,
    required dynamic data,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Response> uploadFileWithMethod({
    required String endpoint,
    required FormData data,
    String method = 'POST',                     // defaults to old behaviour
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.request(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        options: Options(
          method: method,
          headers: headers,
        ),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                   PUT                                      */
  /* -------------------------------------------------------------------------- */

  Future<Response> put({
    required String endpoint,
    required dynamic data,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        endpoint,
        data: data,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                  DELETE                                    */
  /* -------------------------------------------------------------------------- */

  Future<Response> delete({
    required String endpoint,
    dynamic data,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                               FILE UPLOAD                                  */
  /* -------------------------------------------------------------------------- */

  Future<Response> uploadFile({
    required String endpoint,
    required FormData data,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        options: headers == null ? null : Options(headers: headers),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                              FILE DOWNLOAD                                 */
  /* -------------------------------------------------------------------------- */

  Future<Response> downloadFile({
    required String endpoint,
    required String savePath,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.download(
        endpoint,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}