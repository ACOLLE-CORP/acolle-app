import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../shared/acolle_design.dart';
import '../services/acessibilidade_service.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _filtro = 'todos';

  StreamController<int>? _tick;
  int _tickValue = 0;

  @override
  void initState() {
    super.initState();

    _tick = StreamController<int>.broadcast();

    AcessibilidadeService.instance.addListener(
      _onAcessibilidadeChanged,
    );
  }

  void _onAcessibilidadeChanged() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    AcessibilidadeService.instance.removeListener(
      _onAcessibilidadeChanged,
    );

    _tick?.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acessibilidade = AcessibilidadeService.instance;
    final altoContraste = acessibilidade.altoContraste;

    final fundo = AcolleDesign.corFundo(altoContraste);
    final texto = AcolleDesign.corTexto(altoContraste);
    final textoSecundario =
        AcolleDesign.corTextoSecundario(altoContraste);
    final card = AcolleDesign.corCard(altoContraste);
    final borda = AcolleDesign.corBorda(altoContraste);
    final destaque = AcolleDesign.corIcone(altoContraste);

    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: fundo,
        appBar: AcolleDesign.appBarPadrao(
          'Histórico',
          centralizado: true,
        ),
        body: Center(
          child: Text(
            'Usuário não autenticado.',
            style: AcolleDesign.texto(
              tamanho: 18,
            ),
          ),
        ),
      );
    }

    final userId = user.uid;

    return Scaffold(
      backgroundColor: fundo,

      appBar: AcolleDesign.appBarPadrao(
        'Histórico',
        centralizado: true,
      ),

      body: Column(
        children: [
          // ============================================================
          // FILTROS
          // ============================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFiltroChip(
                    'Todos',
                    'todos',
                    altoContraste,
                    texto,
                    destaque,
                    card,
                    borda,
                  ),

                  const SizedBox(width: 8),

                  _buildFiltroChip(
                    'Mensagens',
                    'mensagem',
                    altoContraste,
                    texto,
                    destaque,
                    card,
                    borda,
                  ),

                  const SizedBox(width: 8),

                  _buildFiltroChip(
                    'Links',
                    'link',
                    altoContraste,
                    texto,
                    destaque,
                    card,
                    borda,
                  ),

                  const SizedBox(width: 8),

                  _buildFiltroChip(
                    'Chamadas',
                    'chamada',
                    altoContraste,
                    texto,
                    destaque,
                    card,
                    borda,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // ============================================================
          // HISTÓRICO
          // ============================================================

          Expanded(
            child: StreamBuilder<int>(
              stream: _tick?.stream,
              initialData: 0,
              builder: (context, tickSnap) {
                final tick = tickSnap.data ?? 0;

                if (tick != _tickValue) {
                  _tickValue = tick;
                }

                return RefreshIndicator(
                  color: destaque,
                  backgroundColor: card,

                  onRefresh: () async {
                    _tick?.add(_tickValue + 1);

                    await Future.delayed(
                      const Duration(seconds: 2),
                    );
                  },

                  child: StreamBuilder<QuerySnapshot>(
                    stream: _construirStream(userId),

                    builder: (context, snapshot) {
                      // ==================================================
                      // ERRO
                      // ==================================================

                      if (snapshot.hasError) {
                        final msg = snapshot.error.toString();

                        final waiting =
                            msg.contains('failed-precondition') ||
                            msg.contains('building') ||
                            msg.contains('currently building');

                        if (waiting) {
                          Future.delayed(
                            const Duration(seconds: 4),
                            () {
                              if (!mounted) return;

                              _tick?.add(
                                _tickValue + 1,
                              );
                            },
                          );

                          return ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),

                            children: [
                              const SizedBox(height: 80),

                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),

                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.hourglass_top,
                                        size: 72,
                                        color: destaque,
                                      ),

                                      const SizedBox(height: 16),

                                      Text(
                                        'Preparando índice do Firestore...\n'
                                        'Aguarde alguns segundos.',

                                        textAlign:
                                            TextAlign.center,

                                        style:
                                            AcolleDesign.texto(
                                          tamanho: 17,
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      Text(
                                        'Puxe para baixo para tentar de novo',

                                        textAlign:
                                            TextAlign.center,

                                        style:
                                            AcolleDesign.texto(
                                          tamanho: 14,
                                          cor:
                                              textoSecundario,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),

                          children: [
                            const SizedBox(height: 80),

                            Padding(
                              padding:
                                  const EdgeInsets.all(20),

                              child: SelectableText(
                                'ERRO ao carregar histórico:\n'
                                '${snapshot.error}',

                                style:
                                    AcolleDesign.texto(
                                  tamanho: 13,
                                  cor:
                                      Colors.red,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // ==================================================
                      // CARREGANDO
                      // ==================================================

                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),

                          children: [
                            const SizedBox(height: 80),

                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(20),

                                child: Column(
                                  children: [
                                    CircularProgressIndicator(
                                      color: destaque,
                                    ),

                                    const SizedBox(height: 20),

                                    Text(
                                      'Carregando histórico...',

                                      style:
                                          AcolleDesign.texto(
                                        tamanho: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      final docs =
                          snapshot.data?.docs ?? [];

                      // ==================================================
                      // VAZIO
                      // ==================================================

                      if (docs.isEmpty) {
                        return ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),

                          children: [
                            const SizedBox(height: 90),

                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(24),

                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 70,
                                      color:
                                          textoSecundario,
                                    ),

                                    const SizedBox(height: 16),

                                    Text(
                                      'Nenhum histórico encontrado',

                                      textAlign:
                                          TextAlign.center,

                                      style:
                                          AcolleDesign.texto(
                                        tamanho: 19,
                                        peso:
                                            FontWeight.bold,
                                        cor: texto,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      'As verificações realizadas '
                                      'aparecerão aqui.',

                                      textAlign:
                                          TextAlign.center,

                                      style:
                                          AcolleDesign.texto(
                                        tamanho: 16,
                                        cor:
                                            textoSecundario,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // ==================================================
                      // LISTA
                      // ==================================================

                      return ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),

                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          24,
                        ),

                        itemCount: docs.length,

                        itemBuilder:
                            (context, index) {
                          final doc = docs[index];

                          final dados = doc.data()
                              as Map<String, dynamic>;

                          return _buildItemHistorico(
                            dados,
                            doc.id,
                            altoContraste,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // STREAM FIRESTORE
  // ==============================================================

  Stream<QuerySnapshot> _construirStream(
    String userId,
  ) {
    var query = _firestore
        .collection('verificacoes')
        .where(
          'usuarioId',
          isEqualTo: userId,
        )
        .orderBy(
          'data',
          descending: true,
        );

    if (_filtro != 'todos') {
      query = query.where(
        'tipo',
        isEqualTo: _filtro,
      );
    }

    return query
        .limit(50)
        .snapshots();
  }

  // ==============================================================
  // FILTRO
  // ==============================================================

  Widget _buildFiltroChip(
    String label,
    String valor,
    bool altoContraste,
    Color texto,
    Color destaque,
    Color card,
    Color borda,
  ) {
    final ativo = _filtro == valor;

    return FilterChip(
      label: Text(
        label,

        style: AcolleDesign.texto(
          tamanho: 15,
          peso: FontWeight.w600,
          cor: ativo
              ? Colors.black
              : texto,
        ),
      ),

      selected: ativo,

      onSelected: (selecionado) {
        setState(() {
          _filtro = valor;
        });
      },

      backgroundColor: card,

      selectedColor: destaque,

      checkmarkColor: Colors.black,

      side: BorderSide(
        color: ativo
            ? destaque
            : borda,
        width: ativo ? 2 : 1,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
    );
  }

  // ==============================================================
  // ITEM DO HISTÓRICO
  // ==============================================================

  Widget _buildItemHistorico(
    Map<String, dynamic> dados,
    String docId,
    bool altoContraste,
  ) {
    final tipo =
        dados['tipo'] as String? ??
            'desconhecido';

    final conteudo =
        dados['conteudo'] as String? ??
            '';

    final risco =
        dados['risco'] as String? ??
            'desconhecido';

    final percentual =
        dados['percentual'] as int? ??
            0;

    final data =
        (dados['data'] as Timestamp?)
                ?.toDate() ??
            DateTime.now();

    final formatada =
        DateFormat(
          'dd/MM/yyyy HH:mm',
        ).format(data);

    IconData icone = Icons.info_outline;

    if (tipo == 'mensagem') {
      icone = Icons.message_outlined;
    } else if (tipo == 'link') {
      icone = Icons.link;
    } else if (tipo == 'chamada') {
      icone = Icons.phone_missed;
    }

    Color cor = _corPorRisco(
      risco,
      altoContraste,
    );

    final texto = AcolleDesign.corTexto(
      altoContraste,
    );

    final textoSecundario =
        AcolleDesign.corTextoSecundario(
      altoContraste,
    );

    final card = AcolleDesign.corCard(
      altoContraste,
    );

    final borda = AcolleDesign.corBorda(
      altoContraste,
    );

    return GestureDetector(
      onLongPress: () {
        _mostrarMenuOpcoes(
          docId,
          altoContraste,
        );
      },

      child: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: card,

          borderRadius:
              BorderRadius.circular(16),

          border: Border.all(
            color: borda,
            width: 1.2,
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ========================================================
            // CABEÇALHO
            // ========================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color:
                        cor.withValues(
                      alpha: 0.15,
                    ),

                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  child: Center(
                    child: Icon(
                      icone,
                      color: cor,
                      size: 26,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        _obterTituloTipo(tipo),

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            AcolleDesign.texto(
                          tamanho: 16,
                          peso:
                              FontWeight.bold,
                          cor: texto,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        formatada,

                        style:
                            AcolleDesign.texto(
                          tamanho: 12,
                          cor:
                              textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ====================================================
                // PERCENTUAL
                // ====================================================

                Container(
                  constraints:
                      const BoxConstraints(
                    minWidth: 52,
                  ),

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color:
                        cor.withValues(
                      alpha: 0.15,
                    ),

                    borderRadius:
                        BorderRadius.circular(20),
                  ),

                  child: Text(
                    '$percentual%',

                    textAlign:
                        TextAlign.center,

                    style:
                        AcolleDesign.texto(
                      tamanho: 13,
                      peso:
                          FontWeight.bold,
                      cor: cor,
                    ),
                  ),
                ),
              ],
            ),

            // ========================================================
            // CONTEÚDO
            // ========================================================

            if (conteudo.isNotEmpty) ...[
              const SizedBox(height: 12),

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color:
                      altoContraste
                          ? Colors.black
                          : Colors.white,

                  borderRadius:
                      BorderRadius.circular(12),

                  border: Border.all(
                    color: borda,
                  ),
                ),

                child: Text(
                  conteudo.length > 100
                      ? '${conteudo.substring(0, 100)}...'
                      : conteudo,

                  maxLines: 3,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      AcolleDesign.texto(
                    tamanho: 13,
                    cor:
                        textoSecundario,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ========================================================
            // RISCO
            // ========================================================

            Row(
              children: [
                Icon(
                  _iconePorRisco(risco),
                  size: 18,
                  color: cor,
                ),

                const SizedBox(width: 6),

                Flexible(
                  child: Text(
                    _obterTextoRisco(risco),

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        AcolleDesign.texto(
                      tamanho: 13,
                      peso:
                          FontWeight.w600,
                      cor: cor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // COR DO RISCO
  // ==============================================================

  Color _corPorRisco(
    String risco,
    bool altoContraste,
  ) {
    if (risco == 'alto' ||
        risco == 'malicioso') {
      return Colors.red;
    }

    if (risco == 'médio' ||
        risco == 'suspeito') {
      return Colors.orange;
    }

    if (risco == 'baixo' ||
        risco == 'confiável') {
      return altoContraste
          ? Colors.lightGreenAccent
          : AcolleDesign.verde;
    }

    return AcolleDesign.corTextoSecundario(
      altoContraste,
    );
  }

  // ==============================================================
  // MENU DE OPÇÕES
  // ==============================================================

  void _mostrarMenuOpcoes(
    String docId,
    bool altoContraste,
  ) {
    final fundo =
        AcolleDesign.corFundo(
      altoContraste,
    );

    final texto =
        AcolleDesign.corTexto(
      altoContraste,
    );

    final destaque =
        AcolleDesign.corIcone(
      altoContraste,
    );

    showModalBottomSheet<void>(
      context: context,

      backgroundColor: fundo,

      showDragHandle: true,

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                ListTile(
                  leading: Icon(
                    Icons.visibility,
                    color: destaque,
                  ),

                  title: Text(
                    'Ver detalhes',
                    style:
                        AcolleDesign.texto(
                      tamanho: 17,
                      peso:
                          FontWeight.w600,
                      cor: texto,
                    ),
                  ),

                  onTap: () {
                    Navigator.pop(context);

                    _mostrarDetalhes(
                      docId,
                      altoContraste,
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),

                  title: Text(
                    'Deletar do histórico',
                    style:
                        AcolleDesign.texto(
                      tamanho: 17,
                      peso:
                          FontWeight.w600,
                      cor: texto,
                    ),
                  ),

                  onTap: () {
                    Navigator.pop(context);

                    _deletarItemHistorico(
                      docId,
                      altoContraste,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==============================================================
  // DETALHES
  // ==============================================================

  Future<void> _mostrarDetalhes(
    String docId,
    bool altoContraste,
  ) async {
    final doc = await _firestore
        .collection('verificacoes')
        .doc(docId)
        .get();

    if (!mounted) return;

    final dados = doc.data();

    if (dados == null) return;

    final fundo =
        AcolleDesign.corFundo(
      altoContraste,
    );

    final texto =
        AcolleDesign.corTexto(
      altoContraste,
    );

    final textoSecundario =
        AcolleDesign.corTextoSecundario(
      altoContraste,
    );

    final destaque =
        AcolleDesign.corIcone(
      altoContraste,
    );

    showDialog<void>(
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor: fundo,

          title: Text(
            'Detalhes da Verificação',

            style:
                AcolleDesign.tituloDialogo,
          ),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisSize:
                  MainAxisSize.min,

              children: [
                _buildDetalheLinha(
                  'Tipo:',
                  _obterTituloTipo(
                    dados['tipo']
                            as String? ??
                        '',
                  ),
                  texto,
                ),

                const SizedBox(height: 12),

                _buildDetalheLinha(
                  'Risco:',
                  dados['risco']
                          as String? ??
                      'Desconhecido',
                  texto,
                ),

                const SizedBox(height: 12),

                _buildDetalheLinha(
                  'Percentual:',
                  '${dados['percentual'] as int? ?? 0}%',
                  texto,
                ),

                if (dados['conteudo'] != null &&
                    (dados['conteudo']
                            as String)
                        .isNotEmpty) ...[
                  const SizedBox(height: 12),

                  Text(
                    'Conteúdo:',

                    style:
                        AcolleDesign.texto(
                      tamanho: 16,
                      peso:
                          FontWeight.bold,
                      cor: texto,
                    ),
                  ),

                  const SizedBox(height: 6),

                  SelectableText(
                    dados['conteudo']
                        as String,

                    style:
                        AcolleDesign.texto(
                      tamanho: 15,
                      cor:
                          textoSecundario,
                    ),
                  ),
                ],
              ],
            ),
          ),

          actions: [
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    destaque,

                foregroundColor:
                    Colors.black,
              ),

              onPressed: () {
                Navigator.pop(context);
              },

              child: Text(
                'Fechar',

                style:
                    AcolleDesign.texto(
                  tamanho: 16,
                  peso:
                      FontWeight.bold,
                  cor: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==============================================================
  // LINHA DE DETALHE
  // ==============================================================

  Widget _buildDetalheLinha(
    String label,
    String valor,
    Color texto,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style:
              AcolleDesign.texto(
            tamanho: 15,
            peso:
                FontWeight.bold,
            cor: texto,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            valor,

            style:
                AcolleDesign.texto(
              tamanho: 15,
              cor: texto,
            ),
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // DELETAR
  // ==============================================================

  Future<void> _deletarItem(
    String docId,
  ) async {
    try {
      await _firestore
          .collection('verificacoes')
          .doc(docId)
          .delete();

      if (!mounted) return;

      AcolleDesign.snackbar(
        context,
        'Item removido do histórico.',
        cor: AcolleDesign.verde,
      );
    } catch (e) {
      if (!mounted) return;

      AcolleDesign.snackbar(
        context,
        'Não foi possível remover o item.',
      );
    }
  }

  // ==============================================================
  // CONFIRMAR EXCLUSÃO
  // ==============================================================

  void _deletarItemHistorico(
    String docId,
    bool altoContraste,
  ) {
    final fundo =
        AcolleDesign.corFundo(
      altoContraste,
    );

    final texto =
        AcolleDesign.corTexto(
      altoContraste,
    );

    showDialog<void>(
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor: fundo,

          title: Text(
            'Deletar item',

            style:
                AcolleDesign.tituloDialogo,
          ),

          content: Text(
            'Deseja remover este item do histórico?',

            style:
                AcolleDesign.textoDialogo,
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: Text(
                'Cancelar',

                style:
                    AcolleDesign.texto(
                  tamanho: 16,
                  cor: texto,
                ),
              ),
            ),

            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red.shade700,

                foregroundColor:
                    Colors.white,
              ),

              onPressed: () async {
                Navigator.pop(context);

                await _deletarItem(
                  docId,
                );
              },

              child: Text(
                'Deletar',

                style:
                    AcolleDesign.texto(
                  tamanho: 16,
                  peso:
                      FontWeight.bold,
                  cor: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==============================================================
  // TÍTULO DO TIPO
  // ==============================================================

  String _obterTituloTipo(
    String tipo,
  ) {
    switch (tipo) {
      case 'mensagem':
        return 'Análise de Mensagem';

      case 'link':
        return 'Verificação de Link';

      case 'chamada':
        return 'Alerta de Chamada';

      default:
        return 'Verificação';
    }
  }

  // ==============================================================
  // TEXTO DO RISCO
  // ==============================================================

  String _obterTextoRisco(
    String risco,
  ) {
    switch (risco) {
      case 'alto':
      case 'malicioso':
        return 'Alto risco';

      case 'médio':
      case 'suspeito':
        return 'Risco médio';

      case 'baixo':
      case 'confiável':
        return 'Baixo risco';

      default:
        return 'Desconhecido';
    }
  }

  // ==============================================================
  // ÍCONE DO RISCO
  // ==============================================================

  IconData _iconePorRisco(
    String risco,
  ) {
    switch (risco) {
      case 'alto':
      case 'malicioso':
        return Icons.dangerous;

      case 'médio':
      case 'suspeito':
        return Icons.warning_amber_rounded;

      case 'baixo':
      case 'confiável':
        return Icons.verified;

      default:
        return Icons.help_outline;
    }
  }
}