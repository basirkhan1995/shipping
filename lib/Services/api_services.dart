import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_exception.dart';
import 'localization_services.dart';

class ApiServices {
  static const String baseUrl = "http://localhost/rapi";
  static const String imageUrl = "http://localhost/images/personal/";

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
  }

  late final Dio _dio;

  Dio get client => _dio;

  /* -------------------------------------------------------------------------- */
  /*                            Connectivity Check                               */
  /* -------------------------------------------------------------------------- */

  Future<void> _checkConnectivity() async {
    final tr = localizationService.loc;
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw ApiException(tr.noInternet);
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
        return ApiException(
          tr.timeOutMessage,
          statusCode: e.response?.statusCode,
        );

      case DioExceptionType.cancel:
        return ApiException(
          tr.requestCancelMessage,
          statusCode: e.response?.statusCode,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          tr.noInternet,
          statusCode: e.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;

        // Extract the server-provided machine code, e.g. TOKEN_EXPIRED,
        // TOKEN_INVALID, so the bloc can react to it.
        String? code;
        if (data is Map && data['code'] is String) {
          code = data['code'] as String;
        }

        // Prefer a server-provided message when it's a plain string.
        String? serverMessage;
        if (data is Map && data['error'] is String) {
          serverMessage = data['error'] as String;
        }

        String message;
        switch (status) {
          case 400:
            message = serverMessage ?? tr.badRequest;
            break;
          case 401:
            message = serverMessage ?? tr.unAuthorized;
            break;
          case 403:
            message = serverMessage ?? tr.forbidden;
            break;
          case 404:
            message = serverMessage ?? tr.url404;
            break;
          case 405:
            message = serverMessage ?? tr.notAllowedError;
            break;
          case 500:
            message = serverMessage ?? tr.internalServerError;
            break;
          case 503:
            message = serverMessage ?? tr.serviceUnavailable;
            break;
          default:
            message = serverMessage ?? "${tr.serverError}: $status";
        }

        return ApiException(message, statusCode: status, code: code);

      default:
        return ApiException(
          tr.networkError,
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
     // await _checkConnectivity();
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
     // await _checkConnectivity();
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

  /* -------------------------------------------------------------------------- */
  /*                                   PUT                                      */
  /* -------------------------------------------------------------------------- */

  Future<Response> put({
    required String endpoint,
    required dynamic data,
    CancelToken? cancelToken,
  }) async {
    try {
     // await _checkConnectivity();
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

  // Future<Response> uploadFile({
  //   required String endpoint,
  //   required FormData data,
  //   CancelToken? cancelToken,
  // }) async {
  //   try {
  //     await _checkConnectivity();
  //     return await _dio.post(
  //       endpoint,
  //       data: data,
  //       cancelToken: cancelToken,
  //       options: Options(contentType: 'multipart/form-data'),
  //     );
  //   } on DioException catch (e) {
  //     throw _handleError(e);
  //   } catch (e) {
  //     throw ApiException(e.toString());
  //   }
  // }

  Future<Response> uploadFile({
    required String endpoint,
    required FormData data,
    CancelToken? cancelToken,
  }) async {
    try {
    //  await _checkConnectivity();
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
     // await _checkConnectivity();
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