/// Representa um vídeo do canal Zoeira Car no YouTube
class VideoItemModel {
  final String videoId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final DateTime publishedAt;
  final String? duration; // formato ISO 8601: PT12M34S
  final int? viewCount;
  final int? likeCount;

  const VideoItemModel({
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
    this.duration,
    this.viewCount,
    this.likeCount,
  });

  /// URL de embed para o YouTube Player
  String get embedUrl => 'https://www.youtube.com/watch?v=$videoId';

  /// Thumbnail em alta qualidade
  String get highResThumbnail =>
      'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';

  /// Thumbnail padrão como fallback
  String get standardThumbnail =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  /// Data formatada em português
  String get publishedFormatted {
    final now = DateTime.now();
    final diff = now.difference(publishedAt);

    if (diff.inDays == 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
    if (diff.inDays < 30) return 'Há ${(diff.inDays / 7).floor()} semana(s)';
    if (diff.inDays < 365) return 'Há ${(diff.inDays / 30).floor()} mês(es)';
    return 'Há ${(diff.inDays / 365).floor()} ano(s)';
  }

  /// Visualizações formatadas (ex: 1.2M, 340K)
  String get viewCountFormatted {
    if (viewCount == null) return '';
    if (viewCount! >= 1000000) {
      return '${(viewCount! / 1000000).toStringAsFixed(1)}M views';
    }
    if (viewCount! >= 1000) {
      return '${(viewCount! / 1000).toStringAsFixed(1)}K views';
    }
    return '$viewCount views';
  }

  /// Duração formatada (ex: 12:34)
  String get durationFormatted {
    if (duration == null) return '';
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(duration!);
    if (match == null) return '';

    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Cria a partir do JSON da API do YouTube (search endpoint)
  factory VideoItemModel.fromYouTubeSearchJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>;
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>;
    final thumbUrl = (thumbnails['high']?['url'] ??
        thumbnails['medium']?['url'] ??
        thumbnails['default']?['url'] ??
        '') as String;

    return VideoItemModel(
      videoId: (json['id'] is Map)
          ? json['id']['videoId'] as String
          : json['id'] as String,
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnailUrl: thumbUrl,
      channelTitle: snippet['channelTitle'] ?? 'Zoeira Car',
      publishedAt: DateTime.tryParse(snippet['publishedAt'] ?? '') ??
          DateTime.now(),
    );
  }

  /// Cria a partir do JSON da API do YouTube (videos endpoint — com stats)
  factory VideoItemModel.fromYouTubeVideoJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>;
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>;
    final thumbUrl = (thumbnails['maxres']?['url'] ??
        thumbnails['high']?['url'] ??
        thumbnails['medium']?['url'] ??
        '') as String;

    final stats = json['statistics'] as Map<String, dynamic>?;
    final contentDetails = json['contentDetails'] as Map<String, dynamic>?;

    return VideoItemModel(
      videoId: json['id'] as String,
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnailUrl: thumbUrl,
      channelTitle: snippet['channelTitle'] ?? 'Zoeira Car',
      publishedAt: DateTime.tryParse(snippet['publishedAt'] ?? '') ??
          DateTime.now(),
      duration: contentDetails?['duration'] as String?,
      viewCount: int.tryParse(stats?['viewCount'] ?? '0'),
      likeCount: int.tryParse(stats?['likeCount'] ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video_id': videoId,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'channel_title': channelTitle,
      'published_at': publishedAt.toIso8601String(),
      'duration': duration,
      'view_count': viewCount,
      'like_count': likeCount,
    };
  }
}
