import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../repositories/interfaces/pet_repository.dart';
import '../repositories/firebase/firebase_pet_repository.dart';

/// Tela de Edição de Anúncio de Pet (View pura - SRP / DIP).
class EditPetScreen extends StatefulWidget {
  final PetModel pet;
  final IPetRepository? petRepository;

  EditPetScreen({
    super.key,
    PetModel? pet,
    Map<String, dynamic>? petData,
    String? petId,
    this.petRepository,
  }) : pet = pet ??
            PetModel.fromMap(
              petData ?? const {},
              id: petId ?? (petData?['id'] ?? ''),
            );

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  late final IPetRepository _petRepository;

  late final TextEditingController _nomeController;
  late final TextEditingController _racaController;
  late final TextEditingController _pesoController;
  late final TextEditingController _descricaoController;

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
    _petRepository = widget.petRepository ?? FirebasePetRepository();

    final pet = widget.pet;
    _nomeController = TextEditingController(text: pet.nome);
    _racaController = TextEditingController(text: pet.raca);
    _pesoController = TextEditingController(text: pet.peso);
    _descricaoController = TextEditingController(text: pet.descricao);

    _especie = _especies.contains(pet.especie) ? pet.especie : 'Cachorro';
    _porte = _portes.contains(pet.porte) ? pet.porte : 'Médio';
    _faixaEtaria = _idades.contains(pet.faixaEtaria) ? pet.faixaEtaria : 'Adulto';
    _sexo = _sexos.contains(pet.sexo) ? pet.sexo : 'Macho';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _racaController.dispose();
    _pesoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _atualizarPet() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do animal.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedPet = widget.pet.copyWith(
        nome: _nomeController.text.trim(),
        raca: _racaController.text.trim().isEmpty ? 'Não informada' : _racaController.text.trim(),
        peso: _pesoController.text.trim(),
        descricao: _descricaoController.text.trim(),
        especie: _especie,
        porte: _porte,
        faixaEtaria: _faixaEtaria,
        sexo: _sexo,
      );

      await _petRepository.updatePet(updatedPet);

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anúncio atualizado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
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
        elevation: 0,
        title: const Text('Editar Animal', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(_nomeController, 'Nome do Pet'),
            const SizedBox(height: 16),
            _buildTextField(_racaController, 'Raça (Ex: Poodle, SRD...)'),
            const SizedBox(height: 16),
            _buildTextField(_pesoController, 'Peso (Ex: 12kg)', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildDropdown('Espécie', _especie, _especies, (val) => setState(() => _especie = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Porte', _porte, _portes, (val) => setState(() => _porte = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Idade', _faixaEtaria, _idades, (val) => setState(() => _faixaEtaria = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Sexo', _sexo, _sexos, (val) => setState(() => _sexo = val!)),
            const SizedBox(height: 16),
            _buildTextField(_descricaoController, 'História / Descrição do Pet', maxLines: 3),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _atualizarPet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Salvar Alterações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF1E1E1E),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}
