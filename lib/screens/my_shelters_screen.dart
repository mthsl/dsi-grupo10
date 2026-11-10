import 'package:flutter/material.dart';
import '../models/shelter_model.dart';
import '../repositories/interfaces/shelter_repository.dart';
import '../repositories/firebase/firebase_shelter_repository.dart';

/// Tela de Gerenciamento de Abrigos (View pura - SRP / DIP).
class MySheltersScreen extends StatefulWidget {
  final IShelterRepository? shelterRepository;

  const MySheltersScreen({super.key, this.shelterRepository});

  @override
  State<MySheltersScreen> createState() => _MySheltersScreenState();
}

class _MySheltersScreenState extends State<MySheltersScreen> {
  late final IShelterRepository _shelterRepository;

  @override
  void initState() {
    super.initState();
    _shelterRepository = widget.shelterRepository ?? FirebaseShelterRepository();
  }

  void _editarTelefone(BuildContext context, ShelterModel abrigo) {
    final TextEditingController telefoneController =
        TextEditingController(text: abrigo.telefone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar WhatsApp', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: telefoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'WhatsApp (Ex: 81999999999)',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = abrigo.copyWith(telefone: telefoneController.text.trim());
              await _shelterRepository.updateShelter(updated);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Telefone atualizado com sucesso!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Gerenciar Abrigos', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<ShelterModel>>(
        stream: _shelterRepository.watchShelters(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum abrigo encontrado.', style: TextStyle(color: Colors.white)));
          }

          final abrigos = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: abrigos.length,
            itemBuilder: (context, index) {
              final abrigo = abrigos[index];

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.home_work, color: Colors.white70),
                  title: Text(abrigo.nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    abrigo.telefone.isEmpty ? 'Sem telefone cadastrado' : 'WhatsApp: ${abrigo.telefone}',
                    style: TextStyle(color: abrigo.telefone.isEmpty ? Colors.redAccent : Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => _editarTelefone(context, abrigo),
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
