import 'package:acolle/telas/verificar_link_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  setUpAll(() => Firebase.initializeApp());
  testWidgets(
    'editar o endereço descarta o resultado anterior, inclusive se o novo link é inválido',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const canal = MethodChannel('com.example.acolle1/notification_settings');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        canal,
        (_) async => false,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          canal,
          null,
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: VerificarLinkPage()));
      final campo = find.byType(TextField);
      final analisar = find.text('Analisar');
      await tester.enterText(campo, 'https://google.com');
      await tester.ensureVisible(analisar);
      await tester.tap(analisar);
      await tester.pumpAndSettle();
      expect(find.text('Risco Baixo'), findsOneWidget);
      await tester.enterText(campo, 'outro endereço');
      await tester.pump();
      expect(find.text('Risco Baixo'), findsNothing);
      await tester.ensureVisible(analisar);
      await tester.tap(analisar);
      await tester.pumpAndSettle();
      expect(find.textContaining('Link inválido'), findsOneWidget);
      expect(find.text('URL analisada:'), findsNothing);
    },
  );
}
