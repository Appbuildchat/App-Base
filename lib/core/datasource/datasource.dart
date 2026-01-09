/// DataSource 통합 관리
///
/// 모든 데이터소스를 하나로 통합하여 쉽게 사용할 수 있습니다.
///
/// ## 사용법
///
/// ### 초기화 (main.dart에서)
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await DS.initialize();
///   runApp(MyApp());
/// }
/// ```
///
/// ### API 호출
/// ```dart
/// // GET 요청
/// final response = await DS.remote.get<Map>('/users/me');
/// if (response.isSuccess) {
///   final user = User.fromJson(response.data!);
/// }
///
/// // POST 요청
/// final response = await DS.remote.post('/posts', data: {'title': 'Hello'});
///
/// // 인증 없이 요청
/// final response = await DS.remote.get('/public', requiresAuth: false);
/// ```
///
/// ### 로컬 저장
/// ```dart
/// // 단순 저장
/// await DS.local.setString('theme', 'dark');
/// final theme = DS.local.getString('theme');
///
/// // JSON 저장
/// await DS.local.setJson('user', {'name': 'John', 'age': 25});
/// final user = DS.local.getJson('user');
///
/// // 캐시 저장 (30분 후 만료)
/// await DS.local.setCacheItem('feed', feedData, expiry: Duration(minutes: 30));
/// final cachedFeed = DS.local.getCacheItem('feed');
/// ```
///
/// ### 보안 저장 (토큰)
/// ```dart
/// // 토큰 저장
/// await DS.secure.setTokens(
///   accessToken: 'abc123',
///   refreshToken: 'xyz789',
/// );
///
/// // 토큰 조회
/// final token = await DS.secure.getAccessToken();
///
/// // 로그아웃
/// await DS.clearAll();
/// ```
library;

import 'remote/remote_datasource.dart';
import 'local/local_datasource.dart';
import 'secure/secure_datasource.dart';

/// DataSource 싱글톤
///
/// `DS`로 짧게 접근 가능:
/// - `DS.remote` - API 요청
/// - `DS.local` - 로컬 저장
/// - `DS.secure` - 보안 저장
class DS {
  DS._();

  static final SecureDataSource _secure = SecureDataSource();
  static final LocalDataSource _local = LocalDataSource();
  static late final RemoteDataSource _remote;

  static bool _initialized = false;

  /// Remote DataSource (API)
  static RemoteDataSource get remote {
    _checkInitialized();
    return _remote;
  }

  /// Local DataSource (SharedPreferences)
  static LocalDataSource get local {
    _checkInitialized();
    return _local;
  }

  /// Secure DataSource (FlutterSecureStorage)
  static SecureDataSource get secure {
    _checkInitialized();
    return _secure;
  }

  /// 초기화 여부 확인
  static void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'DataSource not initialized. Call DS.initialize() in main() first.',
      );
    }
  }

  /// 초기화
  ///
  /// main.dart에서 앱 시작 전 호출:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await DS.initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> initialize() async {
    if (_initialized) return;

    await _secure.initialize();
    await _local.initialize();

    _remote = RemoteDataSource(_secure);
    _remote.initialize();

    _initialized = true;
  }

  /// 모든 데이터 삭제 (로그아웃 시 사용)
  ///
  /// ```dart
  /// Future<void> logout() async {
  ///   await DS.clearAll();
  ///   // 로그인 화면으로 이동
  /// }
  /// ```
  static Future<void> clearAll() async {
    _checkInitialized();
    await _secure.clearTokens();
    await _local.clearAll();
  }

  /// 캐시만 삭제
  static Future<void> clearCache() async {
    _checkInitialized();
    await _local.clearCache();
  }

  /// 토큰 존재 여부 확인 (로그인 상태)
  static Future<bool> get isLoggedIn async {
    _checkInitialized();
    return _secure.hasTokens();
  }
}
