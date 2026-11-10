import 'package:flutter/foundation.dart';

/// Modelo de domínio imutável para Perfil de Usuário.
///
/// Atende aos princípios:
/// - Functional Programming: Imutabilidade, copyWith, funções determinísticas.
/// - GRASP Information Expert: Sabe derivar se é voluntário, se possui coordenadas válidas, etc.
/// - SOLID SRP: Responsabilidade única de modelar o usuário do sistema.
@immutable
class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String whatsapp;
  final String address;
  final double latitude;
  final double longitude;
  final String userType;
  final List<String> favorites;

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.whatsapp = '',
    this.address = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.userType = 'Adotante',
    this.favorites = const [],
  });

  /// Information Expert: Sabe se o perfil possui privilégios de voluntário.
  bool get isVolunteer => userType.trim().toLowerCase() == 'voluntário';

  /// Information Expert: Sabe se o usuário favoritou um determinado pet.
  bool hasFavorite(String petId) => favorites.contains(petId);

  /// Verifica se possui coordenadas válidas para cálculo de proximidade.
  bool get hasValidCoordinates =>
      latitude != 0.0 &&
      longitude != 0.0 &&
      latitude >= -90.0 &&
      latitude <= 90.0 &&
      longitude >= -180.0 &&
      longitude <= 180.0;

  /// Retorna o número sanitizado apenas com dígitos.
  String get sanitizedWhatsApp => whatsapp.replaceAll(RegExp(r'[^0-9]'), '');

  /// Padrão Imutável: Retorna nova instância com alterações aplicadas.
  UserProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? whatsapp,
    String? address,
    double? latitude,
    double? longitude,
    String? userType,
    List<String>? favorites,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      whatsapp: whatsapp ?? this.whatsapp,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      userType: userType ?? this.userType,
      favorites: favorites != null ? List.unmodifiable(favorites) : this.favorites,
    );
  }

  /// Factory Method (GoF) / Creator (GRASP): Cria instância a partir de Map do Firestore.
  factory UserProfileModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
    }

    final rawFavorites = map['favorites'];
    List<String> parsedFavorites = [];
    if (rawFavorites is List) {
      parsedFavorites = rawFavorites.map((e) => e.toString()).toList();
    }

    return UserProfileModel(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      name: map['name'] ?? map['nome'] ?? '',
      email: map['email'] ?? '',
      whatsapp: map['whatsapp'] ?? map['phone'] ?? '',
      address: map['address'] ?? map['endereco'] ?? '',
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      userType: map['userType'] ?? 'Adotante',
      favorites: List.unmodifiable(parsedFavorites),
    );
  }

  /// Converte a entidade de domínio para Map compatível com o Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'whatsapp': whatsapp,
      'phone': whatsapp, // Garante interoperabilidade com legado
      'address': address,
      'endereco': address, // Garante interoperabilidade com legado
      'latitude': latitude,
      'longitude': longitude,
      'userType': userType,
      'favorites': favorites,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          userType == other.userType;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode;
}
