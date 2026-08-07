import 'package:http/http.dart' as http;
import 'dart:convert';

/// Exceção lançada quando a API do Acolle falha, retorna erro
/// ou devolve uma resposta em formato inesperado.
class AcolleApiException implements Exception {
  final String message;
  AcolleApiException(this.message);

  @override
  String toString() => message;
}

class AcolleApi {
  static const String baseUrl = 'https://acolle-api.onrender.com';

  /// Envia um texto/conversa para a IA analisar.
  /// Retorna: {risco, classificacao, motivos, recomendacao}.
  /// Lança [AcolleApiException] em caso de falha de conexão,
  /// erro HTTP ou resposta em formato inesperado.
  static Future<Map<String, dynamic>> analisarConversa(String texto) async {
    final url = Uri.parse('$baseUrl/analisar');

    late http.Response resposta;
    try {
      resposta = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'texto': texto}),
          )
          // Render free tier pode demorar para "acordar" (cold start).
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw AcolleApiException('Falha de conexão com a API: $e');
    }

    if (resposta.statusCode != 200) {
      throw AcolleApiException(
        'API retornou erro ${resposta.statusCode}: ${resposta.body}',
      );
    }

    Map<String, dynamic> dados;
    try {
      dados = jsonDecode(resposta.body) as Map<String, dynamic>;
    } catch (e) {
      throw AcolleApiException('Resposta inválida da API: ${resposta.body}');
    }

    if (!dados.containsKey('risco') || !dados.containsKey('classificacao')) {
      throw AcolleApiException('Formato inesperado da API: $dados');
    }

    return dados;
  }

  /// Envia um link para a IA analisar, adaptando o prompt.
  /// Retorna o mesmo formato: {risco, classificacao, motivos, recomendacao}.
  /// Se a API falhar por qualquer motivo (conexão, erro HTTP, formato
  /// inesperado), cai automaticamente no fallback local offline.
  static Future<Map<String, dynamic>> analisarLink(String link) async {
    final prompt = '''
Analise esta URL para identificar se é segura ou perigosa (golpe/phishing): $link
Responda com: classificacao, risco numerico de 0 a 100, motivos e recomendacao.
''';
    try {
      return await analisarConversa(prompt);
    } catch (_) {
      // Fallback: análise local offline.
      return _analisarLinkLocal(link);
    }
  }

  static Map<String, dynamic> _analisarLinkLocal(String link) {
    const dominiosSuspeitos = {
      'bancoserver.com': 65,
      'login-bank.net': 65,
      'verify-account.tk': 95,
      'security-alert.com': 95,
      'promo-premio.xyz': 80,
      'golpista.online': 90,
      'confirme-seus-dados.tk': 95,
    };
    const dominiosConfiados = {
      'google.com': 5,
      'facebook.com': 5,
      'instagram.com': 5,
      'youtube.com': 5,
      'twitter.com': 5,
      'github.com': 5,
    };

    for (final entry in dominiosSuspeitos.entries) {
      if (link.contains(entry.key)) {
        return {
          'risco': entry.value,
          'classificacao': entry.value >= 90 ? 'Alto' : 'Médio',
          'motivos': ['Domínio conhecido por atividades suspeitas'],
          'recomendacao':
              'Não clique neste link. Pode conter malware ou roubar seus dados.',
        };
      }
    }
    for (final entry in dominiosConfiados.entries) {
      if (link.contains(entry.key)) {
        return {
          'risco': entry.value,
          'classificacao': 'Baixo',
          'motivos': ['Domínio verificado e confiável'],
          'recomendacao': 'Link aparentemente seguro.',
        };
      }
    }
    return {
      'risco': 35,
      'classificacao': 'Médio',
      'motivos': ['Domínio desconhecido. Confirme antes de clicar.'],
      'recomendacao':
          'Verifique o domínio em um buscador de confiança antes de abrir.',
    };
  }
}