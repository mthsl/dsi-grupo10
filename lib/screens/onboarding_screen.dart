import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Lista de páginas do Onboarding
  final List<Map<String, String>> onboardingData = [
    {
      "titulo": "Bem-vindo ao Adotaí",
      "texto": "Encontre seu novo melhor amigo de forma rápida e segura.",
      "icone": "pets",
    },
    {
      "titulo": "Conecte-se com Abrigos",
      "texto": "Descubra animais disponíveis perto de você através de mapas interativos.",
      "icone": "map",
    },
    {
      "titulo": "Adote com Responsabilidade",
      "texto": "Entre em contato diretamente com os voluntários e mude a vida de um pet.",
      "icone": "favorite",
    },
  ];

  IconData _getIconData(String iconeNome) {
    switch (iconeNome) {
      case 'pets': return Icons.pets;
      case 'map': return Icons.map;
      case 'favorite': return Icons.favorite;
      default: return Icons.pets;
    }
  }

  void _finalizarOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('viuOnboarding', true); 
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), 
      body: SafeArea(
        child: Column(
          children: [
            // LOGO ADICIONADA AQUI (No topo e centralizada)
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
              child: Image.asset(
                'assets/logo.png', // Certifique-se de que o nome confere com o arquivo salvo
                height: 60, // Ajuste a altura conforme preferir (aumente ou diminua)
                fit: BoxFit.contain,
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIconData(onboardingData[index]["icone"]!),
                          size: 120,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          onboardingData[index]["titulo"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          onboardingData[index]["texto"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Indicador de Páginas e Botões
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _finalizarOnboarding,
                    child: const Text('Pular', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  ),
                  
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 12 : 8,
                        height: _currentPage == index ? 12 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white24,
                        ),
                      ),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == onboardingData.length - 1) {
                        _finalizarOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      _currentPage == onboardingData.length - 1 ? 'Começar' : 'Próximo',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}