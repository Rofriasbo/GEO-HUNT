
-----

# 🌍 GeoHunt

> **La plataforma definitiva de exploración y geolocalización.**
> *Conecta el mundo físico con el virtual: esconde tesoros digitales y cázalos usando tecnología GPS de vanguardia y sensores de movimiento.*

-----

## 🔗 Referencia del Repositorio

[https://github.com/Rofriasbo/geohunt](https://github.com/Rofriasbo/geohunt)

-----

## 👑 Credenciales de Acceso (Modo Desarrollo)

Debido a que el **Google Sign-In (llave SHA-1)** puede no estar configurado en entornos locales, puedes usar esta cuenta para acceder a la vista de Administrador de inmediato.

# **SUPER ADMIN: superadmin@geohunt.com**

# **SUPER CONTRASEÑA: 12345678**

-----

## 1\. Dependencias de Flutter (Dart)

Las librerías requeridas se encuentran en el archivo **`pubspec.yaml`**.

| Categoría | Librería | Versión (mínima) | Función Principal |
| :--- | :--- | :--- | :--- |
| **Backend (Firebase)** | `firebase_core` | `^3.1.0` | Inicialización de Firebase. |
| | `firebase_auth` | `^5.1.0` | Autenticación de usuarios. |
| | `cloud_firestore` | `^5.0.2` | Base de datos NoSQL. |
| | `firebase_messaging` | `^15.2.10` | Notificaciones Push. |
| | `firebase_storage` | `^12.0.0` | Almacenamiento de archivos (Imágenes). |
| | `google_sign_in` | `^6.1.6` | Autenticación con Google. |
| **Localización/Mapa** | `flutter_map` | `^6.1.0` | Renderizado de mapas OpenStreetMap. |
| | `geolocator` | `^10.1.0` | Rastreo de la posición GPS en tiempo real. |
| | `latlong2` | `^0.9.0` | Utilidad para cálculos de distancia geográfica. |
| **Hardware** | `sensors_plus` | `^5.0.1` | Acceso al acelerómetro (mecánica "Shake to Claim"). |
| | `vibration` | `^3.1.4` | Control de la vibración del dispositivo. |
| **UI/Utilidades** | `image_picker` | `^1.0.7` | Selección de imágenes de galería o cámara. |
| | `permission_handler`| `^11.3.0` | Gestión de permisos. |
| | `flutter_local_notifications` | `^19.5.0` | Muestra notificaciones locales. |
| | `curved_navigation_bar` | `^1.0.6` | Barra de navegación inferior animada. |

-----

## 2\. Dependencias de Firebase Functions (Node.js)

Las funciones en la nube (ubicadas en la carpeta `functions/`) utilizan el archivo **`functions/package.json`**.

| Librería | Versión | Función Principal |
| :--- | :--- | :--- |
| `firebase-admin` | `^12.0.0` | SDK de administrador para interactuar con Firestore y FCM. |
| `firebase-functions` | `^5.0.1` | Módulo para crear funciones en la nube. |
| `geolib` | `^3.3.4` | Cálculos de distancia geocéntrica para notificaciones de cercanía. |

-----

## 3\. Guía de Instalación

Sigue estos pasos para instalar todas las dependencias:

### A. Instalar Dependencias de Flutter

En la **raíz del proyecto local** (la carpeta principal que contiene `lib/` y `pubspec.yaml`):

```bash
flutter pub get
```

### B. Instalar Dependencias de Cloud Functions

Navega al directorio de funciones e instala las dependencias de Node.js:

```bash
cd functions
npm install
```

-----

## 4\. Permisos de Android

El archivo modificado para registrar los permisos de la aplicación es:

➡️ **`android/app/src/main/AndroidManifest.xml`**

| Permiso | Descripción y Justificación |
| :--- | :--- |
| `ACCESS_FINE_LOCATION` | **Ubicación GPS precisa** (esencial para la jugabilidad y geofencing). |
| `ACCESS_COARSE_LOCATION` | Ubicación aproximada (complemento). |
| `POST_NOTIFICATIONS` | Requerido para mostrar notificaciones push y locales en Android 13+. |
| `CAMERA` | Acceso a la cámara (para perfiles y pistas). |
| `READ_MEDIA_IMAGES` | Permiso moderno para acceder a la galería de imágenes. |
| `READ_EXTERNAL_STORAGE` | Permiso heredado para acceder a la galería. |

```
```
