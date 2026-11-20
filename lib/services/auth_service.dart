import '../repositories/interfaces/auth_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';

/// Fachada de Autenticação (GoF Facade / GRASP Indirection).
///
/// Refatorado para respeitar SOLID DIP: depende de IAuthRepository
/// em vez de criar dependência rígida ao FirebaseAuth nativo.
class AuthService {
  final IAuthRepository _authRepository;

  AuthService({IAuthRepository? authRepository})
      : _authRepository = authRepository ?? FirebaseAuthRepository();

  String? get currentUserId => _authRepository.currentUserId;
  String? get currentUserEmail => _authRepository.currentUserEmail;

  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String userType,
  }) {
    return _authRepository.registerUser(
      name: name,
      email: email,
      password: password,
      phone: phone,
      userType: userType,
    );
  }

  Future<String?> loginUser({
    required String email,
    required String password,
  }) {
    return _authRepository.loginUser(email: email, password: password);
  }

  Future<void> signOut() {
    return _authRepository.signOut();
  }
}
