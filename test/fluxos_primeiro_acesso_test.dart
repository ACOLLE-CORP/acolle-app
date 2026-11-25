import 'package:acolle/main.dart';
import 'package:acolle/services/acessibilidade_service.dart';
import 'package:acolle/telas/adicionar_lembrete_page.dart';
import 'package:acolle/telas/cadastro_page.dart';
import 'package:acolle/telas/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('cadastro pede aceite antes de criar a conta', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CadastroPage()));
    final campos = find.byType(TextField);
    final valores = [
      'Pessoa Teste',
      'teste@example.invalid',
      '11987654321',
      '01011960',
      'senha123',
      'senha123',
    ];
    for (var i = 0; i < valores.length; i++) {
      await tester.enterText(campos.at(i), valores[i]);
    }
    final enviar = find.widgetWithText(ElevatedButton, 'Criar conta');
    await tester.ensureVisible(enviar);
    await tester.tap(enviar);
    await tester.pumpAndSettle();
    expect(find.text('Li e concordo'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Vamos criar sua conta'), findsOneWidget);
  });

  testWidgets('sob demanda dispensa horário e explica que não haverá alarme', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AdicionarLembretePage()));
    await tester.ensureVisible(find.text('Diário'));
    await tester.tap(find.text('Diário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sob demanda').last);
    await tester.pumpAndSettle();
    expect(find.text('Escolher horário'), findsNothing);
    expect(find.textContaining('sem alarme'), findsOneWidget);
  });

  testWidgets('a ampliação interna respeita a letra do celular', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AcessibilidadeService.instance.carregar();
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const AcolleApp());
    double medir() => MediaQuery.textScalerOf(
      tester.element(find.byType(SplashPage)),
    ).scale(20);
    expect(medir(), 30);
    await AcessibilidadeService.instance.alterarEscalaTexto(1.2);
    await tester.pump();
    expect(medir(), closeTo(36, 0.01));
    await tester.pumpWidget(const SizedBox());
    await AcessibilidadeService.instance.alterarEscalaTexto(1);
  });
}
