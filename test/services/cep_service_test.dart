import 'package:flutter_test/flutter_test.dart';

import 'package:adotai_app/services/cep_service.dart';

void main() {
  const cepResult = CepResult(
    cep: '52221-305',
    logradouro: 'Rua Hercília de Medeiros',
    complemento: '',
    bairro: 'Cajueiro',
    localidade: 'Recife',
    uf: 'PE',
  );

  group('CepResult.composeAddress', () {
    test('deve colocar o número logo após o logradouro', () {
      expect(
        cepResult.composeAddress(numero: '78'),
        'Rua Hercília de Medeiros, 78, Cajueiro, Recife - PE',
      );
    });

    test('deve incluir o complemento após o número', () {
      expect(
        cepResult.composeAddress(numero: '78', complemento: 'Apto 12'),
        'Rua Hercília de Medeiros, 78 - Apto 12, Cajueiro, Recife - PE',
      );
    });

    test('deve montar o endereço sem número', () {
      expect(
        cepResult.composeAddress(),
        'Rua Hercília de Medeiros, Cajueiro, Recife - PE',
      );
    });

    test('deve incluir o complemento mesmo sem número', () {
      expect(
        cepResult.composeAddress(complemento: 'Bloco B'),
        'Rua Hercília de Medeiros, Bloco B, Cajueiro, Recife - PE',
      );
    });

    test('deve ignorar espaços em branco em número e complemento', () {
      expect(
        cepResult.composeAddress(numero: '  78  ', complemento: '   '),
        'Rua Hercília de Medeiros, 78, Cajueiro, Recife - PE',
      );
    });
  });
}
