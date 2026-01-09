# Flutter Base Project Structure

> AI가 쉽게 이해하고 수정할 수 있도록 설계된 모듈화 아키텍처

## Quick Start

```dart
import 'package:app/core/datasource/datasource.dart';
import 'package:app/addons/addons.dart';
import 'package:app/app_config.dart';

// 1. 앱 시작 시 초기화
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DataSource 초기화
  await DS.initialize();

  // Addons 초기화 (선택적 기능)
  await AddonRegistry.initialize([
    if (AppConfig.enableNotification) NotificationAddon(),
    if (AppConfig.enablePayment) PaymentAddon(publishableKey: 'pk_...'),
    if (AppConfig.enableMedia) MediaAddon(),
  ]);

  runApp(MyApp());
}

// 2. API 호출
final response = await DS.remote.get<Map>('/users/me');
if (response.isSuccess) {
  final user = User.fromJson(response.data!);
}

// 3. 로컬 저장
await DS.local.setString('theme', 'dark');

// 4. 보안 저장 (토큰)
await DS.secure.setAccessToken(token);
```

---

## Directory Structure

```
lib/
├── main.dart                 # 앱 진입점
├── app_config.dart           # 🎛️ 기능 ON/OFF, API URL 설정
│
├── core/                     # 🔒 핵심 인프라 (변경 최소화)
│   ├── datasource/           # 📡 데이터 관리 (NEW)
│   │   ├── datasource.dart   #     → DS.remote / DS.local / DS.secure
│   │   ├── remote/           #     → API 호출
│   │   ├── local/            #     → 로컬 저장 (캐시)
│   │   └── secure/           #     → 토큰 저장
│   │
│   ├── themes/               # 🎨 디자인 토큰 (반응형 지원)
│   │   ├── app_theme.dart    #     → ThemeData 생성
│   │   ├── color_theme.dart  #     → 색상 (JSON에서 로드)
│   │   ├── app_spacing.dart  #     → 간격 (반응형: AppSpacing.responsive(context).md)
│   │   ├── app_typography.dart #   → 타이포 (반응형: AppTypography.responsive(context).h1)
│   │   ├── responsive.dart   #     → 반응형 유틸 (context.isMobile, Breakpoints)
│   │   └── ...
│   │
│   ├── router/               # 🧭 라우팅
│   │   ├── app_router.dart   #     → GoRouter 설정
│   │   ├── auth_guard.dart   #     → 인증 상태 관리
│   │   └── shell_routes.dart #     → 바텀 네비 라우트
│   │
│   ├── widgets/              # 🧩 공통 위젯
│   │   ├── modern_button.dart
│   │   ├── modern_text_field.dart
│   │   └── ...
│   │
│   ├── result.dart           # Result<T> 패턴
│   ├── validators.dart       # 입력 검증
│   └── app_error_code.dart   # 에러 코드 정의
│
├── domain/                   # 📦 비즈니스 도메인
│   ├── auth/                 # 인증 (필수)
│   ├── user/                 # 사용자 (필수)
│   ├── home/                 # 홈 화면
│   └── settings/             # 설정
│
└── addons/                   # 🧩 선택적 기능 (플러그인 방식)
    ├── addon_registry.dart   # Addon 등록/관리
    ├── addons.dart           # 통합 export
    │
    ├── notification/         # 알림 (FCM + Local)
    │   ├── notification_addon.dart
    │   └── README.md
    │
    ├── payment/              # 결제 (Stripe)
    │   ├── payment_addon.dart
    │   └── README.md
    │
    └── media/                # 미디어 (이미지/비디오)
        ├── media_addon.dart
        └── README.md
```

---

## Key Files Reference

### Configuration
| File | Purpose |
|------|---------|
| `lib/app_config.dart` | 기능 ON/OFF, API URL, 테마 설정 |
| `assets/colorset.json` | 색상 팔레트 정의 |
| `assets/font.json` | 폰트 설정 |

### DataSource (API & Storage)
| File | Purpose | Usage |
|------|---------|-------|
| `lib/core/datasource/datasource.dart` | 통합 진입점 | `DS.remote`, `DS.local`, `DS.secure` |
| `lib/core/datasource/remote/remote_datasource.dart` | API 클라이언트 | `DS.remote.get('/path')` |
| `lib/core/datasource/local/local_datasource.dart` | 로컬 저장 | `DS.local.setString('key', 'val')` |
| `lib/core/datasource/secure/secure_datasource.dart` | 토큰 저장 | `DS.secure.getAccessToken()` |

### Theme
| File | Purpose |
|------|---------|
| `lib/core/themes/app_theme.dart` | ThemeData 생성 |
| `lib/core/themes/color_theme.dart` | AppColors, AppHSLColors |
| `lib/core/themes/app_spacing.dart` | 간격 토큰 (AppSpacing.xs ~ AppSpacing.xxxxxl) |
| `lib/core/themes/app_typography.dart` | 타이포그래피 |

### Router
| File | Purpose |
|------|---------|
| `lib/core/router/app_router.dart` | GoRouter 메인 설정 |
| `lib/core/router/auth_guard.dart` | 인증 상태 리스너 |
| `lib/core/router/general_routes.dart` | 공개 라우트 (splash, auth) |
| `lib/core/router/shell_routes.dart` | 보호된 라우트 (home, settings) |

---

## Domain Module Pattern

각 도메인은 동일한 구조를 따릅니다:

```
domain/[feature]/
├── entities/          # 데이터 모델
│   └── user_entity.dart
├── functions/         # 비즈니스 로직 (static methods → Result<T>)
│   ├── fetch_user.dart
│   └── update_user.dart
├── models/            # DTO (optional)
└── presentation/
    ├── screens/       # 전체 페이지
    │   └── profile_screen.dart
    └── widgets/       # 재사용 위젯
        └── profile_card.dart
```

### Function Pattern
```dart
// domain/user/functions/fetch_user.dart
import 'package:app/core/datasource/datasource.dart';

class FetchUser {
  static Future<Result<UserEntity>> call(String userId) async {
    final response = await DS.remote.get<Map>('/users/$userId');

    if (response.isSuccess && response.data != null) {
      return Result.success(UserEntity.fromJson(response.data!));
    }

    return Result.failure(
      AppErrorCode.serverError,
      response.message,
    );
  }
}
```

---

## AppConfig Usage

```dart
// lib/app_config.dart

class AppConfig {
  // 🌐 API
  static const String apiBaseUrl = 'https://api.example.com';
  static const int apiTimeout = 30;

  // 🔌 Addons (선택적 기능)
  static const bool enablePayment = false;      // Stripe
  static const bool enableNotification = false; // FCM
  static const bool enableMedia = true;         // 이미지 피커
  static const bool enableAdmin = false;        // 관리자
  static const bool enableFeedback = false;     // 피드백

  // 🎨 Theme
  static const String themePreset = 'minimal';  // minimal, rounded, sharp
  static const bool enableDarkMode = true;

  // 🔐 Auth
  static const bool enableEmailAuth = true;
  static const bool enableGoogleAuth = true;
  static const bool enableAppleAuth = true;
}
```

---

## DataSource API Reference

### Remote (API)
```dart
// GET
final response = await DS.remote.get<Map>('/users/me');
final response = await DS.remote.get<Map>('/users', params: {'page': 1});

// POST
final response = await DS.remote.post('/posts', data: {'title': 'Hello'});

// PUT / PATCH / DELETE
await DS.remote.put('/users/me', data: {...});
await DS.remote.patch('/users/me', data: {'name': 'New'});
await DS.remote.delete('/posts/123');

// 파일 업로드
final formData = FormData.fromMap({'file': await MultipartFile.fromFile(path)});
await DS.remote.postFormData('/upload', data: formData);

// 인증 없이 요청
await DS.remote.get('/public', requiresAuth: false);
```

### Local (SharedPreferences)
```dart
// 기본 타입
await DS.local.setString('key', 'value');
final value = DS.local.getString('key');

await DS.local.setInt('count', 10);
await DS.local.setBool('flag', true);

// JSON
await DS.local.setJson('user', {'name': 'John'});
final user = DS.local.getJson('user');

// 캐시 (만료 시간 포함)
await DS.local.setCacheItem('feed', data, expiry: Duration(minutes: 30));
final cached = DS.local.getCacheItem('feed'); // 만료 시 null 반환

// 설정
await DS.local.setSetting('theme', 'dark');
final theme = DS.local.getSetting<String>('theme');
```

### Secure (FlutterSecureStorage)
```dart
// 토큰
await DS.secure.setTokens(accessToken: 'abc', refreshToken: 'xyz');
final token = await DS.secure.getAccessToken();
await DS.secure.clearTokens();

// FCM
await DS.secure.setFcmToken(fcmToken);
final fcm = await DS.secure.getFcmToken();

// 로그인 상태
final isLoggedIn = await DS.isLoggedIn;

// 전체 삭제 (로그아웃)
await DS.clearAll();
```

---

## Adding New Features

### 1. New Domain
```bash
mkdir -p lib/domain/[feature]/{entities,functions,presentation/{screens,widgets}}
```

### 2. New API Endpoint
```dart
// domain/[feature]/functions/fetch_something.dart
class FetchSomething {
  static Future<Result<Something>> call() async {
    final response = await DS.remote.get<Map>('/something');
    if (response.isSuccess) {
      return Result.success(Something.fromJson(response.data!));
    }
    return Result.failure(AppErrorCode.serverError);
  }
}
```

### 3. New Screen
```dart
// domain/[feature]/presentation/screens/something_screen.dart
class SomethingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: 'Something'),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(...),
      ),
    );
  }
}
```

### 4. Add Route
```dart
// core/router/shell_routes.dart
GoRoute(
  path: '/something',
  builder: (context, state) => const SomethingScreen(),
),
```

---

## Color System

Colors are loaded from `assets/colorset.json`:

```json
{
  "primary": "#6366F1",
  "secondary": "#EC4899",
  "background": "#FFFFFF",
  "surface": "#F8FAFC",
  "text": "#1E293B",
  "textSecondary": "#64748B",
  "error": "#EF4444",
  "success": "#22C55E"
}
```

Usage:
```dart
Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.text),
  ),
)
```

---

## Spacing System

```dart
// 사용 가능한 간격 (정적)
AppSpacing.xs     // 4
AppSpacing.sm     // 8
AppSpacing.md     // 16
AppSpacing.lg     // 24
AppSpacing.xl     // 32
AppSpacing.xxl    // 40
AppSpacing.xxxl   // 48

// 정적 사용법
Padding(
  padding: EdgeInsets.all(AppSpacing.md),
  child: ...
)

// 반응형 사용법 (NEW)
final sp = AppSpacing.responsive(context);
Padding(
  padding: EdgeInsets.all(sp.md), // 디바이스별 자동 조정
  child: ...
)
```

---

## Responsive System

```dart
// 디바이스 타입 확인
if (context.isMobile) { ... }
if (context.isTablet) { ... }
if (context.isDesktop) { ... }

// 디바이스별 다른 값
final padding = context.responsive<double>(
  mobile: 16,
  tablet: 24,
  desktop: 32,
);

// 반응형 간격
final sp = AppSpacing.responsive(context);
sp.xs  // mobile: 4, tablet: 6, desktop: 8
sp.sm  // mobile: 8, tablet: 12, desktop: 16
sp.md  // mobile: 16, tablet: 20, desktop: 24

// 반응형 타이포그래피
final typo = AppTypography.responsive(context);
Text('Hello', style: typo.h1) // 디바이스별 폰트 크기 자동 조정

// 반응형 위젯
ResponsiveWidget(
  mobile: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
)
```

---

## Addons System

```dart
// 1. main.dart에서 초기화
await AddonRegistry.initialize([
  if (AppConfig.enableNotification) NotificationAddon(),
  if (AppConfig.enablePayment) PaymentAddon(publishableKey: 'pk_...'),
  if (AppConfig.enableMedia) MediaAddon(),
]);

// 2. Addon 활성화 확인
if (NotificationHelper.isEnabled) {
  await NotificationCore.requestPermission();
}

if (PaymentHelper.isEnabled) {
  final intent = await createPaymentIntent(...);
}

if (MediaHelper.isEnabled) {
  final image = await MediaPickerUtils.pickImage();
}

// 3. 라우터에 Addon 라우트 추가
final router = GoRouter(
  routes: [
    ...baseRoutes,
    ...AddonRegistry.routes,
  ],
);
```

---

## For AI: Quick Modifications

### API URL 변경
→ `lib/app_config.dart` → `apiBaseUrl`

### 새 기능 활성화/비활성화
→ `lib/app_config.dart` → `enablePayment`, `enableNotification`, etc.

### 색상 변경
→ `assets/colorset.json`

### 간격 조정
→ `lib/core/themes/app_spacing.dart`

### 새 API 추가
→ `lib/domain/[feature]/functions/` 에 새 파일 생성

### 새 화면 추가
→ `lib/domain/[feature]/presentation/screens/` 에 새 파일 생성
→ `lib/core/router/shell_routes.dart` 에 라우트 추가
