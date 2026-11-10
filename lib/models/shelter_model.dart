import 'package:flutter/foundation.dart';

/// Modelo de domínio imutável para Abrigo.
///
/// Atende aos princípios:
/// - Functional Programming: Imutabilidade (@immutable, campos final, copyWith, funções puras).
/// - GRASP Information Expert: Especialista nos dados de geolocalização e contato do abrigo.
/// - SOLID SRP: Responsabilidade única de representar o Abrigo.
@immutable
class ShelterModel {
  final String id;
  final String nome;
  final String endereco;
  final double latitude;
  final double longitude;
  final String telefone;

  const ShelterModel({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    required this.telefone,
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

  /// Padrão Imutável: Cria uma nova instância com valores alterados (Functional Programming).
  ShelterModel copyWith({
    String? id,
    String? nome,
    String? endereco,
    double? latitude,
    double? longitude,
    String? telefone,
  }) {
    return ShelterModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      endereco: endereco ?? this.endereco,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      telefone: telefone ?? this.telefone,
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
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShelterModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => id.hashCode ^ nome.hashCode ^ latitude.hashCode;
}
