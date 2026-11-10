import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Coordenada geográfica imutável (Functional Programming).
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({required this.latitude, required this.longitude});
}

/// Serviço de geocodificação de endereços usando Nominatim (OpenStreetMap).
///
/// Converte um endereço textual (CEP + número + complemento) em coordenadas,
/// para que o usuário não precise conhecer latitude/longitude.
class GeocodingService {
  final http.Client _client;

  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  /// Busca a primeira coordenada correspondente ao [address].
  ///
  /// Retorna `null` quando o endereço não é encontrado ou há falha de rede.
  Future<GeoPoint?> geocodeAddress(String address) async {
    final query = address.trim();
    if (query.isEmpty) return null;

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '1',
        'countrycodes': 'br',
        'addressdetails': '0',
      });

      // Em Flutter Web o navegador define o User-Agent automaticamente
      // (cabeçalho não permitido via JS). Fora da web, identificamos o app
      // conforme a política de uso do Nominatim.
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (!kIsWeb) 'User-Agent': 'adotai_app/1.0',
        },
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! List || data.isEmpty) return null;

      final first = data.first;
      if (first is! Map) return null;

      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;

      return GeoPoint(latitude: lat, longitude: lon);
    } catch (_) {
      // Falha silenciosa: o chamador pode usar uma coordenada de fallback.
      return null;
    }
  }
}
