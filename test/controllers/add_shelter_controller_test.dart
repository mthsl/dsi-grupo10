import 'package:flutter_test/flutter_test.dart';
import 'package:adotai_app/controllers/add_pet_controller.dart';
import 'package:adotai_app/controllers/add_shelter_controller.dart';
import 'package:adotai_app/models/shelter_model.dart';
import '../mocks/mock_repositories.dart';

void main() {
  group('AddShelterController (GRASP Controller / Ownership)', () {
    late MockShelterRepository shelterRepo;
    late MockAuthRepository authRepo;
    late AddShelterController controller;

    setUp(() {
      shelterRepo = MockShelterRepository();
      authRepo = MockAuthRepository(initialUid: 'vol_1', initialEmail: 'vol@teste.com');
      controller = AddShelterController(
        shelterRepository: shelterRepo,
        authRepository: authRepo,
      );
    });

    tearDown(() => controller.dispose());

    test('deve cadastrar abrigo vinculado ao voluntário logado e com chave Pix', () async {
      final success = await controller.registerShelter(
        nome: 'Abrigo Esperança',
        endereco: 'Rua A, 10, Recife - PE',
        latText: '-8,05',
        lngText: '-34,88',
        telefone: '(81) 99999-0000',
        chavePix: 'pix@esperanca.com',
      );

      expect(success, isTrue);
      expect(shelterRepo.shelters, hasLength(1));

      final shelter = shelterRepo.shelters.single;
      expect(shelter.nome, 'Abrigo Esperança');
      expect(shelter.criadorId, 'vol_1');
      expect(shelter.chavePix, 'pix@esperanca.com');
      expect(shelter.latitude, closeTo(-8.05, 0.0001));
      expect(shelter.longitude, closeTo(-34.88, 0.0001));
    });

    test('deve atualizar todos os campos editáveis do abrigo', () async {
      await controller.registerShelter(
        nome: 'Abrigo Antigo',
        endereco: 'Rua Antiga, 1',
        latText: '0',
        lngText: '0',
        telefone: '1111',
        chavePix: '',
      );

      final original = shelterRepo.shelters.single;
      final success = await controller.updateShelter(
        original.copyWith(
          nome: 'Abrigo Novo',
          endereco: 'Rua Nova, 100, Olinda - PE',
          telefone: '(81) 98888-7777',
          chavePix: 'novo@pix.com',
          latitude: -8.0100,
          longitude: -34.8500,
        ),
      );

      expect(success, isTrue);

      final updated = shelterRepo.shelters.single;
      expect(updated.nome, 'Abrigo Novo');
      expect(updated.endereco, 'Rua Nova, 100, Olinda - PE');
      expect(updated.telefone, '(81) 98888-7777');
      expect(updated.chavePix, 'novo@pix.com');
      expect(updated.latitude, closeTo(-8.0100, 0.0001));
      expect(updated.longitude, closeTo(-34.8500, 0.0001));
      expect(updated.criadorId, 'vol_1');
    });
  });

  group('AddPetController (restrição a abrigos do próprio voluntário)', () {
    late MockPetRepository petRepo;
    late MockShelterRepository shelterRepo;
    late MockAuthRepository authRepo;
    late AddPetController controller;

    setUp(() {
      petRepo = MockPetRepository();
      shelterRepo = MockShelterRepository([
        const ShelterModel(
          id: 's_meu',
          nome: 'Meu Abrigo',
          endereco: 'Recife',
          latitude: -8.0,
          longitude: -34.8,
          telefone: '8199999',
          criadorId: 'vol_1',
        ),
        const ShelterModel(
          id: 's_outro',
          nome: 'Abrigo de Outro',
          endereco: 'Recife',
          latitude: -8.1,
          longitude: -34.9,
          telefone: '8188888',
          criadorId: 'vol_2',
        ),
      ]);
      authRepo = MockAuthRepository(initialUid: 'vol_1', initialEmail: 'vol@teste.com');
      controller = AddPetController(
        petRepository: petRepo,
        shelterRepository: shelterRepo,
        authRepository: authRepo,
      );
    });

    tearDown(() {
      controller.dispose();
      petRepo.dispose();
    });

    test('deve carregar apenas os abrigos criados pelo voluntário logado', () async {
      await controller.loadShelters();

      expect(controller.shelters, hasLength(1));
      expect(controller.shelters.single.id, 's_meu');
      expect(controller.selectedShelter?.id, 's_meu');
    });

    test('deve vincular o pet ao abrigo selecionado e ao voluntário logado', () async {
      await controller.loadShelters();

      final success = await controller.registerPet(
        nome: 'Pipoca',
        raca: 'Beagle',
        especie: 'Cachorro',
        porte: 'Médio',
        faixaEtaria: 'Filhote',
        sexo: 'Macho',
        peso: '8kg',
        descricao: 'Muito dócil',
      );

      expect(success, isTrue);
      expect(petRepo.pets, hasLength(1));

      final pet = petRepo.pets.single;
      expect(pet.abrigoId, 's_meu');
      expect(pet.voluntarioId, 'vol_1');
    });

    test('não deve permitir cadastrar pet sem nenhum abrigo próprio', () async {
      final controllerSemAbrigo = AddPetController(
        petRepository: petRepo,
        shelterRepository: MockShelterRepository(),
        authRepository: authRepo,
      );

      await controllerSemAbrigo.loadShelters();

      final success = await controllerSemAbrigo.registerPet(
        nome: 'Rex',
        raca: 'SRD',
        especie: 'Cachorro',
        porte: 'Pequeno',
        faixaEtaria: 'Adulto',
        sexo: 'Macho',
        peso: '5kg',
        descricao: '',
      );

      expect(success, isFalse);
      expect(controllerSemAbrigo.errorMessage, isNotNull);
      expect(petRepo.pets, isEmpty);

      controllerSemAbrigo.dispose();
    });
  });
}
