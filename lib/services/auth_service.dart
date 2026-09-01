import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método de Cadastro
  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String userType, // 'Adotante' ou 'Voluntário'
  }) async {
    try {
      // 1. Cria o usuário no Firebase Authentication
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Salva os dados do perfil e a distinção do tipo de usuário no Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // Retorna null em caso de sucesso
    } on FirebaseAuthException catch (e) {
      return e.message; // Retorna mensagem de erro se falhar
    } catch (e) {
      return "An unknown error occurred.";
    }
  }

  // Método de Login
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}