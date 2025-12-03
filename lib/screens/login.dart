import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registro.dart';
import 'pagina.dart';
import 'admin.dart';
import '../models/user.dart';
import '../models/admin_model.dart';
import '../services/registro_google.dart';

// Pantalla de Inicio de Sesión (Login).
//
// Actúa como la puerta de enlace principal ("Gateway") de la aplicación.
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Definición de paleta de colores estática para mantener consistencia visual (Theming)
  static const Color primaryColor = Color(0xFF91B1A8);
  static const Color backgroundColor = Color(0xFF97AAA6);
  static const Color inputBgColor = Color(0xFFE9F3F0);
  static const Color accentColor = Color(0xFF8CB9AC);
  static const Color secondaryColor = Color(0xFF8992D7);

  // Instancias Singleton de Firebase para Auth y Base de Datos
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _navigateToRegister() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) =>  Registro()));
  }

  // Ejecuta el flujo de inicio de sesión asíncrono.
  //
  // Implementa un patrón de validación de dos pasos:
  // 1. **Autenticación (Auth):** Verifica "quién eres" (correo/contraseña).
  // 2. **Autorización (Firestore):** Verifica "qué puedes hacer" (Rol: Admin o User).
  Future<void> _performLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    // Validación básica de campos vacíos en el cliente
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Ingresa correo y contraseña')));
      return;
    }

    try {
      // ---------------------------------------------------------
      // PASO 1: Autenticación con Firebase Auth
      // ---------------------------------------------------------
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // ---------------------------------------------------------
      // PASO 2: Obtener perfil y Rol desde Firestore
      // ---------------------------------------------------------
      // Es necesario consultar la BD porque Auth no guarda datos personalizados como el 'role'.
      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        // Fallback: Si no existe el campo role, se asume 'user' por seguridad (principio de menor privilegio).
        final String role = data['role'] ?? 'user';

        if (mounted) {
          // ---------------------------------------------------------
          // PASO 3: Redirección Condicional (RBAC)
          // ---------------------------------------------------------
          if (role == 'admin') {
            // Flujo ADMINISTRADOR: Se inyecta el modelo AdminModel
            AdminModel admin = AdminModel.fromMap(data, docSnapshot.id);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => AdminScreen(adminUser: admin)),
            );
          } else {
            // Flujo USUARIO ESTÁNDAR: Se inyecta el modelo UserModel
            UserModel user = UserModel.fromMap(data, docSnapshot.id);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => WelcomeScreen(username: user.username)),
            );
          }
        }
      } else {
        // Caso de borde: El usuario está en Auth pero su documento fue borrado de Firestore
        if (mounted) ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error: Usuario sin perfil en base de datos.')));
      }
    } on FirebaseAuthException catch (e) {
      // Manejo específico de errores de Firebase para mejorar la UX
      String msg = 'Error de autenticación';
      if (e.code == 'user-not-found') msg = 'Usuario no encontrado';
      else if (e.code == 'wrong-password') msg = 'Contraseña incorrecta';

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      // Captura de cualquier otro error inesperado (ej. sin internet)
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        // SingleChildScrollView es vital aquí para evitar errores de renderizado
        // cuando aparece el teclado virtual en pantallas pequeñas.
        child: SingleChildScrollView(
          padding:  EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- SECCIÓN DE BRANDING ---
              Container(
                margin:  EdgeInsets.only(bottom: 12),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: accentColor,
                  child: Icon(Icons.explore, color: Colors.white, size: 48),
                ),
              ),
              // Efecto de Gradiente sobre el Texto del Título
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [secondaryColor, primaryColor, accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: Text(
                  'GeoHunt',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Colors.white, // Color base necesario para el ShaderMask
                    shadows: [
                      Shadow(blurRadius: 16.0, color: Colors.black.withOpacity(0.25), offset:  Offset(0, 4)),
                    ],
                  ),
                ),
              ),
               SizedBox(height: 32),

              // --- SECCIÓN DE FORMULARIO ---
              Card(
                color: inputBgColor,
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding:  EdgeInsets.symmetric(horizontal: 18, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Correo',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.email, color: accentColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                       SizedBox(height: 18),
                      TextField(
                        controller: _passwordController,
                        obscureText: true, // Ocultar caracteres para contraseña
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.lock, color: accentColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                       SizedBox(height: 28),

                      // Botón de Login con animación de contenedor
                      AnimatedContainer(
                        duration:  Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: ElevatedButton(
                          onPressed: _performLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding:  EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child:  Text('Iniciar Sesión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                       SizedBox(height: 18),

                      // Integración de Login Social (Google)
                       GoogleLoginButton(),

                       SizedBox(height: 10),
                      TextButton(
                        onPressed: _navigateToRegister,
                        child: Text('¿No tienes cuenta? Regístrate aquí', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: secondaryColor)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}