import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _nomeController = TextEditingController();
  String _especie = 'Cachorro';
  String _porte = 'Médio';
  String _faixaEtaria = 'Adulto';
  String _sexo = 'Macho';
  bool _isLoading = false;

  final List<String> _especies = ['Cachorro', 'Gato', 'Outro'];
  final List<String> _portes = ['Pequeno', 'Médio', 'Grande'];
  final List<String> _idades = ['Filhote', 'Adulto', 'Idoso'];
  final List<String> _sexos = ['Macho', 'Fêmea'];

  Future<void> _salvarPet() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o nome do animal.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance.collection('pets').add({
        'nome_busca': _nomeController.text.trim().toLowerCase(),
        'especie': _especie,
        'porte': _porte,
        'faixa_etaria': _faixaEtaria,
        'sexo': _sexo,
        'status': 'Disponível',
        'voluntarioId': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animal cadastrado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao cadastrar no banco de dados.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Cadastrar Animal', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nome do Pet', style: TextStyle(color: Colors.white70)),
            TextField(
              controller: _nomeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
              ),
            ),
            const SizedBox(height: 24),
            _buildDropdown('Espécie', _especies, _especie, (val) => setState(() => _especie = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Porte', _portes, _porte, (val) => setState(() => _porte = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Faixa Etária', _idades, _faixaEtaria, (val) => setState(() => _faixaEtaria = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Sexo', _sexos, _sexo, (val) => setState(() => _sexo = val!)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _salvarPet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Salvar Cadastro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.grey[900],
          style: const TextStyle(color: Colors.white, fontSize: 16),
          underline: Container(height: 1, color: Colors.white24),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}