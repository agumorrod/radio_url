import 'package:flutter/material.dart';

/// Colores de la app - Paleta oscura estilo Spotify
class AppColors {
  // Fondos
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color card = Color(0xFF282828);
  static const Color cardLight = Color(0xFF333333);

  // Acento principal - verde
  static const Color primary = Color(0xFF1DB954);
  static const Color primaryDark = Color(0xFF158a3e);

  // Favorito - rojo
  static const Color favorite = Color(0xFFE53935);

  // Textos
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textHint = Color(0xFF727272);

  // Otros
  static const Color divider = Color(0xFF333333);
  static const Color iconInactive = Color(0xFF727272);
  static const Color sliderTrack = Color(0xFF535353);
}

/// Estilos de texto reutilizables
class AppTextStyles {
  static const TextStyle title = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle subtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle radioName = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle radioDial = TextStyle(
    color: AppColors.primary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle podcastTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle podcastMeta = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle navLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}

/// Dimensiones y radios
class AppDimensions {
  static const double borderRadius = 12.0;
  static const double borderRadiusLarge = 20.0;
  static const double cardPadding = 16.0;
  static const double screenPadding = 20.0;
  static const double avatarSize = 56.0;
  static const double avatarSizeLarge = 220.0;
  static const double iconButtonSize = 44.0;
}
