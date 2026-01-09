/// Remote Data Source
///
/// API 요청을 담당하는 클래스입니다.
/// - 자동 토큰 주입
/// - 401 에러 시 자동 토큰 갱신
/// - 통일된 에러 처리
///
/// 사용법:
/// ```dart
/// // GET 요청
/// final response = await DS.remote.get<Map>('/users/me');
///
/// // POST 요청
/// final response = await DS.remote.post('/users', data: {'name': 'John'});
///
/// // 인증 없이 요청
/// final response = await DS.remote.get('/public/info', requiresAuth: false);
/// ```
library;

import 'package:dio/dio.dart';
import '../../../app_config.dart';
import '../secure/secure_datasource.dart';
import 'api_response.dart';

class RemoteDataSource {
  late final Dio _dio;
  final SecureDataSource _secure;

  bool _refreshingToken = false;
  final List<void Function()> _refreshQueue = [];

  RemoteDataSource(this._secure);

  /// 초기화
  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(seconds: AppConfig.apiTimeout),
      receiveTimeout: Duration(seconds: AppConfig.apiTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 인증이 필요한 요청에 토큰 자동 추가
        if (options.extra['requiresAuth'] != false) {
          final token = await _secure.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        if (AppConfig.logApiCalls) {
          _logRequest(options);
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        if (AppConfig.logApiCalls) {
          _logResponse(response);
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (AppConfig.logApiCalls) {
          _logError(error);
        }

        // 401 에러 시 토큰 자동 갱신
        if (error.response?.statusCode == 401) {
          final success = await _handleTokenRefresh(error, handler);
          if (success) return;
        }

        handler.next(error);
      },
    ));
  }

  /// 토큰 갱신 처리
  Future<bool> _handleTokenRefresh(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final originalRequest = error.requestOptions;

    // 이미 갱신 중이면 대기열에 추가
    if (_refreshingToken) {
      _refreshQueue.add(() async {
        try {
          final token = await _secure.getAccessToken();
          originalRequest.headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(originalRequest);
          handler.resolve(response);
        } catch (e) {
          handler.next(error);
        }
      });
      return true;
    }

    _refreshingToken = true;

    try {
      final success = await _secure.refreshTokens();

      if (success) {
        // 대기열 요청 처리
        for (final callback in _refreshQueue) {
          callback();
        }
        _refreshQueue.clear();

        // 원래 요청 재시도
        final token = await _secure.getAccessToken();
        originalRequest.headers['Authorization'] = 'Bearer $token';
        final response = await _dio.fetch(originalRequest);
        handler.resolve(response);
        return true;
      }
    } catch (e) {
      // 갱신 실패 시 로그아웃 처리
      await _secure.clearTokens();
    } finally {
      _refreshingToken = false;
    }

    return false;
  }

  // ============================================================
  // HTTP Methods
  // ============================================================

  /// GET 요청
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? params,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: params,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST 요청
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST FormData (파일 업로드)
  Future<ApiResponse<T>> postFormData<T>(
    String endpoint, {
    required FormData data,
    bool requiresAuth = true,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: Options(
          extra: {'requiresAuth': requiresAuth},
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onProgress,
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PUT 요청
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PATCH 요청
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE 요청
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? params,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: params,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================
  // Error Handling
  // ============================================================

  ApiResponse<T> _handleError<T>(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiResponse.timeout();
        case DioExceptionType.connectionError:
          return ApiResponse.networkError();
        case DioExceptionType.badResponse:
          final response = error.response;
          if (response != null) {
            final data = response.data;
            return ApiResponse.error(
              status: response.statusCode ?? 500,
              message: data is Map ? data['message'] : null,
              errorCode: data is Map ? data['errorCode'] : null,
            );
          }
          break;
        default:
          break;
      }
    }

    return ApiResponse.error(message: error.toString());
  }

  // ============================================================
  // Logging
  // ============================================================

  void _logRequest(RequestOptions options) {
    print('[API] → ${options.method} ${options.path}');
    if (options.data != null) {
      print('[API]   Data: ${options.data}');
    }
  }

  void _logResponse(Response response) {
    print('[API] ← ${response.statusCode} ${response.requestOptions.path}');
  }

  void _logError(DioException error) {
    print('[API] ✗ ${error.response?.statusCode} ${error.requestOptions.path}');
    print('[API]   Error: ${error.message}');
  }
}
