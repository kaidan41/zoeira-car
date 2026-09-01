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
      'https://kaidan41.github.io/zoeira-car/privacidade.html';
  static const String termsOfServiceUrl =
      'https://kaidan41.github.io/zoeira-car/termos.html';

  // ─────────────────────────────────────────────
  // Paginação / Cache
  // ─────────────────────────────────────────────

  static const int videosPerPage = 20;
  static const int vehiclesPerPage = 15;

  /// Duração do cache de vídeos em memória (em minutos)
  static const int videoCacheDurationMinutes = 10;

  // ─────────────────────────────────────────────
  // Validação de pagamentos (Cloudflare Worker)
  // ─────────────────────────────────────────────

  /// URL base do Worker que valida as compras (sem barra final).
  /// Preenchido automaticamente no deploy (scripts/10_deploy_worker.ps1).
  static const String billingWorkerUrl =
      'https://zoeira-car-billing.<SEU_ACCOUNT>.workers.dev';
}
