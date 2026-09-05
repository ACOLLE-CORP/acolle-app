import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/acessibilidade_service.dart';
import '../services/emergencia_service.dart';
import '../shared/acolle_design.dart';
import '../shared/acolle_icons.dart';
import 'contatos_emergencia_page.dart';

class PedirAjudaPage extends StatefulWidget {
  const PedirAjudaPage({super.key});

  @override
  State<PedirAjudaPage> createState() =>
      _PedirAjudaPageState();
}

class _PedirAjudaPageState
    extends State<PedirAjudaPage> {
  bool _carregando = false;

  Future<void> _ligarParaContato() async {
    if (_carregando) return;

    final usuario =
        FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      AcolleDesign.snackbar(
        context,
        'Usuário não autenticado.',
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('contatos_emergencia')
              .where(
                'usuarioId',
                isEqualTo: usuario.uid,
              )
              .orderBy(
                'criadoEm',
                descending: true,
              )
              .limit(1)
              .get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        setState(() {
          _carregando = false;
        });

        _mostrarNenhumContato();
        return;
      }

      final dados =
          snapshot.docs.first.data();

      final nome =
          dados['nome'] as String? ??
              'contato de emergência';

      final telefone =
          dados['telefone'] as String? ??
              '';

      if (telefone.trim().isEmpty) {
        setState(() {
          _carregando = false;
        });

        AcolleDesign.snackbar(
          context,
          'O contato não possui telefone cadastrado.',
          cor: AcolleDesign.vermelho,
        );
        return;
      }

      final sucesso =
          await EmergenciaService.ligarPara(
        telefone,
      );

      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      if (sucesso) {
        AcolleDesign.snackbar(
          context,
          'Discador aberto para $nome.',
          cor: AcolleDesign.verde,
        );
      } else {
        AcolleDesign.snackbar(
          context,
          'Não foi possível abrir o discador.',
          cor: AcolleDesign.vermelho,
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      AcolleDesign.snackbar(
        context,
        'Não foi possível acessar seus contatos.',
        cor: AcolleDesign.vermelho,
      );
    }
  }

  void _mostrarNenhumContato() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            AcolleIcons.contatos,
            size: 48,
            color: AcolleDesign.laranja,
          ),
          title: const Text(
            'Nenhum contato cadastrado',
          ),
          content: const Text(
            'Cadastre uma pessoa de confiança para poder pedir ajuda rapidamente.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Agora não',
              ),
            ),
            FilledButton.icon(
              icon: const Icon(
                Icons.person_add_rounded,
              ),
              label: const Text(
                'Cadastrar',
              ),
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ContatosEmergenciaPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final altoContraste =
        AcessibilidadeService
            .instance
            .altoContraste;

    return Scaffold(
      backgroundColor:
          AcolleDesign.corFundo(
        altoContraste,
      ),
      appBar:
          AcolleDesign.appBarPadrao(
        'Pedir Ajuda',
        centralizado: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Text(
                'Precisa de ajuda?',
                style:
                    AcolleDesign.texto(
                  tamanho: 27,
                  peso:
                      FontWeight.bold,
                  cor:
                      AcolleDesign.corTexto(
                    altoContraste,
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Entre em contato rapidamente com alguém de confiança.',
                style:
                    AcolleDesign.texto(
                  tamanho: 17,
                  cor:
                      AcolleDesign.corTextoSecundario(
                    altoContraste,
                  ),
                  altura: 1.3,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              _BotaoAjuda(
                icone:
                    AcolleIcons.ligar,
                titulo:
                    'Ligar para meu contato',
                descricao:
                    'Abre o telefone com o contato principal.',
                cor:
                    AcolleDesign.verde,
                carregando:
                    _carregando,
                onTap:
                    _ligarParaContato,
              ),

              const SizedBox(
                height: 12,
              ),

              _BotaoAjuda(
                icone:
                    AcolleIcons.contatos,
                titulo:
                    'Meus contatos de confiança',
                descricao:
                    'Adicione, remova ou entre em contato com alguém.',
                cor:
                    AcolleDesign.roxo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ContatosEmergenciaPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotaoAjuda extends StatelessWidget {
  const _BotaoAjuda({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.cor,
    required this.onTap,
    this.carregando = false,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final Color cor;
  final VoidCallback onTap;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final altoContraste =
        AcessibilidadeService
            .instance
            .altoContraste;

    return Semantics(
      button: true,
      label: '$titulo. $descricao',
      child: Material(
        color:
            AcolleDesign.corCard(
          altoContraste,
        ),
        borderRadius:
            BorderRadius.circular(20),
        child: InkWell(
          onTap:
              carregando ? null : onTap,
          borderRadius:
              BorderRadius.circular(20),
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration:
                      BoxDecoration(
                    color:
                        cor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: carregando
                      ? Padding(
                          padding:
                              const EdgeInsets.all(
                            15,
                          ),
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 3,
                            color: cor,
                          ),
                        )
                      : Icon(
                          icone,
                          size: 32,
                          color: cor,
                        ),
                ),

                const SizedBox(
                  width: 16,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style:
                            AcolleDesign.texto(
                          tamanho: 19,
                          peso:
                              FontWeight.bold,
                          cor:
                              AcolleDesign.corTexto(
                            altoContraste,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        descricao,
                        style:
                            AcolleDesign.texto(
                          tamanho: 16,
                          cor:
                              AcolleDesign.corTextoSecundario(
                            altoContraste,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  AcolleIcons.avancar,
                  size: 30,
                  color:
                      AcolleDesign.corIcone(
                    altoContraste,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
