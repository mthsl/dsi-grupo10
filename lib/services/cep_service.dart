import 'dart:convert';
import 'package:http/http.dart' as http;
import 'geocoding_service.dart';

/// Resultado da consulta de endereço por CEP.
class CepResult {
  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String localidade;
  final String uf;

  const CepResult({
    required this.cep,
    required this.logradouro,
    required this.complemento,
    required this.bairro,
    required this.localidade,
    required this.uf,
  });

  /// Endereço formatado legível.
  String get formattedAddress {
    final parts = [
      if (logradouro.isNotEmpty) logradouro,
      if (bairro.isNotEmpty) bairro,
      if (localidade.isNotEmpty && uf.isNotEmpty) '$localidade - $uf',
      if (cep.isNotEmpty) 'CEP $cep',
    ];
    return parts.join(', ');
  }

  /// Compõe o endereço completo no formato usado pela geocodificação:
  /// `Logradouro, Número - Complemento, Bairro, Cidade - UF`.
  ///
  /// O número precisa vir logo após o logradouro para que serviços como o
  /// Nominatim localizem corretamente o ponto no mapa.
  String composeAddress({String numero = '', String complemento = ''}) {
    final trimmedNumero = numero.trim();
    final trimmedComplemento = complemento.trim();
    final buffer = StringBuffer();

    if (logradouro.isNotEmpty) buffer.write(logradouro);

    if (trimmedNumero.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write(trimmedNumero);
    }

    if (trimmedComplemento.isNotEmpty) {
      if (trimmedNumero.isNotEmpty) {
        buffer.write(' - $trimmedComplemento');
      } else {
        if (buffer.isNotEmpty) buffer.write(', ');
        buffer.write(trimmedComplemento);
      }
    }

    if (bairro.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write(bairro);
    }

    if (localidade.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write(uf.isNotEmpty ? '$localidade - $uf' : localidade);
    }

    return buffer.toString();
  }

  factory CepResult.fromMap(Map<String, dynamic> map) {
    return CepResult(
      cep: map['cep'] ?? '',
      logradouro: map['logradouro'] ?? '',
      complemento: map['complemento'] ?? '',
      bairro: map['bairro'] ?? '',
      localidade: map['localidade'] ?? '',
      uf: map['uf'] ?? '',
    );
  }
}

/// Serviço para busca automática de endereço por CEP (ViaCEP).
class CepService {
  final http.Client _client;

  CepService({http.Client? client}) : _client = client ?? http.Client();

  /// Consulta os dados do CEP na API pública ViaCEP.
  Future<CepResult?> fetchCep(String rawCep) async {
    final cleanCep = rawCep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return null;

    try {
      final uri = Uri.parse('https://viacep.com.br/ws/$cleanCep/json/');
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['erro'] != true) {
          return CepResult.fromMap(data);
        }
      }
    } catch (_) {
      // Falha silenciosa em caso de ausência de rede
    }
    return null;
  }

  /// Obtém as coordenadas aproximadas do CEP via BrasilAPI (fallback).
  ///
  /// Usado quando a geocodificação pelo endereço completo não encontra resultado.
  Future<GeoPoint?> fetchCepCoordinates(String rawCep) async {
    final cleanCep = rawCep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return null;

    try {
      final uri = Uri.parse('https://brasilapi.com.br/api/cep/v2/$cleanCep');
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final location = data['location'];
          if (location is Map) {
            final coordinates = location['coordinates'];
            if (coordinates is Map) {
              final lat = double.tryParse(coordinates['latitude']?.toString() ?? '');
              final lng = double.tryParse(coordinates['longitude']?.toString() ?? '');
              if (lat != null && lng != null) {
                return GeoPoint(latitude: lat, longitude: lng);
              }
            }
          }
        }
      }
    } catch (_) {
      // Falha silenciosa em caso de ausência de rede
    }
    return null;
  }
}
