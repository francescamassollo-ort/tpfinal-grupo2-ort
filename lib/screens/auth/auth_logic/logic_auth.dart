import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      /*
      if (e.code == 'weak-password') {
        // Handle weak password - espera al menos 6 caracteres!!
      } else 
      */
      if (e.code == 'email-already-in-use') {
        // Handle email already registered
        // deberia de enviar un alerta, pero dejar las data de textField como esta
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
      } else if (e.code == 'wrong-password') {
        // Handle incorrect password
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

  // Example: Google Sign-In (requires additional setup for iOS/Android/Web)
  // This is a simplified example, a full implementation involves more steps
  // with google_sign_in package.
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      // Create a new credential
      // final OAuthCredential credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );

      // Sign in to Firebase with the credential
      // UserCredential result = await _auth.signInWithCredential(credential);
      // return result.user;
      debugPrint("Google Sign-In not fully implemented in this snippet, requires google_sign_in package.");
      return null;
    } catch (e) {
      debugPrint("Error with Google Sign-In: $e");
      return null;
    }
  }
}

/*
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // For UI elements like SnackBar

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
      print("FirebaseAuthException during registration: ${e.code} - ${e.message}");
      // You can display a user-friendly message based on e.code
      if (e.code == 'weak-password') {
        // Handle weak password
      } else if (e.code == 'email-already-in-use') {
        // Handle email already registered
      }
      return null;
    } catch (e) {
      // Catch any other general exceptions
      print("General error during registration: $e");
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
      print("FirebaseAuthException during sign-in: ${e.code} - ${e.message}");
      if (e.code == 'user-not-found') {
        // Handle no user found
      } else if (e.code == 'wrong-password') {
        // Handle incorrect password
      }
      return null;
    } catch (e) {
      print("General error during sign-in: $e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Signs out the currently authenticated user.
      await _auth.signOut();
      print("User signed out successfully.");
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // Example: Google Sign-In (requires additional setup for iOS/Android/Web)
  // This is a simplified example, a full implementation involves more steps
  // with google_sign_in package.
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      // Create a new credential
      // final OAuthCredential credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );

      // Sign in to Firebase with the credential
      // UserCredential result = await _auth.signInWithCredential(credential);
      // return result.user;
      print("Google Sign-In not fully implemented in this snippet, requires google_sign_in package.");
      return null;
    } catch (e) {
      print("Error with Google Sign-In: $e");
      return null;
    }
  }
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
          return const HomeScreen(); // Navigate to your main app screen
        } else {
          // If there is no user data, the user is signed out
          return const SignInScreen(); // Navigate to your sign-in screen
        }
      },
    );
  }
}

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            ElevatedButton(
              onPressed: () async {
                User? user = await _auth.signInWithEmailAndPassword(_emailController.text, _passwordController.text);
                if (user != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed In Successfully!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign In Failed.')));
                }
              },
              child: const Text('Sign In'),
            ),
            ElevatedButton(
              onPressed: () async {
                User? user = await _auth.registerWithEmailAndPassword(_emailController.text, _passwordController.text);
                if (user != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered Successfully!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Failed.')));
                }
              },
              child: const Text('Register'),
            ),
            // Add Google Sign-In button here (requires google_sign_in package)
            // ElevatedButton(
            //   onPressed: () async {
            //     User? user = await _auth.signInWithGoogle();
            //     if (user != null) {
            //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed In with Google!')));
            //     } else {
            //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign In Failed.')));
            //     }
            //   },
            //   child: const Text('Sign In with Google'),
            // ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();
    final User? currentUser = FirebaseAuth.instance.currentUser; // Get current user

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${currentUser?.email ?? 'Guest'}!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to other parts of your app
                print('Navigate to profile or settings');
              },
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}


*/