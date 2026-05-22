/// Global environment settings for third-party integrations.
///
/// Preferred setup (CI / release builds):
/// ```bash
/// flutter run --dart-define=GOOGLE_PLACES_API_KEY=your_key_here
/// ```
///
/// Runtime override (e.g. after loading from secure storage):
/// ```dart
/// KinEnvConfig.configure(googlePlacesApiKey: loadedKey);
/// ```
class KinEnvConfig {
  KinEnvConfig._();

  static String? _googlePlacesApiKeyOverride;

  /// Optional runtime injection from app bootstrap or secure storage.
  static void configure({String? googlePlacesApiKey}) {
    _googlePlacesApiKeyOverride = googlePlacesApiKey?.trim();
  }

  /// Google Places API key used for Text Search and photo media URLs.
  static String get googlePlacesApiKey {
    final override = _googlePlacesApiKeyOverride;
    if (override != null && override.isNotEmpty) {
      return override;
    }

    const dartDefineKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
    if (dartDefineKey.isNotEmpty) {
      return dartDefineKey;
    }

    const legacyMapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (legacyMapsKey.isNotEmpty) {
      return legacyMapsKey;
    }

    return '';
  }

  static bool get hasGooglePlacesApiKey => googlePlacesApiKey.isNotEmpty;

  static String requireGooglePlacesApiKey() {
    final key = googlePlacesApiKey;
    if (key.isEmpty) {
      throw StateError(
        'GOOGLE_PLACES_API_KEY is not configured. '
        'Pass --dart-define=GOOGLE_PLACES_API_KEY=... or call '
        'KinEnvConfig.configure(googlePlacesApiKey: ...) during startup.',
      );
    }
    return key;
  }
}
