import 'package:acolle/services/notificacao_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renova a frequência de 8 horas após a janela inicial', () {
    final ocorrencias = NotificacaoService.proximasOcorrencias(
      horario: '22:30',
      frequencia: 'A cada 8 horas',
      ancora: DateTime(2026, 11, 1, 18),
      agora: DateTime(2026, 11, 24, 10),
    );
    expect(ocorrencias, hasLength(42));
    expect(ocorrencias.take(3), [
      DateTime(2026, 11, 24, 14, 30),
      DateTime(2026, 11, 24, 22, 30),
      DateTime(2026, 11, 25, 6, 30),
    ]);
  });

  test('a primeira ocorrência respeita o horário escolhido', () {
    final agora = DateTime(2026, 11, 24, 18);
    final ocorrencias = NotificacaoService.proximasOcorrencias(
      horario: '17:30',
      frequencia: 'A cada 12 horas',
      ancora: agora,
      agora: agora,
    );
    expect(ocorrencias, hasLength(28));
    expect(ocorrencias.first, DateTime(2026, 11, 25, 17, 30));
  });

  test('renova o semanal preservando o dia original após oito semanas', () {
    final ocorrencias = NotificacaoService.proximasOcorrencias(
      horario: '07:15',
      frequencia: 'Semanal',
      ancora: DateTime(2026, 9, 1, 12),
      agora: DateTime(2026, 11, 24, 12),
    );
    expect(ocorrencias, hasLength(8));
    expect(ocorrencias.first, DateTime(2026, 11, 25, 7, 15));
    expect(ocorrencias.last, DateTime(2027, 1, 13, 7, 15));
  });

  test('sob demanda não agenda alarme', () {
    final agora = DateTime(2026, 11, 24, 12);
    expect(
      NotificacaoService.proximasOcorrencias(
        horario: '07:15',
        frequencia: 'Sob demanda',
        ancora: agora,
        agora: agora,
      ),
      isEmpty,
    );
  });
}
