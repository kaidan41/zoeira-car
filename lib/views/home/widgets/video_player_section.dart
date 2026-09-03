import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zoeira_car/models/video_item_model.dart';
import 'package:zoeira_car/theme/app_colors.dart';
import 'package:zoeira_car/widgets/shimmer_box.dart';

class VideoPlayerSection extends StatefulWidget {
  final VideoItemModel? video;
  final bool isLoading;

  const VideoPlayerSection({
    super.key,
    required this.video,
    required this.isLoading,
  });

  @override
  State<VideoPlayerSection> createState() => _VideoPlayerSectionState();
}

class _VideoPlayerSectionState extends State<VideoPlayerSection> {
  WebViewController? _controller;
  String? _currentVideoId;
  bool _pageLoading = false;

  @override
  void didUpdateWidget(VideoPlayerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.video?.videoId != _currentVideoId) {
      _initController();
    }
  }

  @override
  void initState() {
    super.initState();
    _initController();
  }

  /// Carrega o player móvel do YouTube (m.youtube) em vez do embed/iframe,
  /// que apresenta "erro de configuração do player" neste WebView.
  /// Pinça-zoom do WebView fica habilitado pra quem quiser o vídeo ainda maior.
  void _initController() {
    final videoId = widget.video?.videoId;
    if (videoId == null) return;

    _currentVideoId = videoId;

    if (_controller == null) {
      late final PlatformWebViewControllerCreationParams params;
      if (defaultTargetPlatform == TargetPlatform.android) {
        params = const PlatformWebViewControllerCreationParams();
      } else {
        // iOS: usa o padrão (todos os targets)
        params = const PlatformWebViewControllerCreationParams();
      }

      _controller = WebViewController.fromPlatformCreationParams(params)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..enableZoom(true)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _pageLoading = true);
            },
            onProgress: (progress) {
              if (progress > 30) {
                // Injeta antes mesmo da página terminar de carregar
                _controller?.runJavaScript('''
                  (function() {
                    var id = 'zoeira-persistent-hide-style';
                    if (!document.getElementById(id)) {
                      var style = document.createElement('style');
                      style.id = id;
                      style.textContent = `
                        ytm-mobile-topbar-renderer,
                        ytm-header-bar,
                        header,
                        .mobile-topbar-header,
                        .ytm-mobile-topbar-renderer,
                        ytm-pivot-bar-renderer,
                        .pivot-bar,
                        .ytm-open-app-button,
                        .open-app-button,
                        [aria-label*="Abrir"],
                        [aria-label*="Open"],
                        ytm-promoted-sparkles-web-renderer,
                        .banner-image,
                        ytm-companion-ad-renderer {
                          display: none !important;
                          visibility: hidden !important;
                          height: 0 !important;
                          max-height: 0 !important;
                          opacity: 0 !important;
                          pointer-events: none !important;
                          position: absolute !important;
                          top: -9999px !important;
                        }
                        html,
                        body {
                          margin: 0 !important;
                          padding: 0 !important;
                          background: #000 !important;
                        }
                        ytm-player-page,
                        #player,
                        .html5-video-player {
                          width: 100% !important;
                          max-width: 100% !important;
                        }
                        video {
                          object-fit: cover !important;
                        }
                      `;
                      (document.head || document.documentElement).appendChild(style);
                    }
                  })();
                ''');
              }
            },
            onPageFinished: (url) {
              if (mounted) {
                setState(() => _pageLoading = false);
              }
              _controller?.runJavaScript('''
                (function() {
                  var hideIt = function() {
                    var id = 'zoeira-persistent-hide-style';
                    if (!document.getElementById(id)) {
                      var style = document.createElement('style');
                      style.id = id;
                      style.textContent = `
                        ytm-mobile-topbar-renderer,
                        ytm-header-bar,
                        header,
                        .mobile-topbar-header,
                        .ytm-mobile-topbar-renderer,
                        ytm-pivot-bar-renderer,
                        .pivot-bar,
                        .ytm-open-app-button,
                        .open-app-button,
                        [aria-label*="Abrir"],
                        [aria-label*="Open"],
                        ytm-promoted-sparkles-web-renderer,
                        .banner-image,
                        ytm-companion-ad-renderer {
                          display: none !important;
                          visibility: hidden !important;
                          height: 0 !important;
                          max-height: 0 !important;
                          opacity: 0 !important;
                          pointer-events: none !important;
                          position: absolute !important;
                          top: -9999px !important;
                        }
                        html,
                        body {
                          margin: 0 !important;
                          padding: 0 !important;
                          background: #000 !important;
                        }
                        ytm-player-page,
                        #player,
                        .html5-video-player {
                          width: 100% !important;
                          max-width: 100% !important;
                        }
                        video {
                          object-fit: cover !important;
                        }
                      `;
                      (document.head || document.documentElement).appendChild(style);
                    }
                    var topbars = document.querySelectorAll('ytm-mobile-topbar-renderer, ytm-header-bar, header, .mobile-topbar-header, [aria-label*="Abrir app"]');
                    topbars.forEach(function(el) { el.remove(); });
                  };
                  hideIt();
                  setInterval(hideIt, 1000);
                })();
              ''');
            },
            onNavigationRequest: (request) {
              // Bloqueia tentativas de deep link "abrir no app" vindas da própria página do YouTube
              if (request.url.contains('open_app') ||
                  request.url.startsWith('vnd.youtube') ||
                  request.url.startsWith('intent://')) {
                return NavigationDecision.prevent;
              }
              // Mantém dentro do YouTube; links externos abrem no navegador.
              final host = Uri.tryParse(request.url)?.host.toLowerCase() ?? '';
              final isYouTube = host == 'youtube.com' ||
                  host.endsWith('.youtube.com') ||
                  host == 'youtu.be' ||
                  host.endsWith('ytimg.com');
              if (isYouTube) return NavigationDecision.navigate;
              if (request.url.startsWith('http')) {
                launchUrl(Uri.parse(request.url),
                    mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            },
          ),
        );
    }

    _controller!.loadRequest(
      Uri.parse(
        'https://m.youtube.com/watch?v=$videoId&playsinline=1&hl=pt-BR',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const ShimmerBox(
        width: double.infinity,
        height: 220,
      );
    }

    if (_controller == null || widget.video == null) {
      return _buildPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Player: largura total, com espaço pro vídeo 16:9 inteiro + barra do YouTube
        SizedBox(
          height: MediaQuery.sizeOf(context).width * 9 / 16 + 56,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              WebViewWidget(controller: _controller!),
              if (_pageLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Info do vídeo
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.video!.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.video!.viewCountFormatted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.video!.publishedFormatted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 12),

              // Ações nativas: curtir e assistir abrem o vídeo EXATO do
              // ZoeiraCar no app do YouTube (o like dentro do player embutido
              // exige login e pode desviar para canais aleatórios).
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openInYouTubeApp(),
                      icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                      label: const Text('Curtir',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openInYouTubeApp(),
                      icon: const Icon(Icons.play_circle_outline_rounded,
                          size: 16),
                      label: const Text('Assistir no YouTube',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openInYouTubeApp() async {
    final uri = Uri.parse(
      'https://www.youtube.com/watch?v=${widget.video!.videoId}',
    );
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o YouTube.')),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 220,
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline_rounded,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              'Esquentando os pocotós, aguarde...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}