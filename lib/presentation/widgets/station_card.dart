import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/station_icons.dart';
import '../../data/models/station.dart';
import '../../domain/providers/app_providers.dart';

/// Widget reutilizable para mostrar una emisora en lista
class StationCard extends ConsumerWidget {
  final Station station;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap; // pulsar la tarjeta abre la edición (en Emisoras)

  const StationCard({
    super.key,
    required this.station,
    this.onFavoriteToggle,
    this.onTap,
  });

  Future<void> _onPlayPressed(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(radioPlaybackProvider.notifier).toggleStation(station);
    } catch (_) {
      // Con listas de 200 URLs es normal que alguna esté caída o mal escrita
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo reproducir "${station.name}"'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ¿Es la emisora cargada en Inicio? ¿Y está sonando ahora mismo?
    final isCurrent =
        ref.watch(currentStationIdProvider.select((id) => id.value)) ==
        station.id;
    final isRadioPlaying = ref.watch(radioPlaybackProvider);
    final isThisPlaying = isCurrent && isRadioPlaying;

    return GestureDetector(
      // Los botones de play y favorito tienen su propio onTap y tienen prioridad
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          // Borde verde en la emisora activa para localizarla en la lista
          border: isCurrent
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.6))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icono de la emisora: el elegido a mano o el automático por categoría
              Container(
                width: AppDimensions.avatarSize,
                height: AppDimensions.avatarSize,
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  StationIcons.iconFor(station.iconKey, station.category),
                  color: isCurrent ? AppColors.primary : AppColors.textHint,
                ),
              ),

              const SizedBox(width: 12),

              // Nombre y metadatos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: AppTextStyles.podcastTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Ancho máximo para que una categoría larga no empuje la URL
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Text(
                            station.category,
                            style: AppTextStyles.podcastMeta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                            station.url,
                            style: AppTextStyles.podcastMeta,
                            maxLines: 1,
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
                onTap: () => _onPlayPressed(context, ref),
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
                    color: station.isFavorite
                        ? AppColors.favorite
                        : AppColors.cardLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    station.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
