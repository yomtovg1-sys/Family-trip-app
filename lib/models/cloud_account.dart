/// The future remote backends a [CloudRepository] could be backed by. No
/// vendor is connected yet — this exists so the account picker and settings
/// UI have a fixed, known set of choices to show once one is wired up.
enum CloudProviderKind { googleDrive, iCloud, dropbox }

extension CloudProviderKindX on CloudProviderKind {
  String get label {
    switch (this) {
      case CloudProviderKind.googleDrive:
        return 'Google Drive';
      case CloudProviderKind.iCloud:
        return 'iCloud';
      case CloudProviderKind.dropbox:
        return 'Dropbox';
    }
  }

  String get emoji {
    switch (this) {
      case CloudProviderKind.googleDrive:
        return '🟢';
      case CloudProviderKind.iCloud:
        return '☁️';
      case CloudProviderKind.dropbox:
        return '📦';
    }
  }
}

/// The signed-in account a backup is associated with. Until a real
/// [CloudProviderKind] is connected, this reflects the local device account
/// only (see `SettingsRepository`), which is enough to validate ownership
/// of on-device backups and to show "Connected account" in the UI.
class CloudAccountInfo {
  final String email;
  final String displayName;
  final CloudProviderKind? provider;

  const CloudAccountInfo({
    required this.email,
    required this.displayName,
    this.provider,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'provider': provider?.name,
      };

  factory CloudAccountInfo.fromJson(Map<String, dynamic> json) {
    return CloudAccountInfo(
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      provider: json['provider'] != null
          ? CloudProviderKind.values.byName(json['provider'] as String)
          : null,
    );
  }
}
