import 'package:flutter/foundation.dart';

/// Modelo de domínio imutável para Pet.
///
/// Atende aos princípios:
/// - Functional Programming: Imutabilidade (@immutable, campos final, copyWith, funções puras).
/// - GRASP Information Expert: É especialista nas próprias informações (busca, elegibilidade, formatação).
/// - SOLID SRP: Responsabilidade única de representar a entidade de negócio Pet.
@immutable
class PetModel {
  final String id;
  final String nome;
  final String especie;
  final String raca;
  final String porte;
  final String sexo;
  final String faixaEtaria;
  final String peso;
  final String descricao;
  final String fotoBase64;
  final String abrigoId;
  final String voluntarioId;
  final String status;
  final DateTime? dataCadastro;

  const PetModel({
    required this.id,
    required this.nome,
    required this.especie,
    required this.raca,
    required this.porte,
    required this.sexo,
    required this.faixaEtaria,
    this.peso = '',
    this.descricao = '',
    this.fotoBase64 = '',
    this.abrigoId = '',
    this.voluntarioId = '',
    this.status = 'Disponível',
    this.dataCadastro,
  });

  /// Verifica se o pet está disponível para adoção (Information Expert).
  bool get isDisponivel => status.trim().toLowerCase() == 'disponível';

  /// Verifica se o usuário informado é o tutor/cadastrador (Information Expert).
  bool isOwnedBy(String userId) => voluntarioId.isNotEmpty && voluntarioId == userId;

  /// Função pura de correspondência com consulta textual (Functional Programming).
  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    final normalized = query.trim().toLowerCase();
    final matchNome = nome.toLowerCase().contains(normalized);
    final matchRaca = raca.toLowerCase().contains(normalized);
    final matchEspecie = especie.toLowerCase().contains(normalized);
    return matchNome || matchRaca || matchEspecie;
  }

  /// Padrão Imutável: Cria uma nova instância com valores alterados (Functional Programming).
  PetModel copyWith({
    String? id,
    String? nome,
    String? especie,
    String? raca,
    String? porte,
    String? sexo,
    String? faixaEtaria,
    String? peso,
    String? descricao,
    String? fotoBase64,
    String? abrigoId,
    String? voluntarioId,
    String? status,
    DateTime? dataCadastro,
  }) {
    return PetModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      especie: especie ?? this.especie,
      raca: raca ?? this.raca,
      porte: porte ?? this.porte,
      sexo: sexo ?? this.sexo,
      faixaEtaria: faixaEtaria ?? this.faixaEtaria,
      peso: peso ?? this.peso,
      descricao: descricao ?? this.descricao,
      fotoBase64: fotoBase64 ?? this.fotoBase64,
      abrigoId: abrigoId ?? this.abrigoId,
      voluntarioId: voluntarioId ?? this.voluntarioId,
      status: status ?? this.status,
      dataCadastro: dataCadastro ?? this.dataCadastro,
    );
  }

  /// Factory Method (GoF) / Creator (GRASP): Cria instância a partir de Map do Firestore.
  factory PetModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return PetModel(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      nome: map['nome_busca'] ?? map['nome'] ?? 'Sem nome',
      especie: map['especie'] ?? 'Outro',
      raca: map['raca'] ?? 'Não informada',
      porte: map['porte'] ?? 'Médio',
      sexo: map['sexo'] ?? 'Indefinido',
      faixaEtaria: map['faixa_etaria'] ?? map['idade'] ?? 'Adulto',
      peso: (map['peso'] ?? '').toString(),
      descricao: map['descricao'] ?? map['bio'] ?? '',
      fotoBase64: map['fotoBase64'] ?? '',
      abrigoId: map['abrigoId'] ?? '',
      voluntarioId: map['voluntarioId'] ?? '',
      status: map['status'] ?? 'Disponível',
      dataCadastro: map['dataCadastro'] != null
          ? (map['dataCadastro'] is DateTime
              ? map['dataCadastro'] as DateTime
              : DateTime.tryParse(map['dataCadastro'].toString()))
          : null,
    );
  }

  /// Converte a entidade de domínio para Map compatível com o Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nome_busca': nome,
      'especie': especie,
      'raca': raca,
      'porte': porte,
      'sexo': sexo,
      'faixa_etaria': faixaEtaria,
      'peso': peso,
      'descricao': descricao,
      'fotoBase64': fotoBase64,
      'abrigoId': abrigoId,
      'voluntarioId': voluntarioId,
      'status': status,
      if (dataCadastro != null) 'dataCadastro': dataCadastro!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          especie == other.especie &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ nome.hashCode ^ status.hashCode;
}
