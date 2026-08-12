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

  /// Abre uma conversa no WhatsApp com uma mensagem de emergência pronta.
  /// Telefones locais com DDD recebem automaticamente o código do Brasil.
  static Future<bool> abrirWhatsApp(String numero, String corpo) async {
    final telefone = normalizarNumeroWhatsApp(numero);
    if (telefone.isEmpty) return false;

    final query = Uri(
      queryParameters: {'phone': telefone, 'text': corpo},
    ).query;

    // Primeiro tenta abrir diretamente o aplicativo instalado.
    final appUri = Uri.parse('whatsapp://send?$query');
    try {
      if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (e) {
      debugPrint('WhatsApp nativo indisponível: $e');
    }

    // O link oficial também abre o app; se ele não estiver instalado, abre
    // o WhatsApp Web no navegador em vez de deixar o botão sem resposta.
    final webUri = Uri.https('wa.me', '/$telefone', {'text': corpo});
    return _launch(webUri, 'Não foi possível abrir o WhatsApp.');
  }

  @visibleForTesting
  static String normalizarNumeroWhatsApp(String numero) {
    var digitos = numero.replaceAll(RegExp(r'\D'), '');
    if (digitos.startsWith('00')) digitos = digitos.substring(2);
    if ((digitos.length == 10 || digitos.length == 11) &&
        !digitos.startsWith('55')) {
      digitos = '55$digitos';
    }
    return digitos;
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
