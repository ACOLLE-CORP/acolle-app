import 'package:flutter/services.dart';

/// Serviço responsável por conversar com o NotificationListener.kt
/// (lado nativo Android) via MethodChannel/EventChannel.
///
/// Diferente do NotificacaoService (que agenda lembretes e cuida do FCM),
/// este serviço apenas ESCUTA notificações de outros apps (WhatsApp, SMS)
/// para encaminhar o conteúdo à verificação de golpes.
class NotificationListenerService {
  NotificationListenerService._();

  static const _canalMetodos = MethodChannel(
    'com.example.acolle1/notification_settings',
  );
  static const _canalEventos = EventChannel(
    'com.example.acolle1/notification_events',
  );

  /// Verifica se o usuário já concedeu a permissão de acesso a notificações.
  static Future<bool> permissaoConcedida() async {
    final resultado = await _canalMetodos.invokeMethod<bool>(
      'isPermissaoConcedida',
    );
    return resultado ?? false;
  }

  /// Leva o usuário até a tela de configurações do sistema para ativar
  /// o acesso a notificações. Não existe forma de conceder isso via
  /// pop-up padrão do Android.
  static Future<void> abrirConfiguracoes() async {
    await _canalMetodos.invokeMethod('abrirConfiguracoes');
  }

  /// Stream com as notificações capturadas em tempo real.
  /// Cada evento vem como um Map com as chaves: 'pacote', 'titulo', 'texto'.
  static Stream<Map<String, dynamic>> get notificacoes {
    return _canalEventos.receiveBroadcastStream().map(
          (evento) => Map<String, dynamic>.from(evento as Map),
        );
  }
}