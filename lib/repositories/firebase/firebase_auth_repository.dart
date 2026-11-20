import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/auth_repository.dart';

/// Implementação concreta do IAuthRepository usando Firebase Authentication.
class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get currentUserEmail => _auth.currentUser?.email;

  @override
  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String userType,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'whatsapp': phone.trim(),
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Erro ao cadastrar usuário.';
    } catch (e) {
      return 'Ocorreu um erro inesperado: $e';
    }
  }

  @override
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Erro ao autenticar usuário.';
    } catch (e) {
      return 'Ocorreu um erro inesperado: $e';
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
