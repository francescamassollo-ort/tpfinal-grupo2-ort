
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to authentication state changes (User logged in/out)
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Register with Email and Password
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      // Creates a new user account with the provided email and password.
      // On success, returns a UserCredential object containing the newly created user.
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user; // Return the User object
    } on FirebaseAuthException catch (e) {
      // Catch specific Firebase authentication exceptions for better error handling
      debugPrint("FirebaseAuthException during registration: ${e.code} - ${e.message}");
      // You can display a user-friendly message based on e.code
      final message = switch (e.code) {
        'invalid-email' => 'El formato de mail agregado no es correcto.',
        'weak-password' => 'Contraseña no debe ser menor a 6 caracteres!!',
        'email-already-in-use' => 'Éste email ya esta en uso!!',
        _ => 'Error al registrarse (${e.code}).',
      };
      showGlobalErrorSnackBar(message);
      return null;
    } catch (e) {
      // Catch any other general exceptions
      debugPrint("General error during registration: $e");
      showGlobalErrorSnackBar('Ocurrió un error inesperado. Revisá tu conexión.');
      return null;
    }
  }

  // Sign in with Email and Password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Signs in an existing user with email and password.
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
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
      return null;
    } catch (e) {
      debugPrint("General error during sign-in: $e");
      // Sin esto el ingreso fallaba sin decir nada: ahora el aviso sale acá,
      // igual que en el registro.
      showGlobalErrorSnackBar('Ocurrió un error inesperado. Revisá tu conexión.');
      return null;
    }
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
