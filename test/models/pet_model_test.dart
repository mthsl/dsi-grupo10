import 'package:flutter_test/flutter_test.dart';
import 'package:adotai_app/models/pet_model.dart';

void main() {
  group('PetModel (GRASP Information Expert & Immutability)', () {
    const pet = PetModel(
      id: 'pet_1',
      nome: 'Thor',
      especie: 'Cachorro',
      raca: 'Golden Retriever',
      porte: 'Grande',
      sexo: 'Macho',
      faixaEtaria: 'Adulto',
      peso: '30kg',
      descricao: 'Muito brincalhão',
      voluntarioId: 'user_123',
      status: 'Disponível',
    );

    test('deve manter imutabilidade e criar nova instância com copyWith', () {
      final updated = pet.copyWith(nome: 'Thor Silva', status: 'Adotado');
      expect(pet.nome, 'Thor'); // Imutável
      expect(updated.nome, 'Thor Silva');
      expect(updated.status, 'Adotado');
      expect(updated.id, pet.id);
    });

    test('deve verificar se o pet está disponível corretamente', () {
      expect(pet.isDisponivel, isTrue);
      final adotado = pet.copyWith(status: 'Adotado');
      expect(adotado.isDisponivel, isFalse);
    });

    test('deve verificar autoria do voluntário via isOwnedBy', () {
      expect(pet.isOwnedBy('user_123'), isTrue);
      expect(pet.isOwnedBy('user_999'), isFalse);
    });

    test('deve realizar busca textual pura e determinística em matchesQuery', () {
      expect(pet.matchesQuery('thor'), isTrue);
      expect(pet.matchesQuery('golden'), isTrue);
      expect(pet.matchesQuery('cachorro'), isTrue);
      expect(pet.matchesQuery('gato'), isFalse);
      expect(pet.matchesQuery(''), isTrue);
    });

    test('deve serializar e desserializar com precisão (fromMap / toMap)', () {
      final map = pet.toMap();
      final fromMap = PetModel.fromMap(map, id: pet.id);
      expect(fromMap.nome, pet.nome);
      expect(fromMap.especie, pet.especie);
      expect(fromMap.raca, pet.raca);
      expect(fromMap.porte, pet.porte);
      expect(fromMap.sexo, pet.sexo);
      expect(fromMap.faixaEtaria, pet.faixaEtaria);
    });
  });
}
