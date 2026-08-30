import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:zoeira_car/models/video_item_model.dart';
import 'package:zoeira_car/utils/app_constants.dart';

class YouTubeService {
  static const String _feedUrl =
      'https://www.youtube.com/feeds/videos.xml?channel_id=';

  final http.Client _client;

  YouTubeService({http.Client? client}) : _client = client ?? http.Client();

  /// Busca os vídeos mais recentes do canal Zoeira Car via RSS (sem API key).
  ///
  /// O feed do YouTube retorna no máximo as 15 últimas publicações e inclui:
  /// título, descrição, miniatura, data de publicação e número de views.
  /// Não inclui duração dos vídeos.
  Future<List<VideoItemModel>> fetchLatestVideos({int maxResults = 15}) async {
    final uri = Uri.parse('$_feedUrl${AppConstants.youtubeChannelId}');

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw YouTubeServiceException(
        'Erro ao buscar vídeos: ${response.statusCode}',
      );
    }

    final decoded = utf8.decode(response.bodyBytes);
    final document = XmlDocument.parse(decoded);

    final videos = <VideoItemModel>[];
    final entries = document.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 'entry');

    for (final entry in entries) {
      final videoId = _firstText(entry, 'videoId') ?? '';
      if (videoId.isEmpty) continue;

      final title = _firstText(entry, 'title') ?? '';
      final description = _firstText(entry, 'description') ?? '';
      final channelTitle =
          _firstText(entry, 'name') ?? 'Zoeira Car';

      final thumbnail =
          _first(entry, 'thumbnail')?.getAttribute('url') ?? '';

      final publishedAt =
          DateTime.tryParse(_firstText(entry, 'published') ?? '') ??
              DateTime.now();

      final statsNode = _first(entry, 'statistics');
      final viewCount = int.tryParse(statsNode?.getAttribute('views') ?? '');

      videos.add(VideoItemModel(
        videoId: videoId,
        title: title,
        description: description,
        thumbnailUrl: thumbnail == ''
            ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
            : thumbnail,
        channelTitle: channelTitle,
        publishedAt: publishedAt,
        viewCount: viewCount,
      ));

      if (videos.length >= maxResults) break;
    }

    return videos;
  }

  XmlElement? _first(XmlElement parent, String localName) {
    for (final node in parent.descendants) {
      if (node is XmlElement && node.name.local == localName) return node;
    }
    return null;
  }

  String? _firstText(XmlElement parent, String localName) {
    return _first(parent, localName)?.innerText;
  }

  void dispose() => _client.close();
}

class YouTubeServiceException implements Exception {
  final String message;
  const YouTubeServiceException(this.message);

  @override
  String toString() => 'YouTubeServiceException: $message';
}