import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPetScreen extends StatefulWidget {
  final Map<String, dynamic> petData;
  final String petId;

  const EditPetScreen({super.key, required this.petData, required this.petId});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _racaController;
  late TextEditingController _pesoController;
  late TextEditingController _descricaoController;
  
  late String _especie;
  late String _porte;
  late String _faixaEtaria;
  late String _sexo;
  bool _isLoading = false;

  final List<String> _especies = ['Cachorro', 'Gato', 'Outro'];
  final List<String> _portes = ['Pequeno', 'Médio', 'Grande'];
  final List<String> _idades = ['Filhote', 'Adulto', 'Idoso'];
  final List<String> _sexos = ['Macho', 'Fêmea'];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.petData['nome_busca'] ?? '');
    _racaController = TextEditingController(text: widget.petData['raca'] ?? '');
    _pesoController = TextEditingController(text: widget.petData['peso'] ?? '');
    _descricaoController = TextEditingController(text: widget.petData['descricao'] ?? '');
    
    _especie = _especies.contains(widget.petData['especie']) ? widget.petData['especie'] : 'Cachorro';
    _porte = _portes.contains(widget.petData['porte']) ? widget.petData['porte'] : 'Médio';
    _faixaEtaria = _idades.contains(widget.petData['faixa_etaria']) ? widget.petData['faixa_etaria'] : 'Adulto';
    _sexo = _sexos.contains(widget.petData['sexo']) ? widget.petData['sexo'] : 'Macho';
  }

  Future<void> _atualizarPet() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome do animal.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('pets').doc(widget.petId).update({
        'nome_busca': _nomeController.text.trim().toLowerCase(),
        'raca': _racaController.text.trim(),
        'peso': _pesoController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'especie': _especie,
        'porte': _porte,
        'faixa_etaria': _faixaEtaria,
        'sexo': _sexo,
      });

      if (mounted) {
        Navigator.pop(context); 
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anúncio atualizado com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao atualizar.')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Editar Anúncio', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nomeController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nome do Pet', labelStyle: TextStyle(color: Colors.white70))),
            const SizedBox(height: 16),
            TextField(controller: _racaController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Raça', labelStyle: TextStyle(color: Colors.white70))),
            const SizedBox(height: 16),
            TextField(controller: _pesoController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Peso (kg)', labelStyle: TextStyle(color: Colors.white70))),
            const SizedBox(height: 16),
            TextField(controller: _descricaoController, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Descrição/Bio', labelStyle: TextStyle(color: Colors.white70))),
            const SizedBox(height: 16),
            _buildDropdown('Espécie', _especies, _especie, (val) => setState(() => _especie = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Porte', _portes, _porte, (val) => setState(() => _porte = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Faixa Etária', _idades, _faixaEtaria, (val) => setState(() => _faixaEtaria = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Sexo', _sexos, _sexo, (val) => setState(() => _sexo = val!)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _atualizarPet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Salvar Alterações', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          items: items.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}