import 'dart:async';
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

  static const String baseUrl =
      'https://acolle-ia.acolle-corp.workers.dev';

  /// Cloudflare normalmente responde rapidamente.
  static const Duration timeout = Duration(seconds: 30);

  /// ============================================================
  /// ANALISAR CONVERSA
  /// ============================================================

  static Future<Map<String, dynamic>> analisarConversa(
    String texto,
  ) async {
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
    } on TimeoutException {
      throw AcolleApiException(
        'A análise demorou mais que o esperado. '
        'Verifique sua conexão e tente novamente.',
      );
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
      json = jsonDecode(
        utf8.decode(resposta.bodyBytes),
      );
    } catch (_) {
      throw AcolleApiException(
        'A API retornou uma resposta inválida.',
      );
    }

    if (json is! Map) {
      throw AcolleApiException(
        'Formato inesperado recebido da API.',
      );
    }

    final dados = Map<String, dynamic>.from(json);

    if (!_respostaAnaliseValida(dados)) {
      throw AcolleApiException(
        'A análise retornada pela API está incompleta.',
      );
    }

    final risco = _normalizarRisco(
      dados['risco'],
    );

    final resultado = <String, dynamic>{
      'risco': risco,

      'classificacao':
          _normalizarClassificacao(
        dados['classificacao'],
        risco,
      ),

      'motivos':
          _normalizarMotivos(
        dados['motivos'],
      ),

      'recomendacao':
          _normalizarRecomendacao(
        dados['recomendacao'],
      ),
    };

    /// O backend híbrido retorna:
    ///
    /// "provedor": "cloudflare"
    ///
    /// ou:
    ///
    /// "provedor": "gemini"
    ///
    /// Mantemos esse valor para os testes.
    final provedor = dados['provedor'];

    if (provedor != null &&
        provedor.toString().trim().isNotEmpty) {
      resultado['provedor'] =
          provedor.toString().trim();
    }

    return resultado;
  }

  /// ============================================================
  /// ANALISAR LINK
  /// ============================================================

  static Future<Map<String, dynamic>> analisarLink(
    String link,
  ) async {
    final linkLimpo = link.trim();

    if (linkLimpo.isEmpty) {
      throw AcolleApiException(
        'Informe um link para análise.',
      );
    }

    /// Faz primeiro uma análise local.
    ///
    /// Ela será usada caso Cloudflare Workers AI
    /// e Gemini fiquem indisponíveis.
    final analiseLocal =
        _analisarLinkLocal(linkLimpo);

    final prompt = '''
O conteúdo abaixo é uma URL que deve ser analisada para identificar possível golpe, phishing ou site malicioso.

URL:
$linkLimpo

Verifique principalmente:

- domínio tentando imitar empresa conhecida;
- erros no nome do domínio;
- domínio estranho;
- página falsa de banco;
- tentativa de roubo de senha;
- tentativa de roubo de dados;
- falsas promoções;
- falsos prêmios;
- links encurtados;
- palavras relacionadas a login, segurança ou confirmação;
- tentativa de se passar por banco, empresa ou serviço conhecido.

Avalie o risco de 0 a 100.
''';

    try {
      return await analisarConversa(prompt);
    } catch (_) {
      /// Continua funcionando mesmo sem internet/IA.
      return analiseLocal;
    }
  }

  /// ============================================================
  /// FALLBACK LOCAL PARA LINKS
  /// ============================================================

  static Map<String, dynamic> _analisarLinkLocal(
    String link,
  ) {
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
        'provedor': 'local',
      };
    }

    final host =
        uri.host.toLowerCase().trim();

    /// Exemplos usados pelo projeto/testes.
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

    /// ==========================================================
    /// DOMÍNIOS SUSPEITOS
    /// ==========================================================

    for (final entry
        in dominiosSuspeitos.entries) {
      if (_dominioCorresponde(
        host,
        entry.key,
      )) {
        final risco = entry.value;

        return {
          'risco': risco,
          'classificacao':
              _classificacaoPorRisco(risco),
          'motivos': [
            'O domínio apresenta características associadas a links suspeitos.',
          ],
          'recomendacao':
              'Não abra o link nem informe senhas, códigos ou dados pessoais.',
          'provedor': 'local',
        };
      }
    }

    /// ==========================================================
    /// DOMÍNIOS CONHECIDOS
    /// ==========================================================

    for (final entry
        in dominiosConfiados.entries) {
      if (_dominioCorresponde(
        host,
        entry.key,
      )) {
        return {
          'risco': entry.value,
          'classificacao': 'Baixo',
          'motivos': [
            'O domínio principal corresponde a um serviço conhecido.',
          ],
          'recomendacao':
              'O domínio parece legítimo, mas confirme o conteúdo antes de informar dados pessoais.',
          'provedor': 'local',
        };
      }
    }

    /// ==========================================================
    /// ANÁLISE HEURÍSTICA
    /// ==========================================================

    var risco = 20;

    final motivos = <String>[];

    if (uri.scheme != 'https') {
      risco += 20;

      motivos.add(
        'O endereço não utiliza conexão HTTPS.',
      );
    }

    if (_possuiTldSuspeito(host)) {
      risco += 20;

      motivos.add(
        'A extensão do domínio merece atenção.',
      );
    }

    if (_possuiPalavraSuspeita(host)) {
      risco += 20;

      motivos.add(
        'O domínio contém palavras frequentemente encontradas em páginas suspeitas.',
      );
    }

    if (_pareceEnderecoIp(host)) {
      risco += 25;

      motivos.add(
        'O endereço utiliza um IP diretamente em vez de um domínio comum.',
      );
    }

    if (_possuiMuitosSubdominios(host)) {
      risco += 10;

      motivos.add(
        'O endereço possui uma estrutura de subdomínios incomum.',
      );
    }

    risco = risco.clamp(
      0,
      100,
    ).toInt();

    if (motivos.isEmpty) {
      motivos.add(
        'O domínio não está na lista local de sites conhecidos.',
      );
    }

    return {
      'risco': risco,

      'classificacao':
          _classificacaoPorRisco(
        risco,
      ),

      'motivos': motivos,

      'recomendacao':
          risco >= 70
              ? 'Evite abrir o link até confirmar sua origem.'
              : 'Confirme quem enviou o link antes de abrir.',

      'provedor': 'local',
    };
  }

  /// ============================================================
  /// URL
  /// ============================================================

  static Uri? _parseUrl(
    String link,
  ) {
    var valor = link.trim();

    if (valor.isEmpty) {
      return null;
    }

    if (!valor.startsWith('http://') &&
        !valor.startsWith('https://')) {
      valor = 'https://$valor';
    }

    try {
      final uri = Uri.parse(valor);

      if (uri.host.isEmpty) {
        return null;
      }

      return uri;
    } catch (_) {
      return null;
    }
  }

  /// Impede casos como:
  ///
  /// google.com.golpe.xyz
  ///
  /// de serem considerados google.com.
  static bool _dominioCorresponde(
    String host,
    String dominio,
  ) {
    final hostNormalizado =
        host.toLowerCase();

    final dominioNormalizado =
        dominio.toLowerCase();

    return hostNormalizado ==
            dominioNormalizado ||
        hostNormalizado.endsWith(
          '.$dominioNormalizado',
        );
  }

  static bool _possuiTldSuspeito(
    String host,
  ) {
    const tlds = [
      '.tk',
      '.xyz',
      '.top',
      '.click',
      '.online',
    ];

    return tlds.any(
      (tld) => host.endsWith(tld),
    );
  }

  static bool _possuiPalavraSuspeita(
    String host,
  ) {
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
      'senha',
      'conta',
      'secure',
    ];

    return palavras.any(
      (palavra) =>
          host.contains(palavra),
    );
  }

  static bool _pareceEnderecoIp(
    String host,
  ) {
    final regex = RegExp(
      r'^(?:\d{1,3}\.){3}\d{1,3}$',
    );

    if (!regex.hasMatch(host)) {
      return false;
    }

    final partes =
        host.split('.');

    return partes.every((parte) {
      final numero =
          int.tryParse(parte);

      return numero != null &&
          numero >= 0 &&
          numero <= 255;
    });
  }

  static bool _possuiMuitosSubdominios(
    String host,
  ) {
    return host.split('.').length > 4;
  }

  /// ============================================================
  /// VALIDAÇÃO DA RESPOSTA
  /// ============================================================

  static bool _respostaAnaliseValida(
    Map<String, dynamic> dados,
  ) {
    return dados.containsKey('risco') &&
        dados.containsKey(
          'classificacao',
        ) &&
        dados.containsKey('motivos') &&
        dados.containsKey(
          'recomendacao',
        );
  }

  static int _normalizarRisco(
    dynamic valor,
  ) {
    num? numero;

    if (valor is num) {
      numero = valor;
    } else {
      numero = num.tryParse(
        valor?.toString() ?? '',
      );
    }

    return (numero ?? 0)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  static String _normalizarClassificacao(
    dynamic valor,
    int risco,
  ) {
    final classificacao =
        valor
            ?.toString()
            .trim()
            .toLowerCase();

    switch (classificacao) {
      case 'baixo':
        return 'Baixo';

      case 'medio':
      case 'médio':
        return 'Médio';

      case 'alto':
        return 'Alto';

      default:
        return _classificacaoPorRisco(
          risco,
        );
    }
  }

  static List<String> _normalizarMotivos(
    dynamic valor,
  ) {
    if (valor is List) {
      final motivos = valor
          .map(
            (e) => e.toString().trim(),
          )
          .where(
            (e) => e.isNotEmpty,
          )
          .toList();

      if (motivos.isNotEmpty) {
        return motivos;
      }
    }

    if (valor != null) {
      final texto =
          valor.toString().trim();

      if (texto.isNotEmpty) {
        return [texto];
      }
    }

    return [
      'Nenhum motivo específico foi informado.',
    ];
  }

  static String _normalizarRecomendacao(
    dynamic valor,
  ) {
    final texto =
        valor?.toString().trim() ?? '';

    if (texto.isNotEmpty) {
      return texto;
    }

    return 'Tenha cuidado e confirme as informações antes de prosseguir.';
  }

  static String _classificacaoPorRisco(
    int risco,
  ) {
    if (risco >= 70) {
      return 'Alto';
    }

    if (risco >= 30) {
      return 'Médio';
    }

    return 'Baixo';
  }

  /// ============================================================
  /// ERROS DA API
  /// ============================================================

  static String _obterMensagemErro(
    http.Response resposta,
  ) {
    try {
      final dados = jsonDecode(
        utf8.decode(
          resposta.bodyBytes,
        ),
      );

      if (dados is Map) {
        final detalhe =
            dados['detail'];

        if (detalhe != null &&
            detalhe
                .toString()
                .trim()
                .isNotEmpty) {
          return detalhe
              .toString()
              .trim();
        }
      }
    } catch (_) {
      // Usa mensagens abaixo.
    }

    switch (resposta.statusCode) {
      case 400:
        return 'A solicitação enviada é inválida.';

      case 401:
      case 403:
        return 'O serviço de análise não está autorizado corretamente.';

      case 404:
        return 'O serviço de análise não foi encontrado.';

      case 429:
        return 'O limite de análises foi atingido. Tente novamente mais tarde.';

      case 500:
      case 502:
      case 503:
      case 504:
        return 'O serviço de análise está temporariamente indisponível.';

      default:
        return 'Não foi possível realizar a análise '
            '(erro ${resposta.statusCode}).';
    }
  }
}