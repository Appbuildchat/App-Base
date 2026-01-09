/// Secure Data Source
///
/// 민감한 데이터(토큰 등)를 안전하게 저장합니다.
/// - 암호화된 저장소 사용
/// - 토큰 자동 갱신
/// - 보안 키체인 통합
///
/// 사용법:
/// ```dart
/// // 토큰 저장
/// await DS.secure.setAccessToken(token);
///
/// // 토큰 조회
/// final token = await DS.secure.getAccessToken();
///
/// // 토큰 유효성 확인 및 갱신
/// final isValid = await DS.secure.ensureValidToken();
/// ```
library;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../app_config.dart';

class SecureDataSource {
  late FlutterSecureStorage _storage;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyFcmToken = 'fcm_token';
  static const _keyUserId = 'user_id';

  /// 초기화
  Future<void> initialize() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }

  // ============================================================
  // Token Management
  // ============================================================

  /// 액세스 토큰 저장
  Future<void> setAccessToken(String token) {
    return _storage.write(key: _keyAccessToken, value: token);
  }

  /// 액세스 토큰 조회
  Future<String?> getAccessToken() {
    return _storage.read(key: _keyAccessToken);
  }

  /// 리프레시 토큰 저장
  Future<void> setRefreshToken(String token) {
    return _storage.write(key: _keyRefreshToken, value: token);
  }

  /// 리프레시 토큰 조회
  Future<String?> getRefreshToken() {
    return _storage.read(key: _keyRefreshToken);
  }

  /// 토큰 쌍 저장
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await setAccessToken(accessToken);
    await setRefreshToken(refreshToken);
  }

  /// 모든 토큰 삭제
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  /// 토큰 존재 여부 확인
  Future<bool> hasTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    return access != null && refresh != null;
  }

  // ============================================================
  // Token Refresh
  // ============================================================

  /// 토큰 갱신
  Future<bool> refreshTokens() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      // RemoteDataSource와 순환 참조 방지를 위해 직접 Dio 사용
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(seconds: AppConfig.apiTimeout),
        receiveTimeout: Duration(seconds: AppConfig.apiTimeout),
      ));

      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await setAccessToken(data['accessToken'] ?? data['access_token']);
        await setRefreshToken(data['refreshToken'] ?? data['refresh_token']);

        if (AppConfig.debugMode) {
          print('[SecureDS] Token refreshed successfully');
        }

        return true;
      }
    } catch (e) {
      if (AppConfig.debugMode) {
        print('[SecureDS] Token refresh failed: $e');
      }
      await clearTokens();
    }

    return false;
  }

  /// 토큰 유효성 확인 및 필요 시 갱신
  Future<bool> ensureValidToken() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;

    // TODO: JWT 디코딩하여 만료 시간 확인
    // 현재는 토큰이 있으면 유효하다고 가정
    return true;
  }

  // ============================================================
  // FCM Token
  // ============================================================

  /// FCM 토큰 저장
  Future<void> setFcmToken(String token) {
    return _storage.write(key: _keyFcmToken, value: token);
  }

  /// FCM 토큰 조회
  Future<String?> getFcmToken() {
    return _storage.read(key: _keyFcmToken);
  }

  /// FCM 토큰 삭제
  Future<void> clearFcmToken() {
    return _storage.delete(key: _keyFcmToken);
  }

  // ============================================================
  // User ID
  // ============================================================

  /// 사용자 ID 저장
  Future<void> setUserId(String userId) {
    return _storage.write(key: _keyUserId, value: userId);
  }

  /// 사용자 ID 조회
  Future<String?> getUserId() {
    return _storage.read(key: _keyUserId);
  }

  /// 사용자 ID 삭제
  Future<void> clearUserId() {
    return _storage.delete(key: _keyUserId);
  }

  // ============================================================
  // Generic Secure Storage
  // ============================================================

  /// 보안 데이터 저장
  Future<void> setSecureItem(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  /// 보안 데이터 조회
  Future<String?> getSecureItem(String key) {
    return _storage.read(key: key);
  }

  /// 보안 데이터 삭제
  Future<void> removeSecureItem(String key) {
    return _storage.delete(key: key);
  }

  /// 모든 보안 데이터 삭제
  Future<void> clearAll() {
    return _storage.deleteAll();
  }
}
