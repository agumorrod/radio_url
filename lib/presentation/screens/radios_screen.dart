import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/station_icons.dart';
import '../../core/utils/text_utils.dart';
import '../../data/models/station.dart';
import '../../data/services/station_importer.dart';
import '../../domain/providers/app_providers.dart';
import '../widgets/station_card.dart';

InputDecoration _inputDecoration(String label, {String? hint}) {
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

/// Resultado del diálogo cuando el usuario pulsa "Eliminar"
/// (si pulsa "Guardar" el diálogo devuelve la Station editada)
class _DeleteStation {
  const _DeleteStation();
}

class RadiosScreen extends ConsumerStatefulWidget {
  const RadiosScreen({super.key});

  @override
  ConsumerState<RadiosScreen> createState() => _RadiosScreenState();
}

class _RadiosScreenState extends ConsumerState<RadiosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAscending = true; // true = A-Z, false = Z-A

  @override
  void dispose() {
    _searchController.dispose();
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

  // ─── Acciones: añadir / editar / eliminar ───────────────────────────────────

  /// Sin parámetro = emisora nueva. Con una emisora = la edita (o la elimina).
  Future<void> _addOrEditStation([Station? station]) async {
    // Quitamos el foco del buscador para que no reaparezca el teclado al cerrar
    FocusScope.of(context).unfocus();

    final result = await showDialog<Object>(
      context: context,
      builder: (_) =>
          _StationFormDialog(initial: station, categories: _categories()),
    );
    if (result == null || !mounted) return;

    if (result is _DeleteStation && station != null) {
      await _confirmDelete(station);
      return;
    }

    if (result is Station) {
      final notifier = ref.read(stationsProvider.notifier);
      if (station == null) {
        await notifier.add(result);
      } else {
        await notifier.updateStation(result);
      }
    }
  }

  Future<void> _confirmDelete(Station station) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Eliminar emisora',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '¿Eliminar "${station.name}" de la lista?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(stationsProvider.notifier).remove(station.id);
    }
  }

  // ─── Importar / exportar ────────────────────────────────────────────────────

  Future<void> _importStations() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _ImportDialog(),
    );
    if (text == null || text.trim().isEmpty) return;

    final parsed = StationImporter.parse(text);
    final added = await ref.read(stationsProvider.notifier).addMany(parsed);
    if (!mounted) return;

    if (parsed.isEmpty) {
      _showMessage(
        'No se encontró ninguna emisora válida',
        color: Colors.redAccent,
      );
    } else {
      _showMessage(
        '$added emisoras añadidas '
        '(${parsed.length - added} repetidas omitidas)',
      );
    }
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
    final all = stationsAsync.value ?? [];
    final filtered = _applyFilters(all);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _addOrEditStation(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                      onSelected: (value) {
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
              const Text(
                'Tus emisoras de streaming',
                style: AppTextStyles.subtitle,
              ),

              const SizedBox(height: 16),

              // ─── Buscador ────────────────────────────────────────────────────
              TextField(
                controller: _searchController,
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
                      _searchQuery.isEmpty
                          ? '${all.length} emisoras'
                          : '${filtered.length} de ${all.length} emisoras',
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

              // ─── Lista de Emisoras ───────────────────────────────────────────
              Expanded(
                child: stationsAsync.when(
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      // Espacio extra para que el botón + no tape la última emisora
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final station = filtered[index];
                        return StationCard(
                          station: station,
                          onFavoriteToggle: () {
                            ref
                                .read(stationsProvider.notifier)
                                .toggleFavorite(station.id);
                          },
                          // Pulsar la tarjeta abre la ventana de edición
                          onTap: () => _addOrEditStation(station),
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

  /// Selector de icono: "Auto" (sigue a la categoría) + el catálogo completo
  Widget _buildIconPicker() {
    // Lo que se vería con la categoría escrita ahora mismo
    final autoIcon = StationIcons.iconFor(null, _categoryController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Icono',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _IconOption(
              icon: autoIcon,
              label: 'Auto',
              selected: _iconKey == null,
              onTap: () => setState(() => _iconKey = null),
            ),
            for (final entry in StationIcons.catalog.entries)
              _IconOption(
                icon: entry.value,
                selected: _iconKey == entry.key,
                onTap: () => setState(() => _iconKey = entry.key),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(
        isEditing ? 'Editar emisora' : 'Nueva emisora',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
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
              decoration: _inputDecoration(
                'URL del streaming',
                hint: 'https://servidor.com/stream.mp3',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _categoryController,
              style: const TextStyle(color: AppColors.textPrimary),
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('Categoría'),
              // Redibuja para que el icono "Auto" cambie mientras escribes
              onChanged: (_) => setState(() {}),
            ),

            // Atajos con las categorías que ya existen
            if (widget.categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 0,
                children: widget.categories
                    .take(10)
                    .map(
                      (c) => ActionChip(
                        label: Text(
                          c,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: AppColors.cardLight,
                        side: BorderSide.none,
                        onPressed: () =>
                            setState(() => _categoryController.text = c),
                      ),
                    )
                    .toList(),
              ),
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
      ),
      actions: [
        // Eliminar solo aparece al editar (antes se hacía con pulsación larga)
        if (isEditing)
          TextButton(
            onPressed: () => Navigator.of(context).pop(const _DeleteStation()),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Una opción del selector de iconos. Con 'label' se pinta como píldora
/// (la opción "Auto"); sin él, como círculo.
class _IconOption extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  const _IconOption({
    required this.icon,
    required this.selected,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: label == null ? 40 : null,
        padding: label == null
            ? null
            : const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 20),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
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
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text(
        'Importar emisoras',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Una emisora por línea:\nNombre;URL;Categoría\n'
              'También admite listas M3U. Las URL repetidas se omiten.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 8,
              autocorrect: false,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
              decoration: _inputDecoration(
                'Listado',
                hint: 'Mi radio;https://servidor.com/stream.mp3;Música',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste, size: 16),
                label: const Text('Pegar del portapapeles'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: const Text('Importar'),
        ),
      ],
    );
  }
}
