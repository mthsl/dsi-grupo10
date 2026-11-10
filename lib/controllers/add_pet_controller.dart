import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/pet_model.dart';
import '../models/shelter_model.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../repositories/interfaces/pet_repository.dart';
import '../repositories/interfaces/shelter_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firebase_pet_repository.dart';
import '../repositories/firebase/firebase_shelter_repository.dart';

/// Controlador para cadastro de pets (GRASP Controller / SOLID SRP & DIP).
class AddPetController extends ChangeNotifier {
  final IPetRepository _petRepository;
  final IShelterRepository _shelterRepository;
  final IAuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  List<ShelterModel> _shelters = [];
  ShelterModel? _selectedShelter;

  AddPetController({
    IPetRepository? petRepository,
    IShelterRepository? shelterRepository,
    IAuthRepository? authRepository,
  })  : _petRepository = petRepository ?? FirebasePetRepository(),
        _shelterRepository = shelterRepository ?? FirebaseShelterRepository(),
        _authRepository = authRepository ?? FirebaseAuthRepository();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ShelterModel> get shelters => _shelters;
  ShelterModel? get selectedShelter => _selectedShelter;
  bool get hasShelters => _shelters.isNotEmpty;

  void setSelectedShelter(ShelterModel? shelter) {
    _selectedShelter = shelter;
    notifyListeners();
  }

  /// Carrega apenas os abrigos criados pelo voluntário logado (Ownership / RBAC).
  Future<void> loadShelters() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUserId = _authRepository.currentUserId ?? '';
      _shelters = await _shelterRepository.getSheltersByCreator(currentUserId);
      if (_shelters.isNotEmpty && _selectedShelter == null) {
        _selectedShelter = _shelters.first;
      }
    } catch (e) {
      _errorMessage = 'Falha ao carregar seus abrigos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerPet({
    required String nome,
    required String raca,
    required String especie,
    required String porte,
    required String faixaEtaria,
    required String sexo,
    required String peso,
    required String descricao,
    Uint8List? imageBytes,
  }) async {
    if (_shelters.isEmpty) {
      _errorMessage = 'Você precisa cadastrar um abrigo antes de cadastrar animais.';
      notifyListeners();
      return false;
    }

    if (nome.trim().isEmpty) {
      _errorMessage = 'Por favor, informe o nome do pet.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUserId = _authRepository.currentUserId ?? '';
      final fotoBase64 = imageBytes != null ? base64Encode(imageBytes) : '';

      final newPet = PetModel(
        id: '',
        nome: nome.trim(),
        especie: especie,
        raca: raca.trim().isEmpty ? 'Não informada' : raca.trim(),
        porte: porte,
        sexo: sexo,
        faixaEtaria: faixaEtaria,
        peso: peso.trim(),
        descricao: descricao.trim(),
        fotoBase64: fotoBase64,
        abrigoId: _selectedShelter?.id ?? '',
        voluntarioId: currentUserId,
        status: 'Disponível',
        dataCadastro: DateTime.now(),
      );

      await _petRepository.addPet(newPet);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar pet: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
