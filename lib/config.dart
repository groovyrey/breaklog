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

  /// Cloudinary cloud that hosts the login background clips.
  static const cloudinaryCloud = 'soqaygtm';

  /// Login background clips, played in order and looped. Vertical, so they
  /// cover the screen. Served at a modest width so the first frame lands fast.
  static const loginVideos = <String>[
    'https://res.cloudinary.com/$cloudinaryCloud/video/upload/q_auto:low,w_540/Jamix_Project_-_Open_the_world_of_freestyle.mp4',
    'https://res.cloudinary.com/$cloudinaryCloud/video/upload/q_auto:low,w_540/B-Boy_Run_USA_Crazy_Moment_Red_Bull_Bc_One_Cypher_2023.mp4',
    'https://res.cloudinary.com/$cloudinaryCloud/video/upload/q_auto:low,w_540/Road_to_Double_Airflare_Monkeyking_Video_clip_by_fitbreakgym_shorts_viral_bc1.mp4',
  ];

  /// Folder created in the user's own Drive for attachment backups.
  static const driveFolderName = 'BreakLog';

  /// `drive.file` grants access only to files this app creates, which is all a
  /// backup needs.
  static const driveScope = 'https://www.googleapis.com/auth/drive.file';

  static const driveApiUrl = 'https://www.googleapis.com/drive/v3';
  static const driveUploadUrl = 'https://www.googleapis.com/upload/drive/v3';

  static bool get cloudConfigured => googleServerClientId.isNotEmpty;
}
