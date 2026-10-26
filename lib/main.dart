import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  // Garante que o Flutter inicializou antes de rodar código nativo (Firebase e SharedPreferences)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Verifica no SharedPreferences se o usuário já passou pelo Onboarding
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool viuOnboarding = prefs.getBool('viuOnboarding') ?? false;

  runApp(MyApp(viuOnboarding: viuOnboarding));
}

class MyApp extends StatelessWidget {
  final bool viuOnboarding;

  const MyApp({super.key, required this.viuOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adotaí',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.orange, // Sua cor principal
          background: Color(0xFF121212),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      // A tela inicial depende da variável viuOnboarding salva no SharedPreferences
      home: viuOnboarding ? const AuthChecker() : const OnboardingScreen(),
      
      // Definição das rotas nomeadas
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainNavigationScreen(),
      },
    );
  }
}

// Widget que escuta as mudanças de autenticação no Firebase
class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Exibe um carregamento enquanto verifica o estado da autenticação
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        // Se o Firebase identificar que existe um usuário logado
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigationScreen();
        }

        // Caso contrário, redireciona para a tela de Login
        return const LoginScreen();
      },
    );
  }
}