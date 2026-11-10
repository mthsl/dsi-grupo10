import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../repositories/interfaces/user_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firebase_user_repository.dart';

/// Controlador da tela de Perfil (GRASP Controller / SOLID SRP / DIP).
///
/// Responsabilidades:
/// - Gerenciar ciclo de vida do carregamento e edição do perfil do usuário.
/// - Validar dados de entrada de forma determinística.
/// - Realizar persistência delegando ao repositório abstrato IUserRepository.
class ProfileController extends ChangeNotifier {
  final IUserRepository _userRepository;
  final IAuthRepository _authRepository;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  UserProfileModel? _profile;

  ProfileController({
    IUserRepository? userRepository,
    IAuthRepository? authRepository,
  })  : _userRepository = userRepository ?? FirebaseUserRepository(),
        _authRepository = authRepository ?? FirebaseAuthRepository();

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  UserProfileModel? get profile => _profile;

  String get userEmail => _authRepository.currentUserEmail ?? _profile?.email ?? '';
  String get userType => _profile?.userType ?? 'Adotante';
  bool get isVolunteer => _profile?.isVolunteer ?? false;

  /// Carrega os dados do perfil do usuário autenticado.
  Future<void> loadProfile() async {
    final uid = _authRepository.currentUserId;
    if (uid == null || uid.isEmpty) {
      _isLoading = false;
      _errorMessage = 'Nenhum usuário autenticado.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _userRepository.getUserProfile(uid);
      _profile ??= UserProfileModel(
        id: uid,
        name: '',
        email: _authRepository.currentUserEmail ?? '',
      );
    } catch (e) {
      _errorMessage = 'Falha ao carregar perfil: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Salva alterações cadastrais com validação e parsing puro.
  Future<bool> saveProfile({
    required String name,
    required String whatsapp,
    required String address,
    required String latitudeStr,
    required String longitudeStr,
  }) async {
    final uid = _authRepository.currentUserId;
    if (uid == null || uid.isEmpty) {
      _errorMessage = 'Usuário não autenticado.';
      notifyListeners();
      return false;
    }

    if (name.trim().isEmpty) {
      _errorMessage = 'Por favor, informe seu nome completo.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final double? parsedLat = latitudeStr.trim().isEmpty
          ? 0.0
          : double.tryParse(latitudeStr.trim().replaceAll(',', '.'));
      final double? parsedLng = longitudeStr.trim().isEmpty
          ? 0.0
          : double.tryParse(longitudeStr.trim().replaceAll(',', '.'));

      if (parsedLat == null || parsedLng == null) {
        _errorMessage = 'Latitude ou longitude com formato inválido.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final updatedProfile = (_profile ??
              UserProfileModel(
                id: uid,
                name: name,
                email: _authRepository.currentUserEmail ?? '',
              ))
          .copyWith(
        name: name.trim(),
        whatsapp: whatsapp.trim(),
        address: address.trim(),
        latitude: parsedLat,
        longitude: parsedLng,
      );

      await _userRepository.saveUserProfile(updatedProfile);
      _profile = updatedProfile;
      _successMessage = 'Perfil atualizado com sucesso!';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao salvar alterações: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Encerra a sessão atual.
  Future<void> logout() async {
    await _authRepository.signOut();
  }
}
