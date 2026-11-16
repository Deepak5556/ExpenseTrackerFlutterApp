import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_journal_budget/core/storage/cache_manager.dart';

void main() {
  group('SharedPreferencesCacheManager Tests', () {
    late SharedPreferences prefs;
    late SharedPreferencesCacheManager cacheManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'connected_spreadsheet_id': 'test-sheet-id',
        'cached_selected_currency': 'USD',
        'last_successful_sync_time_millis': 1700000000000,
        'cached_schema_version': 2,
        'last_dashboard_filter_month': '2026-11',
        'onboarding_complete': true,
        'notifications_enabled': false,
      });
      prefs = await SharedPreferences.getInstance();
      cacheManager = SharedPreferencesCacheManager(prefs);
    });

    test('Initial cached values are correctly read from SharedPreferences', () {
      expect(cacheManager.spreadsheetId, 'test-sheet-id');
      expect(cacheManager.selectedCurrency, 'USD');
      expect(
        cacheManager.lastSyncTime,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      expect(cacheManager.schemaVersion, 2);
      expect(cacheManager.lastDashboardFilterMonth, '2026-11');
      expect(cacheManager.onboardingComplete, isTrue);
      expect(cacheManager.notificationsEnabled, isFalse);
    });

    test('Updating cached values persists to SharedPreferences', () async {
      await cacheManager.setSpreadsheetId('new-sheet-id');
      expect(cacheManager.spreadsheetId, 'new-sheet-id');

      await cacheManager.setSelectedCurrency('EUR');
      expect(cacheManager.selectedCurrency, 'EUR');

      final now = DateTime.now();
      await cacheManager.setLastSyncTime(now);
      expect(
        cacheManager.lastSyncTime?.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );

      await cacheManager.setSchemaVersion(3);
      expect(cacheManager.schemaVersion, 3);

      await cacheManager.setLastDashboardFilterMonth('2026-12');
      expect(cacheManager.lastDashboardFilterMonth, '2026-12');

      await cacheManager.setOnboardingComplete(false);
      expect(cacheManager.onboardingComplete, isFalse);

      await cacheManager.setNotificationsEnabled(true);
      expect(cacheManager.notificationsEnabled, isTrue);
    });

    test('clearConnection clears spreadsheet ID and sync timestamp', () async {
      await cacheManager.clearConnection();
      expect(cacheManager.spreadsheetId, isNull);
      expect(cacheManager.lastSyncTime, isNull);
      // Currency and UI prefs remain preserved
      expect(cacheManager.selectedCurrency, 'USD');
    });
  });

  group('InMemoryCacheManager Tests', () {
    test('Default in-memory cache behaves correctly', () async {
      final inMemory = InMemoryCacheManager();
      expect(inMemory.spreadsheetId, isNull);
      expect(inMemory.selectedCurrency, 'INR');
      expect(inMemory.lastSyncTime, isNull);
      expect(inMemory.schemaVersion, 1);

      await inMemory.setSpreadsheetId('sheet-xyz');
      await inMemory.setSelectedCurrency('GBP');
      expect(inMemory.spreadsheetId, 'sheet-xyz');
      expect(inMemory.selectedCurrency, 'GBP');

      await inMemory.clearConnection();
      expect(inMemory.spreadsheetId, isNull);
      expect(inMemory.selectedCurrency, 'GBP');
    });
  });
}
