import 'package:firebase_core/firebase_core.dart';

/// Firebase Web and environment configuration supplied at build time.
///
/// Firebase Web configuration values are public client settings, not secrets.
/// Pass environment-specific values with --dart-define-from-file.
abstract final class FirebaseConfig {
  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  /// Whether account creation sends an email verification message.
  static const sendEmailVerification = bool.fromEnvironment(
    'SEND_EMAIL_VERIFICATION',
    defaultValue: true,
  );

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw StateError('Firebase Web configuration is missing.');
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
    );
  }
}
