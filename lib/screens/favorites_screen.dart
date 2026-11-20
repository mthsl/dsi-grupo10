import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/favorite_service.dart';
import 'pet_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FavoriteService favoriteService = FavoriteService();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Meus Favoritos', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: favoriteService.getFavoritePets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar favoritos.', style: TextStyle(color: Colors.white)));
          }

          List<Map<String, dynamic>> favoritePets = snapshot.data ?? [];

          if (favoritePets.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum pet favoritado ainda 🐾',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: favoritePets.length,
            itemBuilder: (context, index) {
              final pet = favoritePets[index];
              final String fotoBase64 = pet['fotoBase64'] ?? '';
              final String petId = pet['id'];

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: fotoBase64.isNotEmpty ? MemoryImage(base64Decode(fotoBase64)) : null,
                    backgroundColor: Colors.grey,
                    child: fotoBase64.isEmpty ? const Icon(Icons.pets, color: Colors.white) : null,
                  ),
                  // Correção: Atualizado para buscar a chave 'nome_busca'
                  title: Text(pet['nome_busca'] ?? 'Sem nome', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(pet['raca'] ?? 'Raça não informada', style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => favoriteService.toggleFavorite(petId), // Remove dos favoritos com um clique
                  ),
                  // Correção: Adicionada a navegação para a tela de detalhes ao clicar no card
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetDetailsScreen(
                          petData: pet,
                          petId: petId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}