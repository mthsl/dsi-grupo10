import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/shelter_model.dart';

/// Tela de Detalhes do Abrigo (View pura - SRP).
///
/// Exibe todas as informações públicas de um abrigo: nome, endereço,
/// contato, chave Pix para doações e localização no mapa.
class ShelterDetailsScreen extends StatelessWidget {
  final ShelterModel shelter;

  const ShelterDetailsScreen({super.key, required this.shelter});

  Future<void> _abrirWhatsApp(BuildContext context) async {
    final telefone = shelter.sanitizedPhone;
    if (telefone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefone do abrigo não cadastrado.')),
      );
      return;
    }

    final mensagem = 'Olá! Gostaria de saber mais sobre o abrigo ${shelter.nome}.';
    final url = Uri.parse(
      'https://wa.me/$telefone?text=${Uri.encodeComponent(mensagem)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    }
  }

  void _copiarChavePix(BuildContext context) {
    Clipboard.setData(ClipboardData(text: shelter.chavePix));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chave Pix copiada: ${shelter.chavePix}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildMapa() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localização',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(shelter.latitude, shelter.longitude),
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.adotai_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(shelter.latitude, shelter.longitude),
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.redAccent,
                        size: 44,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Coordenadas: ${shelter.latitude.toStringAsFixed(6)}, '
          '${shelter.longitude.toStringAsFixed(6)}',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Abrigo', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho do abrigo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.home_work,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shelter.nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Abrigo parceiro do Adotaí',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Informações do Abrigo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            _infoTile(
              icon: Icons.location_on_outlined,
              label: 'Endereço',
              value: shelter.endereco.isNotEmpty
                  ? shelter.endereco
                  : 'Endereço não informado.',
            ),
            _infoTile(
              icon: Icons.phone_android,
              label: 'WhatsApp / Telefone',
              value: shelter.telefone.isNotEmpty
                  ? shelter.telefone
                  : 'Contato não informado.',
              trailing: shelter.telefone.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.chat, color: Colors.greenAccent),
                      tooltip: 'Chamar no WhatsApp',
                      onPressed: () => _abrirWhatsApp(context),
                    )
                  : null,
            ),
            _infoTile(
              icon: Icons.pix,
              label: 'Chave Pix para doações',
              value: shelter.hasPix
                  ? shelter.chavePix
                  : 'Chave Pix não cadastrada.',
              trailing: shelter.hasPix
                  ? IconButton(
                      icon: const Icon(Icons.copy, color: Colors.greenAccent),
                      tooltip: 'Copiar Chave Pix',
                      onPressed: () => _copiarChavePix(context),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // Ações principais
            if (shelter.telefone.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => _abrirWhatsApp(context),
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text(
                  'Entrar em contato',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            if (shelter.hasPix) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _copiarChavePix(context),
                icon: const Icon(Icons.pix, color: Colors.greenAccent),
                label: const Text(
                  'Copiar chave Pix',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: Colors.greenAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            if (shelter.hasValidCoordinates) _buildMapa(),
          ],
        ),
      ),
    );
  }
}
