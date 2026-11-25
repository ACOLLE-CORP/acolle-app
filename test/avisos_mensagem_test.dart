import 'package:acolle/services/notification_listener_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ajustes = MethodChannel('com.example.acolle1/notification_settings');
  const permissoes = MethodChannel('flutter.baseflow.com/permissions/methods');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late bool acesso;
  late bool avisos;
  final abertos = <String>[];
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    acesso = false;
    avisos = false;
    abertos.clear();
    messenger.setMockMethodCallHandler(ajustes, (call) async {
      switch (call.method) {
        case 'isPermissaoConcedida':
          return acesso;
        case 'avisosMensagemPermitidos':
          return avisos;
        case 'abrirConfiguracoes':
        case 'abrirAjustesDeAvisos':
          abertos.add(call.method);
          return null;
        default:
          throw UnsupportedError(call.method);
      }
    });
    messenger.setMockMethodCallHandler(permissoes, (call) async {
      expect(call.method, 'requestPermissions');
      return {for (final id in call.arguments as List) id: 1};
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(ajustes, null);
    messenger.setMockMethodCallHandler(permissoes, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'verificação ativa exige acesso às mensagens e saída de avisos',
    () async {
      for (final entrada in [false, true]) {
        for (final saida in [false, true]) {
          acesso = entrada;
          avisos = saida;
          expect(
            await NotificationListenerService.verificacaoAtiva(),
            entrada && saida,
          );
        }
      }
    },
  );
  test(
    'com acesso concedido, configurar abre o ajuste do canal bloqueado',
    () async {
      acesso = true;
      await NotificationListenerService.configurarVerificacao();
      expect(abertos, ['abrirAjustesDeAvisos']);
    },
  );
  test('sem acesso abre o seletor de acesso do Android', () async {
    avisos = true;
    await NotificationListenerService.configurarVerificacao();
    expect(abertos, ['abrirConfiguracoes']);
  });
}
