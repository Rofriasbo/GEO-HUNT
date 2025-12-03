# 🌍 GeoHunt

> **La plataforma definitiva de exploración y geolocalización.**
> *Conecta el mundo físico con el virtual: esconde tesoros digitales y cázalos usando tecnología GPS de vanguardia y sensores de movimiento.*

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

---

````markdown
# 🌍 Dependencias y Configuración del Proyecto GeoHunt

**Referencia del Repositorio:** [https://github.com/Rofriasbo/geohunt](https://github.com/Rofriasbo/geohunt)

---

## 👑 Credenciales de Acceso (Modo Desarrollo)

Debido a que el **Google Sign-In (llave SHA-1)** puede no estar configurado en entornos locales, puedes usar esta cuenta para acceder a la vista de Administrador de inmediato:

# **SUPER ADMIN: superadmin@geohunt.com**
# **SUPER CONTRASEÑA: 12345678**

---

Este documento detalla todas las librerías de Flutter y las dependencias de Firebase Cloud Functions, junto con los permisos esenciales configurados para el correcto funcionamiento de la aplicación móvil.

## 1. Dependencias de Flutter (Dart)

Las siguientes dependencias se encuentran en el archivo **`pubspec.yaml`**.

| Categoría | Librería | Versión | Función Principal |
| :--- | :--- | :--- | :--- |
| **Backend (Firebase)** | `firebase_core` | `^3.1.0` | Inicialización de los servicios de Firebase. |
| | `firebase_auth` | `^5.1.0` | Manejo de autenticación por email y Google Sign-In. |
| | `cloud_firestore` | `^5.0.2` | Base de datos NoSQL para almacenar tesoros y usuarios. |
| | `firebase_messaging` | `^15.2.10` | Servicio de notificaciones push. |
| | `firebase_storage` | `^12.0.0` | Almacenamiento de imágenes de perfil y pistas de tesoros. |
| | `google_sign_in` | `^6.1.6` | Autenticación con cuentas de Google. |
| **Localización/Mapa** | `flutter_map` | `^6.1.0` | Renderizado del mapa principal (OpenStreetMap). |
| | `geolocator` | `^10.1.0` | Rastreo de la posición GPS del usuario en tiempo real. |
| | `latlong2` | `^0.9.0` | Cálculos de distancia geodésica para la mecánica de juego. |
| **Hardware** | `sensors_plus` | `^5.0.1` | Acceso al acelerómetro para la mecánica "Shake to Claim". |
| | `vibration` | `^3.1.4` | Retroalimentación háptica (vibración) al encontrar un tesoro. |
| **UI/Utilidades** | `image_picker` | `^1.0.7` | Permite al usuario seleccionar imágenes de la galería o cámara. |
| | `permission_handler`| `^11.3.0` | Gestión segura de los permisos del sistema operativo. |
| | `flutter_local_notifications` | `^19.5.0` | Muestra notificaciones locales en la barra de estado. |
| | `curved_navigation_bar` | `^1.0.6` | Estilo personalizado para la barra de navegación inferior. |

---

## 2. Dependencias de Firebase Functions (Node.js)

Las funciones en la nube se encuentran en el directorio `functions` y utilizan el archivo **`functions/package.json`**.

| Librería | Versión | Función Principal |
| :--- | :--- | :--- |
| `firebase-admin` | `^12.0.0` | SDK de administrador para interactuar con Firestore y Messaging. |
| `firebase-functions` | `^5.0.1` | Módulo base para crear y desplegar funciones en la nube. |
| `geolib` | `^3.3.4` | Utilidad para cálculos de distancia geográfica en el backend. |

---

## 3. Guía de Instalación

Sigue estos pasos en la terminal para asegurar que todas las dependencias estén instaladas:

### A. Instalar Dependencias de Flutter

En la **raíz del proyecto local** (la carpeta principal que contiene `lib/` y `pubspec.yaml`):

```bash
flutter pub get
````

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

| Permiso | Descripción y Justificación |
| :--- | :--- |
| `ACCESS_FINE_LOCATION` | **Ubicación GPS precisa** (vital para el geofencing y la detección de tesoros). |
| `ACCESS_COARSE_LOCATION` | Ubicación aproximada (complemento). |
| `POST_NOTIFICATIONS` | Requerido para mostrar notificaciones push y locales en Android 13+. |
| `CAMERA` | Acceso para que los administradores puedan tomar fotos como pistas. |
| `READ_MEDIA_IMAGES` | Permiso moderno de Android para acceder a las imágenes (galería). |
| `READ_EXTERNAL_STORAGE` | Permiso heredado para acceder a la galería (compatibilidad). |

```
```
