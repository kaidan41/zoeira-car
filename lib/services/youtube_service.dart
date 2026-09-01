import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zoeira_car/models/video_item_model.dart';
import 'package:zoeira_car/utils/app_constants.dart';

class YouTubeService {
  static const String _apiBase = 'https://www.googleapis.com/youtube/v3';

  final http.Client _client;

  YouTubeService({http.Client? client}) : _client = client ?? http.Client();

  /// Busca os vídeos mais recentes do canal via YouTube Data API v3.
  Future<List<VideoItemModel>> fetchLatestVideos({int maxResults = 20}) async {
    final uri = Uri.parse(
      '$_apiBase/search'
      '?part=snippet'
      '&channelId=${AppConstants.youtubeChannelId}'
      '&maxResults=$maxResults'
      '&order=date'
      '&type=video'
      '&key=${AppConstants.youtubeApiKey}',
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw YouTubeServiceException(
        'Erro ao buscar vídeos: ${response.statusCode} — ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    final videos = <VideoItemModel>[];

    for (final item in items) {
      final id      = item['id'] as Map<String, dynamic>?;
      final snippet = item['snippet'] as Map<String, dynamic>?;
      if (id == null || snippet == null) continue;

      final videoId = id['videoId'] as String? ?? '';
      if (videoId.isEmpty) continue;

      final thumbs = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
      final thumb  = (thumbs['high']    as Map<String, dynamic>?)?['url']
                  ?? (thumbs['medium']  as Map<String, dynamic>?)?['url']
                  ?? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

      videos.add(VideoItemModel(
        videoId:      videoId,
        title:        snippet['title']        as String? ?? '',
        description:  snippet['description']  as String? ?? '',
        thumbnailUrl: thumb as String,
        channelTitle: snippet['channelTitle'] as String? ?? 'ZoeiraCar',
        publishedAt:  DateTime.tryParse(
                        snippet['publishedAt'] as String? ?? '',
                      ) ?? DateTime.now(),
        viewCount: null, // search endpoint não retorna views
      ));
    }

    return videos;
  }

  void dispose() => _client.close();
}

class YouTubeServiceException implements Exception {
  final String message;
  const YouTubeServiceException(this.message);

  @override
  String toString() => 'YouTubeServiceException: $message';
}
