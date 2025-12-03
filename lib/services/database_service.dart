import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/admin_model.dart';
import '../models/tesoro.dart';

// Servicio de Base de Datos (Pattern DAO / Repository).
//
// Centraliza todas las operaciones CRUD (Crear, Leer, Actualizar, Borrar)
// e interacciones con Firebase Firestore. Esto permite desacoplar la lógica
// de acceso a datos de la interfaz de usuario (UI).
class DatabaseService {
  // Instancia Singleton de Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Nombres de colecciones constantes para evitar errores de tipeo ('magic strings')
  final String _userCollection = 'users';
  final String _treasureCollection = 'treasures';

  // ===========================================================================
  // SECCIÓN: GESTIÓN DE USUARIOS
  // ===========================================================================

  // Crea un nuevo documento de usuario en la colección 'users'.
  // Se utiliza el [uid] de autenticación como ID del documento para facilitar búsquedas.
  Future<void> createUser(UserModel user) async {
    await _db.collection(_userCollection).doc(user.uid).set(user.toJson());
  }

  // Actualiza campos específicos de un usuario sin sobrescribir todo el documento.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection(_userCollection).doc(uid).update(data);
    } catch (e) {
      // Se recomienda implementar un logger o manejo de errores aquí
      print("Error actualizando usuario: $e");
    }
  }

  // Guarda el token de notificaciones (FCM) del dispositivo.
  // Usa [SetOptions(merge: true)] para crear el campo si no existe,
  // o actualizarlo sin borrar el resto de datos del usuario.
  Future<void> saveFCMToken(String uid, String? token) async {
    if (token != null) {
      await _db.collection(_userCollection).doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  // Crea o actualiza un perfil de Administrador.
  Future<void> createOrUpdateAdmin(AdminModel admin) async {
    await _db.collection(_userCollection).doc(admin.uid).set(admin.toJson(), SetOptions(merge: true));
  }

  // Obtiene una "foto instantánea" (Snapshot) de un usuario.
  // Útil para verificar roles (Admin vs User) durante el Login.
  Future<DocumentSnapshot?> getUserSnapshot(String uid) async {
    try {
      return await _db.collection(_userCollection).doc(uid).get();
    } catch (e) {
      return null;
    }
  }

  // ===========================================================================
  // SECCIÓN: GESTIÓN DE TESOROS
  // ===========================================================================

  // Crea un nuevo tesoro en la base de datos.
  // Firestore genera automáticamente un ID único para el documento.
  // Retorna el [id] del documento creado.
  Future<String?> createTreasure(TreasureModel treasure) async {
    try {
      // .doc() sin argumentos genera un ID automático
      final docRef = _db.collection(_treasureCollection).doc();
      await docRef.set(treasure.toJson());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Flujo de datos en tiempo real (Stream) de todos los tesoros.
  // Si un tesoro se agrega, elimina o edita en la consola, la app
  // lo reflejará instantáneamente sin necesidad de recargar.
  Stream<List<TreasureModel>> getTreasures() {
    return _db.collection(_treasureCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Convierte cada documento JSON a un objeto TreasureModel
        return TreasureModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Actualiza la información de un tesoro existente.
  Future<void> updateTreasure(String treasureId, Map<String, dynamic> data) async {
    await _db.collection(_treasureCollection).doc(treasureId).update(data);
  }

  // Elimina físicamente un tesoro de la base de datos.
  Future<void> deleteTreasure(String treasureId) async {
    await _db.collection(_treasureCollection).doc(treasureId).delete();
  }

  // Registra que un usuario ha encontrado un tesoro.
  // Utiliza [FieldValue.arrayUnion] que es una OPERACIÓN ATÓMICA:
  // Garantiza que el ID se agregue al array solo si no existe ya,
  // evitando duplicados y condiciones de carrera.
  Future<void> markTreasureAsFound(String userUid, String treasureId) async {
    final userRef = _db.collection(_userCollection).doc(userUid);
    await userRef.update({
      'foundTreasures': FieldValue.arrayUnion([treasureId]),
    });
  }
}