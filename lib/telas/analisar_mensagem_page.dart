import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/acolle_api.dart';
import '../services/notification_listener_service.dart';
import '../services/acessibilidade_service.dart';
import '../shared/acolle_design.dart';

class AnalisarMensagemPage extends StatefulWidget {
  final String? textoInicial;
  final bool analisarAutomaticamente;
  final bool origemCapturaTela;

  const AnalisarMensagemPage({
    super.key,
    this.textoInicial,
    this.analisarAutomaticamente = false,
    this.origemCapturaTela = false,
  });

  @override
  State<AnalisarMensagemPage> createState() =>
      _AnalisarMensagemPageState();
}

class _AnalisarMensagemPageState
    extends State<AnalisarMensagemPage> with WidgetsBindingObserver {
  final TextEditingController _controller =
      TextEditingController();

  final stt.SpeechToText _speech =
      stt.SpeechToText();

  bool _speechDisponivel = false;

  bool _ouvindo = false;

  bool _carregando = false;

  Map<String, dynamic>? _resultado;

  String? _erro;

  bool _permissaoNotificacaoConcedida =
      false;

  StreamSubscription<Map<String, dynamic>>?
      _subscricaoNotificacoes;

  AcessibilidadeService get acessibilidade =>
      AcessibilidadeService.instance;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    acessibilidade.addListener(
      _atualizarTela,
    );

    _inicializarSpeech();

    _verificarPermissaoNotificacao();

    final textoInicial =
    widget.textoInicial?.trim();

    if (textoInicial != null &&
        textoInicial.isNotEmpty) {

      _controller.text = textoInicial;

      _controller.selection =
          TextSelection.fromPosition(
        TextPosition(
          offset: _controller.text.length,
        ),
      );

      if (widget.analisarAutomaticamente) {

        WidgetsBinding.instance
            .addPostFrameCallback((_) {

          if (!mounted) return;

          _analisar();
        });
      }
    }


  }

  // ============================================================
  // ATUALIZAR ACESSIBILIDADE
  // ============================================================

  void _atualizarTela() {
    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // SPEECH
  // ============================================================

  Future<void> _inicializarSpeech() async {
    _speechDisponivel =
        await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' ||
            status == 'notListening') {
          if (!mounted) return;

          setState(() {
            _ouvindo = false;
          });
        }
      },
      onError: (_) {
        if (!mounted) return;

        setState(() {
          _ouvindo = false;
        });
      },
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _alternarGravacao() async {
    if (!_speechDisponivel) {
      if (!mounted) return;

      setState(() {
        _erro =
            'Reconhecimento de voz não disponível neste dispositivo.';
      });

      return;
    }

    if (_ouvindo) {
      await _speech.stop();

      if (!mounted) return;

      setState(() {
        _ouvindo = false;
      });

      return;
    }

    setState(() {
      _ouvindo = true;
      _erro = null;
    });

    await _speech.listen(
      onResult: (resultado) {
        if (!mounted) return;

        setState(() {
          _controller.text =
              resultado.recognizedWords;

          _controller.selection =
              TextSelection.fromPosition(
            TextPosition(
              offset:
                  _controller.text.length,
            ),
          );
        });
      },
    );
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

  Future<void>
      _verificarPermissaoNotificacao() async {
    final concedida =
        await NotificationListenerService
              .verificacaoAtiva();

    if (!mounted) return;

    setState(() {
      _permissaoNotificacaoConcedida =
          concedida;
    });

    if (concedida) {
      _iniciarEscutaDeNotificacoes();
    }
  }

  Future<void>
      _ativarNotificationListener() async {
    await NotificationListenerService
        .configurarVerificacao();

    await _verificarPermissaoNotificacao();
  }

  void _iniciarEscutaDeNotificacoes() {
    _subscricaoNotificacoes?.cancel();

    _subscricaoNotificacoes =
        NotificationListenerService
            .notificacoes
            .listen(
      (notificacao) {
        // Uma notificação não pode substituir a análise que a pessoa está lendo.
        if (_controller.text.trim().isNotEmpty || _resultado != null) return;
        final texto =
            notificacao['texto']
                    as String? ??
                '';

        final classificacao =
            notificacao['classificacao']
                as String?;

        if (texto.trim().isEmpty ||
            classificacao == null) {
          return;
        }

        final resultado =
            <String, dynamic>{
          'classificacao':
              classificacao,

          'risco':
              notificacao['risco'] ??
                  0,

          'recomendacao':
              notificacao[
                      'recomendacao'] ??
                  '',

          'motivos':
              const <String>[],
        };

        if (!mounted) return;

        setState(() {
          _controller.text = texto;

          _resultado = resultado;

          _erro = null;
        });

        _salvarResultadoDaNotificacao(
          texto,
          resultado,
        );
      },
    );
  }

  Future<void>
      _salvarResultadoDaNotificacao(
    String texto,
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

        'tipo': 'mensagem',

        'conteudo': texto,

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
        'Erro ao salvar verificação: $e',
      );
    }
  }

  // ============================================================
  // LINKS ENCONTRADOS NO TEXTO
  // ============================================================

  static final RegExp _regexLinks = RegExp(
    r'(?:https?:\/\/|www\.)[^\s<>"]+|'
    r'\b[a-z0-9][a-z0-9\-]*(?:\.[a-z0-9\-]+)*\.'
    r'(?:com|net|org|br|io|xyz|tk|top|online|site|club|info|link|app|me|co|ly|gl|cc|ru|cn|click|shop|store|live|vip)'
    r'(?:\/[^\s<>"]*)?',
    caseSensitive: false,
  );

  List<String> _extrairLinks(String texto) {
    final encontrados = <String>[];

    for (final m in _regexLinks.allMatches(texto)) {
      // Ignora endereços de e-mail (ex.: nome@gmail.com).
      if (m.start > 0 && texto[m.start - 1] == '@') continue;

      var link = m.group(0)!.replaceAll(
            RegExp(r'[.,;:!?)\]]+$'),
            '',
          );
      if (link.length < 4) continue;

      if (!link.toLowerCase().startsWith('http')) {
        link = 'https://$link';
      }

      if (!encontrados.contains(link)) encontrados.add(link);
      if (encontrados.length >= 3) break;
    }

    return encontrados;
  }

  Future<void> _incorporarAnaliseDeLinks(
    String texto,
    Map<String, dynamic> resultado,
  ) async {
    final links = _extrairLinks(texto);
    if (links.isEmpty) return;

    final analises = await Future.wait(
      links.map((link) async {
        try {
          return await AcolleApi.analisarLink(link);
        } catch (_) {
          return null;
        }
      }),
    );

    var riscoFinal =
        (resultado['risco'] as num?)?.toInt() ?? 0;
    final motivos = List<dynamic>.from(
      (resultado['motivos'] as List?) ?? const [],
    );
    var linkPerigoso = false;

    for (var i = 0; i < links.length; i++) {
      final a = analises[i];
      if (a == null) continue;

      final risco = (a['risco'] as num?)?.toInt() ?? 0;
      final host = Uri.tryParse(links[i])?.host ?? links[i];
      final motivosLink = (a['motivos'] as List?) ?? const [];
      final detalhe =
          motivosLink.isNotEmpty ? ' — ${motivosLink.first}' : '';

      if (risco >= 30) {
        motivos.add('Link suspeito ($host): risco $risco%$detalhe');
        if (risco >= 70) linkPerigoso = true;
      } else {
        motivos.add('Link verificado ($host): sem sinais claros de golpe.');
      }

      if (risco > riscoFinal) riscoFinal = risco;
    }

    resultado['risco'] = riscoFinal;
    resultado['motivos'] = motivos;
    resultado['classificacao'] = riscoFinal >= 70
        ? 'Alto'
        : riscoFinal >= 30
            ? 'Médio'
            : 'Baixo';

    if (linkPerigoso) {
      resultado['recomendacao'] =
          'Não toque nos links desta mensagem. '
          '${resultado['recomendacao'] ?? ''}'.trim();
    }
  }

  // ============================================================
  // ANALISAR
  // ============================================================

  Future<void> _analisar() async {
    final mensagem =
        _controller.text.trim();

    if (mensagem.isEmpty) {
      AcolleDesign.snackbar(
        context,
        'Digite ou fale uma mensagem para analisar.',
      );

      return;
    }

    setState(() {
      _carregando = true;

      _resultado = null;

      _erro = null;
    });

    try {
      final resposta =
          await AcolleApi.analisarConversa(
        mensagem,
      );

      // Verifica também cada link encontrado no texto e incorpora
      // o resultado (risco, motivos e recomendação) à análise.
      await _incorporarAnaliseDeLinks(
        mensagem,
        resposta,
      );

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

          'tipo': widget.origemCapturaTela
              ? 'tela'
              : 'mensagem',

          'conteudo': widget.origemCapturaTela
              ? '[Conteúdo extraído da tela]'
              : mensagem,

          'risco':
              resposta['classificacao'] ??
                  'desconhecido',

          'percentual':
              resposta['risco'] ?? 0,

          'data':
              FieldValue.serverTimestamp(),
        });
      }
    } on AcolleApiException catch (e) {
      debugPrint(
        'Erro Acolle API: $e',
      );

      if (!mounted) return;

      setState(() {
        _erro =
            'Não foi possível analisar agora. Detalhe: $e';
      });
    } catch (e) {
      debugPrint(
        'Erro inesperado: $e',
      );

      if (!mounted) return;

      setState(() {
        _erro =
            'Ocorreu um erro inesperado. Tente novamente.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });
    }
  }

  // ============================================================
  // COR DO RISCO
  // ============================================================

  Color _corPorRisco(
    String? classificacao,
  ) {
    switch (classificacao) {
      case 'Alto':
        return AcolleDesign.vermelho;

      case 'Médio':
        return AcolleDesign.laranja;

      case 'Baixo':
        return AcolleDesign.verde;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final altoContraste =
        acessibilidade.altoContraste;

    final corFundo =
        AcolleDesign.corFundo(
      altoContraste,
    );

    final corTexto =
        AcolleDesign.corTexto(
      altoContraste,
    );

    final corTextoSecundario =
        AcolleDesign.corTextoSecundario(
      altoContraste,
    );

    final corDestaque =
        AcolleDesign.corIcone(
      altoContraste,
    );

    return Scaffold(
      backgroundColor: corFundo,

      appBar:
          AcolleDesign.appBarPadrao(
        'Analisar Mensagem',
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              if (NotificationListenerService.disponivel && !_permissaoNotificacaoConcedida)
                _buildCardAtivarAutomatico(
                  altoContraste,
                  corTexto,
                  corDestaque,
                ),

              Text(
                'Cole a mensagem ou toque no microfone para falar:',
                style:
                    AcolleDesign.texto(
                  tamanho: 16,
                  peso:
                      FontWeight.w500,
                  cor: corTexto,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller: _controller,

                maxLines: 8,

                style:
                    AcolleDesign.texto(
                  tamanho: 17,
                  cor: corTexto,
                ),

                decoration:
                    AcolleDesign
                        .inputDecoration(
                  hint:
                      'Cole a conversa aqui ou use o microfone...',

                  icone:
                      Icons.chat_bubble_outline_rounded,

                  altoContraste:
                      altoContraste,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              _buildMicrofone(
                altoContraste,
                corDestaque,
              ),

              const SizedBox(
                height: 6,
              ),

              Center(
                child: Text(
                  _ouvindo
                      ? 'Ouvindo... toque para parar'
                      : 'Toque para falar',

                  style:
                      AcolleDesign.texto(
                    tamanho: 15,
                    cor:
                        corTextoSecundario,
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              AcolleDesign.botaoPrimario(
                texto: 'Analisar',
                icone: Icons.manage_search_rounded,
                carregando: _carregando,
                onPressed: _analisar,
              ),

              const SizedBox(
                height: 24,
              ),

              if (_erro != null)
                _buildErro(
                  altoContraste,
                  _erro!,
                ),

              if (_resultado != null)
                _buildResultado(
                  altoContraste,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD AUTOMÁTICO
  // ============================================================

  Widget _buildCardAtivarAutomatico(
    bool altoContraste,
    Color corTexto,
    Color corDestaque,
  ) {
    return AcolleDesign.cartao(
      margem:
          const EdgeInsets.only(
        bottom: 20,
      ),

      filho: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                Icons
                    .notifications_active_outlined,

                color: corDestaque,

                size: 28,
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  'Verificação automática',

                  style:
                      AcolleDesign.texto(
                    tamanho: 16,
                    peso:
                        FontWeight.bold,
                    cor: corTexto,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Ative para o Acolle analisar sozinho as mensagens que chegam no WhatsApp e SMS, mesmo com o app fechado.',

            style:
                AcolleDesign.texto(
              tamanho: 15,
              cor: corTexto,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          SizedBox(
            width: double.infinity,

            child: OutlinedButton(
              onPressed:
                  _ativarNotificationListener,

              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    corDestaque,

                side: BorderSide(
                  color: corDestaque,
                  width: 2,
                ),

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),

              child: Text(
                'Ativar verificação automática',

                style:
                    AcolleDesign.texto(
                  tamanho: 16,
                  peso:
                      FontWeight.bold,
                  cor: corDestaque,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MICROFONE
  // ============================================================

  Widget _buildMicrofone(
    bool altoContraste,
    Color corDestaque,
  ) {
    return Semantics(
      button: true,

      label: _ouvindo
          ? 'Parar gravação de voz'
          : 'Iniciar gravação de voz',

      child: Center(
        child: GestureDetector(
          onTap:
              _alternarGravacao,

          child: Container(
            width: 70,

            height: 70,

            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,

              color: _ouvindo
                  ? AcolleDesign.vermelho
                  : corDestaque,

              border:
                  altoContraste
                      ? Border.all(
                          color:
                              Colors.white,
                          width: 2,
                        )
                      : null,
            ),

            child: Icon(
              _ouvindo
                  ? Icons.mic_rounded
                  : Icons.mic_none_rounded,

              color:
                  Colors.white,

              size: 34,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _buildErro(
    bool altoContraste,
    String mensagem,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(14),

      decoration:
          BoxDecoration(
        color: altoContraste
            ? Colors.black
            : Colors.red.shade50,

        borderRadius:
            BorderRadius.circular(12),

        border: Border.all(
          color:
              AcolleDesign.vermelho,

          width: 1.5,
        ),
      ),

      child: Text(
        mensagem,

        style:
            AcolleDesign.texto(
          tamanho: 16,

          peso:
              FontWeight.w500,

          cor:
              AcolleDesign.vermelho,
        ),
      ),
    );
  }

  // ============================================================
  // RESULTADO
  // ============================================================

  Widget _buildResultado(
    bool altoContraste,
  ) {
    final classificacao =
        _resultado![
                'classificacao']
            as String? ??
        'Desconhecido';

    final motivos =
        (_resultado!['motivos']
                as List?) ??
            [];

    final recomendacao =
        _resultado![
                'recomendacao']
            as String?;

    final cor =
        _corPorRisco(
      classificacao,
    );

    return AcolleDesign.cartao(
      margem:
          const EdgeInsets.only(
        top: 4,
      ),

      borda: Border.all(
        color: altoContraste
            ? Colors.white
            : cor,

        width: 2,
      ),

      filho: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                classificacao ==
                        'Alto'
                    ? Icons
                        .warning_amber_rounded
                    : Icons
                        .shield_outlined,

                color: cor,

                size: 32,
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  classificacao == 'Alto'
                      ? 'Pare e confira: sinais de golpe'
                      : classificacao == 'Médio'
                          ? 'Confira esta mensagem com cuidado'
                          : 'Nenhum sinal forte identificado',

                  style:
                      AcolleDesign.texto(
                    tamanho: 20,
                    peso:
                        FontWeight.bold,
                    cor: cor,
                  ),
                ),
              ),
            ],
          ),

          if (motivos.isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),

            Text(
              'Motivos identificados:',

              style:
                  AcolleDesign.texto(
                tamanho: 16,
                peso:
                    FontWeight.w600,
                cor:
                    AcolleDesign.corTexto(
                  altoContraste,
                ),
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            ...motivos.map(
              (motivo) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 4,
                ),

                child: Text(
                  '• $motivo',

                  style:
                      AcolleDesign.texto(
                    tamanho: 16,
                    cor:
                        AcolleDesign.corTexto(
                      altoContraste,
                    ),
                  ),
                ),
              ),
            ),
          ],

          if (recomendacao != null &&
              recomendacao.isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),

            Text(
              'Recomendação:',

              style:
                  AcolleDesign.texto(
                tamanho: 16,
                peso:
                    FontWeight.w600,
                cor:
                    AcolleDesign.corTexto(
                  altoContraste,
                ),
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              recomendacao,

              style:
                  AcolleDesign.texto(
                tamanho: 16,
                cor:
                    AcolleDesign.corTexto(
                  altoContraste,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    acessibilidade.removeListener(
      _atualizarTela,
    );

    _speech.stop();

    _controller.dispose();

    _subscricaoNotificacoes?.cancel();

    super.dispose();
  }
}
