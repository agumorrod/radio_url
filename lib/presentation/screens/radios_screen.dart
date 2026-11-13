import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/station_icons.dart';
import '../../core/utils/text_utils.dart';
import '../../data/models/station.dart';
import '../../data/services/station_importer.dart';
import '../../domain/providers/app_providers.dart';
import '../widgets/app_dialog.dart';
import '../widgets/station_card.dart';

InputDecoration _inputDecoration(String? label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
    filled: true,
    fillColor: AppColors.cardLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

class RadiosScreen extends ConsumerStatefulWidget {
  const RadiosScreen({super.key});

  @override
  ConsumerState<RadiosScreen> createState() => _RadiosScreenState();
}

class _RadiosScreenState extends ConsumerState<RadiosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  bool _sortAscending = true; // true = A-Z, false = Z-A

  // ─── Botón "+" movible ──────────────────────────────────────────────────────
  // Su posición es una fracción (0 a 1) del espacio libre del listado:
  // (0,0) = esquina superior izquierda, (1,1) = esquina inferior derecha.
  static const double _addButtonSize = 56;
  static const double _addButtonMargin = 8;
  double _addX = 1;
  double _addY = 1;

  // ─── Control del foco del buscador ──────────────────────────────────────────
  // Cuando se cierra un diálogo o un menú, Flutter devuelve el foco al primer
  // campo de texto de la pantalla (el buscador) y aparece el teclado. Para
  // evitarlo, mientras hay una ventana abierta (y unos instantes después) el
  // buscador NO puede recibir foco. Es un contador porque los flujos se encadenan
  // (pulsación larga → Editar → diálogo).
  bool _searchCanFocus = true;
  int _focusLocks = 0;

  void _lockSearchFocus() {
    _focusLocks++;
    _searchFocus.unfocus();
    if (_searchCanFocus) setState(() => _searchCanFocus = false);
  }

  void _unlockSearchFocus() {
    // Esperamos a que acabe la animación de cierre antes de permitir el foco
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _focusLocks = math.max(0, _focusLocks - 1);
      if (_focusLocks == 0) setState(() => _searchCanFocus = true);
    });
  }

  /// Ejecuta algo que abre una ventana protegiendo el foco del buscador
  Future<T> _withoutSearchFocus<T>(Future<T> Function() action) async {
    _lockSearchFocus();
    try {
      return await action();
    } finally {
      _unlockSearchFocus();
    }
  }

  @override
  void initState() {
    super.initState();

    // Posición guardada del botón "+" (si el usuario lo movió alguna vez)
    ref.read(settingsRepositoryProvider).getAddButtonPosition().then((pos) {
      if (pos != null && mounted) {
        setState(() {
          _addX = pos[0];
          _addY = pos[1];
        });
      }
    });

    // Comprobación de emisoras en segundo plano, una vez al arrancar la app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(stationHealthProvider.notifier).startBackgroundCheck(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ─── Filtro y orden ─────────────────────────────────────────────────────────

  List<Station> _applyFilters(List<Station> stations) {
    final query = normalizeText(_searchQuery.trim());

    final result = stations.where((s) {
      if (query.isEmpty) return true;
      // Busca en los 3 campos: nombre, URL y categoría
      return normalizeText(s.name).contains(query) ||
          normalizeText(s.url).contains(query) ||
          normalizeText(s.category).contains(query);
    }).toList();

    result.sort((a, b) {
      final cmp = normalizeText(a.name).compareTo(normalizeText(b.name));
      return _sortAscending ? cmp : -cmp;
    });

    return result;
  }

  /// Categorías ya usadas, para sugerirlas en el formulario
  List<String> _categories() {
    final stations = ref.read(stationsProvider).value ?? [];
    final categories = stations
        .map((s) => s.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    categories.sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
    return categories;
  }

  void _showMessage(String text, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color ?? AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Registro de errores ────────────────────────────────────────────────────

  Future<void> _showErrorLog() async {
    await _withoutSearchFocus(
      () => showDialog<void>(
        context: context,
        builder: (_) => const _ErrorLogDialog(),
      ),
    );
  }

  // ─── Pulsación larga: ventana "¿Qué hacer con...?" ──────────────────────────

  Future<void> _showStationActions(Station station, Rect cardRect) async {
    HapticFeedback.mediumImpact(); // pequeña vibración al detectar la pulsación larga

    // Se muestra como una "ruta" transparente: el botón Atrás y pulsar fuera
    // la cierran sin código extra
    final action = await _withoutSearchFocus(
      () => showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Cerrar',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (ctx, animation, secondaryAnimation) =>
            _StationActionsLayer(station: station, cardRect: cardRect),
        transitionBuilder: (ctx, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    if (!mounted) return;

    if (action == 'edit') {
      await _addOrEditStation(station);
    } else if (action == 'delete') {
      await _confirmDelete(station);
    }
  }

  // ─── Acciones: añadir / editar / eliminar ───────────────────────────────────

  /// Sin parámetro = emisora nueva. Con una emisora = la edita.
  Future<void> _addOrEditStation([Station? station]) async {
    final result = await _withoutSearchFocus(
      () => showDialog<Station>(
        context: context,
        builder: (_) =>
            _StationFormDialog(initial: station, categories: _categories()),
      ),
    );
    if (result == null || !mounted) return;

    final notifier = ref.read(stationsProvider.notifier);
    if (station == null) {
      await notifier.add(result);
    } else {
      await notifier.updateStation(result);
      // Si se ha corregido la URL, se vuelve a considerar disponible hasta
      // que se demuestre lo contrario al reproducirla
      ref.read(unavailableStationsProvider.notifier).markAvailable(result.id);
    }
  }

  Future<void> _confirmDelete(Station station) async {
    final confirmed = await _withoutSearchFocus(
      () => showDialog<bool>(
        context: context,
        builder: (ctx) => AppDialog(
          title: 'Eliminar emisora',
          titleColor:
              Colors.redAccent, // color de aviso para acciones destructivas
          content: Text(
            '¿Eliminar "${station.name}" de la lista?',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            AppDialogButton.cancel(
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            AppDialogButton.destructive(
              label: 'Eliminar',
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await ref.read(stationsProvider.notifier).remove(station.id);
    }
  }

  // ─── Importar / exportar ────────────────────────────────────────────────────

  Future<void> _importStations() async {
    final text = await _withoutSearchFocus(
      () => showDialog<String>(
        context: context,
        builder: (_) => const _ImportDialog(),
      ),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;

    final result = StationImporter.parse(text);
    final log = ref.read(errorLogProvider.notifier);

    // Líneas rechazadas por formato incorrecto → registro de errores
    // (las 15 primeras con detalle, el resto resumidas en una sola entrada)
    const maxDetailed = 15;
    for (final issue in result.issues.take(maxDetailed)) {
      log.addError(
        'Línea ${issue.lineNumber} no añadida: ${issue.reason} '
        '("${_shorten(issue.line)}")',
      );
    }
    if (result.issues.length > maxDetailed) {
      log.addError(
        'Otras ${result.issues.length - maxDetailed} líneas no se añadieron '
        'por tener un formato incorrecto',
      );
    }

    final added = await ref
        .read(stationsProvider.notifier)
        .addMany(result.stations);
    final duplicates = result.stations.length - added.length;

    // Único mensaje de éxito del registro: las emisoras añadidas en la carga
    if (added.isNotEmpty) {
      log.addSuccess(_describeLoad(added, duplicates));
    }
    if (!mounted) return;

    if (added.isEmpty) {
      if (result.issues.isNotEmpty) {
        _showMessage(
          'No se añadió ninguna emisora (mira el registro de errores)',
          color: Colors.redAccent,
        );
      } else if (duplicates > 0) {
        _showMessage('Todas las emisoras ya estaban en la lista');
      } else {
        _showMessage('No se encontró ninguna emisora', color: Colors.redAccent);
      }
    } else {
      final extras = <String>[];
      if (duplicates > 0) {
        extras.add('$duplicates repetidas');
      }
      if (result.issues.isNotEmpty) {
        extras.add('${result.issues.length} con errores');
      }
      _showMessage(
        '${added.length} emisoras añadidas'
        '${extras.isEmpty ? '' : ' (${extras.join(', ')})'}',
      );
    }
  }

  String _shorten(String text) =>
      text.length > 60 ? '${text.substring(0, 57)}...' : text;

  /// "Carga completada: 37 emisoras añadidas (Radio A, Radio B, Radio C y 34 más)"
  String _describeLoad(List<Station> added, int duplicates) {
    final names = added.take(3).map((s) => s.name).join(', ');
    final rest = added.length - 3;
    final namesText = rest > 0 ? '$names y $rest más' : names;
    final dupText = duplicates > 0 ? '. $duplicates repetidas omitidas' : '';
    return 'Carga completada: ${added.length} emisoras añadidas ($namesText)$dupText';
  }

  Future<void> _exportStations() async {
    final stations = ref.read(stationsProvider).value ?? [];
    await Clipboard.setData(
      ClipboardData(text: StationImporter.toText(stations)),
    );
    if (!mounted) return;
    _showMessage('${stations.length} emisoras copiadas al portapapeles');
  }

  // ─── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);
    final isChecking = ref.watch(stationHealthProvider);
    final all = stationsAsync.value ?? [];
    final filtered = _applyFilters(all);

    final countText = _searchQuery.isEmpty
        ? '${all.length} emisoras'
        : '${filtered.length} de ${all.length} emisoras';

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
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Emisoras', style: AppTextStyles.title),
                    PopupMenuButton<String>(
                      color: AppColors.card,
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                      ),
                      // El menú también devuelve el foco al buscador al cerrarse
                      onOpened: _lockSearchFocus,
                      onCanceled: _unlockSearchFocus,
                      onSelected: (value) {
                        _unlockSearchFocus();
                        if (value == 'import') {
                          _importStations();
                        } else {
                          _exportStations();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'import',
                          child: Text(
                            'Importar listado',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'export',
                          child: Text(
                            'Exportar al portapapeles',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Subtítulo a la izquierda y botón del registro de errores a la derecha
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tus emisoras de streaming',
                      style: AppTextStyles.subtitle,
                    ),
                  ),
                  _ErrorLogButton(onPressed: _showErrorLog),
                ],
              ),

              const SizedBox(height: 12),

              // ─── Buscador ────────────────────────────────────────────────────
              TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                canRequestFocus: _searchCanFocus,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, URL o categoría...',
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
                // FIX del cursor "pegado": en móvil Flutter no quita el foco al
                // pulsar fuera del campo, hay que pedirlo explícitamente
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),

              const SizedBox(height: 10),

              // ─── Contador y ordenación por nombre ────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      // Mientras corre la comprobación de arranque se avisa aquí
                      isChecking ? '$countText · comprobando…' : countText,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _sortAscending = !_sortAscending),
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
                          const Icon(
                            Icons.sort_by_alpha,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _sortAscending ? 'Nombre A-Z' : 'Nombre Z-A',
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

              // ─── Lista de Emisoras + botón "+" movible ───────────────────────
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Recorrido máximo del botón dentro del espacio del listado
                    final maxX = math.max(
                      0.0,
                      constraints.maxWidth -
                          _addButtonSize -
                          2 * _addButtonMargin,
                    );
                    final maxY = math.max(
                      0.0,
                      constraints.maxHeight -
                          _addButtonSize -
                          2 * _addButtonMargin,
                    );

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: _buildStationList(
                            stationsAsync,
                            all,
                            filtered,
                          ),
                        ),
                        Positioned(
                          left: _addButtonMargin + _addX * maxX,
                          top: _addButtonMargin + _addY * maxY,
                          child: _DraggableAddButton(
                            size: _addButtonSize,
                            onTap: () => _addOrEditStation(),
                            // Al arrastrar, movemos la fracción sin salirnos del listado
                            onDrag: (delta) => setState(() {
                              if (maxX > 0) {
                                _addX = ((_addX * maxX + delta.dx) / maxX)
                                    .clamp(0.0, 1.0)
                                    .toDouble();
                              }
                              if (maxY > 0) {
                                _addY = ((_addY * maxY + delta.dy) / maxY)
                                    .clamp(0.0, 1.0)
                                    .toDouble();
                              }
                            }),
                            // Al soltar, se guarda para la próxima vez
                            onDragEnd: () => ref
                                .read(settingsRepositoryProvider)
                                .saveAddButtonPosition(_addX, _addY),
                          ),
                        ),
                      ],
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

  Widget _buildStationList(
    AsyncValue<List<Station>> stationsAsync,
    List<Station> all,
    List<Station> filtered,
  ) {
    return stationsAsync.when(
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
              'Error al cargar las emisoras\n$error',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(stationsProvider),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
      data: (_) {
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  all.isEmpty ? Icons.radio : Icons.search_off,
                  color: AppColors.textHint,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  all.isEmpty
                      ? 'Aún no hay emisoras\nPulsa + para añadir una o importa un listado'
                      : 'No hay resultados para\n"$_searchQuery"',
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          // Al arrastrar la lista también se cierra el teclado
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final station = filtered[index];
            return StationCard(
              station: station,
              onFavoriteToggle: () {
                ref.read(stationsProvider.notifier).toggleFavorite(station.id);
              },
              // Pulsación larga: ventana con Editar y Eliminar
              onLongPress: (cardRect) => _showStationActions(station, cardRect),
            );
          },
        );
      },
    );
  }
}

// ─── Botón "+" arrastrable ────────────────────────────────────────────────────

/// Un toque abre el alta de emisora; arrastrarlo lo cambia de sitio
class _DraggableAddButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final void Function(Offset delta) onDrag;
  final VoidCallback onDragEnd;

  const _DraggableAddButton({
    required this.size,
    required this.onTap,
    required this.onDrag,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanStart: (_) => HapticFeedback.selectionClick(),
      onPanUpdate: (details) => onDrag(details.delta),
      onPanEnd: (_) => onDragEnd(),
      child: Material(
        color: AppColors.primary,
        elevation: 6,
        shape: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

// ─── Registro de errores: botón y ventana ─────────────────────────────────────

/// Icono que cambia de color: rojo si hay errores en el registro, gris si no
class _ErrorLogButton extends ConsumerWidget {
  final VoidCallback onPressed;

  const _ErrorLogButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasErrors = ref.watch(
      errorLogProvider.select(
        (entries) => entries.any((e) => e.level == LogLevel.error),
      ),
    );

    return IconButton(
      tooltip: 'Registro de errores',
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(
        Icons.error_outline,
        size: 22,
        color: hasErrors ? Colors.redAccent : AppColors.textHint,
      ),
    );
  }
}

class _ErrorLogDialog extends ConsumerWidget {
  const _ErrorLogDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch: la lista se actualiza sola al quitar entradas o llegar nuevas
    final entries = ref.watch(errorLogProvider);
    final notifier = ref.read(errorLogProvider.notifier);
    final hasErrors = entries.any((e) => e.level == LogLevel.error);

    return AppDialog(
      title: 'Registro de errores',
      titleColor: hasErrors ? Colors.redAccent : AppColors.primary,
      content: entries.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.textHint,
                    size: 36,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No hay errores registrados',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          // Altura máxima: a partir de ahí la lista se desliza en vertical
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                primary: false,
                physics: const ClampingScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _LogEntryTile(
                    entry: entry,
                    onRemove: () => notifier.remove(entry.id),
                  );
                },
              ),
            ),
      actions: [
        AppDialogButton.cancel(
          label: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Deshabilitado cuando no hay nada que limpiar
        AppDialogButton(
          label: 'Limpiar registro',
          color: Colors.redAccent,
          onPressed: entries.isEmpty ? null : notifier.clear,
        ),
      ],
    );
  }
}

/// Una entrada del registro, con su botón X para quitarla individualmente
class _LogEntryTile extends StatelessWidget {
  final LogEntry entry;
  final VoidCallback onRemove;

  const _LogEntryTile({required this.entry, required this.onRemove});

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final isError = entry.level == LogLevel.error;
    final t = entry.time;
    final timeLabel = '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 2, 8),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              size: 18,
              color: isError ? Colors.redAccent : AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar',
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.close, size: 16, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ─── Ventana "¿Qué hacer con...?" (Editar / Eliminar) ─────────────────────────

/// Capa a pantalla completa (atenuada) con una ventana pequeña colocada a la
/// altura de la fila pulsada. Devuelve 'edit' o 'delete' (o null si se cierra
/// tocando fuera o con el botón Atrás).
class _StationActionsLayer extends StatelessWidget {
  final Station station;
  final Rect cardRect;

  const _StationActionsLayer({required this.station, required this.cardRect});

  // Alto aproximado de la ventana (con la mitad exterior del título), para
  // centrarla verticalmente respecto a la fila
  static const double _panelHeight = 116;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final minTop = media.padding.top + 24;
    final maxTop = media.size.height - media.padding.bottom - _panelHeight - 24;
    // La ventana se centra en la fila, pero sin salirse de la pantalla
    final top = (cardRect.center.dy - _panelHeight / 2)
        .clamp(minTop, math.max(minTop, maxTop))
        .toDouble();

    // Material transparente: los botones de texto lo necesitan para su efecto
    // al pulsar, y da el estilo de texto por defecto
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        // Tocar cualquier zona vacía cierra la ventana
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 24,
              right: 24,
              top: top,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  // Este GestureDetector vacío evita que tocar la propia ventana
                  // (fuera de los botones) la cierre
                  child: GestureDetector(
                    onTap: () {},
                    child: AppDialogPanel(
                      title: '¿Qué hacer con ${station.name}?',
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppDialogButton(
                            label: 'Editar',
                            color: Colors.white,
                            onPressed: () => Navigator.of(context).pop('edit'),
                          ),
                          const SizedBox(width: 24),
                          AppDialogButton.destructive(
                            label: 'Eliminar',
                            onPressed: () =>
                                Navigator.of(context).pop('delete'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Diálogo: añadir / editar emisora ─────────────────────────────────────────

class _StationFormDialog extends StatefulWidget {
  final Station? initial; // null = emisora nueva
  final List<String> categories;

  const _StationFormDialog({this.initial, required this.categories});

  @override
  State<_StationFormDialog> createState() => _StationFormDialogState();
}

class _StationFormDialogState extends State<_StationFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _categoryController;
  String? _iconKey; // null = icono automático según la categoría
  bool _iconsExpanded = false; // desplegable de iconos abierto o cerrado
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _urlController = TextEditingController(text: widget.initial?.url ?? '');
    _categoryController = TextEditingController(
      text: widget.initial?.category ?? '',
    );
    _iconKey = widget.initial?.iconKey;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final category = _categoryController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Introduce el nombre de la emisora');
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _error = 'La URL debe empezar por http:// o https://');
      return;
    }

    // Devolvemos la emisora al llamador; conservamos id y favorito al editar
    Navigator.of(context).pop(
      Station(
        id: widget.initial?.id ?? Station.newId(),
        name: name,
        url: url,
        category: category.isEmpty ? 'Sin categoría' : category,
        iconKey: _iconKey,
        isFavorite: widget.initial?.isFavorite ?? false,
      ),
    );
  }

  /// Categorías ya usadas: una sola fila que se desliza en horizontal
  Widget _buildCategoryRow() {
    final current = normalizeText(_categoryController.text.trim());

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in widget.categories)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: Text(
                  category,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
                // La categoría que coincide con lo escrito se resalta
                backgroundColor: normalizeText(category) == current
                    ? AppColors.primary.withValues(alpha: 0.45)
                    : AppColors.cardLight,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    setState(() => _categoryController.text = category),
              ),
            ),
        ],
      ),
    );
  }

  /// Selector de icono en una sola fila (el "desplegable"). Al pulsarla se abre
  /// una rejilla con todos los iconos que se desliza en vertical, y la ventana
  /// crece en altura.
  Widget _buildIconPicker() {
    final selectedIcon = StationIcons.iconFor(
      _iconKey,
      _categoryController.text,
    );
    final selectedLabel = _iconKey == null
        ? 'Automático (según la categoría)'
        : (StationIcons.labelFor(_iconKey) ?? 'Personalizado');

    // Total de celdas: la opción "Automático" + todo el catálogo
    final itemCount = StationIcons.options.length + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Icono',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),

        // Fila-cabecera del desplegable: icono actual + nombre + flecha
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _iconsExpanded = !_iconsExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(selectedIcon, color: Colors.white, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: _iconsExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Zona desplegable: AnimatedSize hace que la ventana crezca suavemente
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _iconsExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height:
                        180, // altura fija: lo que no cabe se desliza en vertical
                    child: GridView.builder(
                      // primary: false evita compartir el scroll con la ventana
                      primary: false,
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 52,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        // La primera celda es "Automático"
                        if (index == 0) {
                          return _IconOption(
                            icon: Icons.auto_awesome,
                            tooltip: 'Automático (según la categoría)',
                            selected: _iconKey == null,
                            onTap: () => setState(() {
                              _iconKey = null;
                              _iconsExpanded = false; // al elegir, se pliega
                            }),
                          );
                        }
                        final option = StationIcons.options[index - 1];
                        return _IconOption(
                          icon: option.icon,
                          tooltip: option.label,
                          selected: _iconKey == option.key,
                          onTap: () => setState(() {
                            _iconKey = option.key;
                            _iconsExpanded = false;
                          }),
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return AppDialog(
      title: isEditing ? 'Editar emisora' : 'Nueva emisora',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration('Nombre de la emisora'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: AppColors.textPrimary),
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration:
                _inputDecoration(
                  'URL del streaming',
                  hint: 'https://servidor.com/stream.mp3',
                ).copyWith(
                  // La X solo aparece cuando hay texto, en gris
                  suffixIcon: _urlController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Borrar URL',
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textHint,
                          ),
                          onPressed: () =>
                              setState(() => _urlController.clear()),
                        ),
                ),
            // Redibuja para mostrar u ocultar la X mientras escribes
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _categoryController,
            style: const TextStyle(color: AppColors.textPrimary),
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration('Categoría'),
            // Redibuja para que el icono automático cambie mientras escribes
            onChanged: (_) => setState(() {}),
          ),

          // Atajos con las categorías que ya existen (una fila deslizable)
          if (widget.categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Categorías usadas',
              style: TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
            const SizedBox(height: 2),
            _buildCategoryRow(),
          ],

          const SizedBox(height: 14),
          _buildIconPicker(),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        AppDialogButton.cancel(onPressed: () => Navigator.of(context).pop()),
        AppDialogButton.primary(label: 'Guardar', onPressed: _submit),
      ],
    );
  }
}

/// Una celda de la rejilla de iconos
class _IconOption extends StatelessWidget {
  final IconData icon;
  final String tooltip; // al mantener pulsado muestra el nombre del icono
  final bool selected;
  final VoidCallback onTap;

  const _IconOption({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.cardLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: selected ? Colors.white : AppColors.textSecondary,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Diálogo: importar listado ────────────────────────────────────────────────

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final TextEditingController _controller = TextEditingController();

  // Explicación del formato: ya no ocupa sitio en la ventana, sale al pulsar el "?"
  static const String _formatHelp =
      'Una emisora por línea:\n'
      'Nombre;URL;Categoría\n\n'
      'También admite listas M3U.\n'
      'Las URL repetidas se omiten.';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null) setState(() => _controller.text = text);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Importar emisoras',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta + icono "?" que muestra el formato al pulsarlo
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pega aquí tu listado',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              Tooltip(
                message: _formatHelp,
                triggerMode: TooltipTriggerMode.tap, // se abre al pulsar
                showDuration: const Duration(seconds: 10),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(12),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.help_outline,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Área de texto con el botón de pegar fijo en su esquina inferior derecha.
          // Si el área crece al escribir, el Stack crece con ella y el icono sigue
          // en la esquina.
          Stack(
            children: [
              TextField(
                controller: _controller,
                minLines: 5,
                maxLines: 8,
                autocorrect: false,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
                decoration:
                    _inputDecoration(
                      null,
                      hint: 'Mi radio;https://servidor.com/stream.mp3;Música',
                    ).copyWith(
                      // Hueco inferior para que el texto no quede debajo del icono
                      contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 44),
                    ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: IconButton(
                  tooltip: 'Pegar del portapapeles',
                  onPressed: _pasteFromClipboard,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.content_paste,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        AppDialogButton.cancel(onPressed: () => Navigator.of(context).pop()),
        AppDialogButton.primary(
          label: 'Importar',
          onPressed: () => Navigator.of(context).pop(_controller.text),
        ),
      ],
    );
  }
}
