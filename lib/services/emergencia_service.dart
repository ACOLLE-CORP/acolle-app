import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

/// Serviço de ações SOS: ligar e enviar SMS para contatos de emergência.
class EmergenciaService {
  EmergenciaService._();

  /// Abre o discador com o número preenchido (não disca automaticamente,
  /// para o usuário confirmar — ideal para idosos).
  static Future<bool> ligarPara(String numero) async {
    final clean = numero.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = Uri.parse('tel:$clean');
    return _launch(uri, 'Ligar falhou. Verifique o número.');
  }

  /// Abre o app de SMS com mensagem pré-preenchida para o número.
  static Future<bool> abrirSms(String numero, String corpo) async {
    final clean = numero.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = Uri.parse('sms:$clean?body=${Uri.encodeComponent(corpo)}');
    return _launch(uri, 'Não foi possível abrir as mensagens.');
  }

  /// Envia SMS sem abrir o app (requer permissão SEND_SMS em AndroidManifest).
  /// Em UIThread/lados onde o launcher nativo não resolve, deixamos como
  /// fallback do `abrirSms`.
  static Future<bool> enviarSmsDireto(String numero, String corpo) async {
    return abrirSms(numero, corpo);
  }

  static Future<bool> _launch(Uri uri, String erro) async {
    try {
      if (!await canLaunchUrl(uri)) {
        debugPrint('canLaunchUrl false para $uri');
      }
      return await launchUrl(uri);
    } catch (e) {
      debugPrint('$erro: $e');
      return false;
    }
  }
}
