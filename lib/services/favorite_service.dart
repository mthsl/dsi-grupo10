import '../models/pet_model.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../repositories/interfaces/pet_repository.dart';
import '../repositories/interfaces/user_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firebase_pet_repository.dart';
import '../repositories/firebase/firebase_user_repository.dart';

/// Serviço de Favoritos (GoF Facade / GRASP Indirection).
///
/// Refatorado para respeitar SOLID DIP: depende de interfaces abstratas
/// (IUserRepository, IPetRepository, IAuthRepository) ao invés de
/// acoplamento estático ao Cloud Firestore.
class FavoriteService {
  final IUserRepository _userRepository;
  final IPetRepository _petRepository;
  final IAuthRepository _authRepository;

  FavoriteService({
    IUserRepository? userRepository,
    IPetRepository? petRepository,
    IAuthRepository? authRepository,
  })  : _userRepository = userRepository ?? FirebaseUserRepository(),
        _petRepository = petRepository ?? FirebasePetRepository(),
        _authRepository = authRepository ?? FirebaseAuthRepository();

  Future<void> toggleFavorite(String petId) async {
    final userId = _authRepository.currentUserId;
    if (userId == null) return;
    await _userRepository.toggleFavorite(userId, petId);
  }

  Stream<bool> isFavorite(String petId) {
    final userId = _authRepository.currentUserId;
    if (userId == null) return Stream.value(false);

    return _userRepository.watchFavorites(userId).map(
          (favorites) => favorites.contains(petId),
        );
  }

  /// Retorna a lista de entidades de domínio PetModel dos pets favoritados.
  Stream<List<PetModel>> getFavoritePetModels() {
    final userId = _authRepository.currentUserId;
    if (userId == null) return Stream.value(const []);

    return _userRepository.watchFavorites(userId).asyncMap((favoriteIds) async {
      if (favoriteIds.isEmpty) return const <PetModel>[];

      final List<PetModel> pets = [];
      for (final id in favoriteIds) {
        final pet = await _petRepository.getPetById(id);
        if (pet != null) {
          pets.add(pet);
        }
      }
      return pets;
    });
  }

  /// Mantido para compatibilidade retroativa com telas que leem Map.
  Stream<List<Map<String, dynamic>>> getFavoritePets() {
    return getFavoritePetModels().map(
      (pets) => pets.map((p) => {'id': p.id, ...p.toMap()}).toList(),
    );
  }
}
