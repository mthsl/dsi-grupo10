import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _telefoneController = TextEditingController();
  
  bool isVoluntario = false;
  bool _isLoading = false;

  void _registrar() async {
    setState(() => _isLoading = true);
    
    String tipoUsuario = isVoluntario ? 'Voluntário' : 'Adotante';
    String? erro = await _authService.registerUser(
      name: _nomeController.text,
      email: _emailController.text,
      password: _senhaController.text,
      phone: _telefoneController.text,
      userType: tipoUsuario,
    );

    setState(() => _isLoading = false);

    if (erro == null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text('Cadastre-se', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Já possui uma conta? ', style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Nome', style: TextStyle(color: Colors.white70)),
              TextField(controller: _nomeController, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              const Text('E-mail', style: TextStyle(color: Colors.white70)),
              TextField(controller: _emailController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              const Text('Senha', style: TextStyle(color: Colors.white70)),
              TextField(controller: _senhaController, style: const TextStyle(color: Colors.white), obscureText: true),
              const SizedBox(height: 16),
              const Text('Número de telefone', style: TextStyle(color: Colors.white70)),
              TextField(controller: _telefoneController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Voluntário', style: TextStyle(color: isVoluntario ? Colors.white : Colors.grey)),
                  Switch(
                    value: !isVoluntario,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) => setState(() => isVoluntario = !value),
                  ),
                  Text('Adotante', style: TextStyle(color: !isVoluntario ? Colors.white : Colors.grey)),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _registrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Registrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}