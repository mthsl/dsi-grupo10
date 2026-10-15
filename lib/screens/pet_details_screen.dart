import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/favorite_service.dart';
// import 'edit_pet_screen.dart'; // Descomente quando a tela de edição estiver pronta

class PetDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> petData;
  final String petId;

  const PetDetailsScreen({
    super.key,
    required this.petData,
    required this.petId,
  });

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  
  // Variáveis para verificação de autoria (RBAC)
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get isOwner => widget.petData['voluntarioId'] == currentUserId;

  // Função para abrir o WhatsApp
  Future<void> _abrirWhatsApp(String telefone) async {
    final String nomePet = widget.petData['nome_busca'] ?? 'este pet';
    final String mensagem = "Olá! Tenho interesse em adotar o(a) $nomePet que vi no aplicativo Adotaí.";
    final String url = "https://wa.me/$telefone?text=${Uri.encodeComponent(mensagem)}";
    
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

  // Função para deletar o Pet do Firestore
  Future<void> _deletarPet() async {
    bool confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Excluir anúncio?', style: TextStyle(color: Colors.white)),
        content: const Text('Tem certeza que deseja remover este pet? Essa ação não pode ser desfeita.', style: TextStyle(color: Colors.white70)),
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
    ) ?? false;

    if (confirmar) {
      try {
        await FirebaseFirestore.instance.collection('pets').doc(widget.petId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pet excluído com sucesso!')),
          );
          Navigator.pop(context); // Volta para a tela anterior após excluir
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao excluir o pet. Verifique suas permissões.')),
          );
        }
      }
    }
  }

  // Widget construtor dos Badges (Sexo, Idade, Peso)
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
          Text(
            '$label: $value',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotoBase64 = widget.petData['fotoBase64'] ?? '';
    final abrigoId = widget.petData['abrigoId']; 

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        // Atualizado para nome_busca
        title: Text(widget.petData['nome_busca'] ?? 'Detalhes do Pet', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          StreamBuilder<bool>(
            stream: _favoriteService.isFavorite(widget.petId),
            builder: (context, snapshot) {
              bool isFavorited = snapshot.data ?? false;
              return IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  _favoriteService.toggleFavorite(widget.petId);
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('shelters').doc(abrigoId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          
          Map<String, dynamic>? abrigoData;
          if (snapshot.hasData && snapshot.data!.exists) {
            abrigoData = snapshot.data!.data() as Map<String, dynamic>;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Imagem do Pet (Base64)
                Container(
                  height: 300,
                  width: double.infinity,
                  color: const Color(0xFF1E1E1E),
                  child: fotoBase64.isNotEmpty
                      ? Image.memory(base64Decode(fotoBase64), fit: BoxFit.cover)
                      : const Icon(Icons.pets, size: 100, color: Colors.grey),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome e Raça (Atualizado para nome_busca)
                      Text(
                        widget.petData['nome_busca'] ?? 'Nome não informado',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.petData['raca'] ?? 'Raça não informada',
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      
                      // Badges de Características
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (widget.petData['sexo'] != null && widget.petData['sexo'].toString().isNotEmpty)
                            _buildBadge('Sexo', widget.petData['sexo'], Icons.transgender),
                          // Atualizado para faixa_etaria
                          if (widget.petData['faixa_etaria'] != null && widget.petData['faixa_etaria'].toString().isNotEmpty)
                            _buildBadge('Idade', widget.petData['faixa_etaria'], Icons.cake),
                          if (widget.petData['peso'] != null && widget.petData['peso'].toString().isNotEmpty)
                            _buildBadge('Peso', widget.petData['peso'], Icons.scale),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Bio / Descrição
                      const Text(
                        'Sobre mim',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.petData['descricao'] ?? widget.petData['bio'] ?? 'Nenhuma descrição disponível.',
                        style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Mapa do Abrigo via OpenStreetMap (flutter_map)
                      if (abrigoData != null && abrigoData['latitude'] != null && abrigoData['longitude'] != null) ...[
                        const Text(
                          'Localização do Abrigo',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          abrigoData['nome'] ?? 'Abrigo',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
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
                                initialCenter: LatLng(abrigoData['latitude'], abrigoData['longitude']),
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
                                      point: LatLng(abrigoData['latitude'], abrigoData['longitude']),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Controle de Acesso (RBAC): Botões de Ação Dinâmicos
                      if (!isOwner) ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            if (abrigoData != null && abrigoData['telefone'] != null && abrigoData['telefone'].toString().isNotEmpty) {
                              String foneSomenteNumeros = abrigoData['telefone'].toString().replaceAll(RegExp(r'\D'), '');
                              _abrirWhatsApp(foneSomenteNumeros);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Telefone do abrigo não cadastrado ou inválido.')),
                              );
                            }
                          },
                          icon: const Icon(Icons.chat, color: Colors.white),
                          label: const Text('Entrar em contato', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                                  /* Descomente quando a tela de edição estiver criada
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditPetScreen(petId: widget.petId, petData: widget.petData),
                                    ),
                                  );
                                  */
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
          );
        },
      ),
    );
  }
}