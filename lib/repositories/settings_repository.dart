import '../models/user_settings_model.dart';

abstract interface class SettingsRepository {
  Future<UserSettingsModel> readSettings();
  Future<void> saveSettings(UserSettingsModel settings);
}
