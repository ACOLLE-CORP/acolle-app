import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../shared/acolle_design.dart';
import '../services/acolle_api.dart';
import '../services/acessibilidade_service.dart';
import '../services/notification_listener_service.dart';

class VerificarLinkPage extends StatefulWidget {
  const VerificarLinkPage({super.key});

  @override
  State<VerificarLinkPage> createState() => _VerificarLinkPageState();
}

class _VerificarLinkPageState extends State<VerificarLinkPage> {
  final TextEditingController _linkController = TextEditingController();

  bool _carregando = false;
  Map<String, dynamic>? _resultado;
  String? _erro;

  bool _permissaoNotificacaoConcedida = false;
  StreamSubscription<Map<String, dynamic>>? _subscricaoNotificacoes;

  static final RegExp _regexLink = RegExp(
    r'(https?:\/\/[^\s]+)',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();

    AcessibilidadeService.instance.addListener(
      _onAcessibilidadeChanged,
    );

    AcessibilidadeService.instance.carregar();

    _verificarPermissaoNotificacao();
  }

  void _onAcessibilidadeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  // ============================================================
  // ACESSIBILIDADE
  // ============================================================

  double get _escalaTexto =>
      AcessibilidadeService.instance.escalaTexto;

  bool get _altoContraste =>
      AcessibilidadeService.instance.altoContraste;

  Color get _fundo {
    return _altoContraste ? Colors.black : AcolleDesign.fundo;
  }

  Color get _texto {
    return _altoContraste ? Colors.white : const Color(0xFF25212B);
  }

  Color get _textoSecundario {
    return _altoContraste ? Colors.white : Colors.black87;
  }

  Color get _card {
    return _altoContraste ? Colors.black : Colors.white;
  }

  Color get _borda {
    return _altoContraste ? Colors.white : AcolleDesign.borda;
  }

  Color get _icone {
    // Mantemos o laranja também no alto contraste.
    return Colors.orange;
  }

  // ============================================================
  // NOTIFICAÇÕES
  // ============================================================

  Future<void> _verificarPermissaoNotificacao() async {
    final concedida =
        await NotificationListenerService.permissaoConcedida();

    if (!mounted) return;

    setState(() {
      _permissaoNotificacaoConcedida = concedida;
    });

    if (concedida) {
      _iniciarEscutaDeNotificacoes();
    }
  }

  Future<void> _ativarNotificationListener() async {
    await NotificationListenerService.abrirConfiguracoes();
    await _verificarPermissaoNotificacao();
  }

  void _iniciarEscutaDeNotificacoes() {
    _subscricaoNotificacoes?.cancel();

    _subscricaoNotificacoes =
        NotificationListenerService.notificacoes.listen(
      (notificacao) {
        final texto = notificacao['texto'] as String? ?? '';
        final classificacao =
            notificacao['classificacao'] as String?;

        if (texto.trim().isEmpty || classificacao == null) {
          return;
        }

        final match = _regexLink.firstMatch(texto);

        if (match == null) {
          return;
        }

        final link = match.group(0)!;

        final resultado = <String, dynamic>{
          'classificacao': classificacao,
          'risco': notificacao['risco'] ?? 0,
          'recomendacao':
              notificacao['recomendacao'] ?? '',
          'motivos': const <String>[],
        };

        setState(() {
          _linkController.text = link;
          _resultado = resultado;
          _erro = null;
        });

        _salvarResultadoDaNotificacao(
          link,
          resultado,
        );
      },
    );
  }

  Future<void> _salvarResultadoDaNotificacao(
    String link,
    Map<String, dynamic> resultado,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('verificacoes')
          .add({
        'usuarioId': user.uid,
        'tipo': 'link',
        'conteudo': link,
        'risco':
            resultado['classificacao'] ?? 'desconhecido',
        'percentual': resultado['risco'] ?? 0,
        'data': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Erro ao salvar verificação vinda da notificação: $e',
      );
    }
  }

  // ============================================================
  // ANÁLISE DO LINK
  // ============================================================

  Future<void> _analisarLink() async {
    final link = _linkController.text.trim();

    if (link.isEmpty) {
      setState(() {
        _erro = 'Digite um link para analisar.';
      });
      return;
    }

    if (!_isLinkValido(link)) {
      setState(() {
        _erro =
            'Link inválido. Digite um link que comece com http:// ou https://';
      });
      return;
    }

    setState(() {
      _carregando = true;
      _resultado = null;
      _erro = null;
    });

    try {
      final resposta =
          await AcolleApi.analisarLink(link);

      if (!mounted) return;

      setState(() {
        _resultado = resposta;
      });

      final user =
          FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('verificacoes')
            .add({
          'usuarioId': user.uid,
          'tipo': 'link',
          'conteudo': link,
          'risco':
              resposta['classificacao'] ??
                  'desconhecido',
          'percentual':
              resposta['risco'] ?? 0,
          'data':
              FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro =
            'Erro ao analisar o link. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  bool _isLinkValido(String link) {
    try {
      Uri.parse(link);

      return link.startsWith('http://') ||
          link.startsWith('https://');
    } catch (_) {
      return false;
    }
  }

  Color _corPorRisco(String classificacao) {
    switch (classificacao) {
      case 'Alto':
        return Colors.red;

      case 'Médio':
        return Colors.orange;

      case 'Baixo':
        return AcolleDesign.verde;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    AcessibilidadeService.instance.removeListener(
      _onAcessibilidadeChanged,
    );

    _linkController.dispose();

    _subscricaoNotificacoes?.cancel();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,

      appBar: AppBar(
        backgroundColor: _fundo,
        elevation: 0,

        centerTitle: true,

        iconTheme: IconThemeData(
          color: _icone,
        ),

        title: Text(
          'Verificar Link',
          style: TextStyle(
            color: _icone,
            fontWeight: FontWeight.bold,
            fontSize: 24 * _escalaTexto,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              if (!_permissaoNotificacaoConcedida)
                _buildCardAtivarAutomatico(),

              Text(
                'Verifique se um link é seguro antes de clicar',
                style: TextStyle(
                  fontSize: 18 * _escalaTexto,
                  fontWeight: FontWeight.w600,
                  color: _texto,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Cole o link completo para análise.',
                style: TextStyle(
                  fontSize: 15 * _escalaTexto,
                  color: _textoSecundario,
                ),
              ),

              const SizedBox(height: 24),

              _buildCampoLink(),

              const SizedBox(height: 20),

              _buildBotaoAnalisar(),

              if (_erro != null) ...[
                const SizedBox(height: 20),
                _buildErro(),
              ],

              if (_resultado != null) ...[
                const SizedBox(height: 24),
                _buildResultado(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CAMPO DE LINK
  // ============================================================

  Widget _buildCampoLink() {
    return TextField(
      controller: _linkController,

      style: TextStyle(
        fontSize: 18 * _escalaTexto,
        color: _texto,
      ),

      keyboardType: TextInputType.url,

      decoration: InputDecoration(
        labelText: 'Cole o link aqui',

        labelStyle: TextStyle(
          fontSize: 17 * _escalaTexto,
          color: _textoSecundario,
        ),

        hintText: 'https://exemplo.com',

        hintStyle: TextStyle(
          fontSize: 16 * _escalaTexto,
          color: _textoSecundario,
        ),

        prefixIcon: Icon(
          Icons.link,
          color: _icone,
          size: 28,
        ),

        filled: true,
        fillColor: _card,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: _borda,
            width: 1.5,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: _borda,
            width: 1.5,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: _icone,
            width: 2,
          ),
        ),

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }

  // ============================================================
  // BOTÃO ANALISAR
  // ============================================================

  Widget _buildBotaoAnalisar() {
    return SizedBox(
      height: 58,

      child: ElevatedButton.icon(
        onPressed:
            _carregando ? null : _analisarLink,

        icon: _carregando
            ? const SizedBox(
                width: 24,
                height: 24,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.search,
                size: 28,
              ),

        label: Text(
          _carregando
              ? 'Analisando...'
              : 'Analisar',
          style: TextStyle(
            fontSize: 19 * _escalaTexto,
            fontWeight: FontWeight.bold,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: _icone,
          foregroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD DE VERIFICAÇÃO AUTOMÁTICA
  // ============================================================

  Widget _buildCardAtivarAutomatico() {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 20),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: _card,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: _borda,
          width: 1.5,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: _icone,
                size: 28,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Verificação automática',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize:
                        18 * _escalaTexto,
                    color: _texto,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Ative para o Acolle analisar sozinho os links que chegam no WhatsApp e SMS, mesmo com o app fechado.',
            style: TextStyle(
              fontSize:
                  16 * _escalaTexto,
              color:
                  _textoSecundario,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,

            child: OutlinedButton(
              onPressed:
                  _ativarNotificationListener,

              style:
                  OutlinedButton.styleFrom(
                foregroundColor: _icone,

                side: BorderSide(
                  color: _icone,
                  width: 1.5,
                ),

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),

              child: Text(
                'Ativar verificação automática',
                style: TextStyle(
                  fontSize:
                      16 * _escalaTexto,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _buildErro() {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: _altoContraste
            ? Colors.black
            : Colors.red.shade50,

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color: Colors.red,
          width: 1.5,
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 28,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              _erro!,
              style: TextStyle(
                fontSize:
                    16 * _escalaTexto,
                color: Colors.red,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULTADO
  // ============================================================

  Widget _buildResultado() {
    final classificacao =
        _resultado!['classificacao']
                as String? ??
            'Desconhecido';

    final risco =
        _resultado!['risco'];

    final motivos =
        (_resultado!['motivos'] as List?) ??
            [];

    final recomendacao =
        _resultado!['recomendacao']
            as String?;

    final cor =
        _corPorRisco(classificacao);

    final IconData icone =
        classificacao == 'Alto'
            ? Icons.dangerous
            : classificacao == 'Médio'
                ? Icons.warning_amber_rounded
                : Icons.verified;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,

      children: [
        // -------------------------------
        // CLASSIFICAÇÃO
        // -------------------------------

        Container(
          padding:
              const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: _altoContraste
                ? Colors.black
                : cor.withValues(
                    alpha: 0.1,
                  ),

            borderRadius:
                BorderRadius.circular(18),

            border: Border.all(
              color: cor,
              width: 2,
            ),
          ),

          child: Column(
            children: [
              Icon(
                icone,
                color: cor,
                size: 52,
              ),

              const SizedBox(height: 12),

              Text(
                'Risco $classificacao',
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  fontSize:
                      24 * _escalaTexto,
                  fontWeight:
                      FontWeight.bold,
                  color: cor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Score: $risco%',
                style: TextStyle(
                  fontSize:
                      17 * _escalaTexto,
                  fontWeight:
                      FontWeight.w600,
                  color: cor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // -------------------------------
        // URL ANALISADA
        // -------------------------------

        Container(
          padding:
              const EdgeInsets.all(18),

          decoration: BoxDecoration(
            color: _card,

            borderRadius:
                BorderRadius.circular(16),

            border: Border.all(
              color: _borda,
              width: 1.5,
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                'URL analisada:',
                style: TextStyle(
                  fontSize:
                      16 * _escalaTexto,
                  fontWeight:
                      FontWeight.bold,
                  color: _texto,
                ),
              ),

              const SizedBox(height: 8),

              SelectableText(
                _linkController.text.trim(),

                style: TextStyle(
                  fontSize:
                      15 * _escalaTexto,
                  color:
                      _textoSecundario,
                  wordSpacing: 1,
                ),
              ),
            ],
          ),
        ),

        // -------------------------------
        // MOTIVOS
        // -------------------------------

        if (motivos.isNotEmpty) ...[
          const SizedBox(height: 16),

          Container(
            padding:
                const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: _card,

              borderRadius:
                  BorderRadius.circular(16),

              border: Border.all(
                color: _borda,
                width: 1.5,
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: _icone,
                      size: 26,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Motivos identificados:',
                        style: TextStyle(
                          fontSize:
                              16 * _escalaTexto,
                          fontWeight:
                              FontWeight.bold,
                          color: _texto,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                ...motivos.map(
                  (m) => Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 6,
                    ),

                    child: Text(
                      '• $m',
                      style: TextStyle(
                        fontSize:
                            16 * _escalaTexto,
                        height: 1.5,
                        color:
                            _textoSecundario,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // -------------------------------
        // RECOMENDAÇÃO
        // -------------------------------

        if (recomendacao != null &&
            recomendacao.isNotEmpty) ...[
          const SizedBox(height: 16),

          Container(
            padding:
                const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: _altoContraste
                  ? Colors.black
                  : Colors.amber.shade50,

              borderRadius:
                  BorderRadius.circular(16),

              border: Border.all(
                color: Colors.amber.shade700,
                width: 1.5,
              ),
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color:
                      Colors.amber.shade700,
                  size: 28,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    recomendacao,

                    style: TextStyle(
                      fontSize:
                          16 * _escalaTexto,
                      height: 1.5,

                      color: _altoContraste
                          ? Colors.white
                          : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}