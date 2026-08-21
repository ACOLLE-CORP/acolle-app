import 'package:flutter/services.dart';

/// Serviço responsável por ligar/desligar o botão flutuante persistente
/// (FloatingBubbleService.kt, lado nativo Android) e por descobrir se o
/// app foi aberto a partir de um toque em uma opção do menu flutuante.
class FloatingButtonService {
  FloatingButtonService._();

  static const _canal = MethodChannel('acolle/floating_button');

  /// Inicia o botão flutuante (foreground service no Android).
  /// Só funciona se a permissão de overlay já tiver sido concedida.
  static Future<void> iniciar() async {
    await _canal.invokeMethod('iniciarBotao');
  }

  /// Encerra o botão flutuante.
  static Future<void> parar() async {
    await _canal.invokeMethod('pararBotao');
  }

  /// Verifica se o app foi aberto a partir de um toque no menu do botão
  /// flutuante, e retorna a rota correspondente:
  /// 'analisar', 'verificar_link', 'alertas', 'chat' — ou null se foi
  /// uma abertura normal do app (ícone, notificação, etc).
  static Future<String?> rotaInicial() async {
    return await _canal.invokeMethod<String>('rotaInicial');
  }
}