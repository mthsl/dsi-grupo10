import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pet_model.dart';
import '../models/shelter_model.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../repositories/interfaces/pet_repository.dart';
import '../repositories/interfaces/shelter_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firebase_pet_repository.dart';
import '../repositories/firebase/firebase_shelter_repository.dart';
import '../services/favorite_service.dart';
import 'edit_pet_screen.dart';

/// Tela de Detalhes do Pet (View pura - SRP / DIP).
///
/// Refatorada para receber modelo de domínio PetModel, utilizar repositórios
/// abstratos para carregar dados do abrigo e deletar o anúncio,
/// e permitir editar via EditPetScreen.
class PetDetailsScreen extends StatefulWidget {
  final PetModel pet;
  final IPetRepository? petRepository;
  final IShelterRepository? shelterRepository;
  final IAuthRepository? authRepository;

  PetDetailsScreen({
    super.key,
    PetModel? pet,
    Map<String, dynamic>? petData,
    String? petId,
    this.petRepository,
    this.shelterRepository,
    this.authRepository,
  }) : pet = pet ??
            PetModel.fromMap(
              petData ?? const {},
              id: petId ?? (petData?['id'] ?? ''),
            );

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  late final IPetRepository _petRepository;
  late final IShelterRepository _shelterRepository;
  late final IAuthRepository _authRepository;
  late final FavoriteService _favoriteService;

  ShelterModel? _shelter;
  bool _isLoadingShelter = true;

  @override
  void initState() {
    super.initState();
    _petRepository = widget.petRepository ?? FirebasePetRepository();
    _shelterRepository = widget.shelterRepository ?? FirebaseShelterRepository();
    _authRepository = widget.authRepository ?? FirebaseAuthRepository();
    _favoriteService = FavoriteService(
      petRepository: _petRepository,
      authRepository: _authRepository,
    );
    _loadShelter();
  }

  bool get _isOwner => widget.pet.isOwnedBy(_authRepository.currentUserId ?? '');

  Future<void> _loadShelter() async {
    if (widget.pet.abrigoId.isEmpty) {
      if (mounted) setState(() => _isLoadingShelter = false);
      return;
    }

    try {
      final shelter = await _shelterRepository.getShelterById(widget.pet.abrigoId);
      if (mounted) {
        setState(() {
          _shelter = shelter;
          _isLoadingShelter = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingShelter = false);
    }
  }

  Future<void> _abrirWhatsApp(String telefone) async {
    final nomePet = widget.pet.nome.isNotEmpty ? widget.pet.nome : 'este pet';
    final mensagem = "Olá! Tenho interesse em adotar o(a) $nomePet que vi no aplicativo Adotaí.";
    final cleanPhone = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(mensagem)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    }
  }

  Future<void> _deletarPet() async {
    final bool confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Excluir anúncio?', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Tem certeza que deseja remover este pet? Essa ação não pode ser desfeita.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    try {
      await _petRepository.deletePet(widget.pet.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet excluído com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir o pet.')),
        );
      }
    }
  }

  Widget _buildBadge(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Text(pet.nome, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          StreamBuilder<bool>(
            stream: _favoriteService.isFavorite(pet.id),
            builder: (context, snapshot) {
              final isFavorited = snapshot.data ?? false;
              return IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red : Colors.white,
                ),
                onPressed: () => _favoriteService.toggleFavorite(pet.id),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Foto do Pet
            Container(
              height: 300,
              width: double.infinity,
              color: const Color(0xFF1E1E1E),
              child: pet.fotoBase64.isNotEmpty
                  ? Image.memory(
                      base64Decode(pet.fotoBase64),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 100, color: Colors.grey),
                    )
                  : const Icon(Icons.pets, size: 100, color: Colors.grey),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.nome,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet.raca,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),

                  // Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (pet.sexo.isNotEmpty) _buildBadge('Sexo', pet.sexo, Icons.transgender),
                      if (pet.faixaEtaria.isNotEmpty) _buildBadge('Idade', pet.faixaEtaria, Icons.cake),
                      if (pet.porte.isNotEmpty) _buildBadge('Porte', pet.porte, Icons.straighten),
                      if (pet.peso.isNotEmpty) _buildBadge('Peso', pet.peso, Icons.scale),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Sobre mim',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pet.descricao.isNotEmpty ? pet.descricao : 'Nenhuma descrição fornecida.',
                    style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Seção do Abrigo e Mapa
                  if (_isLoadingShelter)
                    const Center(child: CircularProgressIndicator(color: Colors.orange))
                  else if (_shelter != null) ...[
                    const Text(
                      'Localização do Abrigo',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _shelter!.nome,
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                    if (_shelter!.endereco.isNotEmpty)
                      Text(_shelter!.endereco, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    const SizedBox(height: 12),

                    if (_shelter!.hasValidCoordinates)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(_shelter!.latitude, _shelter!.longitude),
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.adotai_app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(_shelter!.latitude, _shelter!.longitude),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 32),

                  // Ações: Contatar ou Editar/Deletar se for proprietário
                  if (!_isOwner) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        final phone = _shelter?.telefone ?? '';
                        if (phone.isNotEmpty) {
                          _abrirWhatsApp(phone);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Telefone do abrigo não cadastrado.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text(
                        'Entrar em contato',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPetScreen(pet: pet),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text('Editar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _deletarPet,
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text('Deletar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
