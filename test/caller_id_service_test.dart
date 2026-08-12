import 'package:acolle1/services/caller_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizarNumero', () {
    test('normaliza telefone brasileiro com máscara', () {
      expect(
        CallerIdService.normalizarNumero('(11) 98765-4321'),
        '5511987654321',
      );
    });

    test('preserva o código do país existente', () {
      expect(
        CallerIdService.normalizarNumero('+55 11 98765-4321'),
        '5511987654321',
      );
    });

    test('remove o prefixo internacional 00', () {
      expect(
        CallerIdService.normalizarNumero('00 351 912 345 678'),
        '351912345678',
      );
    });
  });
}
