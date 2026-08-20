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
  const AnalisarMensagemPage({
    super.key,
  });

  @override
  State<AnalisarMensagemPage> createState() =>
      _AnalisarMensagemPageState();
}

class _AnalisarMensagemPageState
    extends State<AnalisarMensagemPage> {
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

    acessibilidade.addListener(
      _atualizarTela,
    );

    _inicializarSpeech();

    _verificarPermissaoNotificacao();
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

  // ============================================================
  // NOTIFICAÇÕES
  // ============================================================

  Future<void>
      _verificarPermissaoNotificacao() async {
    final concedida =
        await NotificationListenerService
            .permissaoConcedida();

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
        .abrirConfiguracoes();

    await _verificarPermissaoNotificacao();
  }

  void _iniciarEscutaDeNotificacoes() {
    _subscricaoNotificacoes?.cancel();

    _subscricaoNotificacoes =
        NotificationListenerService
            .notificacoes
            .listen(
      (notificacao) {
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

          'tipo': 'mensagem',

          'conteudo': mensagem,

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
              if (!_permissaoNotificacaoConcedida)
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
                      Icons.message_outlined,

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
                icone: Icons.search,
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
                  ? Icons.mic
                  : Icons.mic_none,

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

    final risco =
        _resultado!['risco'] ?? 0;

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
                  'Risco $classificacao ($risco%)',

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
    acessibilidade.removeListener(
      _atualizarTela,
    );

    _speech.stop();

    _controller.dispose();

    _subscricaoNotificacoes?.cancel();

    super.dispose();
  }
}