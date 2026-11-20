import 'package:flutter/foundation.dart';

/// Modelo de domínio imutável para Abrigo.
///
/// Atende aos princípios:
/// - Functional Programming: Imutabilidade (@immutable, campos final, copyWith, funções puras).
/// - GRASP Information Expert: Especialista nos dados de geolocalização, Pix e contato do abrigo.
/// - SOLID SRP: Responsabilidade única de representar o Abrigo.
@immutable
class ShelterModel {
  final String id;
  final String nome;
  final String endereco;
  final double latitude;
  final double longitude;
  final String telefone;
  final String chavePix;
  final String criadorId;

  const ShelterModel({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    required this.telefone,
    this.chavePix = '',
    this.criadorId = '',
  });

  /// Verifica se possui coordenadas geográficas válidas (Information Expert).
  bool get hasValidCoordinates =>
      latitude != 0.0 &&
      longitude != 0.0 &&
      latitude >= -90.0 &&
      latitude <= 90.0 &&
      longitude >= -180.0 &&
      longitude <= 180.0;

  /// Retorna o número de WhatsApp formatado/sanitizado (Pure Function).
  String get sanitizedPhone => telefone.replaceAll(RegExp(r'[^0-9]'), '');

  /// Verifica se o usuário informado é o criador deste abrigo (Information Expert).
  bool isCreatedBy(String userId) => criadorId.isNotEmpty && criadorId == userId;

  /// Verifica se o abrigo possui chave Pix cadastrada.
  bool get hasPix => chavePix.trim().isNotEmpty;

  /// Padrão Imutável: Cria uma nova instância com valores alterados (Functional Programming).
  ShelterModel copyWith({
    String? id,
    String? nome,
    String? endereco,
    double? latitude,
    double? longitude,
    String? telefone,
    String? chavePix,
    String? criadorId,
  }) {
    return ShelterModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      endereco: endereco ?? this.endereco,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      telefone: telefone ?? this.telefone,
      chavePix: chavePix ?? this.chavePix,
      criadorId: criadorId ?? this.criadorId,
    );
  }

  /// Factory Method (GoF) / Creator (GRASP): Cria instância a partir de Map do Firestore.
  factory ShelterModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
    }

    return ShelterModel(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      nome: map['nome'] ?? 'Sem nome',
      endereco: map['endereco'] ?? '',
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      telefone: map['telefone'] ?? map['whatsapp'] ?? '',
      chavePix: map['chavePix'] ?? map['pix'] ?? '',
      criadorId: map['criadorId'] ?? map['voluntarioId'] ?? map['userId'] ?? '',
    );
  }

  /// Converte a entidade de domínio para Map compatível com o Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'endereco': endereco,
      'latitude': latitude,
      'longitude': longitude,
      'telefone': telefone,
      'chavePix': chavePix,
      'criadorId': criadorId,
      'voluntarioId': criadorId, // Compatibilidade com consultas legadas
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShelterModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          chavePix == other.chavePix &&
          criadorId == other.criadorId &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      id.hashCode ^
      nome.hashCode ^
      chavePix.hashCode ^
      criadorId.hashCode ^
      latitude.hashCode;
}
