import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Botón de la botonera de los diálogos. TODOS los diálogos de la app lo usan,
/// así que tienen siempre el mismo aspecto: solo texto, sin fondo.
///   - AppDialogButton.cancel       → texto gris
///   - AppDialogButton.primary      → texto verde (Guardar, Importar...)
///   - AppDialogButton.destructive  → texto rojo (Eliminar)
///   - AppDialogButton(color: ...)  → cualquier otro color (p. ej. blanco)
class AppDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const AppDialogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.textSecondary,
  });

  const AppDialogButton.cancel({
    super.key,
    required this.onPressed,
    this.label = 'Cancelar',
  }) : color = AppColors.textSecondary;

  const AppDialogButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
  }) : color = AppColors.primary;

  const AppDialogButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
  }) : color = Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

/// Diálogo estándar de la app (centrado en pantalla).
/// Úsalo en lugar de AlertDialog para que todos sean iguales.
class AppDialog extends StatelessWidget {
  final String title;
  final Color titleColor; // p. ej. Colors.redAccent para acciones destructivas
  final Widget content;
  final List<Widget> actions;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.titleColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AppDialogPanel(
          title: title,
          titleColor: titleColor,
          content: content,
          actions: actions,
        ),
      ),
    );
  }
}

/// El aspecto del diálogo (ventana + título a caballo del borde) SIN el
/// posicionamiento. Se separa de AppDialog para poder colocarlo donde haga falta,
/// por ejemplo a la altura de la emisora pulsada.
///
/// El título es una "pestaña" alineada a la izquierda que cabalga sobre el borde
/// superior: la mitad queda fuera de la ventana y la otra mitad dentro.
class AppDialogPanel extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Widget content;
  final List<Widget> actions;

  const AppDialogPanel({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.titleColor = AppColors.primary,
  });

  // Alto de la pestaña del título. Su mitad sobresale por encima de la ventana.
  static const double _titleHeight = 40;

  // Separación entre el borde izquierdo de la ventana y el título
  static const double _titleInset = 16;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ventana: su borde superior queda a media altura del título
        Container(
          margin: const EdgeInsets.only(top: _titleHeight / 2),
          padding: const EdgeInsets.fromLTRB(
            20,
            _titleHeight / 2 + 18, // hueco para la mitad interior del título
            20,
            14,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // El contenido hace scroll si no cabe (teclado abierto, pantallas pequeñas)
              Flexible(child: SingleChildScrollView(child: content)),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 10),
                // Botonera: siempre alineada a la derecha, Cancelar antes que la acción
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  runSpacing: 4,
                  children: actions,
                ),
              ],
            ],
          ),
        ),

        // Título alineado a la izquierda. Con left y right fijos el ancho máximo
        // es el de la ventana, y un título largo se recorta con "..."
        Positioned(
          top: 0,
          left: _titleInset,
          right: _titleInset,
          child: Align(
            alignment: Alignment.centerLeft,
            heightFactor: 1,
            child: Container(
              height: _titleHeight,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: titleColor,
                borderRadius: BorderRadius.circular(_titleHeight / 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
