import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PetDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> petData;

  const PetDetailsScreen({super.key, required this.petData});

  @override
  Widget build(BuildContext context) {
    String nome = petData['nome_busca'] ?? 'Sem nome';
    String especie = petData['especie'] ?? 'Desconhecido';
    String porte = petData['porte'] ?? 'Desconhecido';
    String faixaEtaria = petData['faixa_etaria'] ?? 'Desconhecido';
    String fotoBase64 = petData['fotoBase64'] ?? '';
    String abrigoNome = petData['abrigoNome'] ?? 'Abrigo não informado';
    double lat = (petData['abrigoLat'] ?? 0).toDouble();
    double lng = (petData['abrigoLng'] ?? 0).toDouble();
    bool hasLocation = lat != 0 && lng != 0;

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
              height: 300,
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
                  const SizedBox(height: 8),
                  Text(
                    '$especie • $porte • $faixaEtaria',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const Text('Localização', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(abrigoNome, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 16),
                  if (hasLocation)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(lat, lng),
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(lat, lng),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}