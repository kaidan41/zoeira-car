/// Constantes globais do app Zoeira Car
class AppConstants {
  AppConstants._();

  // ─────────────────────────────────────────────
  // YouTube (via RSS público do canal — sem API key)
  // ─────────────────────────────────────────────

  /// Channel ID do canal Zoeira Car (obtido da página oficial do canal)
  static const String youtubeChannelId = 'UCJHq9RfDWdnnI_eJV-_C13g';

  // ─────────────────────────────────────────────
  // Configurações do App
  // ─────────────────────────────────────────────

  static const String appName = 'Zoeira Car';
  static const String appTagline = 'O raio-x da sua nave!';
  static const String packageName = 'com.zoeiracartv.app';

  // ─────────────────────────────────────────────
  // Links externos
  // ─────────────────────────────────────────────

  static const String youtubeChannelUrl =
      'https://www.youtube.com/@ZoeiraCar';
  static const String instagramUrl = 'https://www.instagram.com/zoeiracartv';
  static const String privacyPolicyUrl =
      'https://zoeiracartv.com.br/privacidade';
  static const String termsOfServiceUrl =
      'https://zoeiracartv.com.br/termos';

  // ─────────────────────────────────────────────
  // Paginação / Cache
  // ─────────────────────────────────────────────

  static const int videosPerPage = 20;
  static const int vehiclesPerPage = 15;

  /// Duração do cache de vídeos em memória (em minutos)
  static const int videoCacheDurationMinutes = 10;
}
