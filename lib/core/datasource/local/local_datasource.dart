/// Local Data Source
///
/// SharedPreferences를 래핑하여 로컬 데이터를 관리합니다.
/// - 타입 안전한 저장/조회
/// - 캐시 기능 (만료 시간 지원)
/// - 사용자 설정 관리
///
/// 사용법:
/// ```dart
/// // 데이터 저장
/// await DS.local.setItem('theme', 'dark');
///
/// // 데이터 조회
/// final theme = DS.local.getString('theme');
///
/// // 캐시 저장 (30분 후 만료)
/// await DS.local.setCacheItem('user_list', users, expiry: Duration(minutes: 30));
///
/// // 캐시 조회 (만료 시 null 반환)
/// final cachedUsers = DS.local.getCacheItem<List>('user_list');
/// ```
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataSource {
  SharedPreferences? _prefs;

  static const _cachePrefix = 'cache_';
  static const _settingsPrefix = 'settings_';

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _storage {
    if (_prefs == null) {
      throw StateError('LocalDataSource not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // ============================================================
  // Basic Operations
  // ============================================================

  /// 문자열 저장
  Future<bool> setString(String key, String value) {
    return _storage.setString(key, value);
  }

  /// 문자열 조회
  String? getString(String key) {
    return _storage.getString(key);
  }

  /// 정수 저장
  Future<bool> setInt(String key, int value) {
    return _storage.setInt(key, value);
  }

  /// 정수 조회
  int? getInt(String key) {
    return _storage.getInt(key);
  }

  /// 불린 저장
  Future<bool> setBool(String key, bool value) {
    return _storage.setBool(key, value);
  }

  /// 불린 조회
  bool? getBool(String key) {
    return _storage.getBool(key);
  }

  /// 실수 저장
  Future<bool> setDouble(String key, double value) {
    return _storage.setDouble(key, value);
  }

  /// 실수 조회
  double? getDouble(String key) {
    return _storage.getDouble(key);
  }

  /// 키 삭제
  Future<bool> remove(String key) {
    return _storage.remove(key);
  }

  /// 키 존재 여부
  bool containsKey(String key) {
    return _storage.containsKey(key);
  }

  // ============================================================
  // JSON Operations
  // ============================================================

  /// JSON 객체 저장
  Future<bool> setJson(String key, Map<String, dynamic> value) {
    return _storage.setString(key, jsonEncode(value));
  }

  /// JSON 객체 조회
  Map<String, dynamic>? getJson(String key) {
    final jsonString = _storage.getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// JSON 리스트 저장
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) {
    return _storage.setString(key, jsonEncode(value));
  }

  /// JSON 리스트 조회
  List<Map<String, dynamic>>? getJsonList(String key) {
    final jsonString = _storage.getString(key);
    if (jsonString == null) return null;
    try {
      final list = jsonDecode(jsonString) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Cache Operations (with expiry)
  // ============================================================

  /// 캐시 저장 (만료 시간 포함)
  Future<bool> setCacheItem<T>(
    String key,
    T value, {
    Duration expiry = const Duration(minutes: 30),
  }) {
    final cacheData = {
      'value': value,
      'expiry': DateTime.now().add(expiry).millisecondsSinceEpoch,
    };
    return _storage.setString('$_cachePrefix$key', jsonEncode(cacheData));
  }

  /// 캐시 조회 (만료 자동 처리)
  T? getCacheItem<T>(String key) {
    final jsonString = _storage.getString('$_cachePrefix$key');
    if (jsonString == null) return null;

    try {
      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final expiry = cacheData['expiry'] as int;

      // 만료 체크
      if (DateTime.now().millisecondsSinceEpoch > expiry) {
        _storage.remove('$_cachePrefix$key'); // 만료된 캐시 삭제
        return null;
      }

      return cacheData['value'] as T?;
    } catch (_) {
      return null;
    }
  }

  /// 캐시 삭제
  Future<bool> removeCacheItem(String key) {
    return _storage.remove('$_cachePrefix$key');
  }

  /// 모든 캐시 삭제
  Future<void> clearCache() async {
    final keys = _storage.getKeys().where((k) => k.startsWith(_cachePrefix));
    for (final key in keys) {
      await _storage.remove(key);
    }
  }

  /// 캐시 유효 여부 확인
  bool isCacheValid(String key) {
    final jsonString = _storage.getString('$_cachePrefix$key');
    if (jsonString == null) return false;

    try {
      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final expiry = cacheData['expiry'] as int;
      return DateTime.now().millisecondsSinceEpoch <= expiry;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // Settings Operations
  // ============================================================

  /// 설정 저장
  Future<bool> setSetting<T>(String key, T value) {
    final settingsKey = '$_settingsPrefix$key';
    if (value is String) return _storage.setString(settingsKey, value);
    if (value is int) return _storage.setInt(settingsKey, value);
    if (value is bool) return _storage.setBool(settingsKey, value);
    if (value is double) return _storage.setDouble(settingsKey, value);
    return _storage.setString(settingsKey, jsonEncode(value));
  }

  /// 설정 조회
  T? getSetting<T>(String key, {T? defaultValue}) {
    final settingsKey = '$_settingsPrefix$key';
    final value = _storage.get(settingsKey);
    if (value == null) return defaultValue;
    return value as T?;
  }

  /// 모든 설정 삭제
  Future<void> clearSettings() async {
    final keys = _storage.getKeys().where((k) => k.startsWith(_settingsPrefix));
    for (final key in keys) {
      await _storage.remove(key);
    }
  }

  // ============================================================
  // Cleanup
  // ============================================================

  /// 모든 데이터 삭제
  Future<bool> clearAll() {
    return _storage.clear();
  }

  /// 만료된 캐시만 정리
  Future<void> cleanupExpiredCache() async {
    final keys = _storage.getKeys().where((k) => k.startsWith(_cachePrefix));
    for (final key in keys) {
      final cleanKey = key.substring(_cachePrefix.length);
      getCacheItem(cleanKey); // 만료 시 자동 삭제됨
    }
  }
}
