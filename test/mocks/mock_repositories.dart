import 'dart:async';
import 'package:adotai_app/models/pet_model.dart';
import 'package:adotai_app/models/shelter_model.dart';
import 'package:adotai_app/models/user_profile_model.dart';
import 'package:adotai_app/repositories/interfaces/auth_repository.dart';
import 'package:adotai_app/repositories/interfaces/pet_repository.dart';
import 'package:adotai_app/repositories/interfaces/shelter_repository.dart';
import 'package:adotai_app/repositories/interfaces/user_repository.dart';

/// Implementação em memória de IPetRepository para testes rápidos e isolados (SOLID LSP/DIP).
class MockPetRepository implements IPetRepository {
  final List<PetModel> pets;
  final StreamController<List<PetModel>> _streamController = StreamController<List<PetModel>>.broadcast();

  MockPetRepository([List<PetModel>? initialPets])
      : pets = initialPets != null ? List.from(initialPets) : [];

  void notify() {
    _streamController.add(List.unmodifiable(pets.where((p) => p.isDisponivel)));
  }

  @override
  Stream<List<PetModel>> watchAvailablePets() {
    Future.microtask(() => notify());
    return _streamController.stream;
  }

  @override
  Future<List<PetModel>> getAvailablePets() async {
    return pets.where((p) => p.isDisponivel).toList();
  }

  @override
  Future<PetModel?> getPetById(String id) async {
    try {
      return pets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addPet(PetModel pet) async {
    final toAdd = pet.id.isEmpty ? pet.copyWith(id: 'mock_pet_${pets.length + 1}') : pet;
    pets.add(toAdd);
    notify();
  }

  @override
  Future<void> updatePet(PetModel pet) async {
    final index = pets.indexWhere((p) => p.id == pet.id);
    if (index != -1) {
      pets[index] = pet;
      notify();
    }
  }

  @override
  Future<void> deletePet(String id) async {
    pets.removeWhere((p) => p.id == id);
    notify();
  }

  void dispose() {
    _streamController.close();
  }
}

/// Implementação em memória de IShelterRepository para testes.
class MockShelterRepository implements IShelterRepository {
  final List<ShelterModel> shelters;

  MockShelterRepository([List<ShelterModel>? initial])
      : shelters = initial != null ? List.from(initial) : [];

  @override
  Stream<List<ShelterModel>> watchShelters() => Stream.value(List.unmodifiable(shelters));

  @override
  Future<List<ShelterModel>> getShelters() async => List.unmodifiable(shelters);

  @override
  Future<ShelterModel?> getShelterById(String id) async {
    try {
      return shelters.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addShelter(ShelterModel shelter) async {
    shelters.add(shelter.id.isEmpty ? shelter.copyWith(id: 'mock_shelter_${shelters.length + 1}') : shelter);
  }

  @override
  Future<void> updateShelter(ShelterModel shelter) async {
    final index = shelters.indexWhere((s) => s.id == shelter.id);
    if (index != -1) {
      shelters[index] = shelter;
    }
  }
}

/// Implementação em memória de IUserRepository para testes.
class MockUserRepository implements IUserRepository {
  final Map<String, UserProfileModel> users = {};

  MockUserRepository([Map<String, UserProfileModel>? initial]) {
    if (initial != null) users.addAll(initial);
  }

  @override
  Future<UserProfileModel?> getUserProfile(String uid) async => users[uid];

  @override
  Stream<UserProfileModel?> watchUserProfile(String uid) => Stream.value(users[uid]);

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    users[profile.id] = profile;
  }

  @override
  Future<void> toggleFavorite(String uid, String petId) async {
    final user = users[uid] ?? UserProfileModel(id: uid, name: 'User', email: 'user@test.com');
    final current = List<String>.from(user.favorites);
    if (current.contains(petId)) {
      current.remove(petId);
    } else {
      current.add(petId);
    }
    users[uid] = user.copyWith(favorites: current);
  }

  @override
  Stream<List<String>> watchFavorites(String uid) =>
      Stream.value(users[uid]?.favorites ?? const []);
}

/// Implementação em memória de IAuthRepository para testes.
class MockAuthRepository implements IAuthRepository {
  String? _currentUid;
  String? _currentEmail;

  MockAuthRepository({String? initialUid, String? initialEmail})
      : _currentUid = initialUid,
        _currentEmail = initialEmail;

  @override
  String? get currentUserId => _currentUid;

  @override
  String? get currentUserEmail => _currentEmail;

  @override
  Stream<String?> get authStateChanges => Stream.value(_currentUid);

  @override
  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String userType,
  }) async {
    _currentUid = 'new_uid_123';
    _currentEmail = email;
    return null;
  }

  @override
  Future<String?> loginUser({required String email, required String password}) async {
    if (password == 'wrong') return 'Senha inválida';
    _currentUid = 'logged_uid_123';
    _currentEmail = email;
    return null;
  }

  @override
  Future<void> signOut() async {
    _currentUid = null;
    _currentEmail = null;
  }
}
