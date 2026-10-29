import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'my_shelters_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _userType = 'Adotante';
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _whatsappController.dispose();
    _enderecoController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  // Carrega os dados do usuário a partir do Firestore
  Future<void> _carregarDadosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _userEmail = user.email;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _nomeController.text = data['name'] ?? '';
        _whatsappController.text = data['whatsapp'] ?? data['phone'] ?? '';
        _enderecoController.text = data['endereco'] ?? data['address'] ?? '';
        
        if (data['latitude'] != null) {
          _latitudeController.text = data['latitude'].toString();
        }
        if (data['longitude'] != null) {
          _longitudeController.text = data['longitude'].toString();
        }

        _userType = data['userType'] ?? 'Adotante';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados do perfil: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Salva ou atualiza os dados no Firestore em conformidade com o banco
  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // Faz o parse numérico de latitude e longitude com suporte a vírgula e ponto
      double? lat;
      double? lng;

      final latText = _latitudeController.text.trim().replaceAll(',', '.');
      final lngText = _longitudeController.text.trim().replaceAll(',', '.');

      if (latText.isNotEmpty) {
        lat = double.tryParse(latText);
      }
      if (lngText.isNotEmpty) {
        lng = double.tryParse(lngText);
      }

      final Map<String, dynamic> dadosAtualizados = {
        'name': _nomeController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'phone': _whatsappController.text.trim(), // Garante compatibilidade caso outro serviço use 'phone'
        'endereco': _enderecoController.text.trim(),
        'address': _enderecoController.text.trim(), // Garante compatibilidade
        'latitude': lat ?? 0.0,
        'longitude': lng ?? 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(dadosAtualizados, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar dados: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
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
      body: _isLoading
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
                    // Header com Avatar, Email e Tipo de Usuário
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
                            _userEmail ?? 'Sem e-mail',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _userType == 'Voluntário'
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _userType == 'Voluntário' ? Colors.orange : Colors.blue,
                              ),
                            ),
                            child: Text(
                              _userType,
                              style: TextStyle(
                                color: _userType == 'Voluntário' ? Colors.orange : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Título da Seção
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
                        hint: 'Ex: Rua Exemplo, 123, Apto 101, Bairro, Cidade - UF',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, informe o endereço completo.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campos 4 e 5: Latitude e Longitude lado a lado
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: _buildInputDecoration(
                              label: 'Latitude',
                              icon: Icons.my_location,
                              hint: 'Ex: -8.0476',
                            ),
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
                                if (parsed == null) {
                                  return 'Valor inválido';
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: _buildInputDecoration(
                              label: 'Longitude',
                              icon: Icons.explore_outlined,
                              hint: 'Ex: -34.8770',
                            ),
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
                                if (parsed == null) {
                                  return 'Valor inválido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Botão Salvar Alterações
                    ElevatedButton(
                      onPressed: _isSaving ? null : _salvarDados,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Salvar Alterações',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Botão exclusivo de Gerenciar Abrigos se for Voluntário
                    if (_userType == 'Voluntário') ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MySheltersScreen(),
                            ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Divider(color: Colors.white12, height: 32),

                    // Botão Sair da Conta
                    TextButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text(
                        'Sair da conta',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
