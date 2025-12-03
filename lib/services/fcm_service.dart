import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geohunt/services/notificaciones.dart';
import 'database_service.dart';

// Servicio de Mensajería en la Nube (Firebase Cloud Messaging).
//
// Se encarga de la gestión técnica de las Notificaciones Push.
// Su responsabilidad es identificar este dispositivo único en la red de Firebase
// y asegurar que el servidor (o Cloud Functions) tenga una "dirección" a donde enviar alertas.
class FCMService {
  // Instancia Singleton de Firebase Messaging para recibir eventos
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  // Servicio de base de datos para guardar el token
  final DatabaseService _dbService = DatabaseService();

  // Configura el dispositivo para recibir notificaciones.
  //
  // Flujo de ejecución:
  // 1. Solicita permiso al usuario (Obligatorio en iOS y Android 13+).
  // 2. Obtiene el token único del dispositivo (Device Token).
  // 3. Guarda el token en el perfil del usuario en Firestore.
  // 4. Mantiene el token actualizado si el sistema lo cambia.
  Future<void> setupFCMToken(String uid) async {
    // 1. Solicitar Permisos
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // false = Pedir permisos completos inmediatamente
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permiso de notificaciones concedido. Iniciando FCM...');

      // 2. Obtener el Token
      // Este string funciona como la "dirección IP" para notificaciones de este celular.
      String? token = await _fcm.getToken();

      if (token != null) {
        print("FCM Token Obtenido: $token");

        // 3. Guardar el token en Firestore
        // Esto es vital para que el Admin pueda enviar alertas a este usuario específico.
        await _dbService.saveFCMToken(uid, token);

        // 4. Listener de Renovación de Token (Token Rotation)
        // Los tokens no son eternos (cambian si se reinstala la app o se borran datos).
        // Este listener asegura que la BD siempre tenga el token más reciente.
        _fcm.onTokenRefresh.listen((newToken) {
          _dbService.saveFCMToken(uid, newToken);
        });
      }
    } else {
      print('Permiso de notificaciones denegado. Las notificaciones Push no funcionarán.');
    }
  }

  // Manejo de notificaciones en PRIMER PLANO (Foreground).
  //
  // Por diseño, Firebase NO muestra alertas visuales (pop-ups) si la app
  // ya está abierta y en uso.
  // Este metodo intercepta el mensaje entrante y fuerza la creación de una
  // Notificación Local para asegurar que el usuario vea la alerta.
  void initForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Delegamos la visualización al servicio de Notificaciones Locales
      mostrarNotificacion(
        message.notification!.title ?? 'Notificación',
        message.notification!.body ?? 'Hay un tesoro cerca de tu zona.',
        'tesoro',
      );
    });
  }
}