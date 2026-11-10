import 'package:flutter/foundation.dart';
import '../models/shelter_model.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../repositories/interfaces/shelter_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firebase_shelter_repository.dart';

/// Controlador para cadastro e edição de Abrigo (GRASP Controller / SOLID SRP & DIP).
class AddShelterController extends ChangeNotifier {
  final IShelterRepository _shelterRepository;
  final IAuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  AddShelterController({
    IShelterRepository? shelterRepository,
    IAuthRepository? authRepository,
  })  : _shelterRepository = shelterRepository ?? FirebaseShelterRepository(),
        _authRepository = authRepository ?? FirebaseAuthRepository();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> registerShelter({
    required String nome,
    required String endereco,
    required String latText,
    required String lngText,
    required String telefone,
    required String chavePix,
  }) async {
    if (nome.trim().isEmpty) {
      _errorMessage = 'Por favor, informe o nome do abrigo.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUserId = _authRepository.currentUserId ?? '';
      final lat = double.tryParse(latText.trim().replaceAll(',', '.')) ?? 0.0;
      final lng = double.tryParse(lngText.trim().replaceAll(',', '.')) ?? 0.0;

      final shelter = ShelterModel(
        id: '',
        nome: nome.trim(),
        endereco: endereco.trim(),
        latitude: lat,
        longitude: lng,
        telefone: telefone.trim(),
        chavePix: chavePix.trim(),
        criadorId: currentUserId,
      );

      await _shelterRepository.addShelter(shelter);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar abrigo: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateShelter(ShelterModel shelter) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _shelterRepository.updateShelter(shelter);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar abrigo: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
