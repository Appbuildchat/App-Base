/// App Configuration
///
/// 앱의 모든 설정을 중앙에서 관리합니다.
/// AI가 쉽게 수정할 수 있도록 한 파일에 모아두었습니다.
///
/// 사용법:
/// ```dart
/// if (AppConfig.enablePayment) {
///   // 결제 기능 활성화
/// }
/// ```
library;

class AppConfig {
  AppConfig._();

  // ============================================================
  // 🌐 API Configuration
  // ============================================================

  /// API 서버 기본 URL
  static const String apiBaseUrl = 'https://api.example.com';

  /// API 요청 타임아웃 (초)
  static const int apiTimeout = 30;

  /// API 요청 시 자동 재시도 횟수
  static const int apiRetryCount = 3;

  // ============================================================
  // 🔌 Addons (선택적 기능)
  // ============================================================

  /// 결제 기능 (Stripe)
  static const bool enablePayment = false;

  /// 푸시 알림 (FCM)
  static const bool enableNotification = false;

  /// 미디어 (이미지/비디오 피커)
  static const bool enableMedia = true;

  /// 관리자 기능
  static const bool enableAdmin = false;

  /// 피드백 기능
  static const bool enableFeedback = false;

  // ============================================================
  // 🎨 Theme Configuration
  // ============================================================

  /// 테마 프리셋: 'minimal', 'rounded', 'sharp', 'glass'
  static const String themePreset = 'minimal';

  /// 다크 모드 지원
  static const bool enableDarkMode = true;

  /// 시스템 테마 따르기
  static const bool followSystemTheme = true;

  // ============================================================
  // 📱 Platform Configuration
  // ============================================================

  /// 웹 지원
  static const bool enableWeb = false;

  /// 데스크탑 지원
  static const bool enableDesktop = false;

  // ============================================================
  // 🔐 Auth Configuration
  // ============================================================

  /// 이메일 로그인
  static const bool enableEmailAuth = true;

  /// 구글 로그인
  static const bool enableGoogleAuth = true;

  /// 애플 로그인
  static const bool enableAppleAuth = true;

  // ============================================================
  // 🔧 Debug Configuration
  // ============================================================

  /// 디버그 모드 (로깅 활성화)
  static const bool debugMode = true;

  /// API 로깅
  static const bool logApiCalls = true;
}
