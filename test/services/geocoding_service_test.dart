import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:adotai_app/services/cep_service.dart';
import 'package:adotai_app/services/geocoding_service.dart';

void main() {
  group('GeocodingService (Nominatim)', () {
    test('deve converter o endereço completo em latitude/longitude', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'nominatim.openstreetmap.org');
        expect(request.url.queryParameters['q'], contains('Avenida Paulista'));
        expect(request.url.queryParameters['countrycodes'], 'br');

        return http.Response(
          '[{"lat":"-23.5614961","lon":"-46.6559677","display_name":"Avenida Paulista"}]',
          200,
        );
      });

      final service = GeocodingService(client: client);
      final point = await service.geocodeAddress(
        'Avenida Paulista, 1578, Bela Vista, São Paulo - SP',
      );

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-23.5614961, 0.0000001));
      expect(point.longitude, closeTo(-46.6559677, 0.0000001));
    });

    test('deve retornar null quando o endereço não é encontrado', () async {
      final client = MockClient((_) async => http.Response('[]', 200));

      final point = await GeocodingService(client: client)
          .geocodeAddress('Endereço Inexistente, 999');

      expect(point, isNull);
    });

    test('deve retornar null em caso de falha de rede', () async {
      final client = MockClient((_) async => throw Exception('sem rede'));

      final point = await GeocodingService(client: client)
          .geocodeAddress('Rua Qualquer, 10, Recife - PE');

      expect(point, isNull);
    });

    test('deve retornar null para endereço vazio', () async {
      final point = await GeocodingService(
        client: MockClient((_) async => http.Response('[]', 200)),
      ).geocodeAddress('   ');

      expect(point, isNull);
    });
  });

  group('CepService (fallback de coordenadas via BrasilAPI)', () {
    test('deve extrair as coordenadas do CEP quando disponíveis', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), contains('/api/cep/v2/01310100'));

        return http.Response(
          '{"cep":"01310100","location":{"type":"Point","coordinates":{"latitude":"-23.5475","longitude":"-46.63611"}}}',
          200,
        );
      });

      final point = await CepService(client: client).fetchCepCoordinates('01310-100');

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-23.5475, 0.0000001));
      expect(point.longitude, closeTo(-46.63611, 0.0000001));
    });

    test('deve retornar null quando o CEP não possui coordenadas', () async {
      final client = MockClient((_) async {
        return http.Response('{"cep":"01310100","location":{}}', 200);
      });

      final point = await CepService(client: client).fetchCepCoordinates('01310-100');

      expect(point, isNull);
    });

    test('deve retornar null para CEP inválido', () async {
      final point = await CepService(
        client: MockClient((_) async => http.Response('{}', 200)),
      ).fetchCepCoordinates('123');

      expect(point, isNull);
    });
  });
}
