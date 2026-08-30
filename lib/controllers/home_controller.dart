import 'package:flutter/foundation.dart';
import 'package:zoeira_car/models/video_item_model.dart';
import 'package:zoeira_car/models/vehicle_model.dart';
import 'package:zoeira_car/services/youtube_service.dart';
import 'package:zoeira_car/services/vehicle_service.dart';

enum HomeLoadState { idle, loading, loaded, error }

class HomeController extends ChangeNotifier {
  final YouTubeService _youtubeService;
  final VehicleService _vehicleService;

  HomeController({
    YouTubeService? youtubeService,
    VehicleService? vehicleService,
  })  : _youtubeService = youtubeService ?? YouTubeService(),
        _vehicleService = vehicleService ?? VehicleService();

  // ── Estado dos vídeos ──
  HomeLoadState _videosState = HomeLoadState.idle;
  List<VideoItemModel> _videos = [];
  String? _videosError;

  // ── Estado dos destaques ──
  HomeLoadState _featuredState = HomeLoadState.idle;
  List<VehicleModel> _featuredVehicles = [];

  // ── Vídeo em reprodução ──
  VideoItemModel? _selectedVideo;

  // ── Getters ──
  HomeLoadState get videosState => _videosState;
  List<VideoItemModel> get videos => _videos;
  String? get videosError => _videosError;
  HomeLoadState get featuredState => _featuredState;
  List<VehicleModel> get featuredVehicles => _featuredVehicles;
  VideoItemModel? get selectedVideo => _selectedVideo;

  bool get isLoadingVideos => _videosState == HomeLoadState.loading;
  bool get hasVideosError => _videosState == HomeLoadState.error;

  // ─────────────────────────────────────────────
  // Ações
  // ─────────────────────────────────────────────

  /// Carrega vídeos e destaques em paralelo
  Future<void> loadAll() async {
    await Future.wait([
      loadVideos(),
      loadFeaturedVehicles(),
    ]);
  }

  /// Carrega os vídeos mais recentes do canal
  Future<void> loadVideos() async {
    if (_videosState == HomeLoadState.loading) return;

    _videosState = HomeLoadState.loading;
    _videosError = null;
    notifyListeners();

    try {
      _videos = await _youtubeService.fetchLatestVideos(
        maxResults: 20,
      );
      _videosState = HomeLoadState.loaded;

      // Seleciona o primeiro vídeo automaticamente
      if (_videos.isNotEmpty && _selectedVideo == null) {
        _selectedVideo = _videos.first;
      }
    } catch (e) {
      _videosState = HomeLoadState.error;
      _videosError = e.toString();
    }

    notifyListeners();
  }

  /// Carrega veículos em destaque para o banner
  Future<void> loadFeaturedVehicles() async {
    _featuredState = HomeLoadState.loading;
    notifyListeners();

    try {
      _featuredVehicles = await _vehicleService.getFeaturedVehicles(limit: 6);
      _featuredState = HomeLoadState.loaded;
    } catch (_) {
      _featuredState = HomeLoadState.error;
    }

    notifyListeners();
  }

  /// Define o vídeo em destaque no player
  void selectVideo(VideoItemModel video) {
    _selectedVideo = video;
    notifyListeners();
  }

  /// Recarrega tudo (pull-to-refresh)
  Future<void> refresh() => loadAll();

  @override
  void dispose() {
    _youtubeService.dispose();
    super.dispose();
  }
}
