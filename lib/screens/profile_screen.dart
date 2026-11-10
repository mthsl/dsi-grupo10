import 'package:flutter/material.dart';
import '../controllers/profile_controller.dart';
import 'login_screen.dart';
import 'my_shelters_screen.dart';

/// Tela de Perfil do Usuário (View pura - SRP / GRASP Controller).
///
/// Responsabilidades:
/// - Coletar entradas do usuário e repassar ao ProfileController.
/// - Exibir dados cadastrais de forma reativa sem acoplamento a banco de dados.
class ProfileScreen extends StatefulWidget {
  final ProfileController? controller;

  const ProfileScreen({super.key, this.controller});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  bool _initializedFields = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ProfileController();
    _controller.loadProfile();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _whatsappController.dispose();
    _enderecoController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _syncFieldsWithProfile() {
    final p = _controller.profile;
    if (p != null && !_initializedFields) {
      _nomeController.text = p.name;
      _whatsappController.text = p.whatsapp;
      _enderecoController.text = p.address;
      _latitudeController.text = p.latitude == 0.0 ? '' : p.latitude.toString();
      _longitudeController.text = p.longitude == 0.0 ? '' : p.longitude.toString();
      _initializedFields = true;
    }
  }

  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.saveProfile(
      name: _nomeController.text,
      whatsapp: _whatsappController.text,
      address: _enderecoController.text,
      latitudeStr: _latitudeController.text,
      longitudeStr: _longitudeController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await _controller.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.orange, size: 20),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.orange, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        _syncFieldsWithProfile();

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF121212),
            title: const Text(
              'Meu Perfil',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            centerTitle: true,
          ),
          body: _controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar e Tipo de Perfil
                        Center(
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 46,
                                backgroundColor: Color(0xFF2A2A2A),
                                child: Icon(Icons.person, size: 50, color: Colors.orange),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _controller.userEmail,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _controller.isVolunteer
                                      ? Colors.orange.withValues(alpha: 0.2)
                                      : Colors.blue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _controller.isVolunteer ? Colors.orange : Colors.blue,
                                  ),
                                ),
                                child: Text(
                                  _controller.userType,
                                  style: TextStyle(
                                    color: _controller.isVolunteer ? Colors.orange : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        const Text(
                          'Dados Cadastrais',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Preencha ou edite suas informações de contato e localização:',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        const SizedBox(height: 18),

                        // Campo 1: Nome
                        TextFormField(
                          controller: _nomeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(
                            label: 'Nome completo',
                            icon: Icons.person_outline,
                            hint: 'Digite seu nome',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, informe seu nome.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo 2: WhatsApp
                        TextFormField(
                          controller: _whatsappController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDecoration(
                            label: 'WhatsApp',
                            icon: Icons.phone_android,
                            hint: 'Ex: (81) 99999-9999',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, informe o WhatsApp para contato.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo 3: Endereço Completo
                        TextFormField(
                          controller: _enderecoController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          decoration: _buildInputDecoration(
                            label: 'Endereço completo',
                            icon: Icons.location_on_outlined,
                            hint: 'Ex: Rua Exemplo, 123, Bairro, Cidade - UF',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, informe o endereço completo.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campos 4 e 5: Latitude e Longitude
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latitudeController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: _buildInputDecoration(
                                  label: 'Latitude',
                                  icon: Icons.my_location,
                                  hint: 'Ex: -8.0476',
                                ),
                                validator: (val) {
                                  if (val != null && val.trim().isNotEmpty) {
                                    if (double.tryParse(val.trim().replaceAll(',', '.')) == null) {
                                      return 'Inválido';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _longitudeController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: _buildInputDecoration(
                                  label: 'Longitude',
                                  icon: Icons.explore_outlined,
                                  hint: 'Ex: -34.8770',
                                ),
                                validator: (val) {
                                  if (val != null && val.trim().isNotEmpty) {
                                    if (double.tryParse(val.trim().replaceAll(',', '.')) == null) {
                                      return 'Inválido';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Botão Salvar
                        ElevatedButton(
                          onPressed: _controller.isSaving ? null : _salvarDados,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 2,
                          ),
                          child: _controller.isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Salvar Alterações',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Botão de Gerenciar Abrigos se for Voluntário
                        if (_controller.isVolunteer) ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MySheltersScreen()),
                              );
                            },
                            icon: const Icon(Icons.home_work, color: Colors.orange),
                            label: const Text(
                              'Gerenciar Meus Abrigos',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.orange),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const Divider(color: Colors.white12, height: 32),

                        // Sair da Conta
                        TextButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
                          label: const Text(
                            'Sair da conta',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
