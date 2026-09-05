import 'package:flutter/services.dart';

/// Serviço responsável por ligar/desligar o botão flutuante persistente
/// (FloatingBubbleService.kt, lado nativo Android) e por descobrir se o
/// app foi aberto a partir de um toque em uma opção do menu flutuante.
class FloatingButtonService {
  FloatingButtonService._();

  static const _canal = MethodChannel('acolle/floating_button');
  static const _canalRotas = EventChannel('acolle/floating_button_routes');

  /// Inicia o botão flutuante (foreground service no Android).
  /// Só funciona se a permissão de overlay já tiver sido concedida.
  static Future<bool> iniciar() async {
    return await _canal.invokeMethod<bool>('iniciarBotao') ?? false;
  }

  /// Encerra o botão flutuante.
  static Future<bool> parar() async {
    return await _canal.invokeMethod<bool>('pararBotao') ?? false;
  }

  /// Estado real do serviço nativo, sem depender do valor visual da chave.
  static Future<bool> estaAtivo() async {
    return await _canal.invokeMethod<bool>('isBotaoAtivo') ?? false;
  }

  /// Verifica se o app foi aberto a partir de um toque no menu do botão
  /// flutuante, e retorna a rota correspondente:
  /// 'analisar', 'verificar_link', 'alertas', 'ajuda' — ou null se foi
  /// uma abertura normal do app (ícone, notificação, etc).
  static Future<String?> rotaInicial() async {
    return await _canal.invokeMethod<String>('rotaInicial');
  }

  /// Rotas tocadas quando o aplicativo já está aberto.
  static Stream<String> get rotas {
    return _canalRotas
        .receiveBroadcastStream()
        .where((rota) => rota is String)
        .cast<String>();
  }
}
