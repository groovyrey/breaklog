/// GitHub coordinates for the releases feed and About links, plus the cloud
/// backend the app talks to.
class AppConfig {
  AppConfig._();

  static const githubOwner = 'groovyrey';
  static const githubRepo = 'breaklog';
  static const githubUrl = 'https://github.com/$githubOwner/$githubRepo';
  static const releasesUrl = '$githubUrl/releases';

  /// Accounts backend, deployed from `~/breaklog-api` on Cloudflare account 4.
  /// It holds the database token so no database credential ships in the APK.
  static const apiUrl = 'https://breaklog-api.luloyapp.workers.dev';

  /// Web OAuth client id. Supply it at build time:
  /// `flutter build apk --dart-define=GOOGLE_SERVER_CLIENT_ID=...`
  /// google_sign_in needs it before Android returns an idToken, and the worker
  /// checks it as the token audience.
  static const googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Firebase project, matching `FIREBASE_PROJECT_ID` on the worker.
  static const firebaseProjectId = 'breaklog-de587';

  /// Cloudinary cloud, kept for future asset delivery. The login screen no
  /// longer streams from it, but assets live under `breaklog-assets`.
  static const cloudinaryCloud = 'soqaygtm';

  /// Folder created in the user's own Drive for attachment backups.
  static const driveFolderName = 'BreakLog';

  /// `drive.file` grants access only to files this app creates, which is all a
  /// backup needs.
  static const driveScope = 'https://www.googleapis.com/auth/drive.file';

  static const driveApiUrl = 'https://www.googleapis.com/drive/v3';
  static const driveUploadUrl = 'https://www.googleapis.com/upload/drive/v3';

  static bool get cloudConfigured => googleServerClientId.isNotEmpty;
}
