import '../../models/shelter_model.dart';

/// Contrato abstrato para persistência e recuperação de Abrigos.
abstract class IShelterRepository {
  /// Emite fluxo em tempo real de todos os abrigos.
  Stream<List<ShelterModel>> watchShelters();

  /// Emite fluxo em tempo real de abrigos criados por um usuário específico.
  Stream<List<ShelterModel>> watchSheltersByCreator(String creatorId);

  /// Obtém a lista atual de abrigos.
  Future<List<ShelterModel>> getShelters();

  /// Obtém a lista de abrigos criados por um usuário específico.
  Future<List<ShelterModel>> getSheltersByCreator(String creatorId);

  /// Busca um abrigo pelo ID.
  Future<ShelterModel?> getShelterById(String id);

  /// Cadastra um novo abrigo.
  Future<void> addShelter(ShelterModel shelter);

  /// Atualiza dados de um abrigo existente.
  Future<void> updateShelter(ShelterModel shelter);
}
