import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Instancia global del plugin de notificaciones locales
final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

// Inicializa el sistema de notificaciones locales.
//
// Configura los canales de notificación requeridos por Android 8.0+ (Oreo) en adelante.
// Sin este canal, las notificaciones no se mostrarían en dispositivos modernos.
Future iniciarNotificaciones() async {
  // Configuración para el icono de la barra de estado (@mipmap/ic_launcher)
  const AndroidInitializationSettings AIS = AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings IS = InitializationSettings(
      android: AIS
    // Aquí se añadiría la configuración para iOS (DarwinInitializationSettings) si fuera necesario
  );

  await plugin.initialize(IS);

  // Obtener la implementación específica de Android para crear el canal
  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
  plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    await androidImplementation.requestNotificationsPermission();

    // Creación del Canal de Notificaciones.
    // Importancia MAX hace que la notificación suene y vibre ("Heads-up notification").
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'treasure_alerts',      // ID único del canal
      'Alertas de Tesoros',   // Nombre visible para el usuario en Ajustes
      description: 'Notificaciones cuando aparece un tesoro cerca',
      importance: Importance.max,
      playSound: true,
    );

    await androidImplementation.createNotificationChannel(channel);
  }
}

// Muestra una notificación local personalizada.
//
// Soporta dos modos:
// 1. **Estándar:** Título y cuerpo normales.
// 2. **Cronómetro (Countdown):** Si se pasa [fechaLimite], muestra una cuenta regresiva
//    en la barra de notificaciones del sistema (Android). Ideal para tesoros temporales.
Future mostrarNotificacion(String titulo, String info, String icono, {DateTime? fechaLimite}) async {

  // Lógica para determinar si es una notificación de tiempo límite
  final bool usarCronometro = fechaLimite != null;
  final int? tiempoObjetivo = fechaLimite?.millisecondsSinceEpoch;

  int? tiempoRestante;
  if (fechaLimite != null) {
    // Calculamos si el tiempo ya expiró para no mostrar tiempos negativos
    tiempoRestante = fechaLimite.difference(DateTime.now()).inMilliseconds;
    if (tiempoRestante < 0) tiempoRestante = 0;
  }

  final AndroidNotificationDetails AND = AndroidNotificationDetails(
    'treasure_alerts',
    'Alertas de Tesoros',
    channelDescription: 'Notificaciones de tesoros cercanos',
    importance: Importance.max,
    priority: Priority.high,

    // Configuración visual
    icon: icono, // Debe coincidir con un recurso drawable en la carpeta Android

    // --- CONFIGURACIÓN DE GAMIFICACIÓN (CRONÓMETRO) ---
    // Muestra una cuenta atrás nativa de Android en la notificación.
    usesChronometer: usarCronometro,
    chronometerCountDown: true,
    when: tiempoObjetivo,      // Fecha meta del cronómetro
    timeoutAfter: tiempoRestante, // La notificación se cancela sola si expira el tiempo

    // Configuración de LED (para dispositivos que aún lo tengan)
    enableLights: true,
    color: const Color.fromARGB(255, 255, 0, 0),
    ledColor: const Color.fromARGB(255, 255, 0, 0),
    ledOnMs: 1000,
    ledOffMs: 500,
  );

  final NotificationDetails notificationDetails = NotificationDetails(
    android: AND,
  );

  // show(ID, Título, Cuerpo, Detalles)
  // El ID '1' sobrescribe la notificación anterior. Usar IDs dinámicos si quieres apilarlas.
  await plugin.show(1, titulo, info, notificationDetails);
}