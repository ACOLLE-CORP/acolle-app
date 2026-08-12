import 'package:acolle1/services/emergencia_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizarNumeroWhatsApp', () {
    test('remove máscara e adiciona o código do Brasil a celular com DDD', () {
      expect(
        EmergenciaService.normalizarNumeroWhatsApp('(11) 98765-4321'),
        '5511987654321',
      );
    });

    test('preserva número que já contém código do país', () {
      expect(
        EmergenciaService.normalizarNumeroWhatsApp('+55 11 98765-4321'),
        '5511987654321',
      );
    });

    test('converte prefixo internacional 00', () {
      expect(
        EmergenciaService.normalizarNumeroWhatsApp('00 351 912 345 678'),
        '351912345678',
      );
    });
  });
}
