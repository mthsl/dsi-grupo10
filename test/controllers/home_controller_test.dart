import 'package:flutter_test/flutter_test.dart';
import 'package:adotai_app/controllers/home_controller.dart';
import 'package:adotai_app/models/pet_model.dart';
import 'package:adotai_app/models/shelter_model.dart';
import 'package:adotai_app/models/user_profile_model.dart';
import '../mocks/mock_repositories.dart';

void main() {
  group('HomeController (GRASP Controller / Observer / High Cohesion)', () {
    late MockPetRepository petRepo;
    late MockUserRepository userRepo;
    late MockAuthRepository authRepo;
    late MockShelterRepository shelterRepo;
    late HomeController controller;

    final mockPets = [
      const PetModel(
        id: 'p1',
        nome: 'Pipoca',
        especie: 'Cachorro',
        raca: 'Beagle',
        porte: 'Médio',
        sexo: 'Macho',
        faixaEtaria: 'Filhote',
        voluntarioId: 'user_vol',
        abrigoId: 'shelter_1',
        status: 'Disponível',
      ),
      const PetModel(
        id: 'p2',
        nome: 'Luna',
        especie: 'Gato',
        raca: 'Persa',
        porte: 'Pequeno',
        sexo: 'Fêmea',
        faixaEtaria: 'Adulto',
        voluntarioId: 'other_user',
        abrigoId: 'shelter_2',
        status: 'Disponível',
      ),
    ];

    setUp(() {
      petRepo = MockPetRepository(mockPets);
      userRepo = MockUserRepository({
        'user_vol': const UserProfileModel(
          id: 'user_vol',
          name: 'Voluntário João',
          email: 'joao@adotai.org',
          userType: 'Voluntário',
        ),
      });
      authRepo = MockAuthRepository(initialUid: 'user_vol', initialEmail: 'joao@adotai.org');
      shelterRepo = MockShelterRepository([
        const ShelterModel(
          id: 'shelter_1',
          nome: 'Abrigo do João',
          endereco: 'Recife',
          latitude: -8.0,
          longitude: -34.8,
          telefone: '8199999',
          criadorId: 'user_vol',
        ),
      ]);

      controller = HomeController(
        petRepository: petRepo,
        userRepository: userRepo,
        authRepository: authRepo,
        shelterRepository: shelterRepo,
      );
    });

    tearDown(() {
      controller.dispose();
      petRepo.dispose();
    });

    test('deve inicializar e carregar pets disponíveis, perfil e abrigos do voluntário', () async {
      controller.init();
      await Future.delayed(Duration.zero);

      expect(controller.isLoading, isFalse);
      expect(controller.filteredPets.length, 2);
      expect(controller.isVolunteer, isTrue);
      expect(controller.userShelters.length, 1);
      expect(controller.userShelters.first.nome, 'Abrigo do João');
    });

    test('deve filtrar por "Seus Animais" (Meus Cadastros)', () async {
      controller.init();
      await Future.delayed(Duration.zero);

      controller.setShowOnlyMyPets(true);
      expect(controller.filteredPets.length, 1);
      expect(controller.filteredPets.first.nome, 'Pipoca');
      expect(controller.filteredPets.first.voluntarioId, 'user_vol');
    });

    test('deve filtrar por abrigo específico do voluntário', () async {
      controller.init();
      await Future.delayed(Duration.zero);

      controller.setSelectedMyShelterId('shelter_1');
      expect(controller.filteredPets.length, 1);
      expect(controller.filteredPets.first.nome, 'Pipoca');

      controller.setSelectedMyShelterId('shelter_inexistente');
      expect(controller.filteredPets.isEmpty, isTrue);
    });

    test('deve filtrar pets por espécie dinamicamente', () async {
      controller.init();
      await Future.delayed(Duration.zero);

      controller.setSpeciesFilter('Gato');
      expect(controller.filteredPets.length, 1);
      expect(controller.filteredPets.first.nome, 'Luna');

      controller.setSpeciesFilter('Cachorro');
      expect(controller.filteredPets.length, 1);
      expect(controller.filteredPets.first.nome, 'Pipoca');
    });

    test('deve filtrar pets por busca textual em tempo real', () async {
      controller.init();
      await Future.delayed(Duration.zero);

      controller.setSearchQuery('luna');
      expect(controller.filteredPets.length, 1);
      expect(controller.filteredPets.first.nome, 'Luna');

      controller.setSearchQuery('inexistente');
      expect(controller.filteredPets.isEmpty, isTrue);
    });

    test('deve limpar todos os filtros aplicados', () async {
      controller.init();
      await Future.delayed(Duration.zero);

      controller.setShowOnlyMyPets(true);
      controller.setSpeciesFilter('Gato');
      expect(controller.filteredPets.isEmpty, isTrue);

      controller.clearAllFilters();
      expect(controller.filteredPets.length, 2);
      expect(controller.showOnlyMyPets, isFalse);
      expect(controller.selectedSpecies, isNull);
    });
  });
}
