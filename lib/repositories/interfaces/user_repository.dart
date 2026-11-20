import '../../models/user_profile_model.dart';

/// Contrato abstrato para persistência e recuperação de Usuários e Favoritos.
///
/// Atende aos princípios:
/// - SOLID DIP & ISP: Interface focada nas necessidades do usuário.
/// - GRASP Pure Fabrication & Protected Variations.
abstract class IUserRepository {
  /// Obtém o perfil do usuário pelo seu UID.
  Future<UserProfileModel?> getUserProfile(String uid);

  /// Emite fluxo em tempo real de atualizações do perfil.
  Stream<UserProfileModel?> watchUserProfile(String uid);

  /// Salva ou atualiza os dados do perfil no repositório.
  Future<void> saveUserProfile(UserProfileModel profile);

  /// Alterna o estado de favorito de um pet para o usuário.
  Future<void> toggleFavorite(String uid, String petId);

  /// Emite fluxo com a lista de IDs de pets favoritos.
  Stream<List<String>> watchFavorites(String uid);
}
