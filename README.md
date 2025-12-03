
# 🌍 GeoHunt

> **La plataforma definitiva de exploración y geolocalización.**
> *Conecta el mundo físico con el virtual: esconde tesoros digitales y cázalos usando tecnología GPS de vanguardia y sensores de movimiento.*

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

---

## 🔗 Referencia del Repositorio

[https://github.com/Rofriasbo/geohunt](https://github.com/Rofriasbo/geohunt)

---

## 👑 Credenciales de Acceso (Modo Desarrollo)

Debido a que el **Google Sign-In (llave SHA-1)** puede no estar configurado en entornos locales, puedes usar esta cuenta para acceder a la vista de Administrador de inmediato.

# **SUPER ADMIN: superadmin@geohunt.com**
# **SUPER CONTRASEÑA: 12345678**

---

## 1. Dependencias de Flutter (Dart)

Las librerías requeridas se encuentran en el archivo **`pubspec.yaml`**.

### 1.1 Bloque para Copiar en `pubspec.yaml`

Copia este bloque en la sección `dependencies:` de tu archivo `pubspec.yaml`.

```yaml
  # FIREBASE (Versiones compatibles actualizadas)
  firebase_core: ^3.1.0
  firebase_auth: ^5.1.0
  cloud_firestore: ^5.0.2
  firebase_messaging: ^15.2.10
  firebase_storage: ^12.0.0  # <--- CAMBIO IMPORTANTE (De 11.6.0 a 12.0.0)

    # OTRAS
  google_sign_in: ^6.1.6
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  geolocator: ^10.1.0
  image_picker: ^1.0.7
  permission_handler: ^11.3.0
  sensors_plus: ^5.0.1  # Para detectar el agitado
  flutter_local_notifications: ^19.5.0
  vibration: ^3.1.4
  curved_navigation_bar: ^1.0.6
````

### 1.2 Resumen de Funciones

| Categoría | Librería | Función Principal |
| :--- | :--- | :--- |
| **Firebase** | `firebase_core`, `firebase_auth`, etc. | Servicios de backend (Auth, DB, Storage, FCM). |
| **Localización/Mapa** | `flutter_map`, `geolocator`, `latlong2` | Mapeo, GPS y cálculos de distancia. |
| **Hardware** | `sensors_plus`, `vibration` | Sensores de movimiento y respuesta háptica. |
| **UI/Utilidades** | `image_picker`, `permission_handler` | Gestión de imágenes, permisos e interfaz. |

-----

## 2\. Dependencias de Firebase Functions (Node.js)

Las funciones en la nube (ubicadas en la carpeta `functions/`) utilizan el archivo **`functions/package.json`**.

| Librería | Versión | Función Principal |
| :--- | :--- | :--- |
| `firebase-admin` | `^12.0.0` | SDK de administrador para interactuar con Firestore y Messaging. |
| `firebase-functions` | `^5.0.1` | Módulo para crear funciones en la nube. |
| `geolib` | `^3.3.4` | Cálculos de distancia geocéntrica para notificaciones de cercanía. |

-----

## 3\. Guía de Instalación

Sigue estos pasos en la terminal para instalar todas las dependencias:

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

El archivo modificado para registrar los permisos de la aplicación en Android es:

➡️ **`android/app/src/main/AndroidManifest.xml`**

### 4.1 Bloque para Copiar en `AndroidManifest.xml`

Copia el siguiente bloque y pégalo dentro de la etiqueta raíz `<manifest>` de tu archivo `AndroidManifest.xml`, preferiblemente justo antes de la etiqueta `<application>`.

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

### 4.2 Resumen de Permisos

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
