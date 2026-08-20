import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../shared/acolle_design.dart';
import 'adicionar_lembrete_page.dart';
import '../services/notificacao_service.dart';

/// Tela de Lembretes de Remédios.
///
/// Lista os lembretes cadastrados pelo usuário, permitindo:
/// - ativar/desativar lembretes;
/// - remover lembretes;
/// - adicionar novos lembretes.
///
/// A tela utiliza o AcolleDesign para:
/// - alto contraste;
/// - escala de fonte;
/// - cores;
/// - cartões;
/// - botões;
/// - AppBar.
class LembretesRemediosPage extends StatefulWidget {
  const LembretesRemediosPage({super.key});

  @override
  State<LembretesRemediosPage> createState() =>
      _LembretesRemediosPageState();
}

class _LembretesRemediosPageState extends State<LembretesRemediosPage> {
  late final String _uid =
      FirebaseAuth.instance.currentUser!.uid;

  StreamController<int>? _tick;
  int _tickValue = 0;

  @override
  void initState() {
    super.initState();

    _tick = StreamController<int>.broadcast();
  }

  @override
  void dispose() {
    _tick?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contraste = AcolleDesign.altoContraste;

    return Scaffold(
      backgroundColor:
          AcolleDesign.corFundo(contraste),

      appBar: AcolleDesign.appBarPadrao(
        'Lembretes de Remédios',
      ),

      body: StreamBuilder<int>(
        stream: _tick?.stream,
        initialData: 0,
        builder: (context, tickSnap) {
          final tick = tickSnap.data ?? 0;

          if (tick != _tickValue) {
            _tickValue = tick;
          }

          return RefreshIndicator(
            color: AcolleDesign.corIcone(contraste),

            onRefresh: () async {
              _tick?.add(_tickValue + 1);

              await Future.delayed(
                const Duration(seconds: 2),
              );
            },

            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('remedios')
                  .where(
                    'usuarioId',
                    isEqualTo: _uid,
                  )
                  .orderBy(
                    'ativo',
                    descending: true,
                  )
                  .snapshots(),

              builder: (context, snapshot) {
                // ======================================================
                // ERRO DO FIRESTORE
                // ======================================================

                if (snapshot.hasError) {
                  final msg =
                      snapshot.error.toString();

                  final waitingIndex =
                      msg.contains('failed-precondition') ||
                      msg.contains('building') ||
                      msg.contains('currently building');

                  if (waitingIndex) {
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
                            padding:
                                const EdgeInsets.all(24),

                            child: Column(
                              children: [
                                Icon(
                                  Icons.hourglass_top,
                                  size: AcolleDesign
                                      .tamanhoTexto(72),
                                  color: AcolleDesign
                                      .corIcone(contraste),
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
                                    cor: AcolleDesign
                                        .corTextoSecundario(
                                      contraste,
                                    ),
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
                          'ERRO ao carregar lembretes:\n'
                          '${snapshot.error}',

                          style:
                              AcolleDesign.texto(
                            tamanho: 13,
                            cor: contraste
                                ? Colors.white
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // ======================================================
                // CARREGANDO
                // ======================================================

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

                          child: Text(
                            'Carregando lembretes...',

                            textAlign:
                                TextAlign.center,

                            style:
                                AcolleDesign.texto(
                              tamanho: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // ======================================================
                // DOCUMENTOS
                // ======================================================

                final docs =
                    snapshot.data?.docs ?? [];

                // ======================================================
                // LISTA VAZIA
                // ======================================================

                if (docs.isEmpty) {
                  return ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    children: [
                      const SizedBox(height: 100),

                      Center(
                        child:
                            AcolleDesign.estadoVazio(
                          icone:
                              Icons.medication_outlined,

                          mensagem:
                              'Nenhum lembrete cadastrado.\n'
                              'Toque no botão + para adicionar '
                              'um remédio.',
                        ),
                      ),
                    ],
                  );
                }

                // ======================================================
                // LISTA
                // ======================================================

                return ListView.builder(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    100,
                  ),

                  itemCount: docs.length,

                  itemBuilder:
                      (context, index) {
                    final dados =
                        docs[index].data()
                            as Map<String, dynamic>;

                    return _ItemLembrete(
                      id: docs[index].id,

                      nome:
                          dados['nome']
                                  as String? ??
                              '',

                      horario:
                          dados['horario']
                                  as String? ??
                              '',

                      frequencia:
                          dados['frequencia']
                                  as String? ??
                              'Diário',

                      ativo:
                          dados['ativo']
                                  as bool? ??
                              true,
                    );
                  },
                );
              },
            ),
          );
        },
      ),

      // ================================================================
      // BOTÃO ADICIONAR
      // ================================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const AdicionarLembretePage(),
            ),
          );
        },

        icon: const Icon(Icons.add),

        label: Text(
          'Adicionar',

          style:
              AcolleDesign.texto(
            tamanho: 16,
            peso: FontWeight.bold,
            cor: contraste
                ? Colors.black
                : Colors.white,
          ),
        ),

        backgroundColor:
            AcolleDesign.corIcone(contraste),

        foregroundColor:
            contraste
                ? Colors.black
                : Colors.white,
      ),
    );
  }
}

// ======================================================================
// ITEM DO LEMBRETE
// ======================================================================

class _ItemLembrete extends StatefulWidget {
  const _ItemLembrete({
    required this.id,
    required this.nome,
    required this.horario,
    required this.frequencia,
    required this.ativo,
  });

  final String id;
  final String nome;
  final String horario;
  final String frequencia;
  final bool ativo;

  @override
  State<_ItemLembrete> createState() =>
      _ItemLembreteState();
}

class _ItemLembreteState
    extends State<_ItemLembrete> {
  late bool _ativo = widget.ativo;

  // ====================================================================
  // ATIVAR / DESATIVAR
  // ====================================================================

  Future<void> _alternar(bool valor) async {
    setState(() {
      _ativo = valor;
    });

    try {
      await FirebaseFirestore.instance
          .collection('remedios')
          .doc(widget.id)
          .update({
        'ativo': valor,
      });

      if (valor) {
        await NotificacaoService.agendarLembrete(
          docId: widget.id,
          nome: widget.nome,
          horario: widget.horario,
          frequencia: widget.frequencia,
        );
      } else {
        await NotificacaoService.cancelarLembrete(
          widget.id,
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _ativo = !valor;
      });

      AcolleDesign.snackbar(
        context,
        'Erro ao atualizar lembrete.',
      );
    }
  }

  // ====================================================================
  // REMOVER
  // ====================================================================

  Future<void> _remover() async {
    final confirmar =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        final contraste =
            AcolleDesign.altoContraste;

        return AlertDialog(
          backgroundColor:
              AcolleDesign.corCard(
            contraste,
          ),

          title: Text(
            'Remover lembrete',

            style:
                AcolleDesign.tituloDialogo,
          ),

          content: Text(
            'Deseja remover o lembrete de '
            '"${widget.nome}"?',

            style:
                AcolleDesign.textoDialogo,
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),

              child: Text(
                'Cancelar',

                style:
                    AcolleDesign.texto(
                  tamanho: 16,
                  peso: FontWeight.w600,
                  cor: AcolleDesign
                      .corIcone(
                    contraste,
                  ),
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

              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),

              child: Text(
                'Remover',

                style:
                    AcolleDesign.texto(
                  tamanho: 16,
                  peso: FontWeight.bold,
                  cor: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await NotificacaoService
          .cancelarLembrete(
        widget.id,
      );

      await FirebaseFirestore.instance
          .collection('remedios')
          .doc(widget.id)
          .delete();

      if (!mounted) return;

      AcolleDesign.snackbar(
        context,
        'Lembrete removido.',
      );
    } catch (_) {
      if (!mounted) return;

      AcolleDesign.snackbar(
        context,
        'Não foi possível remover o lembrete.',
      );
    }
  }

  // ====================================================================
  // BUILD
  // ====================================================================

  @override
  Widget build(BuildContext context) {
    final contraste =
        AcolleDesign.altoContraste;

    final corTexto =
        AcolleDesign.corTexto(
      contraste,
    );

    final corSecundaria =
        AcolleDesign.corTextoSecundario(
      contraste,
    );

    final corDestaque =
        AcolleDesign.corIcone(
      contraste,
    );

    return AcolleDesign.cartao(
      padding:
          const EdgeInsets.all(14),

      margem:
          const EdgeInsets.only(
        bottom: 12,
      ),

      filho: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,

        children: [
          // ============================================================
          // ÍCONE
          // ============================================================

          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color:
                  contraste
                      ? Colors.black
                      : AcolleDesign.card,

              shape: BoxShape.circle,

              border: contraste
                  ? Border.all(
                      color: Colors.white,
                      width: 1.5,
                    )
                  : null,
            ),

            child: Icon(
              Icons.medication,
              color: corDestaque,
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          // ============================================================
          // INFORMAÇÕES
          // ============================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  widget.nome,

                  maxLines: 2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      AcolleDesign.texto(
                    tamanho: 19,
                    peso: FontWeight.bold,
                    cor: corTexto,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${widget.horario} • '
                  '${widget.frequencia}',

                  maxLines: 2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      AcolleDesign.texto(
                    tamanho: 15,
                    cor: corSecundaria,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // ============================================================
          // SWITCH
          // ============================================================

          Semantics(
            label: _ativo
                ? 'Lembrete ativado'
                : 'Lembrete desativado',

            toggled: _ativo,

            child: Switch.adaptive(
              value: _ativo,

              activeTrackColor:
                  AcolleDesign.verde,

              activeThumbColor:
                  Colors.white,

              inactiveTrackColor:
                  contraste
                      ? Colors.grey.shade800
                      : Colors.grey.shade300,

              inactiveThumbColor:
                  contraste
                      ? Colors.white
                      : Colors.grey.shade600,

              onChanged: _alternar,
            ),
          ),

          // ============================================================
          // EXCLUIR
          // ============================================================

          IconButton(
            tooltip: 'Remover lembrete',

            icon: Icon(
              Icons.delete_outline,

              color:
                  contraste
                      ? Colors.redAccent
                      : Colors.red.shade400,

              size: 27,
            ),

            onPressed: _remover,
          ),
        ],
      ),
    );
  }
}