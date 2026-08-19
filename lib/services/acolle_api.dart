import 'dart:convert';
import 'package:http/http.dart' as http;

/// Exceção lançada quando a API do Acolle falha,
/// retorna erro ou devolve uma resposta inesperada.
class AcolleApiException implements Exception {
  final String message;

  AcolleApiException(this.message);

  @override
  String toString() => message;
}

class AcolleApi {
  /// Backend atual do Acolle no Cloudflare Workers.
  static const String baseUrl =
      'https://acolle-ia.gh5931808.workers.dev';

  /// Tempo máximo para uma análise.
  ///
  /// Como não usamos mais o Render Free,
  /// não precisamos esperar 60 segundos por cold start.
  static const Duration timeout = Duration(seconds: 30);

  /// Envia uma conversa/texto para análise.
  ///
  /// Retorno esperado:
  ///
  /// {
  ///   "risco": 0-100,
  ///   "classificacao": "Baixo" | "Médio" | "Alto",
  ///   "motivos": [],
  ///   "recomendacao": "..."
  /// }
  static Future<Map<String, dynamic>> analisarConversa(String texto) async {
    final textoLimpo = texto.trim();

    if (textoLimpo.isEmpty) {
      throw AcolleApiException(
        'Digite ou forneça um texto para análise.',
      );
    }

    final url = Uri.parse('$baseUrl/analisar');

    late http.Response resposta;

    try {
      resposta = await http
          .post(
            url,
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'texto': textoLimpo,
            }),
          )
          .timeout(timeout);
    } catch (e) {
      throw AcolleApiException(
        'Não foi possível conectar ao serviço de análise. '
        'Verifique sua internet e tente novamente.',
      );
    }

    if (resposta.statusCode != 200) {
      throw AcolleApiException(
        _obterMensagemErro(resposta),
      );
    }

    dynamic json;

    try {
      json = jsonDecode(utf8.decode(resposta.bodyBytes));
    } catch (_) {
      throw AcolleApiException(
        'A API retornou uma resposta inválida.',
      );
    }

    if (json is! Map<String, dynamic>) {
      throw AcolleApiException(
        'Formato inesperado recebido da API.',
      );
    }

    final dados = json;

    if (!_respostaAnaliseValida(dados)) {
      throw AcolleApiException(
        'A análise retornada pela API está incompleta.',
      );
    }

    // Normaliza os valores antes de entregar para o restante do app.
    final risco = _normalizarRisco(dados['risco']);

    return {
      'risco': risco,
      'classificacao':
          _normalizarClassificacao(dados['classificacao'], risco),
      'motivos': _normalizarMotivos(dados['motivos']),
      'recomendacao':
          dados['recomendacao']?.toString().trim().isNotEmpty == true
              ? dados['recomendacao'].toString().trim()
              : 'Tenha cuidado e confirme as informações antes de prosseguir.',
    };
  }

  /// Analisa um link utilizando a IA.
  ///
  /// Se o Cloudflare/IA estiver indisponível,
  /// utiliza automaticamente uma análise local.
  static Future<Map<String, dynamic>> analisarLink(String link) async {
    final linkLimpo = link.trim();

    if (linkLimpo.isEmpty) {
      throw AcolleApiException(
        'Informe um link para análise.',
      );
    }

    // Primeiro fazemos uma análise local rápida.
    final analiseLocal = _analisarLinkLocal(linkLimpo);

    final prompt = '''
Você está analisando um possível link malicioso, phishing ou golpe.

Analise SOMENTE esta URL:

$linkLimpo

Considere:
- domínio estranho ou imitando empresa conhecida;
- erros de escrita no domínio;
- domínios incomuns;
- tentativa de roubo de senha ou dados;
- páginas falsas de banco;
- falsas promoções ou prêmios;
- links encurtados;
- tentativa de se passar por empresa conhecida.

Retorne a análise usando o formato padrão do Acolle.
''';

    try {
      return await analisarConversa(prompt);
    } catch (_) {
      // Se a IA estiver indisponível,
      // o aplicativo continua funcionando offline.
      return analiseLocal;
    }
  }

  /// Análise simples de URL feita diretamente no dispositivo.
  static Map<String, dynamic> _analisarLinkLocal(String link) {
    final uri = _parseUrl(link);

    if (uri == null || uri.host.isEmpty) {
      return {
        'risco': 80,
        'classificacao': 'Alto',
        'motivos': [
          'O endereço informado não parece ser uma URL válida.',
        ],
        'recomendacao':
            'Não abra o link. Confirme o endereço antes de continuar.',
      };
    }

    final host = uri.host.toLowerCase();

    const dominiosSuspeitos = <String, int>{
      'bancoserver.com': 65,
      'login-bank.net': 65,
      'verify-account.tk': 95,
      'security-alert.com': 95,
      'promo-premio.xyz': 80,
      'golpista.online': 90,
      'confirme-seus-dados.tk': 95,
    };

    const dominiosConfiados = <String, int>{
      'google.com': 5,
      'facebook.com': 5,
      'instagram.com': 5,
      'youtube.com': 5,
      'x.com': 5,
      'github.com': 5,
    };

    for (final entry in dominiosSuspeitos.entries) {
      if (_dominioCorresponde(host, entry.key)) {
        return {
          'risco': entry.value,
          'classificacao':
              entry.value >= 75 ? 'Alto' : 'Médio',
          'motivos': [
            'O domínio apresenta características associadas a links suspeitos.',
          ],
          'recomendacao':
              'Não abra o link nem informe senhas, códigos ou dados pessoais.',
        };
      }
    }

    for (final entry in dominiosConfiados.entries) {
      if (_dominioCorresponde(host, entry.key)) {
        return {
          'risco': entry.value,
          'classificacao': 'Baixo',
          'motivos': [
            'O domínio principal corresponde a um serviço conhecido.',
          ],
          'recomendacao':
              'O domínio parece legítimo, mas ainda verifique o conteúdo da página.',
        };
      }
    }

    var risco = 30;
    final motivos = <String>[];

    if (uri.scheme != 'https') {
      risco += 20;
      motivos.add(
        'O endereço não utiliza uma conexão HTTPS.',
      );
    }

    if (_possuiTldSuspeito(host)) {
      risco += 20;
      motivos.add(
        'O endereço utiliza uma extensão de domínio que merece atenção.',
      );
    }

    if (_possuiPalavraSuspeita(host)) {
      risco += 20;
      motivos.add(
        'O domínio contém termos frequentemente usados em páginas falsas.',
      );
    }

    if (_pareceEnderecoIp(host)) {
      risco += 25;
      motivos.add(
        'O link utiliza um endereço IP no lugar de um domínio comum.',
      );
    }

    risco = risco.clamp(0, 100);

    if (motivos.isEmpty) {
      motivos.add(
        'O domínio não está na lista local de sites conhecidos.',
      );
    }

    return {
      'risco': risco,
      'classificacao': _classificacaoPorRisco(risco),
      'motivos': motivos,
      'recomendacao':
          risco >= 70
              ? 'Evite abrir o link até confirmar sua origem.'
              : 'Verifique quem enviou o link antes de abrir.',
    };
  }

  /// Tenta interpretar URLs mesmo quando o usuário
  /// não escreve http:// ou https://.
  static Uri? _parseUrl(String link) {
    var valor = link.trim();

    if (!valor.startsWith('http://') &&
        !valor.startsWith('https://')) {
      valor = 'https://$valor';
    }

    try {
      return Uri.parse(valor);
    } catch (_) {
      return null;
    }
  }

  /// Evita um problema importante com verificações usando contains().
  ///
  /// Exemplo:
  ///
  /// google.com.evil.com
  ///
  /// NÃO deve ser considerado google.com.
  static bool _dominioCorresponde(
    String host,
    String dominio,
  ) {
    return host == dominio || host.endsWith('.$dominio');
  }

  static bool _possuiTldSuspeito(String host) {
    const tlds = [
      '.tk',
      '.xyz',
      '.top',
      '.click',
      '.online',
    ];

    return tlds.any(host.endsWith);
  }

  static bool _possuiPalavraSuspeita(String host) {
    const palavras = [
      'verify',
      'verification',
      'account',
      'security',
      'premio',
      'pix',
      'login-bank',
      'confirme',
      'atualize',
      'bloqueio',
    ];

    return palavras.any(host.contains);
  }

  static bool _pareceEnderecoIp(String host) {
    final regex = RegExp(
      r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$',
    );

    return regex.hasMatch(host);
  }

  static bool _respostaAnaliseValida(
    Map<String, dynamic> dados,
  ) {
    return dados.containsKey('risco') &&
        dados.containsKey('classificacao') &&
        dados.containsKey('motivos') &&
        dados.containsKey('recomendacao');
  }

  static int _normalizarRisco(dynamic valor) {
    if (valor is int) {
      return valor.clamp(0, 100);
    }

    if (valor is double) {
      return valor.round().clamp(0, 100);
    }

    final convertido = int.tryParse(valor?.toString() ?? '');

    return (convertido ?? 0).clamp(0, 100);
  }

  static String _normalizarClassificacao(
    dynamic valor,
    int risco,
  ) {
    final classificacao =
        valor?.toString().trim().toLowerCase();

    switch (classificacao) {
      case 'baixo':
        return 'Baixo';

      case 'medio':
      case 'médio':
        return 'Médio';

      case 'alto':
        return 'Alto';

      default:
        return _classificacaoPorRisco(risco);
    }
  }

  static List<String> _normalizarMotivos(dynamic valor) {
    if (valor is List) {
      return valor
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (valor != null && valor.toString().trim().isNotEmpty) {
      return [valor.toString().trim()];
    }

    return [
      'Nenhum motivo específico foi informado.',
    ];
  }

  static String _classificacaoPorRisco(int risco) {
    if (risco >= 70) {
      return 'Alto';
    }

    if (risco >= 30) {
      return 'Médio';
    }

    return 'Baixo';
  }

  /// Tenta apresentar ao usuário a mensagem de erro enviada pelo backend,
  /// em vez de mostrar JSON bruto.
  static String _obterMensagemErro(http.Response resposta) {
    try {
      final dados =
          jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is Map &&
          dados['detail'] != null &&
          dados['detail'].toString().isNotEmpty) {
        return dados['detail'].toString();
      }
    } catch (_) {
      // Se a resposta não for JSON,
      // utiliza mensagens amigáveis abaixo.
    }

    switch (resposta.statusCode) {
      case 400:
        return 'A solicitação enviada é inválida.';

      case 429:
        return 'O limite de análises foi atingido. Tente novamente mais tarde.';

      case 500:
      case 502:
      case 503:
        return 'O serviço de análise está temporariamente indisponível.';

      default:
        return 'Não foi possível realizar a análise '
            '(erro ${resposta.statusCode}).';
    }
  }
}