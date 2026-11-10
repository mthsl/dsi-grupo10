import 'package:flutter/material.dart';
import '../controllers/add_shelter_controller.dart';
import '../widgets/interactive_location_picker.dart';

/// Tela de Cadastro de Abrigo (View pura - SRP / Controller).
class AddShelterScreen extends StatefulWidget {
  final AddShelterController? controller;

  const AddShelterScreen({super.key, this.controller});

  @override
  State<AddShelterScreen> createState() => _AddShelterScreenState();
}

class _AddShelterScreenState extends State<AddShelterScreen> {
  late final AddShelterController _controller;
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _pixController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AddShelterController();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _pixController.dispose();
    _enderecoController.dispose();
    _latController.dispose();
    _lngController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _salvarAbrigo() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.registerShelter(
      nome: _nomeController.text,
      endereco: _enderecoController.text,
      latText: _latController.text,
      lngText: _lngController.text,
      telefone: _telefoneController.text,
      chavePix: _pixController.text,
    );

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Abrigo cadastrado com sucesso!'),
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

  InputDecoration _inputDeco(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.orange, size: 20),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.orange, width: 1.5),
      ),
    );
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Nome da ONG / Abrigo', Icons.home_work_outlined),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Informe o nome do abrigo.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('WhatsApp / Telefone de Contato', Icons.phone_android, hint: 'Ex: (81) 99999-9999'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Informe o telefone/WhatsApp de contato.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Novo campo: Chave Pix p/ Receber Doações
                  TextFormField(
                    controller: _pixController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco(
                      'Chave Pix p/ Receber Doações',
                      Icons.pix,
                      hint: 'CNPJ, CPF, E-mail, Celular ou Chave Aleatória',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Endereço e Mapa Interativo
                  InteractiveLocationPicker(
                    enderecoController: _enderecoController,
                    latitudeController: _latController,
                    longitudeController: _lngController,
                    labelEndereco: 'Endereço Completo do Abrigo',
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
          ),
        );
      },
    );
  }
}
