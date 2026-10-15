import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MySheltersScreen extends StatelessWidget {
  const MySheltersScreen({super.key});

  void _editarTelefone(BuildContext context, String shelterId, String currentPhone) {
    final TextEditingController telefoneController = TextEditingController(text: currentPhone);

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
              await FirebaseFirestore.instance.collection('shelters').doc(shelterId).update({
                'telefone': telefoneController.text.trim(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefone atualizado!')));
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('shelters').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum abrigo encontrado.', style: TextStyle(color: Colors.white)));
          }

          final abrigos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: abrigos.length,
            itemBuilder: (context, index) {
              var abrigoData = abrigos[index].data() as Map<String, dynamic>;
              String nome = abrigoData['nome'] ?? 'Sem nome';
              String telefone = abrigoData['telefone'] ?? '';

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.home_work, color: Colors.white70),
                  title: Text(nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    telefone.isEmpty ? 'Sem telefone cadastrado' : 'WhatsApp: $telefone',
                    style: TextStyle(color: telefone.isEmpty ? Colors.redAccent : Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => _editarTelefone(context, abrigos[index].id, telefone),
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