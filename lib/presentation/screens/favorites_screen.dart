import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/providers/app_providers.dart';
import '../widgets/station_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───────────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(top: 24, bottom: 6),
                child: Text('Favoritos', style: AppTextStyles.title),
              ),
              const Text(
                'Tus emisoras guardadas',
                style: AppTextStyles.subtitle,
              ),

              const SizedBox(height: 24),

              // ─── Lista de Favoritos ───────────────────────────────────────────
              Expanded(
                child: favoritesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'Error al cargar favoritos\n$error',
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (favorites) {
                    if (favorites.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border,
                                color: AppColors.textHint, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Aún no tienes favoritos',
                              style: AppTextStyles.subtitle,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Marca el corazón en una emisora\npara guardarla aquí',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final station = favorites[index];
                        return StationCard(
                          // En favoritos, el corazón siempre está marcado
                          station: station.copyWith(isFavorite: true),
                          onFavoriteToggle: () {
                            // En favoritos, al pulsar el corazón se elimina
                            ref
                                .read(stationsProvider.notifier)
                                .toggleFavorite(station.id);
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
