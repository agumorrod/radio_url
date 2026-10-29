import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/podcast.dart';
import '../../domain/providers/app_providers.dart';

/// Widget reutilizable para mostrar un podcast en lista
class PodcastCard extends ConsumerWidget {
  final Podcast podcast;
  final VoidCallback? onFavoriteToggle;

  const PodcastCard({super.key, required this.podcast, this.onFavoriteToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(podcastPlaybackProvider);
    final isThisPlaying =
        playbackState.currentPodcastId == podcast.id && playbackState.isPlaying;
    final isThisActive = playbackState.currentPodcastId == podcast.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar del podcast
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: podcast.imageUrl,
                    width: AppDimensions.avatarSize,
                    height: AppDimensions.avatarSize,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: AppDimensions.avatarSize,
                      height: AppDimensions.avatarSize,
                      color: AppColors.cardLight,
                      child: const Icon(Icons.mic, color: AppColors.textHint),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: AppDimensions.avatarSize,
                      height: AppDimensions.avatarSize,
                      color: AppColors.cardLight,
                      child: const Icon(Icons.mic, color: AppColors.textHint),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Título y metadatos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        podcast.title,
                        style: AppTextStyles.podcastTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            podcast.duration,
                            style: AppTextStyles.podcastMeta,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              podcast.date,
                              style: AppTextStyles.podcastMeta,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Botón Play / Pausa
                GestureDetector(
                  onTap: () => ref
                      .read(podcastPlaybackProvider.notifier)
                      .togglePodcast(podcast),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isThisPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Botón Favorito
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: podcast.isFavorite
                          ? AppColors.favorite
                          : AppColors.cardLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      podcast.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            // ✅ FIX: La barra aparece en cuanto el podcast está activo,
            // incluso si duration todavía es null (muestra barra en 0)
            if (isThisActive) ...[
              const SizedBox(height: 10),
              _ProgressBar(podcastId: podcast.id),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends ConsumerWidget {
  final String podcastId;

  const _ProgressBar({required this.podcastId});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(podcastPlaybackProvider);
    final position = playbackState.position;
    final duration = playbackState.duration;

    // Si duration es null (aún cargando), mostramos una barra indeterminada
    if (duration == null || duration.inMilliseconds == 0) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const LinearProgressIndicator(
              backgroundColor: AppColors.sliderTrack,
              color: AppColors.primary,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('00:00', style: AppTextStyles.label),
                Text('--:--', style: AppTextStyles.label),
              ],
            ),
          ),
        ],
      );
    }

    final progress = position.inMilliseconds / duration.inMilliseconds;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final newPosition = Duration(
                milliseconds: (value * duration.inMilliseconds).round(),
              );
              ref.read(podcastPlaybackProvider.notifier).seek(newPosition);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position), style: AppTextStyles.label),
              Text(_formatDuration(duration), style: AppTextStyles.label),
            ],
          ),
        ),
      ],
    );
  }
}
