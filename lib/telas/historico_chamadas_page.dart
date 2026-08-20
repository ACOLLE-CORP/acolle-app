import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../shared/acolle_design.dart';
import '../services/acessibilidade_service.dart';

/// Tela de Histórico de Chamadas.
///
/// Lista as chamadas registradas no Firestore, mostrando um indicador
/// diferente para chamadas suspeitas.
///
/// O tamanho da fonte e o alto contraste são controlados pelo
/// AcessibilidadeService e persistidos através dele.
class HistoricoChamadasPage extends StatefulWidget {
  const HistoricoChamadasPage({super.key});

  @override
  State<HistoricoChamadasPage> createState() =>
      _HistoricoChamadasPageState();
}

class _HistoricoChamadasPageState
    extends State<HistoricoChamadasPage> {
  late final String _uid =
      FirebaseAuth.instance.currentUser!.uid;

  StreamController<int>? _tick;

  int _tickValue = 0;

  final AcessibilidadeService _acessibilidade =
      AcessibilidadeService.instance;

  @override
  void initState() {
    super.initState();

    _tick = StreamController<int>.broadcast();

    _acessibilidade.addListener(
      _onAcessibilidadeChanged,
    );
  }

  void _onAcessibilidadeChanged() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _acessibilidade.removeListener(
      _onAcessibilidadeChanged,
    );

    _tick?.close();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final altoContraste =
        _acessibilidade.altoContraste;

    final fundo =
        AcolleDesign.corFundo(altoContraste);

    return Scaffold(
      backgroundColor: fundo,

      appBar: AcolleDesign.appBarPadrao(
        'Histórico de Chamadas',
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
            color: AcolleDesign.corIcone(
              altoContraste,
            ),

            backgroundColor:
                AcolleDesign.corCard(
              altoContraste,
            ),

            onRefresh: () async {
              _tick?.add(
                _tickValue + 1,
              );

              await Future.delayed(
                const Duration(seconds: 2),
              );
            },

            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chamadas')
                  .where(
                    'usuarioId',
                    isEqualTo: _uid,
                  )
                  .orderBy(
                    'data',
                    descending: true,
                  )
                  .limit(100)
                  .snapshots(),

              builder: (
                context,
                snapshot,
              ) {
                // ==================================================
                // ERRO
                // ==================================================

                if (snapshot.hasError) {
                  final msg =
                      snapshot.error.toString();

                  final waiting =
                      msg.contains(
                            'failed-precondition',
                          ) ||
                          msg.contains(
                            'building',
                          ) ||
                          msg.contains(
                            'currently building',
                          );

                  if (waiting) {
                    Future.delayed(
                      const Duration(
                        seconds: 4,
                      ),
                      () {
                        if (!mounted) return;

                        _tick?.add(
                          _tickValue + 1,
                        );
                      },
                    );

                    return _buildPreparandoIndice(
                      altoContraste,
                    );
                  }

                  return _buildErro(
                    altoContraste,
                    snapshot.error.toString(),
                  );
                }

                // ==================================================
                // CARREGANDO
                // ==================================================

                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return _buildCarregando(
                    altoContraste,
                  );
                }

                // ==================================================
                // DOCUMENTOS
                // ==================================================

                final docs =
                    snapshot.data?.docs ?? [];

                // ==================================================
                // VAZIO
                // ==================================================

                if (docs.isEmpty) {
                  return _buildVazio(
                    altoContraste,
                  );
                }

                // ==================================================
                // LISTA
                // ==================================================

                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    24,
                  ),

                  itemCount: docs.length,

                  itemBuilder: (
                    context,
                    index,
                  ) {
                    final dados =
                        docs[index].data()
                            as Map<String, dynamic>;

                    return _ItemChamada(
                      numero:
                          dados['numero']
                                  as String? ??
                              'Desconhecido',

                      suspeito:
                          dados['suspeito']
                                  as bool? ??
                              false,

                      data:
                          (dados['data']
                                  as Timestamp?)
                              ?.toDate(),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CARREGANDO
  // ============================================================

  Widget _buildCarregando(
    bool altoContraste,
  ) {
    final corTexto =
        AcolleDesign.corTexto(
      altoContraste,
    );

    return ListView(
      children: [
        const SizedBox(height: 80),

        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [
                CircularProgressIndicator(
                  color:
                      AcolleDesign.corIcone(
                    altoContraste,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Carregando chamadas...',
                  textAlign: TextAlign.center,

                  style:
                      AcolleDesign.texto(
                    tamanho: 18,
                    peso:
                        FontWeight.w500,
                    cor: corTexto,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FIRESTORE PREPARANDO ÍNDICE
  // ============================================================

  Widget _buildPreparandoIndice(
    bool altoContraste,
  ) {
    final corTexto =
        AcolleDesign.corTexto(
      altoContraste,
    );

    final corSecundaria =
        AcolleDesign.corTextoSecundario(
      altoContraste,
    );

    final corDestaque =
        AcolleDesign.corIcone(
      altoContraste,
    );

    return ListView(
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
                  size: 72,
                  color: corDestaque,
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
                    peso:
                        FontWeight.w500,
                    cor: corTexto,
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
                    cor: corSecundaria,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _buildErro(
    bool altoContraste,
    String erro,
  ) {
    final corTexto =
        altoContraste
            ? Colors.white
            : AcolleDesign.vermelho;

    return ListView(
      children: [
        const SizedBox(height: 80),

        Padding(
          padding:
              const EdgeInsets.all(20),

          child: AcolleDesign.cartao(
            borda: Border.all(
              color:
                  AcolleDesign.vermelho,
              width: 2,
            ),

            filho: SelectableText(
              'ERRO ao carregar chamadas:\n\n'
              '$erro',

              style:
                  AcolleDesign.texto(
                tamanho: 14,
                cor: corTexto,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _buildVazio(
    bool altoContraste,
  ) {
    final corTexto =
        AcolleDesign.corTexto(
      altoContraste,
    );

    final corDestaque =
        AcolleDesign.corIcone(
      altoContraste,
    );

    return ListView(
      children: [
        const SizedBox(height: 100),

        Center(
          child: Column(
            children: [
              Icon(
                Icons.call_received,
                size: 72,
                color: corDestaque,
              ),

              const SizedBox(height: 20),

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 32,
                ),

                child: Text(
                  'Nenhuma chamada registrada.\n'
                  'As chamadas suspeitas aparecerão '
                  'automaticamente aqui.',

                  textAlign:
                      TextAlign.center,

                  style:
                      AcolleDesign.texto(
                    tamanho: 17,
                    peso:
                        FontWeight.w500,
                    cor: corTexto,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================
// ITEM DA CHAMADA
// ================================================================

class _ItemChamada
    extends StatelessWidget {
  const _ItemChamada({
    required this.numero,
    required this.suspeito,
    required this.data,
  });

  final String numero;
  final bool suspeito;
  final DateTime? data;

  @override
  Widget build(BuildContext context) {
    final altoContraste =
        AcessibilidadeService
            .instance
            .altoContraste;

    final formatada = data != null
        ? DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(data!)
        : 'Data desconhecida';

    final corTexto =
        AcolleDesign.corTexto(
      altoContraste,
    );

    final corTextoSecundario =
        AcolleDesign.corTextoSecundario(
      altoContraste,
    );

    final corRisco =
        AcolleDesign.vermelho;

    final corNormal =
        AcolleDesign.verde;

    final corIcone =
        suspeito
            ? corRisco
            : corNormal;

    return AcolleDesign.cartao(
      margem:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(16),

      filho: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ======================================================
          // ÍCONE
          // ======================================================

          Container(
            width: 48,
            height: 48,

            decoration:
                BoxDecoration(
              color: corIcone.withValues(
                alpha: 0.12,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child: Icon(
              suspeito
                  ? Icons
                      .warning_amber_rounded
                  : Icons.phone_missed,

              color: corIcone,

              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          // ======================================================
          // INFORMAÇÕES
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // NÚMERO
                // ==================================================

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,

                  children: [
                    if (suspeito)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          right: 4,
                        ),

                        child: Text(
                          '⚠️',

                          style:
                              AcolleDesign.texto(
                            tamanho: 18,
                          ),
                        ),
                      ),

                    Flexible(
                      child: Text(
                        numero,

                        overflow:
                            TextOverflow.ellipsis,

                        maxLines: 1,

                        style:
                            AcolleDesign.texto(
                          tamanho: 18,
                          peso:
                              FontWeight.bold,
                          cor: suspeito
                              ? corRisco
                              : corTexto,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // ==================================================
                // CLASSIFICAÇÃO
                // ==================================================

                Text(
                  suspeito
                      ? 'Chamada suspeita de golpe'
                      : 'Chamada comum',

                  style:
                      AcolleDesign.texto(
                    tamanho: 14,
                    peso:
                        FontWeight.w600,
                    cor: suspeito
                        ? corRisco
                        : corTextoSecundario,
                  ),
                ),

                const SizedBox(height: 2),

                // ==================================================
                // DATA
                // ==================================================

                Text(
                  formatada,

                  style:
                      AcolleDesign.texto(
                    tamanho: 12,
                    cor:
                        corTextoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}