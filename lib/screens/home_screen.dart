import 'dart:convert';
import 'package:flutter/material.dart';
import '../controllers/home_controller.dart';
import '../models/pet_model.dart';
import 'add_pet_screen.dart';
import 'add_shelter_screen.dart';
import 'pet_details_screen.dart';

/// Tela Principal (View pura - SRP / GRASP High Cohesion).
///
/// Responsabilidades:
/// - Exibir layout visual e receber toques do usuário.
/// - Delegar regras de negócio, filtragem e persistência ao HomeController.
class HomeScreen extends StatefulWidget {
  final HomeController? controller;

  const HomeScreen({super.key, this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? HomeController();
    _controller.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _abrirModalFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros Avançados',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filtro de Espécie
                  _buildSectionTitle('Espécie'),
                  _buildFilterOptions(
                    options: ['Cachorro', 'Gato', 'Outro'],
                    selected: _controller.selectedSpecies,
                    onSelected: (val) {
                      setModalState(() => _controller.setSpeciesFilter(val));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filtro de Porte
                  _buildSectionTitle('Porte'),
                  _buildFilterOptions(
                    options: ['Pequeno', 'Médio', 'Grande'],
                    selected: _controller.selectedSize,
                    onSelected: (val) {
                      setModalState(() => _controller.setSizeFilter(val));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filtro de Sexo
                  _buildSectionTitle('Sexo'),
                  _buildFilterOptions(
                    options: ['Macho', 'Fêmea'],
                    selected: _controller.selectedGender,
                    onSelected: (val) {
                      setModalState(() => _controller.setGenderFilter(val));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filtro de Idade
                  _buildSectionTitle('Idade'),
                  _buildFilterOptions(
                    options: ['Filhote', 'Adulto', 'Idoso'],
                    selected: _controller.selectedAge,
                    onSelected: (val) {
                      setModalState(() => _controller.setAgeFilter(val));
                    },
                  ),
                  const SizedBox(height: 28),

                  // Ações do Modal
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() => _controller.clearAllFilters());
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Limpar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Aplicar Filtros', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildFilterOptions({
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (bool sel) => onSelected(sel ? opt : null),
          selectedColor: Theme.of(context).colorScheme.primary,
          backgroundColor: const Color(0xFF2A2A2A),
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
        );
      }).toList(),
    );
  }

  Widget _buildFiltrosAtivos() {
    final active = _controller.activeFilters;
    if (active.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: active.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InputChip(
                label: Text(entry.value, style: const TextStyle(fontSize: 12, color: Colors.white)),
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                deleteIconColor: Colors.white70,
                onDeleted: () => _controller.removeFilter(entry.key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final pets = _controller.filteredPets;

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            title: const Text('Adotaí', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo de Busca e Botão de Filtro
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nome, raça ou espécie...',
                          hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        ),
                        onChanged: (val) => _controller.setSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                        onPressed: _abrirModalFiltros,
                      ),
                    ),
                  ],
                ),

                _buildFiltrosAtivos(),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pets Disponíveis',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '${pets.length} encontrados',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lista de Pets Renderizada
                Expanded(
                  child: _buildPetsContent(pets),
                ),
              ],
            ),
          ),

          // Botão Flutuante (Exclusivo para voluntários)
          floatingActionButton: _controller.isVolunteer
              ? FloatingActionButton(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  onPressed: () => _mostrarMenuOpcoesVoluntario(context),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  Widget _buildPetsContent(List<PetModel> pets) {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_controller.errorMessage != null) {
      return Center(
        child: Text(
          _controller.errorMessage!,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    if (pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 56, color: Colors.white24),
            const SizedBox(height: 12),
            const Text(
              'Nenhum pet encontrado com esses filtros 🐾',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _controller.clearAllFilters();
              },
              child: const Text('Limpar todos os filtros', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: pets.length,
      itemBuilder: (context, index) {
        final pet = pets[index];
        return _buildPetCard(pet);
      },
    );
  }

  Widget _buildPetCard(PetModel pet) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetDetailsScreen(pet: pet),
            ),
          );
        },
        child: Row(
          children: [
            // Imagem do Pet (Decodificada com tratamento de erro)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: pet.fotoBase64.isNotEmpty
                  ? Image.memory(
                      base64Decode(pet.fotoBase64),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[850],
                        child: const Icon(Icons.pets, color: Colors.white38, size: 40),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[850],
                      child: const Icon(Icons.pets, color: Colors.white38, size: 40),
                    ),
            ),

            // Informações do Pet
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.nome,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.raca,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (pet.sexo.isNotEmpty) _buildMiniBadge(pet.sexo, Icons.transgender),
                        if (pet.faixaEtaria.isNotEmpty) _buildMiniBadge(pet.faixaEtaria, Icons.cake),
                        if (pet.porte.isNotEmpty) _buildMiniBadge(pet.porte, Icons.straighten),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  void _mostrarMenuOpcoesVoluntario(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.pets, color: Colors.white),
                title: const Text('Cadastrar Animal', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.home_work, color: Colors.white),
                title: const Text('Cadastrar Abrigo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddShelterScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
