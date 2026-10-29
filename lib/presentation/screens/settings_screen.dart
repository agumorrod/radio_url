import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isExpanded = false; // ← controla si el panel está desplegado

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final urlAsync = ref.read(radioUrlProvider);
      urlAsync.whenData((url) {
        if (url != null) _urlController.text = url;
      });
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Future<void> _saveAndGoBack() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() => _errorMessage = 'Por favor introduce una URL');
      return;
    }

    if (!_isValidUrl(url)) {
      setState(
        () => _errorMessage = 'La URL debe empezar por http:// o https://',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    await ref.read(radioUrlProvider.notifier).saveUrl(url);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL guardada correctamente'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
      context.pop();
    }
  }

  Future<void> _clearUrl() async {
    await ref.read(radioUrlProvider.notifier).saveUrl('');

    if (mounted) {
      final urlAsync = ref.read(radioUrlProvider);
      urlAsync.whenData((url) {
        if (url != null) {
          setState(() {
            _urlController.text = url;
            _errorMessage = null;
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL borrada correctamente'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Top Bar ────────────────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Configuración', style: AppTextStyles.title),
                ],
              ),

              const SizedBox(height: 28),

              // ─── Card de URL colapsable ───────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusLarge,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Cabecera siempre visible (toca para colapsar) ───────
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.all(
                          AppDimensions.cardPadding,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'URL del streaming de radio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 250),
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ─── Contenido colapsable ────────────────────────────────
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.cardPadding,
                          0,
                          AppDimensions.cardPadding,
                          AppDimensions.cardPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Introduce la URL HTTP o HTTPS del streaming de tu radio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Campo de texto
                            TextField(
                              controller: _urlController,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'https://ejemplo.com/stream',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: const Color(0xFFD9D9D9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                errorText: _errorMessage,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (_) {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                            ),

                            const SizedBox(height: 6),

                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('💡 ', style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    'Ejemplo de URL: https://stream.example.com/radio.mp3',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ─── Botones Guardar y Borrar ────────────────────
                            Row(
                              children: [
                                // Botón Guardar URL
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSaving
                                        ? null
                                        : _saveAndGoBack,
                                    icon: _isSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.save_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                    label: Text(
                                      _isSaving
                                          ? 'Guardando...'
                                          : 'Guardar URL',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      disabledBackgroundColor:
                                          AppColors.primaryDark,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Botón Borrar URL
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSaving ? null : _clearUrl,
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Borrar URL',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      disabledBackgroundColor:
                                          Colors.red.shade200,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Panel colapsado: no muestra nada bajo la cabecera
                      secondChild: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
