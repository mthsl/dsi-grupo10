import '../../models/pet_model.dart';

/// Contrato abstrato para persistência e recuperação de Pets.
///
/// Atende aos princípios:
/// - SOLID DIP: Módulos de alto nível dependem desta abstração, e não do Firestore.
/// - SOLID ISP: Contrato coeso e específico para operações com Pets.
/// - GRASP Protected Variations: Isola o restante da aplicação de variações na fonte de dados.
/// - GRASP Pure Fabrication: Fabricação pura para gerenciar persistência com baixo acoplamento.
abstract class IPetRepository {
  /// Emite fluxo em tempo real de pets disponíveis.
  Stream<List<PetModel>> watchAvailablePets();

  /// Obtém a lista atual de pets disponíveis.
  Future<List<PetModel>> getAvailablePets();

  /// Busca um pet específico pelo identificador único.
  Future<PetModel?> getPetById(String id);

  /// Salva um novo pet no repositório.
  Future<void> addPet(PetModel pet);

  /// Atualiza os dados de um pet existente.
  Future<void> updatePet(PetModel pet);

  /// Remove o pet do repositório.
  Future<void> deletePet(String id);
}
