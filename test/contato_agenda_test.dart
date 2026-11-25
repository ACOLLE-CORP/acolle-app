import 'package:acolle/telas/contatos_emergencia_page.dart';
import 'package:acolle/telas/onboarding_contato_emergencia_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final primeiroAcesso in [true, false]) {
    testWidgets(
      'agenda preenche o contato e preserva dados ao cancelar (primeiro acesso: $primeiroAcesso)',
      (tester) async {
        const canal = MethodChannel('acolle/contatos');
        var chamadas = 0;
        final messenger = tester.binding.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(canal, (call) async {
          expect(call.method, 'selecionarTelefone');
          chamadas++;
          return chamadas == 1
              ? {'nome': 'Contato teste', 'telefone': '+55 11 2345-6789'}
              : null;
        });
        addTearDown(() => messenger.setMockMethodCallHandler(canal, null));
        await tester.pumpWidget(
          MaterialApp(
            home: primeiroAcesso
                ? const OnboardingContatoEmergenciaPage()
                : const AdicionarContatoEmergenciaPage(),
          ),
        );
        final botao = primeiroAcesso
            ? find.byTooltip('Buscar nos contatos')
            : find.byIcon(Icons.contact_page_outlined);
        for (var i = 0; i < 2; i++) {
          await tester.ensureVisible(botao);
          await tester.tap(botao);
          await tester.pumpAndSettle();
          expect(find.text('Contato teste'), findsOneWidget);
          expect(find.text('+55 11 2345-6789'), findsOneWidget);
        }
        expect(chamadas, 2);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }
}
