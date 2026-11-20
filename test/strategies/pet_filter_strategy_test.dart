import 'package:flutter_test/flutter_test.dart';
import 'package:adotai_app/models/pet_model.dart';
import 'package:adotai_app/strategies/pet_filter_strategy.dart';

void main() {
  group('PetFilterStrategy (GoF Strategy / SOLID OCP / Functional Programming)', () {
    final pet1 = const PetModel(
      id: '1',
      nome: 'Bob',
      especie: 'Cachorro',
      raca: 'Labrador',
      porte: 'Grande',
      sexo: 'Macho',
      faixaEtaria: 'Adulto',
      status: 'Disponível',
    );

    final pet2 = const PetModel(
      id: '2',
      nome: 'Mia',
      especie: 'Gato',
      raca: 'Siamês',
      porte: 'Pequeno',
      sexo: 'Fêmea',
      faixaEtaria: 'Filhote',
      status: 'Disponível',
    );

    final pet3 = const PetModel(
      id: '3',
      nome: 'Rex',
      especie: 'Cachorro',
      raca: 'Poodle',
      porte: 'Pequeno',
      sexo: 'Macho',
      faixaEtaria: 'Idoso',
      status: 'Adotado',
    );

    final allPets = [pet1, pet2, pet3];

    test('deve filtrar por espécie com SpeciesFilterStrategy', () {
      final strategy = const SpeciesFilterStrategy('Cachorro');
      expect(strategy.isSatisfiedBy(pet1), isTrue);
      expect(strategy.isSatisfiedBy(pet2), isFalse);
    });

    test('deve filtrar por sexo com GenderFilterStrategy', () {
      final strategy = const GenderFilterStrategy('Fêmea');
      expect(strategy.isSatisfiedBy(pet1), isFalse);
      expect(strategy.isSatisfiedBy(pet2), isTrue);
    });

    test('deve filtrar por porte com SizeFilterStrategy', () {
      final strategy = const SizeFilterStrategy('Pequeno');
      expect(strategy.isSatisfiedBy(pet1), isFalse);
      expect(strategy.isSatisfiedBy(pet2), isTrue);
      expect(strategy.isSatisfiedBy(pet3), isTrue);
    });

    test('deve filtrar por idade com AgeFilterStrategy', () {
      final strategy = const AgeFilterStrategy('Filhote');
      expect(strategy.isSatisfiedBy(pet2), isTrue);
      expect(strategy.isSatisfiedBy(pet1), isFalse);
    });

    test('deve executar pipeline funcional puro com múltiplas estratégias compostas', () {
      // Pipeline: Pets Disponíveis + Cachorro + Porte Grande
      final strategies = <IPetFilterStrategy>[
        const StatusFilterStrategy('Disponível'),
        const SpeciesFilterStrategy('Cachorro'),
        const SizeFilterStrategy('Grande'),
      ];

      final result = filterPets(allPets, strategies);

      expect(result.length, 1);
      expect(result.first.nome, 'Bob');
      // Garante imutabilidade da lista original
      expect(allPets.length, 3);
    });

    test('deve retornar lista inalterada se nenhuma estratégia for fornecida', () {
      final result = filterPets(allPets, []);
      expect(result.length, 3);
    });
  });
}
