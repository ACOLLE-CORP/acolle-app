import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/acolle_design.dart';
import '../shared/extrair_links.dart';
import '../services/acolle_api.dart';
import '../services/acessibilidade_service.dart';
import '../services/notification_listener_service.dart';

class VerificarLinkPage extends StatefulWidget {
  /// Quando aberto pelo botão flutuante: pega o link copiado e já verifica.
  final bool usarAreaDeTransferencia;

  /// Texto lido da tela (OCR) pelo botão flutuante; null = abertura normal.
  final String? textoDaTela;

  const VerificarLinkPage({
    super.key,
    this.usarAreaDeTransferencia = false,
    this.textoDaTela,
  });

  @override
  State<VerificarLinkPage> createState() => _VerificarLinkPageState();
}

class _VerificarLinkPageState extends State<VerificarLinkPage> with WidgetsBindingObserver {
  final TextEditingController _linkController =
      TextEditingController();

  bool _carregando = false;
  List<String> _linksDaTela = const [];
  Map<String, dynamic>? _resultado;
  String? _erro;

  bool _permissaoNotificacaoConcedida = false;

  StreamSubscription<Map<String, dynamic>>?
      _subscricaoNotificacoes;

  static final RegExp _regexLink = RegExp(
    r'(https?:\/\/[^\s]+)',
    caseSensitive: false,
  );

  // ============================================================
  // ACESSIBILIDADE
  // ============================================================

  bool get _altoContraste =>
      AcolleDesign.altoContraste;

  double get _escalaTexto =>
      AcolleDesign.escalaTexto;

  Color get _texto =>
      AcolleDesign.corTexto(_altoContraste);

  Color get _textoSecundario =>
      AcolleDesign.corTextoSecundario(
        _altoContraste,
      );

  Color get _icone =>
      AcolleDesign.corIcone(_altoContraste);

  Color get _card =>
      AcolleDesign.corCard(_altoContraste);

  Color get _borda =>
      AcolleDesign.corBorda(_altoContraste);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    AcessibilidadeService.instance.addListener(
      _onAcessibilidadeChanged,
    );

    AcessibilidadeService.instance.carregar();

    _verificarPermissaoNotificacao();

    if (widget.textoDaTela != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _usarLinksDaTela(widget.textoDaTela!);
      });
    } else if (widget.usarAreaDeTransferencia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _colarLinkCopiado();
      });
    }
  }

  Future<void> _usarLinksDaTela(String texto) async {
    final links = extrairLinks(texto);

    if (links.isEmpty) {
      setState(() {
        _erro = 'Não encontrei nenhum link nesta tela. '
            'Copie o link, volte aqui e cole no campo abaixo.';
      });
      return;
    }

    setState(() => _linksDaTela = links);
    _linkController.text = links.first;
    await _analisarLink();
  }

  void _escolherLinkDaTela(String link) {
    _linkController.text = link;
    _analisarLink();
  }

  Future<void> _colarLinkCopiado() async {
    try {
      final dados = await Clipboard.getData(Clipboard.kTextPlain);
      final texto = dados?.text?.trim() ?? '';
      if (texto.isEmpty || !mounted) return;

      final m = RegExp(
        r'(?:https?:\/\/|www\.)[^\s<>"]+|\b[a-z0-9][a-z0-9\-]*(?:\.[a-z0-9\-]+)*\.[a-z]{2,}(?:\/[^\s<>"]*)?',
        caseSensitive: false,
      ).firstMatch(texto);
      if (m == null) return;

      _linkController.text = m.group(0)!;
      await _analisarLink();
    } catch (e) {
      debugPrint('Erro ao colar link: $e');
    }
  }

  void _onAcessibilidadeChanged() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verificarPermissaoNotificacao();
    }
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
        if (_linkController.text.trim().isNotEmpty || _resultado != null) return;
        final texto =
            notificacao['texto'] as String? ?? '';

        final classificacao =
            notificacao['classificacao'] as String?;

        if (texto.trim().isEmpty ||
            classificacao == null) {
          return;
        }

        final match =
            _regexLink.firstMatch(texto);

        if (match == null) {
          return;
        }

        final link = match.group(0)!;

        final resultado =
            <String, dynamic>{
          'classificacao':
              classificacao,
          'risco':
              notificacao['risco'] ?? 0,
          'recomendacao':
              notificacao['recomendacao'] ?? '',
          'motivos':
              const <String>[],
        };

        if (!mounted) return;

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
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('verificacoes')
          .add({
        'usuarioId': user.uid,
        'tipo': 'link',
        'conteudo': link,
        'risco':
            resultado['classificacao'] ??
                'desconhecido',
        'percentual':
            resultado['risco'] ?? 0,
        'data':
            FieldValue.serverTimestamp(),
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
    var link =
        _linkController.text.trim();

    // Aceita links sem http:// (ex.: bit.ly/abc, www.site.com).
    if (link.isNotEmpty &&
        !link.toLowerCase().startsWith('http') &&
        !link.contains(' ') &&
        link.contains('.')) {
      link = 'https://$link';
      _linkController.text = link;
    }

    if (link.isEmpty) {
      setState(() {
        _erro =
            'Digite um link para analisar.';
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
      final uri = Uri.parse(link);

      return uri.hasScheme &&
          (uri.scheme == 'http' ||
              uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // COR DO RISCO
  // ============================================================

  Color _corPorRisco(
    String classificacao,
  ) {
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
    WidgetsBinding.instance.removeObserver(this);
    AcessibilidadeService.instance
        .removeListener(
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
      backgroundColor:
          AcolleDesign.corFundo(
        _altoContraste,
      ),

      appBar:
          AcolleDesign.appBarPadrao(
        'Verificar Link',
        centralizado: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              if (!_permissaoNotificacaoConcedida)
                _buildCardAtivarAutomatico(),

              Text(
                'Verifique se um link é seguro antes de clicar',
                style: TextStyle(
                  fontSize:
                      18 * _escalaTexto,
                  fontWeight:
                      FontWeight.w600,
                  color: _texto,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Cole o link completo para análise (pode ser sem http://).',
                style: TextStyle(
                  fontSize:
                      15 * _escalaTexto,
                  color:
                      _textoSecundario,
                ),
              ),

              const SizedBox(height: 24),

              if (_linksDaTela.length > 1) ...[
                Text(
                  'Links encontrados na tela (toque para verificar):',
                  style: TextStyle(
                    fontSize: 15 * _escalaTexto,
                    color: _textoSecundario,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final l in _linksDaTela)
                      ActionChip(
                        label: Text(
                          l.replaceFirst(RegExp(r'^https?://'), ''),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => _escolherLinkDaTela(l),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

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
        fontSize:
            18 * _escalaTexto,
        color: _texto,
      ),

      keyboardType:
          TextInputType.url,

      decoration: AcolleDesign.inputDecoration(
        label: 'Cole o link aqui',
        hint: 'https://exemplo.com',
        icone: Icons.link_rounded,
        altoContraste:
            _altoContraste,
      ),
    );
  }

  // ============================================================
  // BOTÃO ANALISAR
  // ============================================================

  Widget _buildBotaoAnalisar() {
    return AcolleDesign.botaoPrimario(
      texto: _carregando
          ? 'Analisando...'
          : 'Analisar',
      icone: Icons.manage_search_rounded,
      carregando: _carregando,
      onPressed:
          _carregando
              ? null
              : _analisarLink,
    );
  }

  // ============================================================
  // CARD DE VERIFICAÇÃO AUTOMÁTICA
  // ============================================================

  Widget _buildCardAtivarAutomatico() {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 20,
      ),

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
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
                Icons.notifications_active_rounded,
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
              height: 1.5,
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
                textAlign:
                    TextAlign.center,
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
      padding:
          const EdgeInsets.all(16),

      decoration:
          BoxDecoration(
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
            Icons.error_outline_rounded,
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

    final motivos =
        (_resultado!['motivos']
                as List?) ??
            [];

    final recomendacao =
        _resultado!['recomendacao']
            as String?;

    final cor =
        _corPorRisco(
      classificacao,
    );

    final IconData icone =
        classificacao == 'Alto'
            ? Icons.dangerous_rounded
            : classificacao == 'Médio'
                ? Icons.warning_amber_rounded
                : Icons.verified_rounded;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,

      children: [
        // ======================================================
        // CLASSIFICAÇÃO
        // ======================================================

        Container(
          padding:
              const EdgeInsets.all(20),

          decoration:
              BoxDecoration(
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
                'Confirme a origem antes de abrir o link.',
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

        // ======================================================
        // URL ANALISADA
        // ======================================================

        Container(
          padding:
              const EdgeInsets.all(18),

          decoration:
              BoxDecoration(
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

        // ======================================================
        // MOTIVOS
        // ======================================================

        if (motivos.isNotEmpty) ...[
          const SizedBox(height: 16),

          Container(
            padding:
                const EdgeInsets.all(18),

            decoration:
                BoxDecoration(
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
                      Icons.info_outline_rounded,
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

        // ======================================================
        // RECOMENDAÇÃO
        // ======================================================

        if (recomendacao != null &&
            recomendacao.isNotEmpty) ...[
          const SizedBox(height: 16),

          Container(
            padding:
                const EdgeInsets.all(18),

            decoration:
                BoxDecoration(
              color: _altoContraste
                  ? Colors.black
                  : Colors.amber.shade50,

              borderRadius:
                  BorderRadius.circular(16),

              border: Border.all(
                color:
                    Colors.amber.shade700,
                width: 1.5,
              ),
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
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
                          : Colors.amber
                              .shade900,
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
