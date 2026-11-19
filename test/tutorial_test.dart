import 'package:acolle1/services/tutorial_service.dart';
import 'package:acolle1/telas/tutorial_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abre o tutorial por cima de uma tela com um botão, como acontece no app.
Widget _app(Future<void> Function()? aoFinalizar) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TutorialPage(aoFinalizar: aoFinalizar),
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('TutorialService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('começa como não concluído', () async {
      expect(await TutorialService.jaConcluiu('u1'), isFalse);
    });

    test('marca como concluído apenas para o usuário informado', () async {
      await TutorialService.marcarConcluido('u1');

      expect(await TutorialService.jaConcluiu('u1'), isTrue);
      expect(await TutorialService.jaConcluiu('u2'), isFalse);
    });

    test('reiniciar volta a exibir o tutorial', () async {
      await TutorialService.marcarConcluido('u1');
      await TutorialService.reiniciar('u1');

      expect(await TutorialService.jaConcluiu('u1'), isFalse);
    });
  });

  group('TutorialPage', () {
    testWidgets('mostra o primeiro passo, sem botão Voltar', (tester) async {
      await tester.pumpWidget(_app(null));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Passo 1 de 14'), findsOneWidget);
      expect(find.text('Olá! Eu sou o Collin'), findsOneWidget);
      expect(find.text('Voltar'), findsNothing);
      expect(find.text('Avançar'), findsOneWidget);
      expect(find.text('Pular'), findsOneWidget);
    });

    testWidgets('avança e volta entre os passos', (tester) async {
      await tester.pumpWidget(_app(null));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
      expect(find.text('Passo 2 de 14'), findsOneWidget);
      expect(find.text('Para que serve o Acolle'), findsOneWidget);

      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Passo 1 de 14'), findsOneWidget);
    });

    testWidgets('Pular fecha o tutorial e avisa o fim', (tester) async {
      var finalizou = 0;
      await tester.pumpWidget(_app(() async => finalizou++));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();

      expect(find.byType(TutorialPage), findsNothing);
      expect(finalizou, 1);
    });

    testWidgets('chega ao último passo e Concluir fecha', (tester) async {
      var finalizou = 0;
      await tester.pumpWidget(_app(() async => finalizou++));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      for (var i = 0; i < 13; i++) {
        await tester.tap(find.text('Avançar'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Passo 14 de 14'), findsOneWidget);
      expect(find.text('Tudo certo!'), findsOneWidget);
      expect(find.text('Pular'), findsNothing);

      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();

      expect(find.byType(TutorialPage), findsNothing);
      expect(finalizou, 1);
    });

    testWidgets('passos de permissões mostram os itens com botão Ativar',
        (tester) async {
      await tester.pumpWidget(_app(null));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Avança até o passo "Ative a proteção de chamadas".
      for (var i = 0; i < 100; i++) {
        if (find.text('Ative a proteção de chamadas').evaluate().isNotEmpty) {
          break;
        }
        await tester.tap(find.text('Avançar'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Ative a proteção de chamadas'), findsOneWidget);
      expect(find.text('Ver quem está ligando'), findsOneWidget);
      expect(find.text('Identificar chamadas'), findsOneWidget);
      expect(find.text('Mostrar o aviso grande'), findsOneWidget);
      // Sem o sistema Android nos testes, nenhuma permissão aparece ativa.
      expect(find.text('Ativar'), findsNWidgets(3));
    });

    testWidgets('botão voltar do aparelho também conta como saída',
        (tester) async {
      var finalizou = 0;
      await tester.pumpWidget(_app(() async => finalizou++));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(TutorialPage), findsNothing);
      expect(finalizou, 1);
    });
  });
}
