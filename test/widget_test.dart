import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adotai_app/screens/home_screen.dart';
import 'package:adotai_app/controllers/home_controller.dart';
import 'package:adotai_app/models/pet_model.dart';
import 'mocks/mock_repositories.dart';

void main() {
  testWidgets('HomeScreen exibe o título Adotaí e lista os pets carregados via controller',
      (WidgetTester tester) async {
    final petRepo = MockPetRepository([
      const PetModel(
        id: '1',
        nome: 'Pipoca',
        especie: 'Cachorro',
        raca: 'Beagle',
        porte: 'Médio',
        sexo: 'Macho',
        faixaEtaria: 'Filhote',
        status: 'Disponível',
      ),
    ]);
    final userRepo = MockUserRepository();
    final authRepo = MockAuthRepository();
    final shelterRepo = MockShelterRepository();

    final controller = HomeController(
      petRepository: petRepo,
      userRepository: userRepo,
      authRepository: authRepo,
      shelterRepository: shelterRepo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(controller: controller),
      ),
    );

    await tester.pump();

    // Verifica identidade visual e presença do título
    expect(find.text('Adotaí'), findsOneWidget);
    expect(find.text('Pets Disponíveis'), findsOneWidget);
    expect(find.text('Pipoca'), findsOneWidget);
    expect(find.text('Beagle'), findsOneWidget);

    controller.dispose();
    petRepo.dispose();
  });
}
