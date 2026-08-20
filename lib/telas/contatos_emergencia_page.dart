// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/acolle_design.dart';
import '../services/acessibilidade_service.dart';
import '../services/emergencia_service.dart';

/// Tela de Contatos de Emergência.
///
/// Lista os contatos cadastrados no Firestore e permite:
/// - ligar para o contato;
/// - abrir o WhatsApp;
/// - remover o contato;
/// - adicionar novos contatos.
///
/// O tamanho da fonte e o alto contraste são controlados
/// pelo AcessibilidadeService e persistidos através dele.
class ContatosEmergenciaPage extends StatefulWidget {
  const ContatosEmergenciaPage({super.key});

  @override
  State<ContatosEmergenciaPage> createState() =>
      _ContatosEmergenciaPageState();
}

class _ContatosEmergenciaPageState
    extends State<ContatosEmergenciaPage> {
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
      _atualizarAcessibilidade,
    );
  }

  void _atualizarAcessibilidade() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _acessibilidade.removeListener(
      _atualizarAcessibilidade,
    );

    _tick?.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final altoContraste =
        _acessibilidade.altoContraste;

    final fundo =
        AcolleDesign.corFundo(altoContraste);

    return Scaffold(
      backgroundColor: fundo,

      appBar: AcolleDesign.appBarPadrao(
        'Contatos de Emergência',
      ),

      body: StreamBuilder<int>(
        stream: _tick?.stream,
        initialData: 0,

        builder: (context, tickSnap) {
          final tick =
              tickSnap.data ?? 0;

          if (tick != _tickValue) {
            _tickValue = tick;
          }

          return RefreshIndicator(
            onRefresh: () async {
              _tick?.add(
                _tickValue + 1,
              );

              await Future.delayed(
                const Duration(seconds: 2),
              );
            },

            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore
                  .instance
                  .collection(
                    'contatos_emergencia',
                  )
                  .where(
                    'usuarioId',
                    isEqualTo: _uid,
                  )
                  .orderBy(
                    'criadoEm',
                    descending: true,
                  )
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
                      const Duration(seconds: 4),
                      () {
                        if (!mounted) return;

                        _tick?.add(
                          _tickValue + 1,
                        );
                      },
                    );

                    return ListView(
                      children: [
                        const SizedBox(
                          height: 80,
                        ),

                        Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              24,
                            ),

                            child: Column(
                              children: [
                                Icon(
                                  Icons.hourglass_top,
                                  size: 72,
                                  color:
                                      AcolleDesign.laranja,
                                ),

                                const SizedBox(
                                  height: 16,
                                ),

                                Text(
                                  'Preparando índice do Firestore...\nAguarde alguns segundos.',

                                  textAlign:
                                      TextAlign.center,

                                  style:
                                      AcolleDesign.texto(
                                    tamanho: 17,
                                    peso:
                                        FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(
                                  height: 16,
                                ),

                                Text(
                                  'Puxe para baixo para tentar de novo',

                                  textAlign:
                                      TextAlign.center,

                                  style:
                                      AcolleDesign.texto(
                                    tamanho: 14,
                                    cor:
                                        AcolleDesign
                                            .corTextoSecundario(
                                      altoContraste,
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
                    children: [
                      const SizedBox(
                        height: 80,
                      ),

                      Padding(
                        padding:
                            const EdgeInsets.all(20),

                        child: SelectableText(
                          'ERRO ao carregar contatos:\n${snapshot.error}',

                          style:
                              AcolleDesign.texto(
                            tamanho: 13,
                            cor:
                                AcolleDesign.vermelho,
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
                    children: [
                      const SizedBox(
                        height: 80,
                      ),

                      Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            20,
                          ),

                          child: Text(
                            'Carregando contatos...',

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

                // ==================================================
                // DOCUMENTOS
                // ==================================================

                final docs =
                    snapshot.data?.docs ?? [];

                // ==================================================
                // LISTA VAZIA
                // ==================================================

                if (docs.isEmpty) {
                  return ListView(
                    children: [
                      const SizedBox(
                        height: 100,
                      ),

                      Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            24,
                          ),

                          child: Column(
                            children: [
                              Icon(
                                Icons
                                    .contact_emergency_outlined,
                                size: 72,
                                color:
                                    AcolleDesign.corIcone(
                                  altoContraste,
                                ),
                              ),

                              const SizedBox(
                                height: 16,
                              ),

                              Text(
                                'Você ainda não cadastrou nenhum contato de emergência.',

                                textAlign:
                                    TextAlign.center,

                                style:
                                    AcolleDesign.texto(
                                  tamanho: 18,
                                  peso:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Text(
                                'Toque no botão + para adicionar.',

                                textAlign:
                                    TextAlign.center,

                                style:
                                    AcolleDesign.texto(
                                  tamanho: 16,
                                  cor:
                                      AcolleDesign
                                          .corTextoSecundario(
                                    altoContraste,
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

                // ==================================================
                // LISTA DE CONTATOS
                // ==================================================

                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    96,
                  ),

                  itemCount:
                      docs.length,

                  itemBuilder:
                      (context, index) {
                    final dados =
                        docs[index].data()
                            as Map<String, dynamic>;

                    return _ItemContato(
                      id: docs[index].id,

                      nome:
                          dados['nome']
                                  as String? ??
                              '',

                      telefone:
                          dados['telefone']
                                  as String? ??
                              '',
                    );
                  },
                );
              },
            ),
          );
        },
      ),

      // ==========================================================
      // BOTÃO ADICIONAR
      // ==========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const AdicionarContatoEmergenciaPage(),
            ),
          );
        },

        icon: const Icon(
          Icons.person_add_alt_1,
        ),

        label: Text(
          'Adicionar',

          style: AcolleDesign.texto(
            tamanho: 16,
            peso: FontWeight.bold,
            cor: Colors.white,
          ),
        ),

        backgroundColor:
            AcolleDesign.roxo,

        foregroundColor:
            Colors.white,
      ),
    );
  }
}

// ================================================================
// ITEM DO CONTATO
// ================================================================

class _ItemContato extends StatelessWidget {
  const _ItemContato({
    required this.id,
    required this.nome,
    required this.telefone,
  });

  final String id;
  final String nome;
  final String telefone;

  @override
  Widget build(BuildContext context) {
    final acessibilidade =
        AcessibilidadeService.instance;

    final altoContraste =
        acessibilidade.altoContraste;

    final corTexto =
        AcolleDesign.corTexto(
      altoContraste,
    );

    final corTextoSecundario =
        AcolleDesign.corTextoSecundario(
      altoContraste,
    );

    final corCard =
        AcolleDesign.corCard(
      altoContraste,
    );

    return AcolleDesign.cartao(
      margem: const EdgeInsets.only(
        bottom: 12,
      ),

      filho: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,

        children: [
          // ========================================================
          // ÍCONE
          // ========================================================

          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: corCard,
              shape: BoxShape.circle,

              border: Border.all(
                color:
                    AcolleDesign.corBorda(
                  altoContraste,
                ),
              ),
            ),

            child: Icon(
              Icons.person,
              color:
                  AcolleDesign.roxo,
              size: 28,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          // ========================================================
          // NOME E TELEFONE
          // ========================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  nome,

                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      AcolleDesign.texto(
                    tamanho: 19,
                    peso:
                        FontWeight.bold,
                    cor: corTexto,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  telefone,

                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      AcolleDesign.texto(
                    tamanho: 16,
                    cor:
                        corTextoSecundario,
                  ),
                ),
              ],
            ),
          ),

          // ========================================================
          // AÇÕES
          // ========================================================

          Wrap(
            children: [
              // ====================================================
              // LIGAR
              // ====================================================

              IconButton(
                tooltip: 'Ligar',

                icon: Icon(
                  Icons.phone,
                  color:
                      AcolleDesign.verde,
                ),

                onPressed: () async {
                  final ok =
                      await EmergenciaService
                          .ligarPara(
                    telefone,
                  );

                  if (!context.mounted) {
                    return;
                  }

                  if (ok) {
                    AcolleDesign.snackbar(
                      context,
                      'Discador aberto.',
                      cor:
                          AcolleDesign.verde,
                    );
                  }
                },
              ),

              // ====================================================
              // WHATSAPP
              // ====================================================

              IconButton(
                tooltip:
                    'Enviar pelo WhatsApp',

                icon: Icon(
                  Icons.message,
                  color:
                      AcolleDesign.roxo,
                ),

                onPressed: () async {
                  final ok =
                      await EmergenciaService
                          .abrirWhatsApp(
                    telefone,
                    'Oi $nome, preciso de ajuda. Mensagem do app Acolle.',
                  );

                  if (!context.mounted) {
                    return;
                  }

                  AcolleDesign.snackbar(
                    context,
                    ok
                        ? 'WhatsApp aberto.'
                        : 'Não foi possível abrir o WhatsApp.',
                    cor: ok
                        ? AcolleDesign.verde
                        : AcolleDesign.vermelho,
                  );
                },
              ),

              // ====================================================
              // REMOVER
              // ====================================================

              IconButton(
                tooltip:
                    'Remover contato',

                icon: Icon(
                  Icons.delete_outline,
                  color:
                      AcolleDesign.vermelho,
                ),

                onPressed: () =>
                    _confirmarRemover(
                  context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // CONFIRMAR REMOÇÃO
  // ==============================================================

  void _confirmarRemover(
    BuildContext context,
  ) {
    final acessibilidade =
        AcessibilidadeService.instance;

    final altoContraste =
        acessibilidade.altoContraste;

    showDialog<void>(
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor:
              AcolleDesign.corCard(
            altoContraste,
          ),

          title: Text(
            'Remover contato',

            style:
                AcolleDesign.texto(
              tamanho: 21,
              peso:
                  FontWeight.bold,
            ),
          ),

          content: Text(
            'Deseja remover "$nome" dos contatos de emergência?',

            style:
                AcolleDesign.texto(
              tamanho: 17,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
              ),

              child: Text(
                'Cancelar',

                style:
                    AcolleDesign.texto(
                  tamanho: 16,
                  peso:
                      FontWeight.bold,
                  cor:
                      AcolleDesign.corIcone(
                    altoContraste,
                  ),
                ),
              ),
            ),

            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    AcolleDesign.vermelho,
              ),

              onPressed: () async {
                try {
                  await FirebaseFirestore
                      .instance
                      .collection(
                        'contatos_emergencia',
                      )
                      .doc(id)
                      .delete();

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.pop(
                    context,
                  );

                  AcolleDesign.snackbar(
                    context,
                    'Contato removido.',
                    cor:
                        AcolleDesign.verde,
                  );
                } catch (e) {
                  if (!context.mounted) {
                    return;
                  }

                  Navigator.pop(
                    context,
                  );

                  AcolleDesign.snackbar(
                    context,
                    'Erro ao remover contato.',
                  );
                }
              },

              child: Text(
                'Remover',

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
}

// ================================================================
// ADICIONAR CONTATO
// ================================================================

class AdicionarContatoEmergenciaPage
    extends StatefulWidget {
  const AdicionarContatoEmergenciaPage({
    super.key,
  });

  @override
  State<AdicionarContatoEmergenciaPage>
      createState() =>
          _AdicionarContatoEmergenciaPageState();
}

class _AdicionarContatoEmergenciaPageState
    extends State<AdicionarContatoEmergenciaPage> {
  final _nomeController =
      TextEditingController();

  final _telefoneController =
      TextEditingController();

  bool _carregando = false;

  final AcessibilidadeService
      _acessibilidade =
      AcessibilidadeService.instance;

  @override
  void initState() {
    super.initState();

    _acessibilidade.addListener(
      _atualizarAcessibilidade,
    );
  }

  void _atualizarAcessibilidade() {
    if (!mounted) return;

    setState(() {});
  }

  // ==============================================================
  // SALVAR
  // ==============================================================

  Future<void> _salvar() async {
    final nome =
        _nomeController.text.trim();

    final telefone =
        _telefoneController.text.trim();

    if (nome.isEmpty) {
      AcolleDesign.snackbar(
        context,
        'Digite o nome do contato.',
      );

      return;
    }

    if (telefone
            .replaceAll(
              RegExp(r'[^\d]'),
              '',
            )
            .length <
        10) {
      AcolleDesign.snackbar(
        context,
        'Digite um telefone válido.',
      );

      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final user =
          FirebaseAuth.instance
              .currentUser;

      if (user == null) {
        AcolleDesign.snackbar(
          context,
          'Usuário não encontrado.',
        );

        return;
      }

      await FirebaseFirestore
          .instance
          .collection(
            'contatos_emergencia',
          )
          .add({
        'usuarioId': user.uid,
        'nome': nome,
        'telefone': telefone,
        'criadoEm':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      AcolleDesign.snackbar(
        context,
        'Contato adicionado!',
        cor:
            AcolleDesign.verde,
      );
    } catch (e) {
      if (mounted) {
        AcolleDesign.snackbar(
          context,
          'Erro ao salvar: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ==============================================================
  // ABRIR CONTATOS DO CELULAR
  // ==============================================================

  Future<void> _abrirContatos() async {
    final Uri uri =
        Uri.parse(
      'content://contacts/people',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        AcolleDesign.snackbar(
          context,
          'Conceda permissão de contatos nas Configurações.',
        );
      }
    } catch (_) {
      AcolleDesign.snackbar(
        context,
        'Não foi possível abrir os contatos.',
      );
    }
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final altoContraste =
        _acessibilidade.altoContraste;

    final fundo =
        AcolleDesign.corFundo(
      altoContraste,
    );

    final corTexto =
        AcolleDesign.corTexto(
      altoContraste,
    );

    final corDestaque =
        AcolleDesign.corIcone(
      altoContraste,
    );

    return Scaffold(
      backgroundColor: fundo,

      appBar: AcolleDesign.appBarPadrao(
        'Adicionar contato',
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(28),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              // ==================================================
              // ÍCONE
              // ==================================================

              Icon(
                Icons.person_add_alt_1,
                size: 70,
                color: corDestaque,
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // TÍTULO
              // ==================================================

              Text(
                'Adicionar contato de emergência',

                textAlign:
                    TextAlign.center,

                style:
                    AcolleDesign.texto(
                  tamanho: 26,
                  peso:
                      FontWeight.bold,
                  cor: corTexto,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // NOME
              // ==================================================

              AcolleDesign.campoTexto(
                label: 'Nome completo',
                controller:
                    _nomeController,
                icone:
                    Icons.person_outline,
                teclado:
                    TextInputType.name,
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // TELEFONE
              // ==================================================

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Expanded(
                    child:
                        AcolleDesign.campoTexto(
                      label: 'Telefone',
                      controller:
                          _telefoneController,
                      icone:
                          Icons.phone_outlined,
                      teclado:
                          TextInputType.phone,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  // Botão para abrir os contatos
                  Semantics(
                    button: true,
                    label:
                        'Abrir contatos do celular',

                    child: SizedBox(
                      height: 58,
                      width: 58,

                      child:
                          OutlinedButton(
                        onPressed:
                            _abrirContatos,

                        style:
                            OutlinedButton
                                .styleFrom(
                          side:
                              BorderSide(
                            color:
                                corDestaque,
                            width: 2,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),

                          padding:
                              EdgeInsets.zero,
                        ),

                        child: Icon(
                          Icons
                              .contact_page_outlined,
                          color:
                              corDestaque,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 28,
              ),

              // ==================================================
              // BOTÃO SALVAR
              // ==================================================

              AcolleDesign.botaoPrimario(
                texto:
                    'Salvar contato',

                icone:
                    Icons.check,

                carregando:
                    _carregando,

                onPressed:
                    _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // DISPOSE
  // ==============================================================

  @override
  void dispose() {
    _acessibilidade.removeListener(
      _atualizarAcessibilidade,
    );

    _nomeController.dispose();

    _telefoneController.dispose();

    super.dispose();
  }
}