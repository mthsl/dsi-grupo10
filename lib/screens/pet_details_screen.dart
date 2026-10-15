import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_pet_screen.dart';

class PetDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> petData;
  final String petId;

  const PetDetailsScreen({super.key, required this.petData, required this.petId});

  Future<void> _deletarAnuncio(BuildContext context) async {
    await FirebaseFirestore.instance.collection('pets').doc(petId).delete();
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anúncio removido!')));
    }
  }

  Future<void> _entrarEmContato(BuildContext context) async {
    String telefone = petData['abrigoTelefone'] ?? '';

    if (telefone.isEmpty && petData['abrigoId'] != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('shelters').doc(petData['abrigoId']).get();
        telefone = doc.data()?['telefone'] ?? '';
      } catch (e) {
        // Ignora erro de busca
      }
    }

    telefone = telefone.replaceAll(RegExp(r'[^0-9]'), '');

    if (telefone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este abrigo ainda não cadastrou um WhatsApp.')));
      }
      return;
    }

    final Uri url = Uri.parse('https://wa.me/55$telefone?text=Olá! Tenho interesse em adotar o pet ${petData['nome_busca']}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String nome = petData['nome_busca'] ?? 'Sem nome';
    String raca = petData['raca'] ?? 'SRD';
    String peso = petData['peso'] ?? '--';
    String descricao = petData['descricao'] ?? 'Sem descrição disponível.';
    String fotoBase64 = petData['fotoBase64'] ?? '';
    String abrigoNome = petData['abrigoNome'] ?? 'Abrigo não informado';
    double lat = (petData['abrigoLat'] ?? 0).toDouble();
    double lng = (petData['abrigoLng'] ?? 0).toDouble();
    bool hasLocation = lat != 0 && lng != 0;
    
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    bool isOwner = petData['voluntarioId'] == currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 350,
              width: double.infinity,
              color: Colors.grey[900],
              child: fotoBase64.isNotEmpty
                  ? Image.memory(base64Decode(fotoBase64), fit: BoxFit.cover)
                  : const Icon(Icons.pets, size: 100, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      _buildBadge(petData['sexo'] ?? 'Macho', Colors.blueGrey),
                      const SizedBox(width: 8),
                      _buildBadge(petData['faixa_etaria'] ?? 'Idade', Colors.orangeAccent),
                      const SizedBox(width: 8),
                      _buildBadge('${peso}kg', Colors.purpleAccent),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    descricao,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Localização', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(abrigoNome, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  if (hasLocation)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 15.0),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                            MarkerLayer(markers: [Marker(point: LatLng(lat, lng), width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 40))]),
                          ],
                        ),
                      ),
                    ),
                    
                  const SizedBox(height: 40),
                  
                  isOwner
                      ? Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => EditPetScreen(petData: petData, petId: petId)),
                                  );
                                },
                                icon: const Icon(Icons.edit, color: Colors.white),
                                label: const Text('Editar', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _deletarAnuncio(context),
                                icon: const Icon(Icons.delete, color: Colors.white),
                                label: const Text('Deletar', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: ElevatedButton.icon(
                            onPressed: () => _entrarEmContato(context),
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: const Text('Entrar em contato', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}