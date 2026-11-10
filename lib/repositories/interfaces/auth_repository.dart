/// Contrato abstrato para Autenticação.
///
/// Atende aos princípios:
/// - SOLID DIP: Permite usar FirebaseAuth em produção e MockAuth em testes.
/// - SOLID ISP: Contrato focado exclusivamente no ciclo de vida de autenticação.
abstract class IAuthRepository {
  /// Retorna o UID do usuário atualmente autenticado, ou null se não houver.
  String? get currentUserId;

  /// Retorna o e-mail do usuário atualmente autenticado.
  String? get currentUserEmail;

  /// Fluxo de mudanças no estado de autenticação (emite UID ou null).
  Stream<String?> get authStateChanges;

  /// Registra um novo usuário. Retorna null em caso de sucesso ou mensagem de erro.
  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String userType,
  });

  /// Realiza login com e-mail e senha. Retorna null em caso de sucesso ou erro.
  Future<String?> loginUser({
    required String email,
    required String password,
  });

  /// Encerra a sessão atual.
  Future<void> signOut();
}
