import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import 'pet_details_screen.dart';
// Descomente as importações abaixo quando tiver as telas de cadastro prontas
// import 'add_pet_screen.dart';
// import 'add_shelter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Variáveis de estado para os filtros avançados
  String? _filtroEspecie;
  String? _filtroPorte;
  String? _filtroSexo;
  String? _filtroIdade;

  bool _isVoluntario = false;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _verificarPapelUsuario();
  }

  // Verifica se o usuário logado é um Voluntário para exibir o botão flutuante (FAB)
  Future<void> _verificarPapelUsuario() async {
    if (currentUserId.isEmpty) return;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    
    if (userDoc.exists && userDoc.data().toString().contains('userType')) {
      setState(() {
        _isVoluntario = userDoc.get('userType') == 'Voluntário';
      });
    }
  }

  void _abrirModalFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
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
                  const Text('Espécie', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Cachorro', 'Gato', 'Outro'].map((especie) {
                      return ChoiceChip(
                        label: Text(especie),
                        selected: _filtroEspecie == especie,
                        onSelected: (bool selected) {
                          setModalState(() => _filtroEspecie = selected ? especie : null);
                        },
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: const Color(0xFF2A2A2A),
                        labelStyle: TextStyle(color: _filtroEspecie == especie ? Colors.white : Colors.white70),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Filtro de Porte
                  const Text('Porte', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Pequeno', 'Médio', 'Grande'].map((porte) {
                      return ChoiceChip(
                        label: Text(porte),
                        selected: _filtroPorte == porte,
                        onSelected: (bool selected) {
                          setModalState(() => _filtroPorte = selected ? porte : null);
                        },
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: const Color(0xFF2A2A2A),
                        labelStyle: TextStyle(color: _filtroPorte == porte ? Colors.white : Colors.white70),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Filtro de Sexo
                  const Text('Sexo', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Macho', 'Fêmea'].map((sexo) {
                      return ChoiceChip(
                        label: Text(sexo),
                        selected: _filtroSexo == sexo,
                        onSelected: (bool selected) {
                          setModalState(() => _filtroSexo = selected ? sexo : null);
                        },
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: const Color(0xFF2A2A2A),
                        labelStyle: TextStyle(color: _filtroSexo == sexo ? Colors.white : Colors.white70),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Filtro de Idade (Faixa Etária)
                  const Text('Idade', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Filhote', 'Adulto', 'Idoso'].map((idade) {
                      return ChoiceChip(
                        label: Text(idade),
                        selected: _filtroIdade == idade,
                        onSelected: (bool selected) {
                          setModalState(() => _filtroIdade = selected ? idade : null);
                        },
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: const Color(0xFF2A2A2A),
                        labelStyle: TextStyle(color: _filtroIdade == idade ? Colors.white : Colors.white70),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Botões de Ação do Modal
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _filtroEspecie = null;
                              _filtroPorte = null;
                              _filtroSexo = null;
                              _filtroIdade = null;
                            });
                            setState(() {}); 
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Limpar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); 
                            Navigator.pop(context); 
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Aplicar Filtros', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFiltrosAtivos() {
    List<Widget> chips = [];

    void adicionarChip(String? valor, VoidCallback onRemover) {
      if (valor != null) {
        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InputChip(
              label: Text(valor, style: const TextStyle(fontSize: 12, color: Colors.white)),
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              deleteIconColor: Colors.white70,
              onDeleted: () => setState(onRemover),
            ),
          ),
        );
      }
    }

    adicionarChip(_filtroEspecie, () => _filtroEspecie = null);
    adicionarChip(_filtroPorte, () => _filtroPorte = null);
    adicionarChip(_filtroSexo, () => _filtroSexo = null);
    adicionarChip(_filtroIdade, () => _filtroIdade = null);

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Construção Dinâmica da Query do Firestore
    Query petQuery = FirebaseFirestore.instance.collection('pets');

    // Sempre busca pets que estejam disponíveis
    petQuery = petQuery.where('status', isEqualTo: 'Disponível');

    if (_filtroEspecie != null) petQuery = petQuery.where('especie', isEqualTo: _filtroEspecie);
    if (_filtroPorte != null) petQuery = petQuery.where('porte', isEqualTo: _filtroPorte);
    if (_filtroSexo != null) petQuery = petQuery.where('sexo', isEqualTo: _filtroSexo);
    if (_filtroIdade != null) petQuery = petQuery.where('faixa_etaria', isEqualTo: _filtroIdade);

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
            // Barra de Pesquisa e Botão de Filtro
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase().trim();
                      });
                    },
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
            const Text(
              'Pets Disponíveis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            
            // Lista de Pets (StreamBuilder)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: petQuery.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.orange));
                  }
                  
                  if (snapshot.hasError) {
                    return const Center(child: Text('Erro ao carregar os pets.', style: TextStyle(color: Colors.white54)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Nenhum pet encontrado com esses filtros 🐾', style: TextStyle(color: Colors.white70)),
                    );
                  }

                  // Aplica o filtro de texto localmente (já que o Firestore não faz `contains` nativo)
                  final pets = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nomeBusca = (data['nome_busca'] ?? '').toString().toLowerCase();
                    return nomeBusca.contains(_searchQuery);
                  }).toList();

                  if (pets.isEmpty) {
                    return const Center(
                      child: Text('Nenhum pet encontrado com esse nome 🐾', style: TextStyle(color: Colors.white70)),
                    );
                  }

                  return ListView.builder(
                    itemCount: pets.length,
                    itemBuilder: (context, index) {
                      final petData = pets[index].data() as Map<String, dynamic>;
                      final petId = pets[index].id;
                      final String fotoBase64 = petData['fotoBase64'] ?? '';

                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PetDetailsScreen(petData: petData, petId: petId),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              // Imagem do Pet
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                child: fotoBase64.isNotEmpty
                                    ? Image.memory(
                                        base64Decode(fotoBase64),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.pets, color: Colors.white54, size: 40),
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
                                        petData['nome_busca'] ?? 'Sem nome',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        petData['raca'] ?? 'Raça não informada',
                                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        children: [
                                          if (petData['sexo'] != null)
                                            _buildMiniBadge(petData['sexo'], Icons.transgender),
                                          if (petData['faixa_etaria'] != null)
                                            _buildMiniBadge(petData['faixa_etaria'], Icons.cake),
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
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
      // Botão Flutuante Exclusivo para Voluntários
      floatingActionButton: _isVoluntario
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              onPressed: () {
                _mostrarMenuOpcoesVoluntario(context);
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // Pequeno badge visual para a lista do feed
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

  // Menu de opções (Adicionar Pet ou Abrigo)
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
                  /* Descomente quando tiver a tela pronta:
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetScreen()));
                  */
                },
              ),
              ListTile(
                leading: const Icon(Icons.home_work, color: Colors.white),
                title: const Text('Cadastrar Abrigo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  /* Descomente quando tiver a tela pronta:
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddShelterScreen()));
                  */
                },
              ),
            ],
          ),
        );
      },
    );
  }
}