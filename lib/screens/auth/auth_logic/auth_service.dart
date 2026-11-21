
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../welcome_screen.dart';
import '../../inventario/inventario_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier { 
  GoRouterRefreshStream(Stream<dynamic> stream) { 
    notifyListeners(); 
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners()); 
  } 

  late final StreamSubscription<dynamic> _subscription; 

  @override 
  void dispose() { 
    _subscription.cancel(); 
    super.dispose(); 
  } 
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
      
      if (e.code == 'weak-password') {
        // Handle weak password - espera al menos 6 caracteres!!
        /*
        esto deberia
          _ tirar una alarma
          _ borrar contraseña
          _ retener usuario para no reescribirlo
        */
        debugPrint('error en auth ${e.code}');
        return null;
      } else 
      
      if (e.code == 'email-already-in-use') {
        // Handle email already registered
        // deberia de enviar un alerta, pero dejar las data de textField como está
        debugPrint('error en auth ${e.code}');
      }
      return null;
    } catch (e) {
      // Catch any other general exceptions
      debugPrint("General error during registration: $e");
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
      if (e.code == 'user-not-found') {
        // Handle no user found
        // enviar alerta, no borrar mail en textField
        debugPrint(e.code);
      } else if (e.code == 'wrong-password') {
        // Handle incorrect password
        // borrar contraseña en el textField
        debugPrint(e.code);
      }
      return null;
    } catch (e) {
      debugPrint("General error during sign-in: $e");
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


// Example of how AuthWrapper might look to manage navigation based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the user stream from AuthService
    return StreamBuilder<User?>(
      stream: AuthService().user, // Listen to authentication state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While waiting for the authentication state to be determined, show a loading spinner
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          // If there is user data, the user is signed in
          //ESTO MUESTRA EL INVENTARIO
          //return const InventarioScreen(); // Navigate to your main app screen
          return const InventarioScreen();
        } else {
          // If there is no user data, the user is signed out
          //return const SignInScreen(); // Navigate to your sign-in screen
          return const WelcomeScreen();
        }
      },
    );
  }
}




