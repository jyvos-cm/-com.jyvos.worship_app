import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream état de connexion
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur courant
  User? get currentUser => _auth.currentUser;

  // Connexion email/mot de passe
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
