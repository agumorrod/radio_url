# Repository Guidelines

## Instrucciones para Radio URL

Este proyecto es una aplicación de radio por Internet desarrollada con Flutter y Dart.

Antes de realizar cualquier trabajo:

1. Lee los documentos de `docs/claude/` relevantes para la tarea.
2. Comprueba la arquitectura y el código actual.
3. Identifica los providers, servicios y modelos existentes antes de modificarlos.

Reglas obligatorias:

- Responde en español.
- Respeta la arquitectura y el uso de Riverpod.
- No inventes funcionalidades ni APIs.
- No trabajes directamente sobre la rama `develop`; realiza cada tarea en una rama independiente.
- No hagas `push` ni crees Pull Requests sin autorización expresa.
- No borres ni sobrescribas cambios existentes.
- Ejecuta `flutter analyze` y `flutter test` cuando corresponda.
- Revisa `git diff` antes de finalizar.
- Actualiza la documentación cuando los cambios lo requieran.
- Explica los archivos modificados y las pruebas realizadas.

La prioridad es mantener la estabilidad de la reproducción de audio, el funcionamiento en segundo plano y la compatibilidad con Android.

## Project Structure & Module Organization

This is a Flutter radio streaming app. Application code lives in `lib/`, organized by responsibility: `core/` for shared utilities, routing, theme, and constants; `data/` for models, services, and repositories; `domain/` for providers; and `presentation/` for screens and widgets. Keep new code in the matching layer. Static images and app icons are under `assets/`; platform-specific runners and configuration are in `android/`, `ios/`, `macos/`, `windows/`, `linux/`, and `web/`. Tests belong in `test/` and should mirror the feature or layer they cover.

## Build, Test, and Development Commands

- `flutter pub get` resolves dependencies from `pubspec.yaml`.
- `flutter run -d <device>` launches the app on a connected device or emulator; use `flutter devices` to list targets.
- `dart format lib test` formats Dart source and tests.
- `flutter analyze` runs the configured Flutter lints and static checks.
- `flutter test` runs the test suite.
- `flutter build apk --release` builds an Android release APK; `flutter build ios --release` builds for iOS on macOS with Xcode.

## Coding Style & Naming Conventions

Follow `flutter_lints` as configured in `analysis_options.yaml` and the repository rules in `docs/claude/CODING_RULES.md`. Use standard Dart formatting (two-space indentation), explicit types where useful, `UpperCamelCase` for types, `lowerCamelCase` for members and variables, and `snake_case.dart` filenames. Keep UI in presentation widgets, and put business, persistence, and network logic in the appropriate non-UI layer. Prefer existing dependencies and patterns, including Riverpod providers.

## Testing Guidelines

Tests use `flutter_test` and live under `test/`, with filenames ending in `_test.dart`. Add focused unit or widget tests for behavior changed, and run `flutter test` along with `flutter analyze` before submitting when the Flutter SDK is available. The current `test/widget_test.dart` is a starter smoke test; keep tests aligned with the app's actual UI and behavior.

## Commit & Pull Request Guidelines

Recent commits use short, informal, mostly lowercase summaries, sometimes in Spanish (for example, `corrección del icono y avatar`). Keep commit subjects concise and describe the change directly. Pull requests should explain the user-visible change and implementation, link a related issue when available, list verification commands and results, and include screenshots for UI changes. Call out platform-specific effects or configuration changes.

## Configuration & Platform Notes

Declare Flutter package dependencies in `pubspec.yaml`; avoid committing generated build output. Treat Android, iOS, and desktop runner changes as platform-specific and keep permissions and native configuration limited to what the feature needs. Do not commit secrets or private streaming credentials.
