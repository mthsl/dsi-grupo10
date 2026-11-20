import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/add_pet_controller.dart';
import '../models/shelter_model.dart';
import 'add_shelter_screen.dart';

/// Tela de Cadastro de Pet (View pura - SRP / Controller).
class AddPetScreen extends StatefulWidget {
  final AddPetController? controller;

  const AddPetScreen({super.key, this.controller});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  late final AddPetController _controller;

  final _nomeController = TextEditingController();
  final _racaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _descricaoController = TextEditingController();

  String _especie = 'Cachorro';
  String _porte = 'Médio';
  String _faixaEtaria = 'Adulto';
  String _sexo = 'Macho';

  Uint8List? _imageBytes;

  final List<String> _especies = ['Cachorro', 'Gato', 'Outro'];
  final List<String> _portes = ['Pequeno', 'Médio', 'Grande'];
  final List<String> _idades = ['Filhote', 'Adulto', 'Idoso'];
  final List<String> _sexos = ['Macho', 'Fêmea'];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AddPetController();
    _controller.loadShelters();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _racaController.dispose();
    _pesoController.dispose();
    _descricaoController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxWidth: 600,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _cadastrar() async {
    final success = await _controller.registerPet(
      nome: _nomeController.text,
      raca: _racaController.text,
      especie: _especie,
      porte: _porte,
      faixaEtaria: _faixaEtaria,
      sexo: _sexo,
      peso: _pesoController.text,
      descricao: _descricaoController.text,
      imageBytes: _imageBytes,
    );

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Pet cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (_controller.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
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
                // Alerta caso o voluntário ainda não tenha criado abrigos
                if (!_controller.isLoading && _controller.shelters.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Atenção, voluntário!',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Você só pode cadastrar animais em abrigos que você mesmo criou. Cadastre seu primeiro abrigo abaixo:',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddShelterScreen()),
                            );
                            _controller.loadShelters();
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Cadastrar Meu Abrigo Agora', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Seleção de Foto
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 48, color: Colors.orange),
                              SizedBox(height: 8),
                              Text('Adicionar Foto', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Seleção do Abrigo (Apenas os criados pelo voluntário)
                if (_controller.shelters.isNotEmpty)
                  DropdownButtonFormField<ShelterModel>(
                    initialValue: _controller.selectedShelter,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Selecione Seu Abrigo',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: _controller.shelters.map((shelter) {
                      return DropdownMenuItem<ShelterModel>(
                        value: shelter,
                        child: Text(shelter.nome),
                      );
                    }).toList(),
                    onChanged: (val) => _controller.setSelectedShelter(val),
                  ),
                const SizedBox(height: 16),

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
                  onPressed: (_controller.isLoading || _controller.shelters.isEmpty) ? null : _cadastrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _controller.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Cadastrar Animal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
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
