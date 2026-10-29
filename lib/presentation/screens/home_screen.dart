import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioUrlAsync = ref.watch(radioUrlProvider);
    final isPlaying = ref.watch(radioPlaybackProvider);
    final volume = ref.watch(volumeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
          ),
          child: Column(
            children: [
              // ─── Top Bar con botón de Ajustes ───────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),

              // ─── Avatar de la Radio ──────────────────────────────────────────
              Container(
                width: AppDimensions.avatarSizeLarge,
                height: AppDimensions.avatarSizeLarge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusLarge,
                  ),
                  color: AppColors.card,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(green: 0.15),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusLarge,
                  ),
                  child: Image.asset(
                    'assets/images/radio_avatar.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.radio,
                      size: 80,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ─── Nombre y dial ───────────────────────────────────────────────
              const Text('Radio URL', style: AppTextStyles.radioName),
              const SizedBox(height: 6),
              const Text('107.7 FM', style: AppTextStyles.radioDial),

              const SizedBox(height: 36),

              // ─── Botón Play / Pausa ──────────────────────────────────────────
              radioUrlAsync.when(
                loading: () =>
                    const CircularProgressIndicator(color: AppColors.primary),
                error: (_, _) => _PlayButton(isPlaying: false, onTap: () {}),
                data: (url) => _PlayButton(
                  isPlaying: isPlaying,
                  onTap: url != null && url.isNotEmpty
                      ? () =>
                            ref.read(radioPlaybackProvider.notifier).toggle(url)
                      : null,
                ),
              ),

              const Spacer(),

              // ─── Control de Volumen ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppDimensions.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadius,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Volumen',
                          style: AppTextStyles.podcastMeta.copyWith(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${(volume * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: volume,
                      onChanged: (value) {
                        ref.read(volumeProvider.notifier).setVolume(value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── Hint de configuración ───────────────────────────────────────
              // GestureDetector(
              //   onTap: () => context.push('/settings'),
              //   child: RichText(
              //     text: TextSpan(
              //       text: 'Configura la URL de tu radio en ',
              //       style: AppTextStyles.podcastMeta,
              //       children: [
              //         TextSpan(
              //           text: 'Ajustes',
              //           style: AppTextStyles.podcastMeta.copyWith(
              //             color: AppColors.primary,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón Play/Pausa que distingue correctamente 3 estados:
/// 1. Reproduciendo  → icono Pausa
/// 2. Conectando     → spinner (solo durante buffering real, no al pausar)
/// 3. Parado/Pausado → icono Play
class _PlayButton extends ConsumerStatefulWidget {
  final bool isPlaying;
  final VoidCallback? onTap;

  const _PlayButton({required this.isPlaying, required this.onTap});

  @override
  ConsumerState<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends ConsumerState<_PlayButton> {
  // Guardamos el processingState real del player para distinguir
  // "conectando" (loading/buffering) de "pausado" (ready pero !playing)
  ProcessingState _processingState = ProcessingState.idle;

  @override
  void initState() {
    super.initState();
    final audioService = ref.read(audioServiceProvider);

    audioService.playerStateStream.listen((playerState) {
      if (!mounted) return;
      if (_processingState != playerState.processingState) {
        setState(() => _processingState = playerState.processingState);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostramos spinner SOLO si está en loading o buffering Y además
    // el usuario quiere que esté reproduciendo (isPlaying = true).
    // Cuando el usuario pausa: isPlaying = false → nunca mostramos spinner.
    final isBuffering =
        widget.isPlaying &&
        (_processingState == ProcessingState.loading ||
            _processingState == ProcessingState.buffering);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: widget.onTap != null ? AppColors.card : AppColors.cardLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.onTap != null
                ? AppColors.primary.withValues(green: 0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: isBuffering
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(
                widget.isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.onTap != null
                    ? AppColors.textPrimary
                    : AppColors.textHint,
                size: 34,
              ),
      ),
    );
  }
}
