import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/admin_model.dart';
import '../screens/pagina.dart';
import '../screens/admin.dart';

// Botón y Lógica de Inicio de Sesión con Google.
//
// Maneja el flujo OAuth 2.0 con Google y sincroniza la cuenta con Firebase Auth y Firestore.
class GoogleLoginButton extends StatefulWidget {
  const GoogleLoginButton({super.key});

  @override
  State<GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<GoogleLoginButton> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isSigningIn = false;

  // Ejecuta el flujo completo de autenticación federada.
  Future<void> _signInWithGoogle() async {
    setState(() { _isSigningIn = true; });

    try {
      // Forzamos cierre de sesión previo para permitir elegir cuenta nuevamente
      await _googleSignIn.signOut();

      // 1. Inicia el flujo visual de Google (Selección de cuenta)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // El usuario canceló la ventana de Google
        setState(() { _isSigningIn = false; });
        return;
      }

      // 2. Obtener credenciales (Tokens) de la cuenta seleccionada
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Crear credencial compatible con Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase con esa credencial
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 5. Verificar si el usuario ya existe en Firestore (Base de Datos)
        final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        String role = 'user';

        // --- LÓGICA DE PRIMER ACCESO ---
        if (!userDoc.exists) {
          // Si no existe, lo creamos.
          // NOTA: En este flujo, se está asumiendo que el login con Google es para ADMINS.
          // Se crea un perfil AdminModel por defecto.
          AdminModel newAdmin = AdminModel(
            uid: user.uid,
            email: user.email ?? '',
            username: user.displayName ?? 'Admin Google',
            role: 'admin',
            permissions: ['manage_treasures'],
            lastLogin: Timestamp.now(),
          );
          await _firestore.collection('users').doc(user.uid).set(newAdmin.toJson());
          role = 'admin';
        } else {
          // Si ya existe, respetamos su rol actual (sea user o admin)
          final data = userDoc.data() as Map<String, dynamic>;
          role = data['role'] ?? 'user';
        }

        if (mounted) {
          // 6. Redirección basada en Rol (RBAC)
          if (role == 'admin') {
            // Preparar datos para la vista de Admin
            final adminData = (userDoc.exists) ? userDoc.data() as Map<String, dynamic> : {
              'email': user.email,
              'username': user.displayName,
              'role': 'admin'
            };

            AdminModel adminModel = AdminModel.fromMap(adminData, user.uid);

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => AdminScreen(adminUser: adminModel)),
            );
          } else {
            // Preparar datos para la vista de Usuario Regular
            final data = userDoc.data() as Map<String, dynamic>;
            UserModel regularUser = UserModel.fromMap(data, user.uid);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => WelcomeScreen(username: regularUser.username)),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) { setState(() { _isSigningIn = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSigningIn ? null : _signInWithGoogle,
        // Feedback visual de carga
        icon: _isSigningIn
            ?  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            :  Icon(Icons.g_mobiledata, color: Colors.black87, size: 30),
        label: Text(_isSigningIn ? 'Cargando...' : 'Continuar con Google (Admin)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding:  EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}