import 'package:flutter/material.dart';
import '../models/shelter_model.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../repositories/interfaces/shelter_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firebase_shelter_repository.dart';
import '../widgets/interactive_location_picker.dart';
import 'add_shelter_screen.dart';

/// Tela de Gerenciamento de Abrigos do Voluntário (View pura - SRP / DIP).
class MySheltersScreen extends StatefulWidget {
  final IShelterRepository? shelterRepository;
  final IAuthRepository? authRepository;

  const MySheltersScreen({
    super.key,
    this.shelterRepository,
    this.authRepository,
  });

  @override
  State<MySheltersScreen> createState() => _MySheltersScreenState();
}

class _MySheltersScreenState extends State<MySheltersScreen> {
  late final IShelterRepository _shelterRepository;
  late final IAuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _shelterRepository = widget.shelterRepository ?? FirebaseShelterRepository();
    _authRepository = widget.authRepository ?? FirebaseAuthRepository();
  }

  void _abrirModalEdicaoCompleta(BuildContext context, ShelterModel abrigo) {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: abrigo.nome);
    final telefoneController = TextEditingController(text: abrigo.telefone);
    final pixController = TextEditingController(text: abrigo.chavePix);
    final enderecoController = TextEditingController(text: abrigo.endereco);
    final latController = TextEditingController(
      text: abrigo.latitude != 0.0 ? abrigo.latitude.toString() : '',
    );
    final lngController = TextEditingController(
      text: abrigo.longitude != 0.0 ? abrigo.longitude.toString() : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Editar Abrigo',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: nomeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Nome da ONG / Abrigo', Icons.home_work_outlined),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Informe o nome do abrigo.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: telefoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('WhatsApp / Telefone de Contato', Icons.phone_android),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Informe o WhatsApp de contato.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: pixController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Chave Pix p/ Receber Doações', Icons.pix),
                  ),
                  const SizedBox(height: 18),

                  InteractiveLocationPicker(
                    enderecoController: enderecoController,
                    latitudeController: latController,
                    longitudeController: lngController,
                    labelEndereco: 'Endereço Completo do Abrigo',
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final lat = double.tryParse(latController.text.trim().replaceAll(',', '.')) ?? 0.0;
                      final lng = double.tryParse(lngController.text.trim().replaceAll(',', '.')) ?? 0.0;

                      final updated = abrigo.copyWith(
                        nome: nomeController.text.trim(),
                        telefone: telefoneController.text.trim(),
                        chavePix: pixController.text.trim(),
                        endereco: enderecoController.text.trim(),
                        latitude: lat,
                        longitude: lng,
                      );

                      await _shelterRepository.updateShelter(updated);

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Abrigo atualizado com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'Salvar Alterações do Abrigo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.orange, size: 20),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.orange, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authRepository.currentUserId ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Meus Abrigos', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.orange),
            tooltip: 'Cadastrar Novo Abrigo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddShelterScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ShelterModel>>(
        stream: _shelterRepository.watchSheltersByCreator(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home_work_outlined, size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      'Você ainda não cadastrou nenhum abrigo.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cadastre seu abrigo para vincular aos animais que você anunciar para adoção.',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddShelterScreen()),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Cadastrar Abrigo Agora', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final abrigos = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: abrigos.length,
            itemBuilder: (context, index) {
              final abrigo = abrigos[index];

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.home_work, color: Colors.orange, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  abrigo.nome,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                if (abrigo.telefone.isNotEmpty)
                                  Text(
                                    'WhatsApp: ${abrigo.telefone}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            tooltip: 'Editar Todos os Campos do Abrigo',
                            onPressed: () => _abrirModalEdicaoCompleta(context, abrigo),
                          ),
                        ],
                      ),
                      if (abrigo.endereco.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          abrigo.endereco,
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                      if (abrigo.hasPix) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Chave Pix: ${abrigo.chavePix}',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
