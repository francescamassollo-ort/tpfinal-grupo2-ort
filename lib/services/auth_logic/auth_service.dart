import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// 1. Global key accessible from anywhere in your app
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// 2. Helper function to show an error SnackBar without needing BuildContext
void showGlobalErrorSnackBar(String message) {
  rootScaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar() // Dismisses any active SnackBar so they don't queue up
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

class AuthService {
  // Se pide cuando se usa y no al crear el servicio: el menú lateral crea uno
  // apenas se dibuja, y así se puede dibujar (y probar) sin Firebase iniciado.
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Stream to listen to authentication state changes (User logged in/out)
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  /// El mail de la cuenta con la sesión iniciada, o null si no hay sesión.
  String? get emailActual => _auth.currentUser?.email;

  // Register with Email and Password. Devuelve true si se creó la cuenta; si no,
  // el motivo ya se mostró en un cartel.
  Future<bool> registerWithEmailAndPassword(String email, String password) async {
    try {
      // Creates a new user account with the provided email and password.
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      // Catch specific Firebase authentication exceptions for better error handling
      debugPrint("FirebaseAuthException during registration: ${e.code} - ${e.message}");
      // You can display a user-friendly message based on e.code
      final message = switch (e.code) {
        'invalid-email' => 'El formato de mail agregado no es correcto.',
        'weak-password' => 'La contraseña es demasiado débil: no cumple las reglas de seguridad.',
        'email-already-in-use' => 'Éste email ya esta en uso!!',
        _ => 'Error al registrarse (${e.code}).',
      };
      showGlobalErrorSnackBar(message);
      return false;
    } catch (e) {
      // Catch any other general exceptions
      debugPrint("General error during registration: $e");
      showGlobalErrorSnackBar('Ocurrió un error inesperado. Revisá tu conexión.');
      return false;
    }
  }

  // Sign in with Email and Password. Devuelve true si se inició sesión; si no,
  // el motivo ya se mostró en un cartel.
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Signs in an existing user with email and password.
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException during sign-in: ${e.code} - ${e.message}");
      final message = switch (e.code) {
        'user-not-found' || 'invalid-credential' => 'Correo o contraseña incorrectos.',
        'wrong-password' => 'Contraseña incorrecta.',
        'invalid-email' => 'El formato del correo no es válido.',
        'user-disabled' => 'Esta cuenta ha sido deshabilitada.',
        'too-many-requests' => 'Demasiados intentos. Intentá más tarde.',
        _ => 'Error al iniciar sesión (${e.code}).',
      };
      showGlobalErrorSnackBar(message);
      return false;
    } catch (e) {
      debugPrint("General error during sign-in: $e");
      // Sin esto el ingreso fallaba sin decir nada: ahora el aviso sale acá,
      // igual que en el registro.
      showGlobalErrorSnackBar('Ocurrió un error inesperado. Revisá tu conexión.');
      return false;
    }
  }

  /// Manda a [email] un correo para elegir una contraseña nueva. Devuelve true
  /// si se pidió bien. Si no hay ninguna cuenta con ese mail también devuelve
  /// true y no avisa: así no se revela qué mails están registrados.
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException during password reset: ${e.code} - ${e.message}");
      if (e.code == 'user-not-found') return true;
      final message = switch (e.code) {
        'invalid-email' => 'El formato del correo no es válido.',
        'too-many-requests' => 'Demasiados intentos. Intentá más tarde.',
        _ => 'No se pudo enviar el correo (${e.code}).',
      };
      showGlobalErrorSnackBar(message);
      return false;
    } catch (e) {
      debugPrint("General error during password reset: $e");
      showGlobalErrorSnackBar('Ocurrió un error inesperado. Revisá tu conexión.');
      return false;
    }
  }

  /// Manda al mail de la cuenta con la sesión iniciada el correo para verificar
  /// que es suyo. Devuelve true si se mandó.
  Future<bool> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException during email verification: ${e.code} - ${e.message}");
      final message = switch (e.code) {
        'too-many-requests' => 'Demasiados intentos. Esperá unos minutos y probá de nuevo.',
        _ => 'No se pudo enviar el correo (${e.code}).',
      };
      showGlobalErrorSnackBar(message);
      return false;
    } catch (e) {
      debugPrint("General error during email verification: $e");
      showGlobalErrorSnackBar('Ocurrió un error inesperado. Revisá tu conexión.');
      return false;
    }
  }

  /// Vuelve a pedirle a Firebase los datos de la cuenta y dice si el mail ya
  /// está verificado. Hace falta porque la app no se entera sola de que la
  /// persona tocó el enlace del correo.
  Future<bool> mailVerificado() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      debugPrint("Error reloading user: $e");
      showGlobalErrorSnackBar('No se pudo comprobar. Revisá tu conexión.');
      return false;
    }
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Signs out the currently authenticated user.
      await _auth.signOut();
      debugPrint("User signed out successfully.");
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  // aca iria autenticacion con ****** si se pide >.>
}
