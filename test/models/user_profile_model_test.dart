import 'package:flutter_test/flutter_test.dart';
import 'package:adotai_app/models/user_profile_model.dart';
import 'package:adotai_app/models/shelter_model.dart';

void main() {
  group('UserProfileModel', () {
    const user = UserProfileModel(
      id: 'uid_1',
      name: 'Maria Silva',
      email: 'maria@example.com',
      whatsapp: '(81) 98888-7777',
      address: 'Rua das Flores, 100, Recife - PE',
      latitude: -8.0476,
      longitude: -34.8770,
      userType: 'Voluntário',
      favorites: ['pet_1', 'pet_2'],
    );

    test('deve verificar perfil de voluntário corretamente', () {
      expect(user.isVolunteer, isTrue);
      final adotante = user.copyWith(userType: 'Adotante');
      expect(adotante.isVolunteer, isFalse);
    });

    test('deve sanitizar o número de WhatsApp em sanitizedWhatsApp', () {
      expect(user.sanitizedWhatsApp, '81988887777');
    });

    test('deve validar coordenadas geográficas', () {
      expect(user.hasValidCoordinates, isTrue);
      final semCoord = user.copyWith(latitude: 0.0, longitude: 0.0);
      expect(semCoord.hasValidCoordinates, isFalse);
    });

    test('deve verificar favoritos via hasFavorite', () {
      expect(user.hasFavorite('pet_1'), isTrue);
      expect(user.hasFavorite('pet_99'), isFalse);
    });

    test('deve serializar e desserializar para o Firestore perfeitamente', () {
      final map = user.toMap();
      final recovered = UserProfileModel.fromMap(map, id: user.id);
      expect(recovered.name, user.name);
      expect(recovered.whatsapp, user.whatsapp);
      expect(recovered.address, user.address);
      expect(recovered.latitude, user.latitude);
      expect(recovered.longitude, user.longitude);
      expect(recovered.userType, user.userType);
      expect(recovered.favorites, user.favorites);
    });
  });

  group('ShelterModel', () {
    const shelter = ShelterModel(
      id: 'shelter_1',
      nome: 'Abrigo Esperança',
      endereco: 'Av. Caxangá, 500, Recife - PE',
      latitude: -8.0400,
      longitude: -34.9000,
      telefone: '(81) 99999-1234',
    );

    test('deve validar coordenadas do abrigo', () {
      expect(shelter.hasValidCoordinates, isTrue);
      expect(shelter.sanitizedPhone, '81999991234');
    });

    test('deve serializar e desserializar abrigo', () {
      final map = shelter.toMap();
      final from = ShelterModel.fromMap(map, id: shelter.id);
      expect(from.nome, shelter.nome);
      expect(from.endereco, shelter.endereco);
      expect(from.latitude, shelter.latitude);
      expect(from.longitude, shelter.longitude);
      expect(from.telefone, shelter.telefone);
    });
  });
}
