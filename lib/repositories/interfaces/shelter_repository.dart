import '../../models/shelter_model.dart';

/// Contrato abstrato para persistência e recuperação de Abrigos.
///
/// Atende aos princípios:
/// - SOLID DIP: Permite trocar o backend sem tocar nas telas ou controladores.
/// - SOLID ISP: Contrato enxuto e específico para Abrigos.
/// - GRASP Protected Variations: Encapsula a fonte de dados externa.
abstract class IShelterRepository {
  /// Emite fluxo em tempo real de abrigos cadastrados.
  Stream<List<ShelterModel>> watchShelters();

  /// Obtém a lista atual de abrigos.
  Future<List<ShelterModel>> getShelters();

  /// Busca um abrigo pelo ID.
  Future<ShelterModel?> getShelterById(String id);

  /// Cadastra um novo abrigo.
  Future<void> addShelter(ShelterModel shelter);

  /// Atualiza dados de um abrigo existente.
  Future<void> updateShelter(ShelterModel shelter);
}
