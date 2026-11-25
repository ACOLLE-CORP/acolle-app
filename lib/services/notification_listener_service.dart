import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Serviço responsável por conversar com o NotificationListener.kt
/// (lado nativo Android) via MethodChannel/EventChannel.
///
/// Diferente do NotificacaoService (que agenda lembretes e cuida do FCM),
/// este serviço apenas ESCUTA notificações de outros apps (WhatsApp, SMS)
/// para encaminhar o conteúdo à verificação de golpes.
class NotificationListenerService {
  NotificationListenerService._();
  static bool get disponivel => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const _canalMetodos = MethodChannel(
    'com.example.acolle1/notification_settings',
  );
  static const _canalEventos = EventChannel(
    'com.example.acolle1/notification_events',
  );

  /// Verifica se o usuário já concedeu a permissão de acesso a notificações.
  static Future<bool> permissaoConcedida() async {
    return _consultar('isPermissaoConcedida');
  }

  static Future<bool> avisosPermitidos() => _consultar('avisosMensagemPermitidos');

  static Future<bool> verificacaoAtiva() async =>
      await permissaoConcedida() && await avisosPermitidos();

  static Future<bool> _consultar(String metodo) async {
    if (!disponivel) return false;
    try {
      return await _canalMetodos.invokeMethod<bool>(metodo) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Leva o usuário até a tela de configurações do sistema para ativar
  /// o acesso a notificações. Não existe forma de conceder isso via
  /// pop-up padrão do Android.
  static Future<void> abrirConfiguracoes() async {
    if (!disponivel) return;
    await _canalMetodos.invokeMethod('abrirConfiguracoes');
  }

  static Future<void> ajustarAvisos() async {
    if (!disponivel) return;
    await Permission.notification.request();
    if (!await avisosPermitidos()) {
      await _canalMetodos.invokeMethod('abrirAjustesDeAvisos');
    }
  }

  static Future<void> configurarVerificacao() async {
    if (!disponivel) return;
    if (!await permissaoConcedida()) {
      await abrirConfiguracoes();
    } else {
      await ajustarAvisos();
    }
  }

  /// Stream com as notificações capturadas em tempo real.
  /// Inclui pacote, título, texto, classificação, risco e recomendação.
  static Stream<Map<String, dynamic>> get notificacoes {
    return _canalEventos.receiveBroadcastStream().map(
          (evento) => Map<String, dynamic>.from(evento as Map),
        );
  }
}
