import '../models/pet_model.dart';

/// Contrato para o padrão comportamental Strategy (GoF) / OCP (SOLID).
///
/// Permite que novos critérios de filtro sejam adicionados por extensão
/// sem necessitar alterar o código dos controladores ou da tela.
abstract class IPetFilterStrategy {
  /// Retorna true se o pet satisfaz a estratégia.
  bool isSatisfiedBy(PetModel pet);

  /// Identificador textual legível do filtro.
  String get label;
}

/// Estratégia de filtro por Espécie (Cachorro, Gato, etc.).
class SpeciesFilterStrategy implements IPetFilterStrategy {
  final String targetSpecies;

  const SpeciesFilterStrategy(this.targetSpecies);

  @override
  bool isSatisfiedBy(PetModel pet) =>
      targetSpecies.trim().isEmpty ||
      pet.especie.trim().toLowerCase() == targetSpecies.trim().toLowerCase();

  @override
  String get label => 'Espécie: $targetSpecies';
}

/// Estratégia de filtro por Porte (Pequeno, Médio, Grande).
class SizeFilterStrategy implements IPetFilterStrategy {
  final String targetSize;

  const SizeFilterStrategy(this.targetSize);

  @override
  bool isSatisfiedBy(PetModel pet) =>
      targetSize.trim().isEmpty ||
      pet.porte.trim().toLowerCase() == targetSize.trim().toLowerCase();

  @override
  String get label => 'Porte: $targetSize';
}

/// Estratégia de filtro por Sexo (Macho, Fêmea).
class GenderFilterStrategy implements IPetFilterStrategy {
  final String targetGender;

  const GenderFilterStrategy(this.targetGender);

  @override
  bool isSatisfiedBy(PetModel pet) =>
      targetGender.trim().isEmpty ||
      pet.sexo.trim().toLowerCase() == targetGender.trim().toLowerCase();

  @override
  String get label => 'Sexo: $targetGender';
}

/// Estratégia de filtro por Faixa Etária (Filhote, Adulto, Idoso).
class AgeFilterStrategy implements IPetFilterStrategy {
  final String targetAge;

  const AgeFilterStrategy(this.targetAge);

  @override
  bool isSatisfiedBy(PetModel pet) =>
      targetAge.trim().isEmpty ||
      pet.faixaEtaria.trim().toLowerCase() == targetAge.trim().toLowerCase();

  @override
  String get label => 'Idade: $targetAge';
}

/// Estratégia de filtro por Busca Textual (Nome, Raça ou Espécie).
class SearchQueryFilterStrategy implements IPetFilterStrategy {
  final String query;

  const SearchQueryFilterStrategy(this.query);

  @override
  bool isSatisfiedBy(PetModel pet) => pet.matchesQuery(query);

  @override
  String get label => 'Busca: "$query"';
}

/// Estratégia de filtro por Status (ex: Disponível).
class StatusFilterStrategy implements IPetFilterStrategy {
  final String status;

  const StatusFilterStrategy([this.status = 'Disponível']);

  @override
  bool isSatisfiedBy(PetModel pet) =>
      pet.status.trim().toLowerCase() == status.trim().toLowerCase();

  @override
  String get label => 'Status: $status';
}

/// Estratégia de filtro: "Seus Animais" cadastrados pelo voluntário.
class VolunteerFilterStrategy implements IPetFilterStrategy {
  final String volunteerId;

  const VolunteerFilterStrategy(this.volunteerId);

  @override
  bool isSatisfiedBy(PetModel pet) =>
      volunteerId.isNotEmpty && pet.voluntarioId == volunteerId;

  @override
  String get label => 'Meus Cadastros';
}

/// Estratégia de filtro: Animais vinculados a um abrigo específico do voluntário.
class ShelterFilterStrategy implements IPetFilterStrategy {
  final String shelterId;
  final String shelterName;

  const ShelterFilterStrategy(this.shelterId, [this.shelterName = 'Abrigo']);

  @override
  bool isSatisfiedBy(PetModel pet) =>
      shelterId.isNotEmpty && pet.abrigoId == shelterId;

  @override
  String get label => 'Abrigo: $shelterName';
}

// ---------------------------------------------------------------------------
// Pipeline Funcional (Functional Programming - Hackr.io)
// ---------------------------------------------------------------------------

/// Função Pura: Aplica uma lista de estratégias de filtro sobre uma coleção de pets.
List<PetModel> filterPets(
  List<PetModel> pets,
  List<IPetFilterStrategy> strategies,
) {
  if (strategies.isEmpty) return List.unmodifiable(pets);

  return pets
      .where((pet) => strategies.every((strategy) => strategy.isSatisfiedBy(pet)))
      .toList();
}
