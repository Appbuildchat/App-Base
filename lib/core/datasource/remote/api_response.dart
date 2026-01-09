/// API Response Wrapper
///
/// 모든 API 응답을 통일된 형식으로 관리합니다.
///
/// 사용법:
/// ```dart
/// final response = await DS.remote.get<User>('/users/me');
/// if (response.isSuccess) {
///   final user = User.fromJson(response.data!);
/// } else {
///   print('Error: ${response.message}');
/// }
/// ```
library;

class ApiResponse<T> {
  final int status;
  final String? message;
  final T? data;
  final bool isSuccess;
  final String? errorCode;

  ApiResponse._({
    required this.status,
    this.message,
    this.data,
    required this.isSuccess,
    this.errorCode,
  });

  /// 성공 응답 생성
  factory ApiResponse.success(dynamic rawData) {
    // 서버 응답 형식에 따라 파싱
    if (rawData is Map<String, dynamic>) {
      return ApiResponse._(
        status: rawData['status'] ?? rawData['statusCode'] ?? 200,
        message: rawData['message'] as String?,
        data: rawData['data'] as T?,
        isSuccess: true,
      );
    }

    // 직접 데이터인 경우
    return ApiResponse._(
      status: 200,
      message: null,
      data: rawData as T?,
      isSuccess: true,
    );
  }

  /// 에러 응답 생성
  factory ApiResponse.error({
    int status = 500,
    String? message,
    String? errorCode,
  }) {
    return ApiResponse._(
      status: status,
      message: message ?? '오류가 발생했습니다',
      data: null,
      isSuccess: false,
      errorCode: errorCode,
    );
  }

  /// 네트워크 에러
  factory ApiResponse.networkError() {
    return ApiResponse._(
      status: 0,
      message: '네트워크 연결을 확인해주세요',
      data: null,
      isSuccess: false,
      errorCode: 'NETWORK_ERROR',
    );
  }

  /// 타임아웃 에러
  factory ApiResponse.timeout() {
    return ApiResponse._(
      status: 408,
      message: '요청 시간이 초과되었습니다',
      data: null,
      isSuccess: false,
      errorCode: 'TIMEOUT',
    );
  }

  /// 인증 에러
  factory ApiResponse.unauthorized() {
    return ApiResponse._(
      status: 401,
      message: '로그인이 필요합니다',
      data: null,
      isSuccess: false,
      errorCode: 'UNAUTHORIZED',
    );
  }

  @override
  String toString() {
    return 'ApiResponse(status: $status, isSuccess: $isSuccess, message: $message, data: $data)';
  }
}
