import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adotai_app/models/pet_model.dart';
import 'package:adotai_app/models/shelter_model.dart';
import 'package:adotai_app/screens/pet_details_screen.dart';
import 'package:adotai_app/screens/shelter_details_screen.dart';

import '../mocks/mock_repositories.dart';

void main() {
  const abrigo = ShelterModel(
    id: 'shelter_1',
    nome: 'Abrigo Patinhas Felizes',
    endereco: 'Rua Hercília de Medeiros, 78, Cajueiro, Recife - PE',
    latitude: 0,
    longitude: 0,
    telefone: '(81) 99999-0000',
    chavePix: 'patinhas@pix.com',
    criadorId: 'voluntario_1',
  );

  testWidgets('ShelterDetailsScreen exibe todas as informações do abrigo',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ShelterDetailsScreen(shelter: abrigo)),
    );

    expect(find.text('Abrigo Patinhas Felizes'), findsOneWidget);
    expect(
      find.text('Rua Hercília de Medeiros, 78, Cajueiro, Recife - PE'),
      findsOneWidget,
    );
    expect(find.text('(81) 99999-0000'), findsOneWidget);
    expect(find.text('patinhas@pix.com'), findsOneWidget);
    expect(find.byTooltip('Copiar Chave Pix'), findsOneWidget);
    expect(find.byTooltip('Chamar no WhatsApp'), findsOneWidget);
    expect(find.text('Entrar em contato'), findsOneWidget);
    expect(find.text('Copiar chave Pix'), findsOneWidget);

    // Sem coordenadas válidas, o mapa não é exibido.
    expect(find.text('Localização'), findsNothing);
  });

  testWidgets('PetDetailsScreen navega para os detalhes do abrigo ao tocar no nome',
      (WidgetTester tester) async {
    final shelterRepo = MockShelterRepository([abrigo]);
    final petRepo = MockPetRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: PetDetailsScreen(
          pet: const PetModel(
            id: 'pet_1',
            nome: 'Rex',
            especie: 'Cachorro',
            raca: 'Vira-lata',
            porte: 'Médio',
            sexo: 'Macho',
            faixaEtaria: 'Adulto',
            abrigoId: 'shelter_1',
            voluntarioId: 'voluntario_1',
          ),
          petRepository: petRepo,
          shelterRepository: shelterRepo,
          authRepository: MockAuthRepository(),
          userRepository: MockUserRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Abrigo responsável'), findsOneWidget);
    expect(find.text('Abrigo Patinhas Felizes'), findsOneWidget);
    expect(find.text('Toque para ver todas as informações do abrigo'), findsOneWidget);

    await tester.ensureVisible(find.text('Abrigo Patinhas Felizes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrigo Patinhas Felizes'));
    await tester.pumpAndSettle();

    expect(find.byType(ShelterDetailsScreen), findsOneWidget);
    expect(find.text('Informações do Abrigo'), findsOneWidget);
    expect(find.text('patinhas@pix.com'), findsOneWidget);

    petRepo.dispose();
  });
}
