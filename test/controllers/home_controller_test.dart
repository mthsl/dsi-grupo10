import 'package:flutter_test/flutter_test.dart';
import 'package:adotai_app/controllers/home_controller.dart';
import 'package:adotai_app/models/pet_model.dart';
import 'package:adotai_app/models/user_profile_model.dart';
import '../mocks/mock_repositories.dart';

void main() {
  group('HomeController (GRASP Controller / Observer / High Cohesion)', () {
    late MockPetRepository petRepo;
    late MockUserRepository userRepo;
    late MockAuthRepository authRepo;
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
      controller = HomeController(
        petRepository: petRepo,
        userRepository: userRepo,
        authRepository: authRepo,
      );
    });

    tearDown(() {
      controller.dispose();
      petRepo.dispose();
    });

    test('deve inicializar e carregar pets disponíveis e papel de voluntário', () async {
      controller.init();
      await Future.delayed(Duration.zero);

      expect(controller.isLoading, isFalse);
      expect(controller.filteredPets.length, 2);
      expect(controller.isVolunteer, isTrue);
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

      controller.setSpeciesFilter('Gato');
      controller.setSizeFilter('Pequeno');
      controller.setSearchQuery('Lu');
      expect(controller.filteredPets.length, 1);

      controller.clearAllFilters();
      expect(controller.filteredPets.length, 2);
      expect(controller.selectedSpecies, isNull);
      expect(controller.searchQuery, isEmpty);
    });
  });
}
