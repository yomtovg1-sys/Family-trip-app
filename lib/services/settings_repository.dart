import 'package:shared_preferences/shared_preferences.dart';
import '../models/cloud_account.dart';

/// App-wide preferences that control the Sync & Backup feature: whether
/// automatic backups are on, whether AI conversations are included, and
/// which account backups are attributed to. Kept separate from
/// [BackupRepository] (which stores the backup payloads themselves) so
/// settings can be read instantly without touching potentially large backup
/// blobs.
abstract class SettingsRepository {
  Future<bool> getAutoBackupEnabled();
  Future<void> setAutoBackupEnabled(bool enabled);

  Future<bool> getIncludeAiConversations();
  Future<void> setIncludeAiConversations(bool include);

  Future<CloudAccountInfo> getConnectedAccount();
}

/// Persists settings with `shared_preferences`, which works the same way
/// (backed by browser localStorage) on web as it does on device — so
/// preferences genuinely survive a page reload, not just an in-memory
/// session.
class LocalSettingsRepository implements SettingsRepository {
  static const _autoBackupKey = 'sync_backup.auto_backup_enabled';
  static const _includeAiKey = 'sync_backup.include_ai_conversations';
  static const _accountEmailKey = 'sync_backup.connected_account_email';
  static const _accountNameKey = 'sync_backup.connected_account_name';

  final String defaultAccountEmail;
  final String defaultAccountName;

  LocalSettingsRepository({
    required this.defaultAccountEmail,
    required this.defaultAccountName,
  });

  @override
  Future<bool> getAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? true;
  }

  @override
  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
  }

  @override
  Future<bool> getIncludeAiConversations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_includeAiKey) ?? false;
  }

  @override
  Future<void> setIncludeAiConversations(bool include) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_includeAiKey, include);
  }

  @override
  Future<CloudAccountInfo> getConnectedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return CloudAccountInfo(
      email: prefs.getString(_accountEmailKey) ?? defaultAccountEmail,
      displayName: prefs.getString(_accountNameKey) ?? defaultAccountName,
    );
  }
}
