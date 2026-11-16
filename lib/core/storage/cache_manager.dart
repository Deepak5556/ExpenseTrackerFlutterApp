import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages lightweight, non-sensitive application settings and metadata in SharedPreferences.
///
/// CRITICAL: In accordance with the system architecture, no financial transactions,
/// balances, or account secrets are ever written to local storage. Google Sheets
/// remains the sole authoritative source of truth.
abstract interface class CacheManager {
  String? get spreadsheetId;
  String get selectedCurrency;
  DateTime? get lastSyncTime;
  int get schemaVersion;
  String? get lastDashboardFilterMonth;
  bool get onboardingComplete;
  bool get notificationsEnabled;

  Future<void> setSpreadsheetId(String? id);
  Future<void> setSelectedCurrency(String currency);
  Future<void> setLastSyncTime(DateTime time);
  Future<void> setSchemaVersion(int version);
  Future<void> setLastDashboardFilterMonth(String? month);
  Future<void> setOnboardingComplete(bool complete);
  Future<void> setNotificationsEnabled(bool enabled);
  Future<void> clearConnection();
}

class SharedPreferencesCacheManager implements CacheManager {
  SharedPreferencesCacheManager(this._prefs);

  final SharedPreferences _prefs;

  static const String _keySpreadsheetId = 'connected_spreadsheet_id';
  static const String _keyCurrency = 'cached_selected_currency';
  static const String _keyLastSyncMillis = 'last_successful_sync_time_millis';
  static const String _keySchemaVersion = 'cached_schema_version';
  static const String _keyDashboardFilterMonth = 'last_dashboard_filter_month';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  @override
  String? get spreadsheetId => _prefs.getString(_keySpreadsheetId);

  @override
  String get selectedCurrency => _prefs.getString(_keyCurrency) ?? 'INR';

  @override
  DateTime? get lastSyncTime {
    final millis = _prefs.getInt(_keyLastSyncMillis);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  @override
  int get schemaVersion => _prefs.getInt(_keySchemaVersion) ?? 1;

  @override
  String? get lastDashboardFilterMonth =>
      _prefs.getString(_keyDashboardFilterMonth);

  @override
  bool get onboardingComplete =>
      _prefs.getBool(_keyOnboardingComplete) ?? false;

  @override
  bool get notificationsEnabled =>
      _prefs.getBool(_keyNotificationsEnabled) ?? true;

  @override
  Future<void> setSpreadsheetId(String? id) async {
    if (id == null) {
      await _prefs.remove(_keySpreadsheetId);
    } else {
      await _prefs.setString(_keySpreadsheetId, id);
    }
  }

  @override
  Future<void> setSelectedCurrency(String currency) async {
    await _prefs.setString(_keyCurrency, currency);
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    await _prefs.setInt(_keyLastSyncMillis, time.millisecondsSinceEpoch);
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    await _prefs.setInt(_keySchemaVersion, version);
  }

  @override
  Future<void> setLastDashboardFilterMonth(String? month) async {
    if (month == null) {
      await _prefs.remove(_keyDashboardFilterMonth);
    } else {
      await _prefs.setString(_keyDashboardFilterMonth, month);
    }
  }

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setBool(_keyOnboardingComplete, complete);
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  @override
  Future<void> clearConnection() async {
    await _prefs.remove(_keySpreadsheetId);
    await _prefs.remove(_keyLastSyncMillis);
  }
}

class InMemoryCacheManager implements CacheManager {
  String? _spreadsheetId;
  String _currency = 'INR';
  DateTime? _lastSyncTime;
  int _schemaVersion = 1;
  String? _dashboardFilterMonth;
  bool _onboardingComplete = false;
  bool _notificationsEnabled = true;

  @override
  String? get spreadsheetId => _spreadsheetId;

  @override
  String get selectedCurrency => _currency;

  @override
  DateTime? get lastSyncTime => _lastSyncTime;

  @override
  int get schemaVersion => _schemaVersion;

  @override
  String? get lastDashboardFilterMonth => _dashboardFilterMonth;

  @override
  bool get onboardingComplete => _onboardingComplete;

  @override
  bool get notificationsEnabled => _notificationsEnabled;

  @override
  Future<void> setSpreadsheetId(String? id) async {
    _spreadsheetId = id;
  }

  @override
  Future<void> setSelectedCurrency(String currency) async {
    _currency = currency;
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    _lastSyncTime = time;
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    _schemaVersion = version;
  }

  @override
  Future<void> setLastDashboardFilterMonth(String? month) async {
    _dashboardFilterMonth = month;
  }

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    _onboardingComplete = complete;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
  }

  @override
  Future<void> clearConnection() async {
    _spreadsheetId = null;
    _lastSyncTime = null;
  }
}

/// Riverpod provider for [CacheManager]. Defaults to [InMemoryCacheManager] if
/// not overridden in [ProviderScope].
final Provider<CacheManager> cacheManagerProvider = Provider<CacheManager>((Ref ref) {
  return InMemoryCacheManager();
});
