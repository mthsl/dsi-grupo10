import 'package:flutter_test/flutter_test.dart';
import 'package:adotai_app/controllers/profile_controller.dart';
import 'package:adotai_app/models/user_profile_model.dart';
import '../mocks/mock_repositories.dart';

void main() {
  group('ProfileController (GRASP Controller / SRP / DIP)', () {
    late MockUserRepository userRepo;
    late MockAuthRepository authRepo;
    late ProfileController controller;

    setUp(() {
      userRepo = MockUserRepository({
        'user_1': const UserProfileModel(
          id: 'user_1',
          name: 'Carlos Oliveira',
          email: 'carlos@example.com',
          whatsapp: '81987654321',
          address: 'Rua Principal, 50',
          latitude: -8.0500,
          longitude: -34.8800,
          userType: 'Adotante',
        ),
      });
      authRepo = MockAuthRepository(initialUid: 'user_1', initialEmail: 'carlos@example.com');
      controller = ProfileController(
        userRepository: userRepo,
        authRepository: authRepo,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('deve carregar dados do perfil com sucesso', () async {
      await controller.loadProfile();

      expect(controller.isLoading, isFalse);
      expect(controller.profile?.name, 'Carlos Oliveira');
      expect(controller.userEmail, 'carlos@example.com');
      expect(controller.userType, 'Adotante');
      expect(controller.isVolunteer, isFalse);
    });

    test('deve salvar perfil atualizado e validar parsing numérico', () async {
      await controller.loadProfile();

      final success = await controller.saveProfile(
        name: 'Carlos Oliveira Santos',
        whatsapp: '81999990000',
        address: 'Nova Rua, 100, Recife',
        latitudeStr: '-8.0555',
        longitudeStr: '-34.8888',
      );

      expect(success, isTrue);
      expect(controller.profile?.name, 'Carlos Oliveira Santos');
      expect(controller.profile?.latitude, -8.0555);
      expect(controller.profile?.longitude, -34.8888);

      final inRepo = await userRepo.getUserProfile('user_1');
      expect(inRepo?.name, 'Carlos Oliveira Santos');
    });

    test('deve rejeitar salvar perfil com nome vazio', () async {
      await controller.loadProfile();

      final success = await controller.saveProfile(
        name: '',
        whatsapp: '81999990000',
        address: 'Rua',
        latitudeStr: '0',
        longitudeStr: '0',
      );

      expect(success, isFalse);
      expect(controller.errorMessage, isNotNull);
    });
  });
}
