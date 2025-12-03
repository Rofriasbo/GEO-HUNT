import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

/// Pantalla de Registro de Usuarios.
///
/// Encargada de crear nuevas cuentas en la plataforma.
/// Implementa el patrón de "Doble Escritura":
/// 1. Crea la credencial de acceso en Firebase Authentication.
/// 2. Crea el documento de perfil en Cloud Firestore.
class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  // Paleta de colores consistente con el diseño general (Theming manual)
  static const Color primaryColor = Color(0xFF91B1A8);
  static const Color backgroundColor = Color(0xFF97AAA6);
  static const Color inputBgColor = Color(0xFFE9F3F0);
  static const Color accentColor = Color(0xFF8CB9AC);
  static const Color secondaryColor = Color(0xFF8992D7);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// Proceso asíncrono de registro.
  /// Maneja la creación de cuenta y la inicialización de datos del usuario en la BD.
  Future<void> _performRegistration() async {
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    // Validación básica de campos vacíos
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor, completa todos los campos.');
      return;
    }

    try {
      // ---------------------------------------------------------
      // PASO 1: Crear usuario en Auth (Credenciales)
      // ---------------------------------------------------------
      // Esto genera el UID único que usaremos como llave en la base de datos.
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ---------------------------------------------------------
      // PASO 2: Preparar el Modelo de Usuario (Datos de Perfil)
      // ---------------------------------------------------------
      // Por seguridad, todo registro nuevo desde la app es rol 'user'.
      // Los admins deben crearse manualmente o mediante otro flujo.
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid, // Enlazamos Auth con Firestore usando el mismo ID
        email: email,
        username: username,
        role: 'user',
      );

      // ---------------------------------------------------------
      // PASO 3: Guardar en Firestore (Persistencia)
      // ---------------------------------------------------------
      await _firestore
          .collection('users')
          .doc(newUser.uid) // Usamos .set() con el UID específico para facilitar búsquedas futuras
          .set(newUser.toJson());

      _showSnackBar('Registro exitoso. Bienvenido!');

      // Cierra la pantalla de registro y vuelve al Login
      if (mounted) {
        Navigator.of(context).pop();
      }

    } on FirebaseAuthException catch (e) {
      // Manejo de errores específicos de Firebase para mejor UX
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'La contraseña es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Ya existe una cuenta con este correo.';
      } else {
        errorMessage = 'Error de registro: ${e.message}';
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('Ocurrió un error inesperado: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title:  Text('Crear Cuenta', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        leading: IconButton(
          icon:  Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding:  EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Título y Branding
               Text(
                '¡Únete a la Aventura!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
               SizedBox(height: 30),

              // Campo de Nombre de Usuario
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de Usuario',
                  labelStyle:  TextStyle(color: primaryColor),
                  filled: true,
                  fillColor: inputBgColor,
                  prefixIcon:  Icon(Icons.person, color: accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
               SizedBox(height: 20),

              // Campo de Correo Electrónico
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  labelStyle:  TextStyle(color: primaryColor),
                  filled: true,
                  fillColor: inputBgColor,
                  prefixIcon:  Icon(Icons.email, color: accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
               SizedBox(height: 20),

              // Campo de Contraseña
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle:  TextStyle(color: primaryColor),
                  filled: true,
                  fillColor: inputBgColor,
                  prefixIcon:  Icon(Icons.lock, color: accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Botón de Acción Principal
              ElevatedButton(
                onPressed: _performRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                child:  Text(
                  'Registrarse',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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