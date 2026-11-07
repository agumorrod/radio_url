# 📻 Mi Radio Stream

App de radio streaming con podcasts para iOS y Android, construida con Flutter.

### Estructura del proyecto

En GitHub deberías ver algo así (sin carpeta `build/` ni `Pods/`):

```
radio_url/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── core/
│   ├── data/
│   ├── domain/
│   └── presentation/
├── assets/
│   └── images/
│       └── radio_avatar.png
├── .gitignore
├── pubspec.yaml
└── README.md
```

---

## 🚀 Cómo montar el proyecto localmente (para colaboradores)

Estos son los pasos para cualquier persona que clone el repositorio.

### Requisitos previos

Tener instalado en el ordenador:

| Herramienta | Para qué | Descarga |
|---|---|---|
| Flutter SDK | Compilar la app | https://docs.flutter.dev/get-started/install |
| Android Studio | Compilar para Android | https://developer.android.com/studio |
| Xcode (solo Mac) | Compilar para iOS | App Store de Mac |
| Git | Clonar el repositorio | https://git-scm.com |

Verificar que Flutter está bien instalado:
```bash
flutter doctor
```
Todos los ítems relevantes deben aparecer con `[✓]`.

---

### Paso 1: Clonar el repositorio

Te posicionas en la carpeta donde te vas a descargar el código
```bash
cd workspace
```
Clonas el código del repositorio remoto a tu repositorio local
```bash
git clone https://github.com/agumorrod/radio_url.git
```

### Paso 2: Instalar dependencias

```bash
flutter pub get
```

Esto descarga automáticamente todos los paquetes definidos en `pubspec.yaml`
(Riverpod, just_audio, go_router, etc.). Es el equivalente a `mvn install` en Maven.

### Paso 3: Instalar dependencias de iOS (solo Mac)

```bash
cd ios
pod install
cd ..
```

### Paso 4: Ejecutar la app

```bash
# Ver dispositivos disponibles (emuladores o móviles conectados)
flutter devices

# Ejecutar en Android
flutter run -d android

# Ejecutar en iOS (solo Mac)
flutter run -d ios

# Ejecutar en navegador Chrome (para pruebas rápidas)
flutter run -d chrome
```

### Paso 5: Configurar la URL de la radio

Una vez abierta la app, pulsa el icono ⚙️ (ajustes) e introduce
la URL del streaming de tu radio.

---

## 🏗️ Generar APK / IPA para producción

**Android:**
```bash
flutter build apk --release
# El APK estará en: build/app/outputs/flutter-apk/app-release.apk
```

**iOS (requiere Mac con Xcode):**
```bash
flutter build ios --release
```

---

## ⚙️ Personalización

| Qué cambiar | Dónde |
|---|---|
| Nombre de la radio | `lib/presentation/screens/home_screen.dart` |
| Dial (107.7 FM) | `lib/presentation/screens/home_screen.dart` |
| URL por defecto | `lib/domain/providers/app_providers.dart` → `_defaultUrl` |
| Avatar de la radio | `assets/images/radio_avatar.png` |
| Nombre de la app | `android/app/src/main/AndroidManifest.xml` → `android:label` |
| Color acento | `lib/core/constants/app_constants.dart` → `AppColors.primary` |
| Podcasts reales (iVoox) | `lib/domain/providers/app_providers.dart` → `PodcastsNotifier.build()` |

---

## 🛠️ Tecnologías utilizadas

| Paquete | Versión | Para qué sirve |
|---|---|---|
| `flutter_riverpod` | ^3.2.1 | Gestión de estado |
| `go_router` | ^17.1.0 | Navegación |
| `just_audio` | ^0.10.5 | Reproducción de audio |
| `audio_service` | ^0.18.14 | Controles en notificación |
| `dio` | ^5.4.3 | HTTP client |
| `cached_network_image` | ^3.3.1 | Imágenes con caché |
| `shared_preferences` | ^2.2.3 | Almacenamiento local |