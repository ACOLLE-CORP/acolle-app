import 'package:acolle/telas/link_redefinicao_enviado_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('explica o passo a passo do LINK, sem falar em código',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LinkRedefinicaoEnviadoPage(email: 'maria@exemplo.com'),
      ),
    );

    expect(find.text('Enviamos um link'), findsOneWidget);
    expect(find.textContaining('maria@exemplo.com'), findsOneWidget);
    expect(find.text('Reenviar e-mail'), findsOneWidget);
    expect(find.text('Voltar para o login'), findsOneWidget);
    expect(find.textContaining('código'), findsNothing);
  });
}
