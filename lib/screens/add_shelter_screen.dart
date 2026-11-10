import 'package:flutter/material.dart';
import '../controllers/add_shelter_controller.dart';

/// Tela de Cadastro de Abrigo (View pura - SRP / Controller).
class AddShelterScreen extends StatefulWidget {
  final AddShelterController? controller;

  const AddShelterScreen({super.key, this.controller});

  @override
  State<AddShelterScreen> createState() => _AddShelterScreenState();
}

class _AddShelterScreenState extends State<AddShelterScreen> {
  late final AddShelterController _controller;

  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _telefoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AddShelterController();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _enderecoController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _telefoneController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _salvarAbrigo() async {
    final success = await _controller.registerShelter(
      nome: _nomeController.text,
      endereco: _enderecoController.text,
      latText: _latController.text,
      lngText: _lngController.text,
      telefone: _telefoneController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abrigo cadastrado com sucesso!')),
      );
    } else if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage!)),
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
            title: const Text('Cadastrar Abrigo', style: TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(_nomeController, 'Nome da ONG / Abrigo'),
                const SizedBox(height: 16),
                _buildTextField(_telefoneController, 'WhatsApp / Telefone de Contato', keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField(_enderecoController, 'Endereço Completo'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _latController,
                        'Latitude (ex: -8.04)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        _lngController,
                        'Longitude (ex: -34.87)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _controller.isLoading ? null : _salvarAbrigo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _controller.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Salvar Abrigo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
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
}
