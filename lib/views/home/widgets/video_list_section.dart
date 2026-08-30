import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zoeira_car/models/video_item_model.dart';
import 'package:zoeira_car/theme/app_colors.dart';
import 'package:zoeira_car/widgets/shimmer_box.dart';
import 'package:zoeira_car/widgets/error_state_widget.dart';

class VideoListSection extends StatelessWidget {
  final List<VideoItemModel> videos;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final String? selectedVideoId;
  final void Function(VideoItemModel) onVideoTap;
  final VoidCallback onRetry;

  const VideoListSection({
    super.key,
    required this.videos,
    required this.isLoading,
    required this.hasError,
    required this.onVideoTap,
    required this.onRetry,
    this.errorMessage,
    this.selectedVideoId,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const _VideoCardShimmer(),
          childCount: 6,
        ),
      );
    }

    if (hasError) {
      return SliverToBoxAdapter(
        child: ErrorStateWidget(
          message: 'Deu BO ao carregar os vídeos 😬',
          detail: errorMessage,
          onRetry: onRetry,
        ),
      );
    }

    if (videos.isEmpty) {
      return const SliverToBoxAdapter(
        child: _EmptyVideosState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _VideoCard(
          video: videos[index],
          isSelected: videos[index].videoId == selectedVideoId,
          onTap: () => onVideoTap(videos[index]),
        ),
        childCount: videos.length,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card individual de vídeo
// ─────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final VideoItemModel video;
  final bool isSelected;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: video.standardThumbnail,
                    width: 130,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ShimmerBox(
                      width: 130,
                      height: 80,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 130,
                      height: 80,
                      color: AppColors.cardBorder,
                      child: const Icon(Icons.play_circle_outline,
                          color: AppColors.textSecondary),
                    ),
                  ),
                  // Duração
                  if (video.durationFormatted.isNotEmpty)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.durationFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Indicador de selecionado
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        color: AppColors.primary.withOpacity(0.25),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.primary,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.publishedFormatted,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (video.viewCountFormatted.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        video.viewCountFormatted,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shimmer placeholder
// ─────────────────────────────────────────────

class _VideoCardShimmer extends StatelessWidget {
  const _VideoCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          ShimmerBox(width: 130, height: 80, borderRadius: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 14, borderRadius: 6),
                const SizedBox(height: 6),
                ShimmerBox(width: 120, height: 12, borderRadius: 6),
                const SizedBox(height: 4),
                ShimmerBox(width: 80, height: 10, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Estado vazio
// ─────────────────────────────────────────────

class _EmptyVideosState extends StatelessWidget {
  const _EmptyVideosState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text('📺', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Nenhum vídeo encontrado por enquanto',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
