import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _nomeController = TextEditingController();
  final _racaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  String _especie = 'Cachorro';
  String _porte = 'Médio';
  String _faixaEtaria = 'Adulto';
  String _sexo = 'Macho';
  
  Uint8List? _imageBytes;
  bool _isLoading = false;

  List<Map<String, dynamic>> _abrigos = [];
  Map<String, dynamic>? _abrigoSelecionado;

  final List<String> _especies = ['Cachorro', 'Gato', 'Outro'];
  final List<String> _portes = ['Pequeno', 'Médio', 'Grande'];
  final List<String> _idades = ['Filhote', 'Adulto', 'Idoso'];
  final List<String> _sexos = ['Macho', 'Fêmea'];

  @override
  void initState() {
    super.initState();
    _carregarAbrigos();
  }

  Future<void> _carregarAbrigos() async {
    final snapshot = await FirebaseFirestore.instance.collection('shelters').get();
    setState(() {
      _abrigos = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      if (_abrigos.isNotEmpty) {
        _abrigoSelecionado = _abrigos.first;
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxWidth: 600,
    );
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _salvarPet() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome do animal.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      String fotoBase64 = '';

      if (_imageBytes != null) {
        fotoBase64 = base64Encode(_imageBytes!);
      }

      await FirebaseFirestore.instance.collection('pets').add({
        'nome_busca': _nomeController.text.trim().toLowerCase(),
        'raca': _racaController.text.trim(),
        'peso': _pesoController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'especie': _especie,
        'porte': _porte,
        'faixa_etaria': _faixaEtaria,
        'sexo': _sexo,
        'status': 'Disponível',
        'voluntarioId': user?.uid,
        'fotoBase64': fotoBase64,
        'abrigoId': _abrigoSelecionado?['id'],
        'abrigoNome': _abrigoSelecionado?['nome'],
        'abrigoTelefone': _abrigoSelecionado?['telefone'] ?? '',
        'abrigoLat': _abrigoSelecionado?['latitude'],
        'abrigoLng': _abrigoSelecionado?['longitude'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Animal cadastrado com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao cadastrar. Tente uma foto menor.')));
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
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  image: _imageBytes != null 
                    ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover) 
                    : null,
                ),
                child: _imageBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.white70, size: 40),
                          SizedBox(height: 8),
                          Text('Adicionar Foto', style: TextStyle(color: Colors.white70)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nomeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nome do Pet', 
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _racaController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Raça', 
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pesoController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Peso (kg)', 
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descricaoController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Descrição/Bio', 
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),
            _buildDropdown('Espécie', _especies, _especie, (val) => setState(() => _especie = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Porte', _portes, _porte, (val) => setState(() => _porte = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Faixa Etária', _idades, _faixaEtaria, (val) => setState(() => _faixaEtaria = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Sexo', _sexos, _sexo, (val) => setState(() => _sexo = val!)),
            const SizedBox(height: 16),
            if (_abrigos.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Abrigo de Destino', style: TextStyle(color: Colors.white70)),
                  DropdownButton<Map<String, dynamic>>(
                    value: _abrigoSelecionado,
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    underline: Container(height: 1, color: Colors.white24),
                    items: _abrigos.map((abrigo) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: abrigo,
                        child: Text(abrigo['nome'] ?? 'Abrigo sem nome'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _abrigoSelecionado = val),
                  ),
                ],
              ),
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
                  : const Text('Salvar Cadastro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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