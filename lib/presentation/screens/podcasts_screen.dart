import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/podcast.dart';
import '../../domain/providers/app_providers.dart';
import '../widgets/podcast_card.dart';

class PodcastsScreen extends ConsumerStatefulWidget {
  const PodcastsScreen({super.key});

  @override
  ConsumerState<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends ConsumerState<PodcastsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortDescending = true; // true = más reciente primero

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Podcast> _applyFilters(List<Podcast> podcasts) {
    var result = podcasts.where((p) {
      final query = _searchQuery.toLowerCase().trim();
      return query.isEmpty || p.title.toLowerCase().contains(query);
    }).toList();

    result.sort(
      (a, b) => _sortDescending
          ? b.pubDate.compareTo(a.pubDate)
          : a.pubDate.compareTo(b.pubDate),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final podcastsAsync = ref.watch(podcastsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ─────────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(top: 24, bottom: 6),
                child: Text('Podcasts', style: AppTextStyles.title),
              ),
              const Text(
                'Descubre nuestros episodios más recientes',
                style: AppTextStyles.subtitle,
              ),

              const SizedBox(height: 16),

              // ─── Buscador ────────────────────────────────────────────────────
              TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar podcast...',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textHint,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadius,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),

              const SizedBox(height: 10),

              // ─── Ordenación ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Ordenar por fecha:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _sortDescending = !_sortDescending),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sortDescending
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _sortDescending ? 'Más reciente' : 'Más antiguo',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ─── Lista de Podcasts ───────────────────────────────────────────
              Expanded(
                child: podcastsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.textHint,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error al cargar podcasts\n$error',
                          style: AppTextStyles.subtitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => ref.invalidate(podcastsProvider),
                          child: const Text(
                            'Reintentar',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  data: (podcasts) {
                    final filtered = _applyFilters(podcasts);

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              color: AppColors.textHint,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No hay resultados para\n"$_searchQuery"'
                                  : 'No hay podcasts disponibles',
                              style: AppTextStyles.subtitle,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final podcast = filtered[index];
                        return PodcastCard(
                          podcast: podcast,
                          onFavoriteToggle: () {
                            ref
                                .read(podcastsProvider.notifier)
                                .toggleFavorite(podcast.id);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
