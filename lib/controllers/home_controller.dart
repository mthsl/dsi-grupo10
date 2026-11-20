import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pet_model.dart';
import '../models/shelter_model.dart';
import '../models/user_profile_model.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../repositories/interfaces/pet_repository.dart';
import '../repositories/interfaces/shelter_repository.dart';
import '../repositories/interfaces/user_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firebase_pet_repository.dart';
import '../repositories/firebase/firebase_shelter_repository.dart';
import '../repositories/firebase/firebase_user_repository.dart';
import '../strategies/pet_filter_strategy.dart';

/// Controlador da tela principal (GRASP Controller / SRP / Observer).
class HomeController extends ChangeNotifier {
  final IPetRepository _petRepository;
  final IUserRepository _userRepository;
  final IAuthRepository _authRepository;
  final IShelterRepository _shelterRepository;

  StreamSubscription<List<PetModel>>? _petsSubscription;

  List<PetModel> _allPets = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Critérios de filtro selecionados pelo usuário
  String _searchQuery = '';
  String? _selectedSpecies;
  String? _selectedSize;
  String? _selectedGender;
  String? _selectedAge;

  // Filtro exclusivo de voluntário: "Seus Animais"
  bool _showOnlyMyPets = false;
  String? _selectedMyShelterId;
  List<ShelterModel> _userShelters = [];

  UserProfileModel? _currentUserProfile;

  HomeController({
    IPetRepository? petRepository,
    IUserRepository? userRepository,
    IAuthRepository? authRepository,
    IShelterRepository? shelterRepository,
  })  : _petRepository = petRepository ?? FirebasePetRepository(),
        _userRepository = userRepository ?? FirebaseUserRepository(),
        _authRepository = authRepository ?? FirebaseAuthRepository(),
        _shelterRepository = shelterRepository ?? FirebaseShelterRepository();

  // Getters de estado
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedSpecies => _selectedSpecies;
  String? get selectedSize => _selectedSize;
  String? get selectedGender => _selectedGender;
  String? get selectedAge => _selectedAge;

  bool get showOnlyMyPets => _showOnlyMyPets;
  String? get selectedMyShelterId => _selectedMyShelterId;
  List<ShelterModel> get userShelters => _userShelters;

  bool get isVolunteer => _currentUserProfile?.isVolunteer ?? false;
  String get currentUserId => _authRepository.currentUserId ?? '';

  /// Retorna lista de pets filtrados através do pipeline funcional puro.
  List<PetModel> get filteredPets {
    final List<IPetFilterStrategy> strategies = [
      const StatusFilterStrategy('Disponível'),
      if (_searchQuery.trim().isNotEmpty)
        SearchQueryFilterStrategy(_searchQuery),
      if (_showOnlyMyPets && currentUserId.isNotEmpty)
        VolunteerFilterStrategy(currentUserId),
      if (_selectedMyShelterId != null && _selectedMyShelterId!.isNotEmpty)
        ShelterFilterStrategy(_selectedMyShelterId!, _getMyShelterName(_selectedMyShelterId!)),
      if (_selectedSpecies != null && _selectedSpecies!.isNotEmpty)
        SpeciesFilterStrategy(_selectedSpecies!),
      if (_selectedSize != null && _selectedSize!.isNotEmpty)
        SizeFilterStrategy(_selectedSize!),
      if (_selectedGender != null && _selectedGender!.isNotEmpty)
        GenderFilterStrategy(_selectedGender!),
      if (_selectedAge != null && _selectedAge!.isNotEmpty)
        AgeFilterStrategy(_selectedAge!),
    ];

    return filterPets(_allPets, strategies);
  }

  String _getMyShelterName(String shelterId) {
    try {
      return _userShelters.firstWhere((s) => s.id == shelterId).nome;
    } catch (_) {
      return 'Abrigo';
    }
  }

  /// Retorna lista de filtros ativos para exibição de chips.
  List<MapEntry<String, String>> get activeFilters {
    final list = <MapEntry<String, String>>[];
    if (_showOnlyMyPets) list.add(const MapEntry('my_pets', 'Meus Cadastros'));
    if (_selectedMyShelterId != null) {
      list.add(MapEntry('my_shelter', 'Abrigo: ${_getMyShelterName(_selectedMyShelterId!)}'));
    }
    if (_selectedSpecies != null) list.add(MapEntry('species', _selectedSpecies!));
    if (_selectedSize != null) list.add(MapEntry('size', _selectedSize!));
    if (_selectedGender != null) list.add(MapEntry('gender', _selectedGender!));
    if (_selectedAge != null) list.add(MapEntry('age', _selectedAge!));
    return list;
  }

  /// Inicializa o controlador carregando o perfil e escutando pets em tempo real.
  void init() {
    _loadUserProfile();
    _subscribeToPets();
  }

  Future<void> _loadUserProfile() async {
    final uid = _authRepository.currentUserId;
    if (uid != null && uid.isNotEmpty) {
      _currentUserProfile = await _userRepository.getUserProfile(uid);
      if (_currentUserProfile?.isVolunteer == true) {
        _userShelters = await _shelterRepository.getSheltersByCreator(uid);
      }
      notifyListeners();
    }
  }

  /// Recarrega os abrigos do voluntário (ex.: após cadastrar um novo abrigo),
  /// mantendo o filtro "Seus Animais" sempre atualizado.
  Future<void> refreshUserShelters() async {
    final uid = _authRepository.currentUserId;
    if (uid == null || uid.isEmpty) return;

    _currentUserProfile ??= await _userRepository.getUserProfile(uid);
    if (_currentUserProfile?.isVolunteer != true) return;

    _userShelters = await _shelterRepository.getSheltersByCreator(uid);
    notifyListeners();
  }

  void _subscribeToPets() {
    _isLoading = true;
    notifyListeners();

    _petsSubscription?.cancel();
    _petsSubscription = _petRepository.watchAvailablePets().listen(
      (pets) {
        _allPets = pets;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar lista de pets: $error';
        notifyListeners();
      },
    );
  }

  /// Atualiza o texto da pesquisa.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Filtro "Seus Animais": define se exibe apenas pets criados pelo voluntário
  void setShowOnlyMyPets(bool value) {
    _showOnlyMyPets = value;
    if (value) {
      _selectedMyShelterId = null; // Prioriza todos os cadastros
    }
    notifyListeners();
  }

  /// Filtro "Seus Animais": filtra pelos animais de um abrigo específico do voluntário
  void setSelectedMyShelterId(String? shelterId) {
    _selectedMyShelterId = shelterId;
    if (shelterId != null) {
      _showOnlyMyPets = false;
    }
    notifyListeners();
  }

  /// Aplica ou remove filtros avançados.
  void setSpeciesFilter(String? species) {
    _selectedSpecies = species;
    notifyListeners();
  }

  void setSizeFilter(String? size) {
    _selectedSize = size;
    notifyListeners();
  }

  void setGenderFilter(String? gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  void setAgeFilter(String? age) {
    _selectedAge = age;
    notifyListeners();
  }

  /// Remove um filtro específico por chave.
  void removeFilter(String key) {
    switch (key) {
      case 'my_pets':
        _showOnlyMyPets = false;
        break;
      case 'my_shelter':
        _selectedMyShelterId = null;
        break;
      case 'species':
        _selectedSpecies = null;
        break;
      case 'size':
        _selectedSize = null;
        break;
      case 'gender':
        _selectedGender = null;
        break;
      case 'age':
        _selectedAge = null;
        break;
    }
    notifyListeners();
  }

  /// Limpa todos os filtros ativos.
  void clearAllFilters() {
    _showOnlyMyPets = false;
    _selectedMyShelterId = null;
    _selectedSpecies = null;
    _selectedSize = null;
    _selectedGender = null;
    _selectedAge = null;
    _searchQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _petsSubscription?.cancel();
    super.dispose();
  }
}
